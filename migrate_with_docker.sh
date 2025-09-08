#!/bin/bash

# OpenCart Migration Script using Docker
# This script runs the migration inside the OpenCart Docker environment

set -e

echo "🚀 Starting OpenCart Complete Migration (SQL-based)..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Generate SQL artifacts from CSV (run in repo root)
echo "🔧 Generating migration SQL from CSV..."
python3 complete_sync_sql_migration.py | cat

echo "🔧 Generating inventory options SQL from inventory.csv..."
python3 generate_inventory_options_sql.py | cat

# Install Ukrainian localisation if present
if [ -d localization/upload ] || [ -f localization/install.sql ]; then
  echo "🌐 Ukrainian localisation detected. Installing..."
fi

# Stage images from data/ into opencart-docker/opencart_data for copying
echo "🖼️  Staging images from data/images into opencart-docker/opencart_data..."
mkdir -p opencart-docker/opencart_data/image/catalog/product
mkdir -p opencart-docker/opencart_data/image/catalog/category
if [ -d data/images/products ]; then
    echo "📁 Copying product images (force update)..."
    rsync -av --delete --force data/images/products/ opencart-docker/opencart_data/image/catalog/product/
    echo "✅ Product images staged: $(ls opencart-docker/opencart_data/image/catalog/product/ | wc -l) files"
fi
if [ -d data/images/categories ]; then
    echo "📁 Copying category images (force update)..."
    rsync -av --delete --force data/images/categories/ opencart-docker/opencart_data/image/catalog/category/
    echo "✅ Category images staged: $(ls opencart-docker/opencart_data/image/catalog/category/ | wc -l) files"
fi

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
echo "📋 Checking OpenCart containers status..."
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    
    # Wait for database to be ready
    echo "⏳ Waiting for database to be ready..."
    sleep 30
fi

# Check if database is accessible
echo "🔍 Testing database connection..."
docker compose exec db mysql -u root -pexample -e "SELECT 1;" opencart

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to database. Please check your Docker setup."
    exit 1
fi

echo "✅ Database connection successful"

# Apply localisation files (copy upload/ into web root) and SQL if available
if [ -d ../localization/upload ]; then
  echo "📦 Copying localisation files into container..."
  docker compose cp ../localization/upload/. web:/var/www/html/
  docker compose exec web bash -lc "chown -R www-data:www-data /var/www/html"
fi

if [ -f ../localization/install.sql ]; then
  echo "📥 Applying localisation SQL..."
  docker compose exec -T db mysql -u root -pexample opencart < ../localization/install.sql
fi

echo "🌍 Resetting languages to Ukrainian only and enforcing defaults..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Remove all languages and re-insert Ukrainian only
DELETE FROM oc_language;
INSERT INTO oc_language (language_id, name, code, locale, image, directory, sort_order, status) VALUES 
(2, 'Українська', 'uk-ua', 'uk_UA.UTF-8,uk_UA,uk-ua,ukrainian', 'ua.png', 'uk-ua', 1, 1);

-- Update settings to use Ukrainian for all stores
UPDATE oc_setting SET value='uk-ua' WHERE `key` IN ('config_language','config_admin_language');
INSERT INTO oc_setting (store_id, `code`, `key`, `value`, serialized) SELECT 0, 'config', 'config_language', 'uk-ua', 0 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM oc_setting WHERE store_id=0 AND `key`='config_language');
INSERT INTO oc_setting (store_id, `code`, `key`, `value`, serialized) SELECT 0, 'config', 'config_admin_language', 'uk-ua', 0 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM oc_setting WHERE store_id=0 AND `key`='config_admin_language');

-- Remove non-UA content from description tables
DELETE FROM oc_product_description WHERE language_id <> 2;
DELETE FROM oc_category_description WHERE language_id <> 2;
DELETE FROM oc_attribute_description WHERE language_id <> 2;
DELETE FROM oc_option_description WHERE language_id <> 2;
DELETE FROM oc_option_value_description WHERE language_id <> 2;
" | cat

# Import main migration SQL
echo "📥 Importing main migration SQL..."
docker compose exec -T db mysql -u root -pexample opencart < ../complete_sync_migration.sql

# Apply inventory options SQL
echo "🧩 Applying inventory options SQL..."
docker compose exec -T db mysql -u root -pexample opencart < ../inventory_options.sql

echo "💱 Enforcing UAH as the only/default currency across settings..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Ensure UAH exists and is enabled
INSERT IGNORE INTO oc_currency (title, code, symbol_left, symbol_right, decimal_place, value, status) VALUES ('Ukrainian Hryvnia','UAH','',' ₴',2,1.00000,1);
UPDATE oc_currency SET value=1.00000, status=1 WHERE code='UAH';
-- Disable all other currencies
UPDATE oc_currency SET status=0 WHERE code<>'UAH';

-- Update settings for all stores (store_id any) to UAH
UPDATE oc_setting SET value='UAH' WHERE `key`='config_currency';
INSERT INTO oc_setting (store_id, `code`, `key`, `value`, serialized)
SELECT 0, 'config', 'config_currency', 'UAH', 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM oc_setting WHERE store_id=0 AND `key`='config_currency');
" | cat

# Copy images into container and set permissions
echo "🖼️  Copying images into container..."
bash ../copy_images_fixed.sh | cat

# Check migration results
if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
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
else
    echo "❌ Migration failed!"
    echo "Check the migration.log file in the container for details:"
    echo "docker compose exec web cat /var/www/html/migration.log"
    exit 1
fi

echo "🎉 Migration process completed!"