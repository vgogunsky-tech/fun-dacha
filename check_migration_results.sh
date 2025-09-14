#!/bin/bash

# Check Migration Results
# This script checks what data was actually inserted into the database

set -e

echo "🔍 Checking Migration Results..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 30
fi

echo "📋 Checking categories..."
docker compose exec db mysql -u root -pexample -e "SELECT category_id, name FROM opencart.oc_category_description WHERE language_id = 20;"

echo ""
echo "📋 Checking products..."
docker compose exec db mysql -u root -pexample -e "SELECT product_id, model, sku, price, status FROM opencart.oc_product;"

echo ""
echo "📋 Checking product descriptions..."
docker compose exec db mysql -u root -pexample -e "SELECT product_id, name FROM opencart.oc_product_description WHERE language_id = 20;"

echo ""
echo "📋 Checking product to category relationships..."
docker compose exec db mysql -u root -pexample -e "SELECT product_id, category_id FROM opencart.oc_product_to_category;"

echo ""
echo "📋 Checking if products are enabled (status = 1)..."
docker compose exec db mysql -u root -pexample -e "SELECT COUNT(*) as enabled_products FROM opencart.oc_product WHERE status = 1;"

echo ""
echo "📋 Checking if categories are enabled (status = 1)..."
docker compose exec db mysql -u root -pexample -e "SELECT COUNT(*) as enabled_categories FROM opencart.oc_category WHERE status = 1;"

echo ""
echo "📋 Checking store settings..."
docker compose exec db mysql -u root -pexample -e "SELECT store_id, name FROM opencart.oc_store;"

echo ""
echo "📋 Checking if products are assigned to store..."
docker compose exec db mysql -u root -pexample -e "SELECT COUNT(*) as products_in_store FROM opencart.oc_product_to_store;"