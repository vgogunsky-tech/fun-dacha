#!/bin/bash

# Check OpenCart Database Structure
# This script checks what tables and columns exist in your OpenCart database

set -e

echo "🔍 Checking OpenCart Database Structure..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 30
fi

echo "📋 Checking oc_category table structure..."
docker compose exec db mysql -u root -pexample -e "DESCRIBE opencart.oc_category;"

echo ""
echo "📋 Checking oc_product table structure..."
docker compose exec db mysql -u root -pexample -e "DESCRIBE opencart.oc_product;"

echo ""
echo "📋 Checking existing tables..."
docker compose exec db mysql -u root -pexample -e "SHOW TABLES FROM opencart LIKE 'oc_%';"

echo ""
echo "📋 Checking existing data in oc_category..."
docker compose exec db mysql -u root -pexample -e "SELECT COUNT(*) as category_count FROM opencart.oc_category;"

echo ""
echo "📋 Checking existing data in oc_product..."
docker compose exec db mysql -u root -pexample -e "SELECT COUNT(*) as product_count FROM opencart.oc_product;"