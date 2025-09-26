#!/usr/bin/env bash
set -euo pipefail

# Install UA localization: copy language files into the web container and run SQL updates.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/opencart-docker/docker-compose.yml"

WEB_CID=$(docker compose -f "$COMPOSE_FILE" ps -q web || true)
DB_CID=$(docker compose -f "$COMPOSE_FILE" ps -q db || true)

if [[ -z "$WEB_CID" || -z "$DB_CID" ]]; then
  echo "Compose services not running. Start them first: (cd opencart-docker && docker compose up -d)" >&2
  exit 1
fi

echo "Installing UA language files into web container..."
docker exec "$WEB_CID" sh -lc "mkdir -p /var/www/html/admin/language/uk-ua /var/www/html/catalog/language/uk-ua"
docker cp "$REPO_ROOT/localization/upload/admin/language/uk-ua/." "$WEB_CID:/var/www/html/admin/language/uk-ua/"
docker cp "$REPO_ROOT/localization/upload/catalog/language/uk-ua/." "$WEB_CID:/var/www/html/catalog/language/uk-ua/"

echo "Applying localization SQL to DB..."
# Feed install.sql via stdin into mysql inside the db container
docker compose -f "$COMPOSE_FILE" exec -T db sh -lc 'mysql -u root -pexample opencart' < "$REPO_ROOT/localization/install.sql"

echo "Localization installed. Verifying active languages:"
docker compose -f "$COMPOSE_FILE" exec -T db sh -lc "mysql -u root -pexample -e 'SELECT language_id, name, code, status FROM opencart.oc_language ORDER BY language_id;'" | cat

echo "Done."

