#!/bin/bash

# Clean OpenCart Migration Script
# This script completely resets the database and performs a fresh migration

set -e

echo "🧹 Starting Clean OpenCart Migration..."
echo "⚠️  WARNING: This will completely reset your OpenCart database!"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Navigate to opencart-docker directory
cd opencart-docker

echo "🛑 Stopping and removing containers..."
docker compose down -v

echo "🗑️  Removing all database data..."
sudo rm -rf db_data/*

echo "🗑️  Removing all OpenCart data..."
sudo rm -rf opencart_data/*

echo "🔧 Starting fresh containers..."
docker compose up -d

echo "⏳ Waiting for database to be ready..."
sleep 30

# Check if database is accessible
echo "🔍 Testing database connection..."
docker compose exec db mysql -u root -pexample -e "SELECT 1;" opencart

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to database. Please check your Docker setup."
    exit 1
fi

echo "✅ Database connection successful"

# Go back to workspace root for migration
cd ..

echo "🔧 Generating fresh migration SQL from CSV..."
python3 complete_sync_sql_migration.py

echo "🔧 Generating inventory options SQL from inventory.csv..."
python3 generate_inventory_options_sql.py

# Stage images from data/ into opencart-docker/opencart_data for copying
echo "🖼️  Staging images from data/images into opencart-docker/opencart_data..."
mkdir -p opencart-docker/opencart_data/image/catalog/product
mkdir -p opencart-docker/opencart_data/image/catalog/category
if [ -d data/images/products ]; then
    rsync -a --delete data/images/products/ opencart-docker/opencart_data/image/catalog/product/
    echo "✅ Product images staged"
fi
if [ -d data/images/categories ]; then
    rsync -a --delete data/images/categories/ opencart-docker/opencart_data/image/catalog/category/
    echo "✅ Category images staged"
fi

# Navigate back to opencart-docker
cd opencart-docker

# Ensure languages UA/RU exist (minimal, schema-safe)
echo "🌍 Setting up languages (UA/RU)..."
docker compose exec db mysql -u root -pexample opencart -e "
-- Clean up any existing language data
DELETE FROM oc_language WHERE language_id IN (1,2,3,20,21);
-- Insert fresh language data
INSERT INTO oc_language (language_id, name, code, locale, image, directory, sort_order, status) VALUES 
(20, 'Українська', 'uk-ua', 'uk_UA.UTF-8,uk_UA,uk-ua,ukrainian', 'ua.png', 'uk-ua', 1, 1),
(21, 'English', 'en-gb', 'en_GB.UTF-8,en_GB,en-gb,english', 'gb.png', 'english', 0, 1);
" | cat

# Import main migration SQL
echo "📥 Importing main migration SQL..."
docker compose exec -T db mysql -u root -pexample opencart < ../complete_sync_migration.sql

# Apply inventory options SQL
echo "🧩 Applying inventory options SQL..."
docker compose exec -T db mysql -u root -pexample opencart < ../inventory_options.sql

# Set up store configuration
echo "🏪 Setting up store configuration..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Set default language to Ukrainian
UPDATE oc_setting SET value='2' WHERE \`key\` IN ('config_language','config_admin_language') AND store_id=0;

-- Ensure UAH currency exists and set default
INSERT IGNORE INTO oc_currency (title, code, symbol_left, symbol_right, decimal_place, value, status) VALUES ('Ukrainian Hryvnia','UAH','',' ₴',2,1.00000,1);
UPDATE oc_currency SET value=1.00000, status=1 WHERE code='UAH';
UPDATE oc_currency SET status=0 WHERE code<>'UAH';
UPDATE oc_setting SET value='UAH' WHERE \`key\`='config_currency' AND store_id=0;

-- Set store name and other basic settings
UPDATE oc_setting SET value='Fun Dacha Store' WHERE \`key\`='config_name' AND store_id=0;
UPDATE oc_setting SET value='fun-dacha@example.com' WHERE \`key\`='config_email' AND store_id=0;
" | cat

# Copy images into container and set permissions
echo "🖼️  Copying images into container..."
bash ../copy_images_fixed.sh

# Verify migration results
echo "🔍 Verifying migration results..."
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 'Categories:' as info, COUNT(*) as count FROM oc_category
UNION ALL
SELECT 'Products:', COUNT(*) FROM oc_product
UNION ALL
SELECT 'Product Descriptions:', COUNT(*) FROM oc_product_description
UNION ALL
SELECT 'Product Images:', COUNT(*) FROM oc_product_image
UNION ALL
SELECT 'Product Options:', COUNT(*) FROM oc_product_option
UNION ALL
SELECT 'Product Option Values:', COUNT(*) FROM oc_product_option_value;
" | cat

# Check migration results
if [ $? -eq 0 ]; then
    echo "✅ Clean migration completed successfully!"
    echo ""
    echo "📊 Migration Summary:"
    echo "   - OpenCart is running at: http://localhost:8080"
    echo "   - Admin panel: http://localhost:8080/admin"
    echo "   - phpMyAdmin: http://localhost:8082"
    echo ""
    echo "🔍 You can verify the migration by:"
    echo "   1. Checking the OpenCart frontend"
    echo "   2. Logging into the admin panel"
    echo "   3. Using phpMyAdmin to inspect the database"
    echo "   4. Verifying options under Admin → Catalog → Products → Options"
    echo ""
    echo "📝 Default admin credentials (if using default OpenCart setup):"
    echo "   Username: admin"
    echo "   Password: admin"
else
    echo "❌ Migration failed!"
    echo "Check the logs above for error details"
    exit 1
fi

echo "🎉 Clean migration process completed!"