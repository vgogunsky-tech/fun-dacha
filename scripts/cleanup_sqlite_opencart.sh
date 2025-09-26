#!/usr/bin/env bash
set -euo pipefail

DB_PATH="${1:-${OPENCART_DB:-/workspace/opencart-docker/opencart.db}}"

python3 "$(dirname "$0")/cleanup_sqlite_opencart.py" --db "$DB_PATH"