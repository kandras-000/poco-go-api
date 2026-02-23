#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="root@119.42.52.217"
REMOTE_DIR="/opt/poco"

echo "Syncing files to ${REMOTE_HOST}:${REMOTE_DIR}..."
rsync -avz --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='frontend/node_modules' \
  --exclude='frontend/dist' \
  --exclude='backend/tmp' \
  --exclude='.env' \
  --exclude='*.env' \
  . "${REMOTE_HOST}:${REMOTE_DIR}"

echo "Deploying on remote..."
ssh "${REMOTE_HOST}" "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml up -d --build"

echo "Deploy complete."
