-- name: CreateMessage :one
INSERT INTO messages (sender_id, recipient_id, content, delivered)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetMessagesBetweenUsers :many
SELECT
    m.id, m.sender_id, m.recipient_id, m.content, m.delivered, m.created_at,
    u.username AS sender_username
FROM messages m
JOIN users u ON u.id = m.sender_id
WHERE (m.sender_id = $1 AND m.recipient_id = $2)
   OR (m.sender_id = $2 AND m.recipient_id = $1)
ORDER BY m.created_at ASC;

-- name: GetUndeliveredMessages :many
SELECT
    m.id, m.sender_id, m.recipient_id, m.content, m.delivered, m.created_at,
    u.username AS sender_username
FROM messages m
JOIN users u ON u.id = m.sender_id
WHERE m.recipient_id = $1 AND m.delivered = FALSE
ORDER BY m.created_at ASC;

-- name: MarkMessageDelivered :exec
UPDATE messages SET delivered = TRUE WHERE id = $1;

-- name: MarkAllMessagesDelivered :exec
UPDATE messages SET delivered = TRUE
WHERE recipient_id = $1 AND delivered = FALSE;
