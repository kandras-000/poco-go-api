package db

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

func NewPool(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("unable to create connection pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("unable to ping database: %w", err)
	}

	return pool, nil
}

func RunMigrations(ctx context.Context, pool *pgxpool.Pool) error {
	schema := `
	CREATE EXTENSION IF NOT EXISTS "pgcrypto";

	CREATE TABLE IF NOT EXISTS users (
		id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
		username     VARCHAR(50)  UNIQUE NOT NULL,
		email        VARCHAR(255) UNIQUE NOT NULL,
		password_hash TEXT        NOT NULL,
		created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS messages (
		id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
		sender_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		recipient_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		content      TEXT        NOT NULL,
		delivered    BOOLEAN     NOT NULL DEFAULT FALSE,
		created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
	);

	CREATE INDEX IF NOT EXISTS idx_messages_recipient        ON messages(recipient_id);
	CREATE INDEX IF NOT EXISTS idx_messages_sender_recipient ON messages(sender_id, recipient_id);

	CREATE TABLE IF NOT EXISTS evidence (
		id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		filename      VARCHAR(255) NOT NULL,
		original_name VARCHAR(255) NOT NULL,
		mime_type     VARCHAR(100) NOT NULL,
		file_size     BIGINT NOT NULL,
		description   TEXT,
		latitude      DOUBLE PRECISION,
		longitude     DOUBLE PRECISION,
		created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
	);
	CREATE INDEX IF NOT EXISTS idx_evidence_user_id ON evidence(user_id);
	`

	_, err := pool.Exec(ctx, schema)
	return err
}
