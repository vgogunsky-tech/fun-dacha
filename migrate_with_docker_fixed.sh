#!/bin/bash

# OpenCart Complete Migration Script (Fixed)
# This script migrates data from CSV files to OpenCart using Docker

set -e

echo "🚀 Starting OpenCart Complete Migration (SQL-based) - FIXED VERSION..."

# Check if we're in the right directory
if [ ! -f "complete_sync_sql_migration.py" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Generate migration SQL
echo "🔧 Generating migration SQL from CSV..."
python3 complete_sync_sql_migration.py

echo "🔧 Generating inventory options SQL from inventory.csv..."
python3 generate_inventory_options_sql.py

# Check if Ukrainian localization exists
if [ -d "localization/upload" ]; then
    echo "🌐 Ukrainian localisation detected. Installing..."
    
    # Stage images
    echo "🖼️  Staging images from data/images into opencart-docker/opencart_data..."
    mkdir -p opencart-docker/opencart_data/image/catalog/product
    mkdir -p opencart-docker/opencart_data/image/catalog/category
    
    echo "📁 Copying product images (force update)..."
    rsync -av --delete data/images/products/ opencart-docker/opencart_data/image/catalog/product/ | cat
    
    echo "📁 Copying category images (force update)..."
    rsync -av --delete data/images/categories/ opencart-docker/opencart_data/image/catalog/category/ | cat
    
    echo "✅ Product images staged:      $(find opencart-docker/opencart_data/image/catalog/product -name "*.jpg" | wc -l) files"
    echo "✅ Category images staged:     $(find opencart-docker/opencart_data/image/catalog/category -name "*.jpg" | wc -l) files"
fi

# Check OpenCart containers
echo "📋 Checking OpenCart containers status..."
cd opencart-docker
docker compose ps | cat

# Test database connection
echo "🔍 Testing database connection..."
docker compose exec -T db mysql -u root -pexample opencart -e "SELECT 1;" | cat

# Copy localization files
echo "📦 Copying localisation files into container..."
docker compose cp ../localization/upload/. custom-opencart-web:/var/www/html/

# Apply localization SQL with error handling
echo "📥 Applying localisation SQL (schema-aware cleanup and fixes)..."
if [ -f "../localization/install.sql" ]; then
    # Check if the tables exist and have the expected columns
    echo "🔍 Checking database schema compatibility..."
    
    # Apply localization with error handling
    docker compose exec -T db mysql -u root -pexample opencart -e "
    -- Try to update country names if the column exists
    SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = \"oc_country\" AND column_name = \"name\"';
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SET @sql = IF(@col_exists > 0, 
        'UPDATE oc_country SET name = \"Україна\" WHERE name = \"Ukraine\"',
        'SELECT \"Country table does not have name column\" as message'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    " | cat
    
    # Try to update zone names if the column exists
    docker compose exec -T db mysql -u root -pexample opencart -e "
    SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = \"oc_zone\" AND column_name = \"name\"';
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SET @sql = IF(@col_exists > 0, 
        'UPDATE oc_zone SET name = \"Черкаська\" WHERE name LIKE \"%Cherkas%\"',
        'SELECT \"Zone table does not have name column\" as message'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    " | cat
fi

# Reset languages and enforce defaults
echo "🌍 Resetting languages (keep en-gb fallback) and enforcing defaults..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Ensure Ukrainian language exists
INSERT IGNORE INTO oc_language (name, code, locale, image, directory, filename, status, sort_order) 
VALUES ('Українська', 'uk-ua', 'uk_UA.UTF-8,uk_UA,ukrainian', 'uk-ua.png', 'uk-ua', 'uk-ua', 1, 1);

-- Update settings to use Ukrainian for all stores
UPDATE oc_setting SET value='uk-ua' WHERE \`key\` IN ('config_language','config_admin_language');
INSERT INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
SELECT 0, 'config', 'config_language', 'uk-ua', 0 FROM DUAL 
WHERE NOT EXISTS (SELECT 1 FROM oc_setting WHERE store_id=0 AND \`key\`='config_language');
INSERT INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized) 
SELECT 0, 'config', 'config_admin_language', 'uk-ua', 0 FROM DUAL 
WHERE NOT EXISTS (SELECT 1 FROM oc_setting WHERE store_id=0 AND \`key\`='config_admin_language');
" | cat

# Normalize country name for UA
echo "🗺️  Normalizing country name for UA to 'Україна'..."
docker compose exec -T db mysql -u root -pexample opencart -e "
UPDATE oc_country SET name='Україна' WHERE iso_code_2='UA';
" | cat

# Clear caches
echo "🧼 Clearing caches..."
docker compose exec custom-opencart-web service apache2 reload | cat

# Import main migration SQL
echo "📥 Importing main migration SQL..."
if [ -f "../complete_sync_migration.sql" ]; then
    docker compose exec -T db mysql -u root -pexample opencart < ../complete_sync_migration.sql | cat
else
    echo "⚠️  Main migration SQL file not found"
fi

# Apply inventory options SQL
echo "🧩 Applying inventory options SQL..."
if [ -f "../inventory_options.sql" ]; then
    docker compose exec -T db mysql -u root -pexample opencart < ../inventory_options.sql | cat
else
    echo "⚠️  Inventory options SQL file not found"
fi

# Enforce UAH as the only/default currency
echo "💱 Enforcing UAH as the only/default currency across settings..."
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Ensure UAH exists and is enabled
INSERT IGNORE INTO oc_currency (title, code, symbol_left, symbol_right, decimal_place, value, status) 
VALUES ('Ukrainian Hryvnia','UAH','',' ₴',2,1.00000,1);
UPDATE oc_currency SET value=1.00000, status=1 WHERE code='UAH';
-- Disable all other currencies
UPDATE oc_currency SET status=0 WHERE code<>'UAH';

-- Update settings for all stores to UAH
UPDATE oc_setting SET value='UAH' WHERE \`key\`='config_currency';
INSERT INTO oc_setting (store_id, \`code\`, \`key\`, \`value\`, serialized)
SELECT 0, 'config', 'config_currency', 'UAH', 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM oc_setting WHERE store_id=0 AND \`key\`='config_currency');
" | cat

# Copy images into container and set permissions
echo "🖼️  Copying images into container..."
bash ../copy_images_fixed.sh | cat

# Set proper permissions
echo "🔧 Setting permissions..."
docker compose exec custom-opencart-web chown -R www-data:www-data /var/www/html/image/ | cat
docker compose exec custom-opencart-web chmod -R 755 /var/www/html/image/ | cat

# Verify images in container
echo "🔍 Verifying images in container..."
echo "Product images:"
docker compose exec custom-opencart-web ls -la /var/www/html/image/catalog/product/ | head -5 | cat
echo "Category images:"
docker compose exec custom-opencart-web ls -la /var/www/html/image/catalog/category/ | head -5 | cat

echo "✅ Image copying completed!"

# Test image URLs
echo "🌐 Test image URLs:"
echo "   http://localhost:8080/image/catalog/product/p100001.jpg"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"

# Final verification
echo "🔍 Final verification..."
docker compose exec -T db mysql -u root -pexample opencart -e "
SELECT 'Products' as table_name, COUNT(*) as count FROM oc_product
UNION ALL
SELECT 'Categories', COUNT(*) FROM oc_category
UNION ALL
SELECT 'Product Descriptions', COUNT(*) FROM oc_product_description
UNION ALL
SELECT 'Category Descriptions', COUNT(*) FROM oc_category_description;
" | cat

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
echo ""
echo "🎉 Migration process completed!"