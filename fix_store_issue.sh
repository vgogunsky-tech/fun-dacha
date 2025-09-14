#!/bin/bash

echo "🔧 Fixing OpenCart Store Configuration Issue..."

# Check if containers are running
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart container is not running. Please start it first."
    exit 1
fi

echo "1. Checking current store configuration..."
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT * FROM oc_store;" | cat

echo ""
echo "2. Creating default store if it doesn't exist..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_store (store_id, name, url, ssl) 
VALUES (0, 'Default Store', 'http://localhost:8080/', 'http://localhost:8080/');
" | cat

echo ""
echo "3. Setting up store settings..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Set default language
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_language', 'uk-ua', 0);

-- Set default currency  
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_currency', 'UAH', 0);

-- Set admin language
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_admin_language', 'uk-ua', 0);

-- Set store name
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_name', 'Fun Dacha', 0);

-- Set store owner
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_owner', 'Fun Dacha', 0);

-- Set store address
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_address', 'Ukraine', 0);

-- Set store email
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_email', 'admin@fundacha.com', 0);

-- Set store telephone
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_telephone', '+380123456789', 0);

-- Set store status
INSERT IGNORE INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
VALUES (0, 'config', 'config_status', '1', 0);
" | cat

echo ""
echo "4. Ensuring all products are assigned to store 0..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_product_to_store (product_id, store_id)
SELECT p.product_id, 0 FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_to_store pts WHERE pts.product_id = p.product_id AND pts.store_id = 0);
" | cat

echo ""
echo "5. Ensuring all categories are assigned to store 0..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_category_to_store (category_id, store_id)
SELECT c.category_id, 0 FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_to_store cts WHERE cts.category_id = c.category_id AND cts.store_id = 0);
" | cat

echo ""
echo "6. Setting up default layout for store..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Create default layout
INSERT IGNORE INTO oc_layout (layout_id, name) VALUES (1, 'Home');

-- Assign layout to store
INSERT IGNORE INTO oc_layout_route (layout_id, store_id, route) 
VALUES (1, 0, 'common/home');
" | cat

echo ""
echo "7. Clearing OpenCart cache..."
docker compose exec custom-opencart-web rm -rf /var/www/html/system/storage/cache/* | cat
docker compose exec custom-opencart-web rm -rf /var/www/html/system/storage/logs/* | cat

echo ""
echo "8. Restarting Apache..."
docker compose exec custom-opencart-web service apache2 restart | cat

echo ""
echo "9. Verifying store configuration..."
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT * FROM oc_store;" | cat

echo ""
echo "10. Verifying store settings..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT \`key\`, value FROM oc_setting 
WHERE store_id = 0 AND \`key\` IN ('config_language', 'config_currency', 'config_name', 'config_status');
" | cat

echo ""
echo "11. Checking product visibility..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT COUNT(*) as products_in_store FROM oc_product_to_store WHERE store_id = 0;
SELECT COUNT(*) as categories_in_store FROM oc_category_to_store WHERE store_id = 0;
" | cat

echo ""
echo "✅ Store configuration completed!"
echo ""
echo "🌐 Now check the frontend:"
echo "   http://localhost:8080"
echo ""
echo "If still no data shows, try:"
echo "1. Clear browser cache (Ctrl+F5 or incognito mode)"
echo "2. Check admin panel: http://localhost:8080/admin"
echo "3. Verify products are visible in admin panel"