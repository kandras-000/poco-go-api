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

## Regenerating the DB Layer

If you modify any SQL files under `backend/sqlc/`, regenerate the Go code with:

```bash
# Install sqlc
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

make generate
```
