#!/bin/bash

# Quick Database Clean Script
# This script only cleans the database without full container reset

set -e

echo "🧹 Quick Database Clean..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

echo "🗑️  Cleaning database tables..."
docker compose exec db mysql -u root -pexample opencart -e "
-- Clean all product-related data
DELETE FROM oc_product_option_value;
DELETE FROM oc_product_option;
DELETE FROM oc_product_to_category;
DELETE FROM oc_product_description;
DELETE FROM oc_product_image;
DELETE FROM oc_product_attribute;
DELETE FROM oc_product_to_store;
DELETE FROM oc_product_to_layout;
DELETE FROM oc_product;

-- Clean all category-related data
DELETE FROM oc_category_path;
DELETE FROM oc_category_description;
DELETE FROM oc_category_to_store;
DELETE FROM oc_category_to_layout;
DELETE FROM oc_category;

-- Clean all option-related data
DELETE FROM oc_option_value_description;
DELETE FROM oc_option_value;
DELETE FROM oc_option_description;
DELETE FROM oc_option;

-- Clean all attribute-related data
DELETE FROM oc_attribute_description;
DELETE FROM oc_attribute;

-- Clean SEO URLs
DELETE FROM oc_seo_url;

-- Reset auto-increment counters
ALTER TABLE oc_product AUTO_INCREMENT = 1;
ALTER TABLE oc_category AUTO_INCREMENT = 1;
ALTER TABLE oc_option AUTO_INCREMENT = 1;
ALTER TABLE oc_option_value AUTO_INCREMENT = 1;
ALTER TABLE oc_attribute AUTO_INCREMENT = 1;
" | cat

echo "✅ Database cleaned successfully!"
echo "You can now run ./migrate_with_docker.sh for a fresh migration"