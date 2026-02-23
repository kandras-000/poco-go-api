# Poco Chat

A real-time chat application built with a Go REST API backend and Vue 3 frontend.

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Go, Gin, sqlc, pgx/v5 |
| Auth | JWT (HS256) |
| Real-time | WebSockets (gorilla/websocket) |
| Database | PostgreSQL 16 (Docker) |
| Hot Reload | Air |
| Frontend | Vue 3, Pinia, Vue Router, Axios, Vite |

---

## Prerequisites

Install the following before getting started:

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose plugin
- [Go 1.22+](https://go.dev/dl/)
- [Node.js 18+](https://nodejs.org/) + npm
- [Air](https://github.com/air-verse/air) — Go hot reload

```bash
# Install Air after Go is set up
go install github.com/air-verse/air@latest
```

---

## Project Structure

```
poco-go-api/
├── docker-compose.yml          # PostgreSQL container
├── Makefile                    # Dev commands
├── backend/
│   ├── cmd/api/main.go         # Entry point
│   ├── internal/
│   │   ├── auth/               # JWT generate & validate
│   │   ├── config/             # Env-based config
│   │   ├── db/
│   │   │   ├── connection.go   # pgxpool + run migrations
│   │   │   └── sqlc/           # Type-safe DB layer (sqlc-generated)
│   │   ├── handlers/           # HTTP handlers: auth, users, messages, ws
│   │   ├── middleware/         # JWT auth middleware
│   │   └── ws/                 # WebSocket hub & client
│   ├── sqlc/                   # SQL schema and query definitions
│   ├── sqlc.yaml               # sqlc config
│   ├── .air.toml               # Air hot reload config
│   ├── .env.example            # Environment variable template
│   └── go.mod
└── frontend/
    └── src/
        ├── views/              # Login, Register, Chat
        ├── components/         # NavBar, UserList, MessageList, MessageInput
        ├── stores/             # Pinia stores: auth, chat
        ├── router/             # Vue Router with auth guard
        ├── api/                # Axios instance + interceptors
        └── types/              # Shared TypeScript interfaces
```

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/kandras-000/poco-go-api.git
cd poco-go-api
```

### 2. Install dependencies

```bash
# Go dependencies
cd backend && go mod tidy && cd ..

# Frontend dependencies
cd frontend && npm install && cd ..
```

### 3. Configure environment

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env` if needed (defaults work out of the box with Docker):

```env
DATABASE_URL=postgres://poco:poco_password@localhost:5432/poco_db?sslmode=disable
JWT_SECRET=change-me-in-production-use-a-long-random-string
PORT=8080
```

### 4. Start PostgreSQL

```bash
make up
# or: docker compose up -d
```

Database tables are created automatically on first backend start — no manual migration needed.

### 5. Start the backend

```bash
make backend
# or: cd backend && air
```

API runs at **http://localhost:8080**

### 6. Start the frontend

```bash
make frontend
# or: cd frontend && npm run dev
```

Frontend runs at **http://localhost:5173**

---

## Database Access

### Connection details

| Field | Value |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `poco_db` |
| Username | `poco` |
| Password | `poco_password` |

### Connect with pgAdmin

1. Open pgAdmin
2. Right-click **Servers** → **Register** → **Server**
3. **General** tab → set a name (e.g. `poco`)
4. **Connection** tab → fill in the values above
5. Click **Save**

### Connect with psql

```bash
psql postgres://poco:poco_password@localhost:5432/poco_db
```

### Schema

```sql
-- Users
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username      VARCHAR(50) UNIQUE NOT NULL,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Messages
CREATE TABLE messages (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content      TEXT NOT NULL,
    delivered    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## API Endpoints

### Auth

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | No | Create account |
| POST | `/api/auth/login` | No | Login, returns JWT |

**Register body:**
```json
{ "username": "alice", "email": "alice@example.com", "password": "secret123" }
```

**Login body:**
```json
{ "email": "alice@example.com", "password": "secret123" }
```

**Response:**
```json
{
  "token": "<jwt>",
  "user": { "id": "...", "username": "alice", "email": "alice@example.com", "created_at": "..." }
}
```

### Users

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/users` | Bearer JWT | List all users |

### Messages

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/messages` | Bearer JWT | Send a message |
| GET | `/api/messages/:userId` | Bearer JWT | Get conversation history |

**Send message body:**
```json
{ "recipient_id": "<uuid>", "content": "Hello!" }
```

### WebSocket

| Endpoint | Auth | Description |
|---|---|---|
| `GET /ws?token=<jwt>` | JWT query param | Open real-time connection |

WebSocket messages are JSON envelopes:
```json
{ "type": "message", "data": { "id": "...", "sender_id": "...", "sender_username": "alice", "content": "Hello!", ... } }
```

---

## Messaging Flow

| Recipient state | Behaviour |
|---|---|
| **Online** | Message saved as `delivered = true`, pushed instantly via WebSocket |
| **Offline** | Message saved as `delivered = false`, delivered automatically when recipient next connects |

---

## Make Commands

```bash
make up        # Start PostgreSQL container
make down      # Stop PostgreSQL container
make backend   # Run Go API with hot reload (port 8080)
make frontend  # Run Vue dev server (port 5173)
make install   # Install all dependencies (run once after clone)
make generate  # Regenerate sqlc DB layer from SQL files
```

---

## Production Deployment

Target: `julius-clinic.bnr.la` (119.42.52.217)

Architecture: nginx (80/443) → Go backend (internal 8080) + PostgreSQL (internal 5432). All services run via Docker Compose.

### Prerequisites on your local machine

- `rsync` and `ssh` available
- SSH key authorized on the server (see step 1)

### 1. Authorize your SSH key on the server

If starting from scratch with no SSH key:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
```

Copy the public key to the server via the VPS web console — paste this output into `/root/.ssh/authorized_keys`:

```bash
cat ~/.ssh/id_ed25519.pub
```

On the server (via web console):

```bash
mkdir -p /root/.ssh && chmod 700 /root/.ssh
echo "<paste public key here>" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### 2. Create the `.env` file on the server

```bash
ssh root@119.42.52.217 'bash -c "
mkdir -p /opt/poco
cat > /opt/poco/.env <<ENVEOF
POSTGRES_USER=poco
POSTGRES_PASSWORD=$(openssl rand -hex 16)
POSTGRES_DB=poco_db
JWT_SECRET=$(openssl rand -hex 32)
CORS_ORIGINS=https://julius-clinic.bnr.la
ENVEOF
"'
```

### 3. Install server dependencies

```bash
ssh root@119.42.52.217 "apt-get install -y rsync certbot"
```

### 4. Obtain the SSL certificate

Port 80 must be free (no nginx running yet on first deploy):

```bash
ssh root@119.42.52.217 "certbot certonly --standalone -d julius-clinic.bnr.la --non-interactive --agree-tos --email kandras-000@proton.me"
```

### 5. Set up the certificate renewal hook

Tells certbot to restart nginx after each auto-renewal:

```bash
ssh root@119.42.52.217 "
  cat > /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh << 'EOF'
#!/bin/bash
docker compose -f /opt/poco/docker-compose.prod.yml restart nginx
EOF
  chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
"
```

### 6. Deploy

```bash
bash deploy.sh
```

This rsyncs the project to `/opt/poco` on the server (excluding `.git`, `node_modules`, `dist`, `tmp`, `.env`) and runs `docker compose -f docker-compose.prod.yml up -d --build`.

### Verify

```bash
# All 3 containers should be running/healthy
ssh root@119.42.52.217 "docker compose -f /opt/poco/docker-compose.prod.yml ps"

# API should return 400 (not 502)
curl -s -o /dev/null -w '%{http_code}' -X POST https://julius-clinic.bnr.la/api/auth/register
```

### Re-deploying after code changes

```bash
bash deploy.sh
```

### Connecting to the production database via pgAdmin

The postgres container is bound to `127.0.0.1:5432` on the server — not publicly reachable. Connect via pgAdmin's built-in SSH tunnel.

**In pgAdmin, create a new server:**

1. Right-click **Servers** → **Register** → **Server**
2. **General** tab → Name: `poco-prod`
3. **Connection** tab:

| Field | Value |
|---|---|
| Host | `127.0.0.1` |
| Port | `5432` |
| Database | `poco_db` |
| Username | `poco` |
| Password | *(value of `POSTGRES_PASSWORD` in `/opt/poco/.env` on the server)* |

4. **SSH Tunnel** tab:

| Field | Value |
|---|---|
| Use SSH tunneling | Yes |
| Tunnel host | `119.42.52.217` |
| Tunnel port | `22` |
| Username | `root` |
| Authentication | Identity file |
| Identity file | `~/.ssh/id_ed25519` |

5. Click **Save**

To look up the password at any time:
```bash
ssh root@119.42.52.217 "grep POSTGRES_PASSWORD /opt/poco/.env"
```

### Certificate info

- Auto-renews via certbot's systemd timer (installed with certbot)
- Renewal hook at `/etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh` restarts nginx after renewal
- To check renewal: `ssh root@119.42.52.217 "certbot renew --dry-run"`

---

## Regenerating the DB Layer

If you modify any SQL files under `backend/sqlc/`, regenerate the Go code with:

```bash
# Install sqlc
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

make generate
```
