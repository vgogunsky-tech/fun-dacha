#!/bin/bash

# Check Database Structure Script
# This script checks the actual structure of OpenCart database tables

set -e

echo "🔍 Checking OpenCart database structure..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

echo "📋 1. Checking oc_language table structure:"
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_language;"

echo ""
echo "📋 2. Checking oc_setting table structure:"
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_setting;"

echo ""
echo "📋 3. Checking oc_product table structure:"
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_product;"

echo ""
echo "📋 4. Checking oc_category table structure:"
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_category;"

echo ""
echo "📋 5. Checking oc_product_description table structure:"
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_product_description;"

echo ""
echo "📋 6. Checking oc_category_description table structure:"
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_category_description;"

echo ""
echo "📋 7. Current languages in database:"
docker compose exec db mysql -u root -pexample opencart -e "SELECT * FROM oc_language;"

echo ""
echo "📋 8. Current settings:"
docker compose exec db mysql -u root -pexample opencart -e "SELECT `key`, value FROM oc_setting WHERE `key` LIKE '%language%' LIMIT 10;"