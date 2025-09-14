#!/bin/bash

echo "🔍 Checking Product/Category Names Issue"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the opencart-docker directory"
    echo "   cd opencart-docker"
    echo "   ../check_names_issue.sh"
    exit 1
fi

echo "1. Checking product descriptions..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    p.product_id,
    p.model,
    p.status,
    pd.name,
    pd.language_id,
    CASE 
        WHEN pd.name IS NULL THEN 'NULL'
        WHEN pd.name = '' THEN 'EMPTY'
        ELSE 'HAS_VALUE'
    END as name_status
FROM oc_product p
LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id
WHERE p.product_id <= 10
ORDER BY p.product_id, pd.language_id;
"

echo ""
echo "2. Checking category descriptions..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    c.category_id,
    c.status,
    cd.name,
    cd.language_id,
    CASE 
        WHEN cd.name IS NULL THEN 'NULL'
        WHEN cd.name = '' THEN 'EMPTY'
        ELSE 'HAS_VALUE'
    END as name_status
FROM oc_category c
LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id
WHERE c.category_id <= 10
ORDER BY c.category_id, cd.language_id;
"

echo ""
echo "3. Checking language configuration..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT language_id, name, code, status FROM oc_language ORDER BY language_id;
"

echo ""
echo "4. Checking if product descriptions exist at all..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    COUNT(*) as total_products,
    COUNT(pd.product_id) as products_with_descriptions,
    COUNT(CASE WHEN pd.name IS NOT NULL AND pd.name != '' THEN 1 END) as products_with_names
FROM oc_product p
LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id;
"

echo ""
echo "5. Checking if category descriptions exist at all..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    COUNT(*) as total_categories,
    COUNT(cd.category_id) as categories_with_descriptions,
    COUNT(CASE WHEN cd.name IS NOT NULL AND cd.name != '' THEN 1 END) as categories_with_names
FROM oc_category c
LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id;
"

echo ""
echo "6. Checking product to store assignments..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    COUNT(*) as total_products,
    COUNT(pts.product_id) as products_in_store,
    COUNT(CASE WHEN pts.store_id = 0 THEN 1 END) as products_in_store_0
FROM oc_product p
LEFT JOIN oc_product_to_store pts ON p.product_id = pts.product_id;
"

echo ""
echo "7. Checking category to store assignments..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    COUNT(*) as total_categories,
    COUNT(cts.category_id) as categories_in_store,
    COUNT(CASE WHEN cts.store_id = 0 THEN 1 END) as categories_in_store_0
FROM oc_category c
LEFT JOIN oc_category_to_store cts ON c.category_id = cts.category_id;
"

echo ""
echo "8. Checking store configuration..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT * FROM oc_store;
"

echo ""
echo "9. Checking store settings..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT \`key\`, value FROM oc_setting 
WHERE store_id = 0 AND \`key\` IN ('config_language', 'config_currency', 'config_name', 'config_status')
ORDER BY \`key\`;
"

echo ""
echo "========================================"
echo "🔧 Analysis:"
echo "If you see NULL or EMPTY names, that's why the UI shows no data."
echo "The fix script will create proper names for all products and categories."
echo ""
echo "Next steps:"
echo "1. Run: ../fix_opencart_complete.sh"
echo "2. Check: http://localhost:8080"