#!/bin/bash

# Adaptive Language Setup Script
# This script tries different column combinations to find what works

set -e

echo "🌍 Adaptive language setup (finding what works)..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    sleep 10
fi

# Test database connection
echo "🔍 Testing database connection..."
docker compose exec db mysql -u root -pexample -e "SELECT 1;" opencart

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to database"
    exit 1
fi

echo "✅ Database connection successful"

# Step 1: Check what columns actually exist
echo "🔍 Step 1: Checking oc_language table structure..."
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_language;"

# Step 2: Try minimal setup
echo "🌍 Step 2: Trying minimal language setup..."
docker compose exec -T db mysql -u root -pexample opencart < ../minimal_language_setup.sql

if [ $? -eq 0 ]; then
    echo "✅ Minimal language setup worked!"
else
    echo "❌ Minimal setup failed, trying even more basic approach..."
    
    # Try with just the most basic columns
    echo "🔧 Trying ultra-minimal setup..."
    docker compose exec db mysql -u root -pexample opencart -e "
    INSERT IGNORE INTO oc_language (language_id, name, code, status) 
    VALUES (2, 'Українська', 'ua', 1);
    
    INSERT IGNORE INTO oc_language (language_id, name, code, status) 
    VALUES (3, 'Русский', 'ru', 1);
    
    UPDATE oc_language SET language_id = 1 WHERE code = 'en' AND language_id != 1;
    "
    
    if [ $? -eq 0 ]; then
        echo "✅ Ultra-minimal setup worked!"
    else
        echo "❌ Even ultra-minimal setup failed"
        echo "Let's see what's in the oc_language table:"
        docker compose exec db mysql -u root -pexample opencart -e "SELECT * FROM oc_language;"
        exit 1
    fi
fi

# Step 3: Verify languages
echo "🔍 Step 3: Verifying languages..."
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 'Languages configured:' as status;
SELECT language_id, name, code, status FROM oc_language ORDER BY language_id;
"

# Step 4: Set default language
echo "🔧 Step 4: Setting default language..."
docker compose exec db mysql -u root -pexample opencart -e "
INSERT IGNORE INTO oc_setting (store_id, code, \`key\`, value, serialized) VALUES
(0, 'config', 'config_language', '2', 0);
"

echo ""
echo "🎉 Language setup completed!"
echo ""
echo "📊 Languages configured:"
echo "   - Ukrainian (Українська) - language_id = 2"
echo "   - Russian (Русский) - language_id = 3"
echo "   - English - language_id = 1"
echo ""
echo "💡 Next step: Run the migration with language support"
echo "   ./run_migration.sh"