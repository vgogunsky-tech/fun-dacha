#!/bin/bash

echo "🔍 Debugging OpenCart Data Issues..."

# Check if containers are running
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart container is not running. Please start it first."
    exit 1
fi

echo "📊 Database Status:"
echo "==================="

echo "1. Products in database:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as product_count FROM oc_product;" | cat

echo ""
echo "2. Product descriptions:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as product_desc_count FROM oc_product_description;" | cat

echo ""
echo "3. Categories in database:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as category_count FROM oc_category;" | cat

echo ""
echo "4. Category descriptions:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as category_desc_count FROM oc_category_description;" | cat

echo ""
echo "5. Languages configured:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT language_id, name, code, status FROM oc_language;" | cat

echo ""
echo "6. Store settings:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT \`key\`, value FROM oc_setting WHERE \`key\` IN ('config_language', 'config_admin_language', 'config_currency');" | cat

echo ""
echo "7. Sample products (first 5):"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT p.product_id, p.model, p.status, pd.name FROM oc_product p LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id LIMIT 5;" | cat

echo ""
echo "8. Sample categories (first 5):"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT c.category_id, c.status, cd.name FROM oc_category c LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id LIMIT 5;" | cat

echo ""
echo "9. Product to store assignments:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as product_store_count FROM oc_product_to_store;" | cat

echo ""
echo "10. Category to store assignments:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as category_store_count FROM oc_category_to_store;" | cat

echo ""
echo "11. Product to category assignments:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as product_category_count FROM oc_product_to_category;" | cat

echo ""
echo "12. Store information:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT store_id, name, url FROM oc_store;" | cat

echo ""
echo "🌐 Frontend Check:"
echo "=================="
echo "OpenCart Frontend: http://localhost:8080"
echo "Admin Panel: http://localhost:8080/admin"
echo "phpMyAdmin: http://localhost:8082"

echo ""
echo "🔧 Common Issues to Check:"
echo "1. Are products assigned to store 0 (default store)?"
echo "2. Are categories assigned to store 0?"
echo "3. Are products assigned to categories?"
echo "4. Is the default language set correctly?"
echo "5. Are product statuses set to enabled (status=1)?"
echo "6. Are category statuses set to enabled (status=1)?"