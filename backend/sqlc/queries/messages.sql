-- name: CreateMessage :one
INSERT INTO messages (sender_id, recipient_id, content, delivered)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetMessagesBetweenUsers :many
SELECT * FROM messages
WHERE (sender_id = $1 AND recipient_id = $2)
   OR (sender_id = $2 AND recipient_id = $1)
ORDER BY created_at ASC;

-- name: GetUndeliveredMessages :many
SELECT * FROM messages
WHERE recipient_id = $1 AND delivered = FALSE
ORDER BY created_at ASC;

-- name: MarkMessageDelivered :exec
UPDATE messages SET delivered = TRUE WHERE id = $1;

-- name: MarkAllMessagesDelivered :exec
UPDATE messages SET delivered = TRUE
WHERE recipient_id = $1 AND delivered = FALSE;
