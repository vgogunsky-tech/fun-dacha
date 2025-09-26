#!/usr/bin/env bash
set -euo pipefail

# Run MySQL migration against the docker-compose "db" service
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

# Resolve repo root relative to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/opencart-docker/docker-compose.yml"

DB_CID=$(docker compose -f "$COMPOSE_FILE" ps -q db || true)
if [[ -z "$DB_CID" ]]; then
  echo "'db' service is not running. Start it first: (cd opencart-docker && docker compose up -d)" >&2
  exit 1
fi
NETWORK_NAME=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{println $k}}{{end}}' "$DB_CID" | head -n1)
if [[ -z "$NETWORK_NAME" ]]; then
  echo "Could not resolve compose network for db container." >&2
  exit 1
fi

docker run --rm \
  --network "$NETWORK_NAME" \
  -v "$REPO_ROOT":/workspace \
  -w /workspace \
  -e MYSQL_HOST="$MYSQL_HOST" \
  -e MYSQL_PORT="$MYSQL_PORT" \
  -e MYSQL_USER="$MYSQL_USER" \
  -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
  -e MYSQL_DATABASE="$MYSQL_DATABASE" \
  -e OPENCART_DATA="$DATA_DIR" \
  python:3.11-alpine sh -lc "pip install --no-cache-dir pymysql && python3 scripts/load_mysql_from_data.py --data \"$DATA_DIR\" --clean"