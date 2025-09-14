#!/bin/bash

echo "🔧 Applying OpenCart Store Configuration Fix"
echo "============================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the opencart-docker directory"
    echo "   cd opencart-docker"
    echo "   ../apply_opencart_fix.sh"
    exit 1
fi

echo "1. Checking if containers are running..."
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart container is not running. Please start it first:"
    echo "   docker compose up -d"
    exit 1
fi

echo "✅ Containers are running"

echo ""
echo "2. Applying store configuration fix..."
docker compose exec -T db mysql -u root -pexample opencart < ../fix_opencart_store.sql

if [ $? -eq 0 ]; then
    echo "✅ SQL fix applied successfully"
else
    echo "❌ SQL fix failed"
    exit 1
fi

echo ""
echo "3. Clearing OpenCart cache..."
docker compose exec custom-opencart-web rm -rf /var/www/html/system/storage/cache/* 2>/dev/null || echo "⚠️  Could not clear cache directory"
docker compose exec custom-opencart-web rm -rf /var/www/html/system/storage/logs/* 2>/dev/null || echo "⚠️  Could not clear logs directory"

echo ""
echo "4. Restarting Apache..."
docker compose exec custom-opencart-web service apache2 restart 2>/dev/null || echo "⚠️  Could not restart Apache"

echo ""
echo "5. Verifying the fix..."
echo "Store configuration:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT * FROM oc_store;" 2>/dev/null

echo ""
echo "Products in store:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as products_in_store FROM oc_product_to_store WHERE store_id = 0;" 2>/dev/null

echo ""
echo "Categories in store:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as categories_in_store FROM oc_category_to_store WHERE store_id = 0;" 2>/dev/null

echo ""
echo "✅ Fix applied! Now check:"
echo "   Frontend: http://localhost:8080"
echo "   Admin: http://localhost:8080/admin"
echo ""
echo "If still no data shows:"
echo "1. Clear browser cache (Ctrl+F5 or incognito mode)"
echo "2. Check if products are visible in admin panel"
echo "3. Run: ../debug_opencart_detailed.sh for more diagnostics"