#!/bin/bash

# Simple Copy Images Script
# This script simply copies images from local opencart_data to the Docker container

set -e

echo "🖼️ Copying images to Docker container..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

echo "📋 Copying product images..."
docker compose cp opencart_data/image/catalog/product web:/var/www/html/image/catalog/product

echo "📋 Copying category images..."
docker compose cp opencart_data/image/catalog/category web:/var/www/html/image/catalog/category

echo "🔧 Setting permissions..."
docker compose exec web bash -c "
    chown -R www-data:www-data /var/www/html/image/
    chmod -R 755 /var/www/html/image/
"

echo "✅ Images copied successfully!"
echo ""
echo "🔍 Test the images:"
echo "   http://localhost:8080/image/catalog/product/p100001.jpg"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"