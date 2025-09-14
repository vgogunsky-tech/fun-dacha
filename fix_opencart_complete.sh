#!/bin/bash

echo "🔧 Complete OpenCart Fix Script"
echo "==============================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the opencart-docker directory"
    echo "   cd opencart-docker"
    echo "   ../fix_opencart_complete.sh"
    exit 1
fi

echo "1. Stopping all containers..."
docker compose down

echo ""
echo "2. Starting containers..."
docker compose up -d

echo ""
echo "3. Waiting for containers to be ready..."
sleep 10

echo ""
echo "4. Checking container status..."
docker compose ps

echo ""
echo "5. Fixing product descriptions (NULL names issue)..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Fix product descriptions for Ukrainian language (language_id = 20)
UPDATE oc_product_description pd 
SET name = CONCAT('Product ', pd.product_id)
WHERE pd.language_id = 20 AND (name IS NULL OR name = '');

-- Fix product descriptions for English language (language_id = 21)  
UPDATE oc_product_description pd 
SET name = CONCAT('Product ', pd.product_id)
WHERE pd.language_id = 21 AND (name IS NULL OR name = '');

-- Add missing product descriptions if they don't exist
INSERT IGNORE INTO oc_product_description (product_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT p.product_id, 20, CONCAT('Product ', p.product_id), '', CONCAT('Product ', p.product_id), '', ''
FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_description pd WHERE pd.product_id = p.product_id AND pd.language_id = 20);

INSERT IGNORE INTO oc_product_description (product_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT p.product_id, 21, CONCAT('Product ', p.product_id), '', CONCAT('Product ', p.product_id), '', ''
FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_description pd WHERE pd.product_id = p.product_id AND pd.language_id = 21);
"

echo ""
echo "6. Fixing category descriptions (NULL names issue)..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Fix category descriptions for Ukrainian language (language_id = 20)
UPDATE oc_category_description cd 
SET name = CONCAT('Category ', cd.category_id)
WHERE cd.language_id = 20 AND (name IS NULL OR name = '');

-- Fix category descriptions for English language (language_id = 21)
UPDATE oc_category_description cd 
SET name = CONCAT('Category ', cd.category_id)
WHERE cd.language_id = 21 AND (name IS NULL OR name = '');

-- Add missing category descriptions if they don't exist
INSERT IGNORE INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT c.category_id, 20, CONCAT('Category ', c.category_id), '', CONCAT('Category ', c.category_id), '', ''
FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_description cd WHERE cd.category_id = c.category_id AND cd.language_id = 20);

INSERT IGNORE INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
SELECT c.category_id, 21, CONCAT('Category ', c.category_id), '', CONCAT('Category ', c.category_id), '', ''
FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_description cd WHERE cd.category_id = c.category_id AND cd.language_id = 21);
"

echo ""
echo "7. Setting up proper store configuration..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Create default store
INSERT IGNORE INTO oc_store (store_id, name, url, ssl) 
VALUES (0, 'Fun Dacha Store', 'http://localhost:8080/', 'http://localhost:8080/');

-- Set up essential store settings
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) VALUES 
(0, 'config', 'config_language', 'uk-ua', 0),
(0, 'config', 'config_currency', 'UAH', 0),
(0, 'config', 'config_admin_language', 'uk-ua', 0),
(0, 'config', 'config_name', 'Fun Dacha', 0),
(0, 'config', 'config_owner', 'Fun Dacha', 0),
(0, 'config', 'config_address', 'Ukraine', 0),
(0, 'config', 'config_email', 'admin@fundacha.com', 0),
(0, 'config', 'config_telephone', '+380123456789', 0),
(0, 'config', 'config_status', '1', 0),
(0, 'config', 'config_meta_title', 'Fun Dacha - Семена и рассада', 0),
(0, 'config', 'config_meta_description', 'Качественные семена и рассада для вашего сада', 0),
(0, 'config', 'config_meta_keyword', 'семена, рассада, сад, огород', 0),
(0, 'config', 'config_seo_url', '1', 0),
(0, 'config', 'config_stock_display', '1', 0),
(0, 'config', 'config_stock_warning', '1', 0),
(0, 'config', 'config_stock_checkout', '1', 0);
"

echo ""
echo "8. Ensuring all products are assigned to store 0..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_product_to_store (product_id, store_id)
SELECT p.product_id, 0 FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_to_store pts WHERE pts.product_id = p.product_id AND pts.store_id = 0);
"

echo ""
echo "9. Ensuring all categories are assigned to store 0..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_category_to_store (category_id, store_id)
SELECT c.category_id, 0 FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_to_store cts WHERE cts.category_id = c.category_id AND cts.store_id = 0);
"

echo ""
echo "10. Creating default layout..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_layout (layout_id, name) VALUES (1, 'Home');
INSERT IGNORE INTO oc_layout_route (layout_id, store_id, route) VALUES 
(1, 0, 'common/home'),
(1, 0, 'product/category'),
(1, 0, 'product/product');
"

echo ""
echo "11. Setting up proper product data..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Set proper product status and visibility
UPDATE oc_product SET status = 1, date_available = NOW(), date_added = NOW(), date_modified = NOW();

-- Set proper category status
UPDATE oc_category SET status = 1, date_added = NOW(), date_modified = NOW();

-- Set proper prices (if they exist)
UPDATE oc_product SET price = 100.00 WHERE price = 0 OR price IS NULL;
"

echo ""
echo "12. Verifying the fix..."
echo "Store configuration:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT * FROM oc_store;" 2>/dev/null

echo ""
echo "Product descriptions (first 5):"
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT p.product_id, pd.name, pd.language_id 
FROM oc_product p 
LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id 
WHERE pd.language_id = 20 
LIMIT 5;
" 2>/dev/null

echo ""
echo "Category descriptions (first 5):"
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT c.category_id, cd.name, cd.language_id 
FROM oc_category c 
LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id 
WHERE cd.language_id = 20 
LIMIT 5;
" 2>/dev/null

echo ""
echo "Products in store:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as products_in_store FROM oc_product_to_store WHERE store_id = 0;" 2>/dev/null

echo ""
echo "Categories in store:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as categories_in_store FROM oc_category_to_store WHERE store_id = 0;" 2>/dev/null

echo ""
echo "13. Restarting OpenCart container..."
docker compose restart web

echo ""
echo "14. Waiting for OpenCart to be ready..."
sleep 15

echo ""
echo "15. Testing OpenCart accessibility..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/

echo ""
echo "✅ Complete fix applied!"
echo ""
echo "🌐 Now check:"
echo "   Frontend: http://localhost:8080"
echo "   Admin: http://localhost:8080/admin"
echo ""
echo "If still no data shows:"
echo "1. Clear browser cache (Ctrl+F5 or incognito mode)"
echo "2. Wait a few minutes for OpenCart to fully initialize"
echo "3. Check admin panel to see if products are visible there"