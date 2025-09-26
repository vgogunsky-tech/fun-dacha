#!/usr/bin/env bash
set -euo pipefail

# Dockerized runner for SQLite migration (load_sqlite_from_data.py)
# Env overrides:
#   OPENCART_DB   - path to SQLite DB inside the container (default: /workspace/opencart-docker/opencart.db)
#   OPENCART_DATA - path to data dir inside the container (default: /workspace/data)
#   NO_CLEAN=1    - skip cleanup before import (by default cleanup is performed)

DB_PATH="${OPENCART_DB:-/workspace/opencart-docker/opencart.db}"
DATA_DIR="${OPENCART_DATA:-/workspace/data}"
FLAG="--clean"
if [[ "${NO_CLEAN:-}" == "1" ]]; then
  FLAG="--no-clean"
fi

docker run --rm \
  -v "$(pwd)":/workspace \
  -w /workspace \
  python:3.11-alpine \
  python3 scripts/load_sqlite_from_data.py --db "$DB_PATH" --data "$DATA_DIR" $FLAG

