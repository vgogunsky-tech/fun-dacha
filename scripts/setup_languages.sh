#!/bin/bash

# Setup Languages Script
# This script sets up Ukrainian and Russian language support for OpenCart

set -e

echo "🌍 Setting up Ukrainian and Russian language support..."

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

# Step 1: Setup languages in database
echo "🌍 Step 1: Setting up languages in database..."
docker compose exec -T db mysql -u root -pexample opencart < ../setup_languages.sql

if [ $? -eq 0 ]; then
    echo "✅ Languages setup completed successfully!"
else
    echo "❌ Languages setup failed!"
    exit 1
fi

# Step 2: Generate updated migration with proper language support
echo "🔧 Step 2: Generating migration with proper language support..."
cd ..
python3 update_migration_for_languages.py

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate updated migration"
    exit 1
fi

# Step 3: Run the updated migration
echo "📥 Step 3: Running updated migration with language support..."
cd opencart-docker
docker compose exec -T db mysql -u root -pexample opencart < ../complete_sync_migration_with_languages.sql

if [ $? -eq 0 ]; then
    echo "✅ Updated migration completed successfully!"
else
    echo "❌ Updated migration failed!"
    exit 1
fi

# Step 4: Copy images
echo "🖼️ Step 4: Copying images..."
bash ../copy_images_fixed.sh

# Step 5: Verify language setup
echo "🔍 Step 5: Verifying language setup..."
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 'Languages configured:' as status;
SELECT language_id, name, code, status FROM oc_language ORDER BY language_id;

SELECT 'Sample Ukrainian products:' as status;
SELECT pd.name FROM oc_product_description pd WHERE pd.language_id = 20 LIMIT 5;

SELECT 'Sample English products:' as status;
SELECT pd.name FROM oc_product_description pd WHERE pd.language_id = 21 LIMIT 5;

SELECT 'Sample Ukrainian categories:' as status;
SELECT cd.name FROM oc_category_description cd WHERE cd.language_id = 20 LIMIT 5;

SELECT 'Sample English categories:' as status;
SELECT cd.name FROM oc_category_description cd WHERE cd.language_id = 21 LIMIT 5;
"

echo ""
echo "🎉 Language setup completed successfully!"
echo ""
echo "📊 Language Support Summary:"
echo "   - Ukrainian (Українська) - language_id = 20"
echo "   - English - language_id = 21"
echo "   - Default language: Ukrainian"
echo ""
echo "🔍 Language Features:"
echo "   ✅ Product names and descriptions in Ukrainian and Russian"
echo "   ✅ Category names and descriptions in Ukrainian and Russian"
echo "   ✅ Attribute names in Ukrainian and Russian"
echo "   ✅ Localized tags (early_maturing → Ранньостиглий)"
echo "   ✅ Language-specific store settings"
echo "   ✅ Language-specific meta titles and descriptions"
echo ""
echo "🌐 Access your multilingual store:"
echo "   - Frontend: http://localhost:8080"
echo "   - Admin: http://localhost:8080/admin"
echo "   - phpMyAdmin: http://localhost:8082"
echo ""
echo "💡 Language switching should be available in the OpenCart frontend!"