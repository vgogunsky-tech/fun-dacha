#!/bin/bash

# Update Images Only Script
# This script only updates images without running full migration

set -e

echo "🖼️  Updating images only..."

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

# Go back to workspace root
cd ..

echo "🖼️  Force updating images from data/images..."

# Force copy product images
if [ -d data/images/products ]; then
    echo "📁 Force copying product images..."
    mkdir -p opencart-docker/opencart_data/image/catalog/product
    # Remove existing images first to force update
    rm -f opencart-docker/opencart_data/image/catalog/product/*
    # Copy all images with force
    cp -f data/images/products/* opencart-docker/opencart_data/image/catalog/product/
    echo "✅ Product images updated: $(ls opencart-docker/opencart_data/image/catalog/product/ | wc -l) files"
    
    # Show specific file info
    if [ -f opencart-docker/opencart_data/image/catalog/product/p100001.jpg ]; then
        echo "📊 p100001.jpg size: $(ls -lh opencart-docker/opencart_data/image/catalog/product/p100001.jpg | awk '{print $5}')"
    fi
else
    echo "❌ data/images/products directory not found"
fi

# Force copy category images
if [ -d data/images/categories ]; then
    echo "📁 Force copying category images..."
    mkdir -p opencart-docker/opencart_data/image/catalog/category
    # Remove existing images first to force update
    rm -f opencart-docker/opencart_data/image/catalog/category/*
    # Copy all images with force
    cp -f data/images/categories/* opencart-docker/opencart_data/image/catalog/category/
    echo "✅ Category images updated: $(ls opencart-docker/opencart_data/image/catalog/category/ | wc -l) files"
else
    echo "❌ data/images/categories directory not found"
fi

# Navigate back to opencart-docker
cd opencart-docker

echo "🖼️  Copying updated images into container..."
docker compose cp opencart_data/image/catalog/product web:/var/www/html/image/catalog/product
docker compose cp opencart_data/image/catalog/category web:/var/www/html/image/catalog/category

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
    if [ -f /var/www/html/image/catalog/product/p100001.jpg ]; then
        echo 'p100001.jpg size in container:'
        ls -lh /var/www/html/image/catalog/product/p100001.jpg
    fi
    echo 'Category images:'
    ls -la /var/www/html/image/catalog/category/ | head -5
"

echo "✅ Images update completed!"
echo ""
echo "🌐 Test image URLs:"
echo "   http://localhost:8080/image/catalog/product/p100001.jpg"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"