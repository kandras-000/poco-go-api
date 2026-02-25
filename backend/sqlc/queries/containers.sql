-- name: CreateContainer :one
INSERT INTO evidence_containers (user_id, name)
VALUES ($1, $2)
RETURNING *;

-- name: ListContainersByUser :many
SELECT * FROM evidence_containers
WHERE user_id = $1
ORDER BY created_at DESC;

-- name: GetContainerByID :one
SELECT * FROM evidence_containers
WHERE id = $1;

-- name: DeleteContainer :exec
DELETE FROM evidence_containers
WHERE id = $1 AND user_id = $2;
