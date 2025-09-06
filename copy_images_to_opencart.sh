#!/bin/bash

# Copy Images to OpenCart Script
# This script copies images from data/images/ to the correct OpenCart locations

set -e

echo "🖼️ Copying images to OpenCart..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
echo "📋 Checking OpenCart containers status..."
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    
    # Wait for containers to be ready
    echo "⏳ Waiting for containers to be ready..."
    sleep 10
fi

# Copy category images
echo "📋 Copying category images..."
if [ -d "../data/images/categories" ]; then
    docker compose cp ../data/images/categories web:/var/www/html/image/catalog/category
    echo "✅ Category images copied to /var/www/html/image/catalog/category/"
else
    echo "⚠️ Category images directory not found: ../data/images/categories"
fi

# Copy product images
echo "📋 Copying product images..."
if [ -d "../data/images/products" ]; then
    docker compose cp ../data/images/products web:/var/www/html/image/catalog/product
    echo "✅ Product images copied to /var/www/html/image/catalog/product/"
else
    echo "⚠️ Product images directory not found: ../data/images/products"
fi

# Set proper permissions
echo "🔧 Setting proper permissions..."
docker compose exec web bash -c "
    chown -R www-data:www-data /var/www/html/image/catalog/
    chmod -R 755 /var/www/html/image/catalog/
"

echo "✅ Images copied successfully!"
echo ""
echo "🖼️ Images are now available at:"
echo "   - Categories: http://localhost:8080/image/catalog/category/"
echo "   - Products: http://localhost:8080/image/catalog/product/"
echo ""
echo "📋 You can verify by visiting:"
echo "   - http://localhost:8080/image/catalog/category/c100.jpg"
echo "   - http://localhost:8080/image/catalog/product/p100001.jpg"

echo "🎉 Image copy process completed!"