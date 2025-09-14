#!/bin/bash

# Fix NULL product/category names after migration
# Run this after migrate_with_docker.sh if you see no data in OpenCart UI

echo "🔧 Fixing NULL product/category names after migration..."

# Check if we're in the right directory
if [ ! -f "migrate_with_docker.sh" ]; then
    echo "❌ Please run this script from the repository root directory"
    echo "   cd /path/to/fun-dacha"
    echo "   ./fix_names_after_migration.sh"
    exit 1
fi

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart containers are not running. Please run migrate_with_docker.sh first."
    exit 1
fi

echo "1. 🔧 Fixing product names..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Fix product descriptions for Ukrainian language (language_id = 20)
UPDATE oc_product_description pd 
SET name = CONCAT('Product ', pd.product_id),
    description = CONCAT('Description for product ', pd.product_id),
    meta_title = CONCAT('Product ', pd.product_id),
    meta_description = CONCAT('Meta description for product ', pd.product_id),
    meta_keyword = CONCAT('product,', pd.product_id)
WHERE pd.language_id = 20 AND (name IS NULL OR name = '');

-- Fix product descriptions for English language (language_id = 21)  
UPDATE oc_product_description pd 
SET name = CONCAT('Product ', pd.product_id),
    description = CONCAT('Description for product ', pd.product_id),
    meta_title = CONCAT('Product ', pd.product_id),
    meta_description = CONCAT('Meta description for product ', pd.product_id),
    meta_keyword = CONCAT('product,', pd.product_id)
WHERE pd.language_id = 21 AND (name IS NULL OR name = '');

-- Add missing product descriptions if they don't exist
INSERT IGNORE INTO oc_product_description (product_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT p.product_id, 20, CONCAT('Product ', p.product_id), CONCAT('Description for product ', p.product_id), CONCAT('Product ', p.product_id), CONCAT('Meta description for product ', p.product_id), CONCAT('product,', p.product_id)
FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_description pd WHERE pd.product_id = p.product_id AND pd.language_id = 20);

INSERT IGNORE INTO oc_product_description (product_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT p.product_id, 21, CONCAT('Product ', p.product_id), CONCAT('Description for product ', p.product_id), CONCAT('Product ', p.product_id), CONCAT('Meta description for product ', p.product_id), CONCAT('product,', p.product_id)
FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_description pd WHERE pd.product_id = p.product_id AND pd.language_id = 21);
" | cat

echo ""
echo "2. 🔧 Fixing category names..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Fix category descriptions for Ukrainian language (language_id = 20)
UPDATE oc_category_description cd 
SET name = CONCAT('Category ', cd.category_id),
    description = CONCAT('Description for category ', cd.category_id),
    meta_title = CONCAT('Category ', cd.category_id),
    meta_description = CONCAT('Meta description for category ', cd.category_id),
    meta_keyword = CONCAT('category,', cd.category_id)
WHERE cd.language_id = 20 AND (name IS NULL OR name = '');

-- Fix category descriptions for English language (language_id = 21)
UPDATE oc_category_description cd 
SET name = CONCAT('Category ', cd.category_id),
    description = CONCAT('Description for category ', cd.category_id),
    meta_title = CONCAT('Category ', cd.category_id),
    meta_description = CONCAT('Meta description for category ', cd.category_id),
    meta_keyword = CONCAT('category,', cd.category_id)
WHERE cd.language_id = 21 AND (name IS NULL OR name = '');

-- Add missing category descriptions if they don't exist
INSERT IGNORE INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT c.category_id, 20, CONCAT('Category ', c.category_id), CONCAT('Description for category ', c.category_id), CONCAT('Category ', c.category_id), CONCAT('Meta description for category ', c.category_id), CONCAT('category,', c.category_id)
FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_description cd WHERE cd.category_id = c.category_id AND cd.language_id = 20);

INSERT IGNORE INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT c.category_id, 21, CONCAT('Category ', c.category_id), CONCAT('Description for category ', c.category_id), CONCAT('Category ', c.category_id), CONCAT('Meta description for category ', c.category_id), CONCAT('category,', c.category_id)
FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_description cd WHERE cd.category_id = c.category_id AND cd.language_id = 21);
" | cat

echo ""
echo "3. 🔗 Ensuring all products and categories are assigned to store 0..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Ensure all products are assigned to store 0
INSERT IGNORE INTO oc_product_to_store (product_id, store_id)
SELECT p.product_id, 0 FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_to_store pts WHERE pts.product_id = p.product_id AND pts.store_id = 0);

-- Ensure all categories are assigned to store 0
INSERT IGNORE INTO oc_category_to_store (category_id, store_id)
SELECT c.category_id, 0 FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_to_store cts WHERE cts.category_id = c.category_id AND cts.store_id = 0);
" | cat

echo ""
echo "4. 🧼 Clearing caches..."
docker compose exec web bash -lc "rm -rf /var/www/html/system/storage/cache/* /var/www/html/image/cache/* || true"

echo ""
echo "5. 🔄 Restarting OpenCart..."
docker compose restart web

echo ""
echo "6. ⏳ Waiting for OpenCart to be ready..."
sleep 10

echo ""
echo "7. 🔍 Verifying the fix..."
echo "Products with names:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as products_with_names FROM oc_product_description WHERE name IS NOT NULL AND name != '';" 2>/dev/null

echo ""
echo "Categories with names:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as categories_with_names FROM oc_category_description WHERE name IS NOT NULL AND name != '';" 2>/dev/null

echo ""
echo "8. 🌐 Testing OpenCart accessibility..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/

echo ""
echo "✅ Names fix completed!"
echo ""
echo "🌐 Now check:"
echo "   Frontend: http://localhost:8080"
echo "   Admin: http://localhost:8080/admin"
echo ""
echo "If you still don't see data:"
echo "1. Clear browser cache (Ctrl+F5 or incognito mode)"
echo "2. Wait a few minutes for OpenCart to fully initialize"