#!/bin/bash

echo "🔍 Detailed OpenCart Debugging Script"
echo "====================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the opencart-docker directory"
    echo "   cd opencart-docker"
    echo "   ../debug_opencart_detailed.sh"
    exit 1
fi

echo "1. Checking Docker containers status..."
docker compose ps

echo ""
echo "2. Checking if OpenCart is accessible..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/

echo ""
echo "3. Checking OpenCart response headers..."
curl -s -I http://localhost:8080/ | head -10

echo ""
echo "4. Checking if admin panel is accessible..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/admin

echo ""
echo "5. Checking database connection..."
docker compose exec -T db mysql -u root -pexample -e "SELECT 'Database connected' as status;" 2>/dev/null || echo "❌ Database connection failed"

echo ""
echo "6. Checking store configuration..."
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT * FROM oc_store;" 2>/dev/null || echo "❌ Store table query failed"

echo ""
echo "7. Checking store settings..."
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT \`key\`, value FROM oc_setting WHERE store_id = 0 ORDER BY \`key\`;" 2>/dev/null || echo "❌ Store settings query failed"

echo ""
echo "8. Checking product visibility..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    p.product_id,
    p.model,
    p.status,
    pd.name,
    pts.store_id,
    CASE WHEN pts.store_id IS NULL THEN 'NOT ASSIGNED' ELSE 'ASSIGNED' END as store_status
FROM oc_product p
LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id AND pd.language_id = 20
LEFT JOIN oc_product_to_store pts ON p.product_id = pts.product_id AND pts.store_id = 0
WHERE p.status = 1
LIMIT 10;
" 2>/dev/null || echo "❌ Product visibility query failed"

echo ""
echo "9. Checking category visibility..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 
    c.category_id,
    c.status,
    cd.name,
    cts.store_id,
    CASE WHEN cts.store_id IS NULL THEN 'NOT ASSIGNED' ELSE 'ASSIGNED' END as store_status
FROM oc_category c
LEFT JOIN oc_category_description cd ON c.category_id = cd.category_id AND cd.language_id = 20
LEFT JOIN oc_category_to_store cts ON c.category_id = cts.category_id AND cts.store_id = 0
WHERE c.status = 1
LIMIT 10;
" 2>/dev/null || echo "❌ Category visibility query failed"

echo ""
echo "10. Checking OpenCart error logs..."
docker compose exec custom-opencart-web tail -20 /var/log/apache2/error.log 2>/dev/null || echo "❌ Could not access Apache error logs"

echo ""
echo "11. Checking OpenCart system logs..."
if docker compose exec custom-opencart-web test -f /var/www/html/system/storage/logs/error.log 2>/dev/null; then
    docker compose exec custom-opencart-web tail -20 /var/www/html/system/storage/logs/error.log 2>/dev/null || echo "❌ Could not access OpenCart system logs"
else
    echo "ℹ️  No OpenCart system logs found"
fi

echo ""
echo "12. Checking OpenCart cache directory..."
docker compose exec custom-opencart-web ls -la /var/www/html/system/storage/ 2>/dev/null || echo "❌ Could not access cache directory"

echo ""
echo "13. Checking if OpenCart config files exist..."
docker compose exec custom-opencart-web ls -la /var/www/html/config* 2>/dev/null || echo "❌ Config files not found"

echo ""
echo "14. Testing OpenCart frontend with verbose output..."
docker compose exec custom-opencart-web curl -v http://localhost/ 2>&1 | head -30

echo ""
echo "15. Checking OpenCart database connection from within container..."
docker compose exec custom-opencart-web php -r "
try {
    \$pdo = new PDO('mysql:host=db;dbname=opencart', 'root', 'example');
    echo '✅ Database connection from OpenCart: SUCCESS' . PHP_EOL;
    
    // Test a simple query
    \$stmt = \$pdo->query('SELECT COUNT(*) as count FROM oc_product');
    \$result = \$stmt->fetch(PDO::FETCH_ASSOC);
    echo '✅ Product count from OpenCart: ' . \$result['count'] . PHP_EOL;
    
    // Test store query
    \$stmt = \$pdo->query('SELECT COUNT(*) as count FROM oc_store');
    \$result = \$stmt->fetch(PDO::FETCH_ASSOC);
    echo '✅ Store count from OpenCart: ' . \$result['count'] . PHP_EOL;
    
} catch (Exception \$e) {
    echo '❌ Database connection from OpenCart: FAILED - ' . \$e->getMessage() . PHP_EOL;
}
" 2>/dev/null || echo "❌ Could not test database connection from OpenCart"

echo ""
echo "16. Checking OpenCart version and installation status..."
docker compose exec custom-opencart-web php -r "
if (file_exists('/var/www/html/index.php')) {
    echo '✅ OpenCart index.php exists' . PHP_EOL;
    if (file_exists('/var/www/html/config.php')) {
        echo '✅ OpenCart config.php exists' . PHP_EOL;
        // Try to read config
        \$config = file_get_contents('/var/www/html/config.php');
        if (strpos(\$config, 'DB_HOSTNAME') !== false) {
            echo '✅ OpenCart config.php contains database settings' . PHP_EOL;
        } else {
            echo '❌ OpenCart config.php missing database settings' . PHP_EOL;
        }
    } else {
        echo '❌ OpenCart config.php missing' . PHP_EOL;
    }
} else {
    echo '❌ OpenCart index.php missing' . PHP_EOL;
}
" 2>/dev/null || echo "❌ Could not check OpenCart installation"

echo ""
echo "====================================="
echo "🔧 Next Steps:"
echo "1. If store table is empty, run: ../fix_opencart_store.sql"
echo "2. If database connection fails, check Docker containers"
echo "3. If OpenCart files are missing, check volume mounts"
echo "4. If still no data, check OpenCart cache and restart containers"