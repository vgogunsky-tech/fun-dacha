#!/usr/bin/env bash
set -euo pipefail

# Copy category and product images into the web container's OpenCart image dir
# Source folders (on host):
#   opencart-docker/opencart_data/image/catalog/{category,product}
#   data/images/{categories,products}
# Destination (container): /var/www/html/image/catalog/{category,product}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/opencart-docker/docker-compose.yml"

WEB_CID=$(docker compose -f "$COMPOSE_FILE" ps -q web || true)
if [[ -z "$WEB_CID" ]]; then
  echo "'web' service is not running. Start it first: (cd opencart-docker && docker compose up -d)" >&2
  exit 1
fi

DEST_BASE="/var/www/html/image/catalog"

# Ensure destination dirs exist
docker exec "$WEB_CID" sh -lc "mkdir -p '$DEST_BASE/category' '$DEST_BASE/product'"

# Copy from opencart_data
SRC_OC_BASE="$REPO_ROOT/opencart-docker/opencart_data/image/catalog"
for folder in category product; do
  SRC_DIR="$SRC_OC_BASE/$folder"
  if [[ -d "$SRC_DIR" ]]; then
    echo "Copying $folder images from opencart_data..."
    docker cp "$SRC_DIR/." "$WEB_CID:$DEST_BASE/$folder/"
  fi
done

# Copy from data/images
SRC_DATA_BASE="$REPO_ROOT/data/images"
if [[ -d "$SRC_DATA_BASE/categories" ]]; then
  echo "Copying category images from data/images/categories..."
  docker cp "$SRC_DATA_BASE/categories/." "$WEB_CID:$DEST_BASE/category/"
fi
if [[ -d "$SRC_DATA_BASE/products" ]]; then
  echo "Copying product images from data/images/products..."
  docker cp "$SRC_DATA_BASE/products/." "$WEB_CID:$DEST_BASE/product/"
fi

echo "Image copy completed."

