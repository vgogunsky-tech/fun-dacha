#!/bin/bash

echo "🔍 Checking OpenCart database schema..."

# Check if containers are running
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart container is not running. Please start it first."
    exit 1
fi

echo "📊 Checking oc_country table structure:"
docker compose exec -T db mysql -u root -pexample opencart -e "DESCRIBE oc_country;" | cat

echo ""
echo "📊 Checking oc_zone table structure:"
docker compose exec -T db mysql -u root -pexample opencart -e "DESCRIBE oc_zone;" | cat

echo ""
echo "📊 Checking oc_setting table structure:"
docker compose exec -T db mysql -u root -pexample opencart -e "DESCRIBE oc_setting;" | cat

echo ""
echo "📊 Checking oc_language table:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT * FROM oc_language;" | cat

echo ""
echo "📊 Checking products count:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as product_count FROM oc_product;" | cat

echo ""
echo "📊 Checking categories count:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as category_count FROM oc_category;" | cat

echo ""
echo "📊 Checking product descriptions count:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as product_desc_count FROM oc_product_description;" | cat

echo ""
echo "📊 Checking category descriptions count:"
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT COUNT(*) as category_desc_count FROM oc_category_description;" | cat