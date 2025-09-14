#!/bin/bash

echo "🔧 Fixing Common OpenCart Data Issues..."

# Check if containers are running
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart container is not running. Please start it first."
    exit 1
fi

echo "1. Ensuring all products are assigned to store 0 (default store)..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_product_to_store (product_id, store_id)
SELECT p.product_id, 0 FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_to_store pts WHERE pts.product_id = p.product_id);
" | cat

echo "2. Ensuring all categories are assigned to store 0..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_category_to_store (category_id, store_id)
SELECT c.category_id, 0 FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_to_store cts WHERE cts.category_id = c.category_id);
" | cat

echo "3. Ensuring all products are assigned to category 0 (default category)..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_product_to_category (product_id, category_id)
SELECT p.product_id, 0 FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_to_category ptc WHERE ptc.product_id = p.product_id);
" | cat

echo "4. Setting all products to enabled status..."
docker compose exec -T db mysql -u root -pexample opencart -e "
UPDATE oc_product SET status = 1 WHERE status = 0;
" | cat

echo "5. Setting all categories to enabled status..."
docker compose exec -T db mysql -u root -pexample opencart -e "
UPDATE oc_category SET status = 1 WHERE status = 0;
" | cat

echo "6. Ensuring default store exists..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_store (store_id, name, url, ssl) 
VALUES (0, 'Default Store', 'http://localhost:8080/', 'http://localhost:8080/');
" | cat

echo "7. Setting default language to Ukrainian..."
docker compose exec -T db mysql -u root -pexample opencart -e "
UPDATE oc_setting SET value='uk-ua' WHERE \`key\`='config_language';
UPDATE oc_setting SET value='uk-ua' WHERE \`key\`='config_admin_language';
" | cat

echo "8. Setting default currency to UAH..."
docker compose exec -T db mysql -u root -pexample opencart -e "
UPDATE oc_setting SET value='UAH' WHERE \`key\`='config_currency';
" | cat

echo "9. Ensuring Ukrainian language exists and is enabled..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_language (name, code, locale, image, directory, filename, status, sort_order) 
VALUES ('Українська', 'uk-ua', 'uk_UA.UTF-8,uk_UA,ukrainian', 'uk-ua.png', 'uk-ua', 'uk-ua', 1, 1);
" | cat

echo "10. Ensuring UAH currency exists and is enabled..."
docker compose exec -T db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_currency (title, code, symbol_left, symbol_right, decimal_place, value, status) 
VALUES ('Ukrainian Hryvnia','UAH','',' ₴',2,1.00000,1);
UPDATE oc_currency SET status=1 WHERE code='UAH';
UPDATE oc_currency SET status=0 WHERE code<>'UAH';
" | cat

echo "11. Clearing OpenCart cache..."
docker compose exec custom-opencart-web rm -rf /var/www/html/system/storage/cache/* | cat
docker compose exec custom-opencart-web rm -rf /var/www/html/system/storage/logs/* | cat

echo "12. Restarting Apache..."
docker compose exec custom-opencart-web service apache2 restart | cat

echo ""
echo "✅ Data fixes completed!"
echo ""
echo "🔍 Verification:"
echo "=================="
echo "1. Check products count:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as products FROM oc_product WHERE status=1;" | cat

echo "2. Check categories count:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as categories FROM oc_category WHERE status=1;" | cat

echo "3. Check product-to-store assignments:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as product_store_assignments FROM oc_product_to_store;" | cat

echo "4. Check category-to-store assignments:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as category_store_assignments FROM oc_category_to_store;" | cat

echo ""
echo "🌐 Now check the frontend:"
echo "   http://localhost:8080"
echo ""
echo "If still no data shows, check:"
echo "1. Browser cache (try incognito/private mode)"
echo "2. OpenCart admin panel: http://localhost:8080/admin"
echo "3. Check if products are visible in admin panel"
echo "4. Check if categories are visible in admin panel"