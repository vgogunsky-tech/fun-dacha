#!/bin/bash

# Check Database Products Script
# This script shows what products are actually in the database

set -e

echo "🔍 Checking what products are in the database..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

echo "📋 All products in database:"
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 
    p.product_id,
    p.model,
    p.price,
    pd.name,
    pd.description
FROM oc_product p
LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id AND pd.language_id = 1
ORDER BY p.product_id;
"

echo ""
echo "📊 Product counts:"
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 'Total products:' as status, COUNT(*) as count FROM oc_product;
SELECT 'Products with descriptions:' as status, COUNT(*) as count FROM oc_product_description;
SELECT 'Products with images:' as status, COUNT(*) as count FROM oc_product WHERE image IS NOT NULL AND image != '';
"

echo ""
echo "🔍 Sample product names:"
docker compose exec db mysql -u root -pexample opencart -e "
SELECT name FROM oc_product_description WHERE language_id = 1 ORDER BY product_id LIMIT 10;
"