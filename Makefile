.PHONY: up down install backend frontend generate

## Start PostgreSQL container
up:
	docker compose up -d

## Stop PostgreSQL container
down:
	docker compose down

## Install all dependencies (run once after clone)
install:
	cd backend && go mod tidy
	cd frontend && npm install

## Run backend with hot reload (requires air: go install github.com/air-verse/air@latest)
backend:
	cd backend && air

## Run frontend dev server
frontend:
	cd frontend && npm run dev

## Regenerate sqlc code from SQL queries
generate:
	cd backend && sqlc generate

## Run both dev servers (requires tmux or two terminals)
dev:
	@echo "Start backend: make backend"
	@echo "Start frontend: make frontend"
	@echo "Or open two terminals and run each separately."
