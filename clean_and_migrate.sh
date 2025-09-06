#!/bin/bash

# Clean and Migrate Script
# This script completely cleans the database and then runs the migration

set -e

echo "🧹 Complete Database Cleanup and Migration"
echo "=========================================="

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
echo "📋 Checking OpenCart containers status..."
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 30
fi

# Test database connection
echo "🔍 Testing database connection..."
docker compose exec db mysql -u root -pexample -e "SELECT 1;" opencart

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to database"
    exit 1
fi

echo "✅ Database connection successful"

# Step 1: Complete cleanup
echo "🧹 Step 1: Complete database cleanup..."
docker compose exec -T db mysql -u root -pexample opencart < ../complete_cleanup.sql

if [ $? -eq 0 ]; then
    echo "✅ Database cleanup completed successfully!"
else
    echo "❌ Database cleanup failed!"
    exit 1
fi

# Step 2: Generate fresh migration SQL
echo "🔧 Step 2: Generating fresh migration SQL..."
cd ..
python3 complete_sync_sql_migration.py

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate SQL file"
    exit 1
fi

# Step 3: Import fresh data
echo "📥 Step 3: Importing fresh data..."
cd opencart-docker
docker compose exec -T db mysql -u root -pexample opencart < ../complete_sync_migration.sql

if [ $? -eq 0 ]; then
    echo "✅ Fresh data import completed successfully!"
else
    echo "❌ Fresh data import failed!"
    exit 1
fi

# Step 4: Copy images
echo "🖼️ Step 4: Copying images..."
bash ../copy_images_fixed.sh

# Step 5: Verify results
echo "🔍 Step 5: Verifying results..."
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 'Products:' as status, COUNT(*) as count FROM oc_product;
SELECT 'Categories:' as status, COUNT(*) as count FROM oc_category;
SELECT 'Product descriptions:' as status, COUNT(*) as count FROM oc_product_description;
SELECT 'Sample products:' as status, name FROM oc_product_description WHERE language_id = 1 LIMIT 5;
"

echo ""
echo "🎉 Complete cleanup and migration finished!"
echo ""
echo "📊 Results:"
echo "   - All old data removed"
echo "   - Fresh data imported from CSV"
echo "   - Images copied to container"
echo "   - Localized tags applied"
echo ""
echo "🔍 Check your OpenCart at:"
echo "   - Frontend: http://localhost:8080"
echo "   - Admin: http://localhost:8080/admin"
echo "   - phpMyAdmin: http://localhost:8082"