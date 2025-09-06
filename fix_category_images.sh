#!/bin/bash

# Fix Category Images Script
# This script diagnoses and fixes broken category images

set -e

echo "🖼️ Diagnosing and fixing category images..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

echo "🔍 Step 1: Checking category images in database..."
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 
    c.category_id,
    cd.name,
    c.image,
    CASE 
        WHEN c.image IS NULL OR c.image = '' THEN 'NO IMAGE'
        ELSE c.image
    END as image_status
FROM oc_category c
LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id AND cd.language_id = 1
ORDER BY c.category_id;
"

echo ""
echo "🔍 Step 2: Checking which category image files exist in container..."
docker compose exec web bash -c "
    echo 'Category images in container:'
    ls -la /var/www/html/image/catalog/category/ | head -10
    echo ''
    echo 'Checking specific category images:'
    for img in c100.jpg c101.jpg c102.jpg c103.jpg c110.jpg c120.jpg; do
        if [ -f \"/var/www/html/image/catalog/category/\$img\" ]; then
            echo \"✅ \$img exists\"
        else
            echo \"❌ \$img missing\"
        fi
    done
"

echo ""
echo "🔍 Step 3: Testing image accessibility via HTTP..."
echo "Testing category image URLs:"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"
echo "   http://localhost:8080/image/catalog/category/c101.jpg"
echo "   http://localhost:8080/image/catalog/category/c102.jpg"

echo ""
echo "🔧 Step 4: Fixing category images..."

# Copy category images again to ensure they're in the container
echo "📋 Re-copying category images..."
docker compose cp opencart_data/image/catalog/category web:/var/www/html/image/catalog/category

# Set proper permissions
echo "🔧 Setting permissions..."
docker compose exec web bash -c "
    chown -R www-data:www-data /var/www/html/image/catalog/category/
    chmod -R 755 /var/www/html/image/catalog/category/
"

# Create symbolic links for alternative access
echo "🔧 Creating symbolic links..."
docker compose exec web bash -c "
    ln -sf /var/www/html/image/catalog/category /var/www/html/catalog/category
    ln -sf /var/www/html/image/catalog/category /var/www/html/category
"

# Create .htaccess for image access
echo "🔧 Creating .htaccess for category images..."
docker compose exec web bash -c "
    cat > /var/www/html/image/catalog/category/.htaccess << 'EOF'
# Allow access to images
<Files ~ \"\.(jpg|jpeg|png|gif|webp)$\">
    Order allow,deny
    Allow from all
</Files>
EOF
"

echo ""
echo "🔍 Step 5: Verifying fixes..."
docker compose exec web bash -c "
    echo 'Category images after fix:'
    ls -la /var/www/html/image/catalog/category/ | head -10
    echo ''
    echo 'Testing image access:'
    for img in c100.jpg c101.jpg c102.jpg c103.jpg; do
        if [ -f \"/var/www/html/image/catalog/category/\$img\" ]; then
            echo \"✅ \$img accessible\"
        else
            echo \"❌ \$img still missing\"
        fi
    done
"

echo ""
echo "🔧 Step 6: Updating database with correct image paths..."

# Update category images in database to ensure they have correct paths
docker compose exec db mysql -u root -pexample opencart -e "
UPDATE oc_category SET image = CONCAT('catalog/category/', SUBSTRING_INDEX(image, '/', -1)) 
WHERE image IS NOT NULL AND image != '' AND image NOT LIKE 'catalog/category/%';

UPDATE oc_category SET image = 'catalog/category/c100.jpg' WHERE category_id = 1 AND (image IS NULL OR image = '');
UPDATE oc_category SET image = 'catalog/category/c101.jpg' WHERE category_id = 2 AND (image IS NULL OR image = '');
UPDATE oc_category SET image = 'catalog/category/c102.jpg' WHERE category_id = 3 AND (image IS NULL OR image = '');
UPDATE oc_category SET image = 'catalog/category/c103.jpg' WHERE category_id = 4 AND (image IS NULL OR image = '');
"

echo ""
echo "✅ Category image fix completed!"
echo ""
echo "🔍 Manual verification steps:"
echo "1. Visit: http://localhost:8080/image/catalog/category/c100.jpg"
echo "2. Visit: http://localhost:8080/catalog/category/c100.jpg"
echo "3. Check OpenCart frontend category pages"
echo ""
echo "📋 If images still don't work, the issue might be:"
echo "- Web server configuration"
echo "- OpenCart image path settings"
echo "- Missing image files in data/images/categories/"