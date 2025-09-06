#!/bin/bash

# Fixed Image Copying Script
# This script copies images with proper path detection

set -e

echo "🖼️ Copying images to Docker container..."

# We're already in the opencart-docker directory when called from simple_sql_migration.sh
# No need to cd again

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

# Check for images in different possible locations
echo "🔍 Looking for images..."

# Check current directory first
if [ -d "opencart_data/image/catalog/product" ]; then
    echo "✅ Found product images in opencart_data/image/catalog/product/"
    docker compose cp opencart_data/image/catalog/product web:/var/www/html/image/catalog/product
    echo "✅ Product images copied"
elif [ -d "../opencart_data/image/catalog/product" ]; then
    echo "✅ Found product images in ../opencart_data/image/catalog/product/"
    docker compose cp ../opencart_data/image/catalog/product web:/var/www/html/image/catalog/product
    echo "✅ Product images copied from parent directory"
else
    echo "❌ Product images not found in either location"
    echo "   Checked: opencart_data/image/catalog/product/"
    echo "   Checked: ../opencart_data/image/catalog/product/"
fi

if [ -d "opencart_data/image/catalog/category" ]; then
    echo "✅ Found category images in opencart_data/image/catalog/category/"
    docker compose cp opencart_data/image/catalog/category web:/var/www/html/image/catalog/category
    echo "✅ Category images copied"
elif [ -d "../opencart_data/image/catalog/category" ]; then
    echo "✅ Found category images in ../opencart_data/image/catalog/category/"
    docker compose cp ../opencart_data/image/catalog/category web:/var/www/html/image/catalog/category
    echo "✅ Category images copied from parent directory"
else
    echo "❌ Category images not found in either location"
    echo "   Checked: opencart_data/image/catalog/category/"
    echo "   Checked: ../opencart_data/image/catalog/category/"
fi

# Set proper permissions
echo "🔧 Setting permissions..."
docker compose exec web bash -c "
    chown -R www-data:www-data /var/www/html/image/
    chmod -R 755 /var/www/html/image/
    echo 'Permissions updated'
"

# Verify images in container
echo "🔍 Verifying images in container..."
docker compose exec web bash -c "
    echo 'Product images:'
    ls -la /var/www/html/image/catalog/product/ | head -5
    echo 'Category images:'
    ls -la /var/www/html/image/catalog/category/ | head -5
"

echo "✅ Image copying completed!"
echo ""
echo "🌐 Test image URLs:"
echo "   http://localhost:8080/image/catalog/product/p100001.jpg"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"