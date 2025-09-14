#!/bin/bash

echo "🔍 Checking OpenCart Configuration..."

# Check if containers are running
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart container is not running. Please start it first."
    exit 1
fi

echo "1. Checking OpenCart version and status..."
docker compose exec custom-opencart-web php -r "
if (file_exists('/var/www/html/index.php')) {
    echo 'OpenCart files exist' . PHP_EOL;
    if (file_exists('/var/www/html/config.php')) {
        echo 'Config file exists' . PHP_EOL;
    } else {
        echo 'Config file missing!' . PHP_EOL;
    }
} else {
    echo 'OpenCart files missing!' . PHP_EOL;
}
" | cat

echo ""
echo "2. Checking Apache status..."
docker compose exec custom-opencart-web service apache2 status | cat

echo ""
echo "3. Checking if OpenCart is accessible..."
docker compose exec custom-opencart-web curl -s -o /dev/null -w "%{http_code}" http://localhost/ | cat

echo ""
echo "4. Checking OpenCart error logs..."
docker compose exec custom-opencart-web tail -20 /var/log/apache2/error.log | cat

echo ""
echo "5. Checking OpenCart system logs..."
if docker compose exec custom-opencart-web test -f /var/www/html/system/storage/logs/error.log; then
    docker compose exec custom-opencart-web tail -20 /var/www/html/system/storage/logs/error.log | cat
else
    echo "No OpenCart system logs found"
fi

echo ""
echo "6. Checking database connection from OpenCart..."
docker compose exec custom-opencart-web php -r "
try {
    \$pdo = new PDO('mysql:host=db;dbname=opencart', 'root', 'example');
    echo 'Database connection successful' . PHP_EOL;
} catch (Exception \$e) {
    echo 'Database connection failed: ' . \$e->getMessage() . PHP_EOL;
}
" | cat

echo ""
echo "7. Checking if products are visible in admin context..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    p.product_id,
    p.model,
    p.status as product_status,
    pd.name,
    pts.store_id,
    ptc.category_id
FROM oc_product p
LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id AND pd.language_id = 20
LEFT JOIN oc_product_to_store pts ON p.product_id = pts.product_id
LEFT JOIN oc_product_to_category ptc ON p.product_id = ptc.product_id
WHERE p.status = 1
LIMIT 5;
" | cat

echo ""
echo "8. Checking if categories are visible in admin context..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    c.category_id,
    c.status as category_status,
    cd.name,
    cts.store_id
FROM oc_category c
LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id AND cd.language_id = 20
LEFT JOIN oc_category_to_store cts ON c.category_id = cts.category_id
WHERE c.status = 1
LIMIT 5;
" | cat

echo ""
echo "9. Checking OpenCart cache directory permissions..."
docker compose exec custom-opencart-web ls -la /var/www/html/system/storage/ | cat

echo ""
echo "10. Testing OpenCart frontend response..."
docker compose exec custom-opencart-web curl -s -I http://localhost/ | head -10 | cat