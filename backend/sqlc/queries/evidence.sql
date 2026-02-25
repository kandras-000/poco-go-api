-- name: CreateEvidence :one
INSERT INTO evidence (user_id, container_id, filename, original_name, mime_type, file_size, description, latitude, longitude)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- name: ListEvidenceByContainer :many
SELECT * FROM evidence
WHERE container_id = $1
ORDER BY created_at DESC;

-- name: GetEvidenceByID :one
SELECT * FROM evidence
WHERE id = $1;

-- name: DeleteEvidence :exec
DELETE FROM evidence
WHERE id = $1 AND user_id = $2;
