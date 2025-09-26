#!/usr/bin/env bash
set -euo pipefail

# Copy category and product images into the web container's OpenCart image dir
# Source folders (on host):
#   opencart-docker/opencart_data/image/catalog/category
#   opencart-docker/opencart_data/image/catalog/product
# Destination (container): /var/www/html/image/catalog/{category,product}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/opencart-docker/docker-compose.yml"

WEB_CID=$(docker compose -f "$COMPOSE_FILE" ps -q web || true)
if [[ -z "$WEB_CID" ]]; then
  echo "'web' service is not running. Start it first: (cd opencart-docker && docker compose up -d)" >&2
  exit 1
fi

SRC_BASE="$REPO_ROOT/opencart-docker/opencart_data/image/catalog"
DEST_BASE="/var/www/html/image/catalog"

for folder in category product; do
  SRC_DIR="$SRC_BASE/$folder"
  if [[ -d "$SRC_DIR" ]]; then
    echo "Copying $folder images..."
    docker cp "$SRC_DIR/." "$WEB_CID:$DEST_BASE/$folder/"
  else
    echo "Skip: $SRC_DIR not found"
  fi
done

echo "Image copy completed."

