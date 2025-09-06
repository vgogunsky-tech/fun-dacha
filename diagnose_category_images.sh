#!/bin/bash

# Diagnose Category Images Script
# Quick diagnostic to see what's wrong with category images

set -e

echo "🔍 Diagnosing category image issues..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

echo "📋 1. Category images in database:"
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 
    c.category_id,
    cd.name,
    c.image
FROM oc_category c
LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id AND cd.language_id = 1
WHERE c.image IS NOT NULL AND c.image != ''
ORDER BY c.category_id;
"

echo ""
echo "📋 2. Category images in container filesystem:"
docker compose exec web bash -c "
    echo 'Files in /var/www/html/image/catalog/category/:'
    ls -la /var/www/html/image/catalog/category/ | head -10
"

echo ""
echo "📋 3. Testing specific image files:"
docker compose exec web bash -c "
    for img in c100.jpg c101.jpg c102.jpg c103.jpg c110.jpg c120.jpg; do
        if [ -f \"/var/www/html/image/catalog/category/\$img\" ]; then
            echo \"✅ \$img exists (\$(ls -lh /var/www/html/image/catalog/category/\$img | awk '{print \$5}'))\"
        else
            echo \"❌ \$img missing\"
        fi
    done
"

echo ""
echo "📋 4. Testing HTTP access to images:"
echo "Try these URLs in your browser:"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"
echo "   http://localhost:8080/image/catalog/category/c101.jpg"
echo "   http://localhost:8080/image/catalog/category/c102.jpg"

echo ""
echo "📋 5. Checking local image files:"
if [ -d "opencart_data/image/catalog/category" ]; then
    echo "✅ Local category images found:"
    ls opencart_data/image/catalog/category/ | head -10
else
    echo "❌ Local category images not found in opencart_data/image/catalog/category/"
fi

echo ""
echo "📋 6. Sample category data from CSV:"
if [ -f "../data/categories_list.csv" ]; then
    echo "First 5 categories from CSV:"
    head -6 ../data/categories_list.csv | tail -5
else
    echo "❌ categories_list.csv not found"
fi