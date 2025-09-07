#!/bin/bash

set -e

echo "🧩 Applying inventory options to OpenCart..."

if [ ! -f "inventory_options.sql" ]; then
	echo "❌ inventory_options.sql not found. Run: python3 generate_inventory_options_sql.py"
	exit 1
fi

cd opencart-docker

echo "📦 Ensuring containers are up..."
if ! docker compose ps | grep -q "Up"; then
	docker compose up -d
	sleep 10
fi

echo "🔍 Testing DB connection..."
docker compose exec db mysql -u root -pexample -e "SELECT 1;" opencart

echo "📥 Importing SQL..."
docker compose exec -T db mysql -u root -pexample opencart < ../inventory_options.sql

if [ $? -eq 0 ]; then
	echo "✅ Inventory options applied."
else
	echo "❌ Failed to apply inventory options."
	exit 1
fi