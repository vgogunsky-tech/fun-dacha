#!/usr/bin/env bash
set -euo pipefail

# Run MySQL migration inside the docker-compose "db" service
# Uses environment variables or defaults:
#   MYSQL_HOST=db
#   MYSQL_PORT=3306
#   MYSQL_USER=root
#   MYSQL_PASSWORD=example
#   MYSQL_DATABASE=opencart
#   OPENCART_DATA=/workspace/data (path inside container)

MYSQL_HOST="${MYSQL_HOST:-db}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-example}"
MYSQL_DATABASE="${MYSQL_DATABASE:-opencart}"
DATA_DIR="${OPENCART_DATA:-/workspace/data}"

# Copy repo path into container via bind mount using temporary python image, then run script against DB service network
# Simpler: exec into web or db? We'll run in a transient python container attached to compose network.

NETWORK_NAME=$(docker compose ps -q db | xargs docker inspect --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}')
if [[ -z "$NETWORK_NAME" ]]; then
  echo "Could not determine compose network; ensure 'db' is up." >&2
  exit 1
fi

# Grab network by project name (more robust)
PROJECT_NAME=$(basename "$(pwd)")
COMPOSE_NETWORK=$(docker network ls --format '{{.Name}}' | grep -E "${PROJECT_NAME}_default|default" | head -n1 || true)

docker run --rm \
  --network "${COMPOSE_NETWORK:-${PROJECT_NAME}_default}" \
  -v "$(pwd)":/workspace \
  -w /workspace \
  -e MYSQL_HOST="$MYSQL_HOST" \
  -e MYSQL_PORT="$MYSQL_PORT" \
  -e MYSQL_USER="$MYSQL_USER" \
  -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
  -e MYSQL_DATABASE="$MYSQL_DATABASE" \
  -e OPENCART_DATA="$DATA_DIR" \
  python:3.11-alpine sh -lc "pip install --no-cache-dir pymysql && python3 scripts/load_mysql_from_data.py --data \"$DATA_DIR\" --clean"