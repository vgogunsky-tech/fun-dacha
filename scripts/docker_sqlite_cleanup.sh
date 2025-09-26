#!/usr/bin/env bash
set -euo pipefail

# Dockerized runner for SQLite cleanup (cleanup_sqlite_opencart.py)
# Env overrides:
#   OPENCART_DB - path to SQLite DB inside the container (default: /workspace/opencart-docker/opencart.db)

DB_PATH="${OPENCART_DB:-/workspace/opencart-docker/opencart.db}"

docker run --rm \
  -v "$(pwd)":/workspace \
  -w /workspace \
  python:3.11-alpine \
  python3 scripts/cleanup_sqlite_opencart.py --db "$DB_PATH"