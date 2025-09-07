#!/bin/bash

# Fix Images SQL Script
# This script generates SQL to fix image issues without full migration

set -e

echo "🔧 Generating SQL to fix image issues..."

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

echo "🗑️  Cleaning existing product images..."
docker compose -f opencart-docker/docker-compose.yml exec db mysql -u root -pexample opencart -e "
-- Clean existing product images to avoid duplicates
DELETE FROM oc_product_image;
" | cat

echo "🖼️  Updating images from data/images..."
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

# Update primary images in database
echo "🔄 Updating primary images in database..."
docker compose exec db mysql -u root -pexample opencart -e "
-- Update primary images for products that have them
UPDATE oc_product p 
SET image = CONCAT('catalog/product/', p.product_id, '.jpg')
WHERE p.product_id IN (1,2,3,4,5,6,7,8,9,10);

-- Update specific known products
UPDATE oc_product SET image = 'catalog/product/p100001.jpg' WHERE product_id = 1;
UPDATE oc_product SET image = 'catalog/product/p100002.jpg' WHERE product_id = 2;
UPDATE oc_product SET image = 'catalog/product/p100003.jpg' WHERE product_id = 3;
" | cat

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

echo "✅ Image fix completed!"
echo ""
echo "🌐 Test image URLs:"
echo "   http://localhost:8080/image/catalog/product/p100001.jpg"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"