#!/bin/bash

# Simple Language Setup Script
# This script sets up languages without problematic columns

set -e

echo "🌍 Setting up languages (simple version)..."

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

# Step 1: Check database structure first
echo "🔍 Step 1: Checking database structure..."
docker compose exec db mysql -u root -pexample opencart -e "DESCRIBE oc_language;"

# Step 2: Setup languages
echo "🌍 Step 2: Setting up languages..."
docker compose exec -T db mysql -u root -pexample opencart < ../simple_language_setup.sql

if [ $? -eq 0 ]; then
    echo "✅ Languages setup completed successfully!"
else
    echo "❌ Languages setup failed!"
    exit 1
fi

# Step 3: Verify languages
echo "🔍 Step 3: Verifying languages..."
docker compose exec db mysql -u root -pexample opencart -e "
SELECT 'Languages configured:' as status;
SELECT language_id, name, code, status FROM oc_language ORDER BY language_id;
"

echo ""
echo "🎉 Simple language setup completed!"
echo ""
echo "📊 Languages configured:"
echo "   - Ukrainian (Українська) - language_id = 2"
echo "   - Russian (Русский) - language_id = 3"
echo "   - English - language_id = 1"
echo ""
echo "💡 Next step: Run the migration with language support"
echo "   ./run_migration.sh"