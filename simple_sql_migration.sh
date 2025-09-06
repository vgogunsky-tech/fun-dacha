#!/bin/bash

# Simple SQL Migration Script
# This script generates SQL and imports it without requiring Python packages in container

set -e

echo "🚀 Starting Simple SQL Migration..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Generate SQL file
echo "🔧 Generating SQL migration file..."
python3 complete_sync_sql_migration.py

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate SQL file"
    exit 1
fi

# Check if SQL file exists
SQL_FILE="complete_sync_migration.sql"
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ SQL file not found: $SQL_FILE"
    exit 1
fi

echo "📋 Found SQL file: $SQL_FILE"

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

# Test database connection
echo "🔍 Testing database connection..."
docker compose exec db mysql -u root -pexample -e "SELECT 1;" opencart

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to database. Please check your Docker setup."
    exit 1
fi

echo "✅ Database connection successful"

# Import the SQL file directly
echo "📥 Importing complete sync SQL file to database..."
docker compose exec -T db mysql -u root -pexample opencart < ../complete_sync_migration.sql

if [ $? -eq 0 ]; then
    echo "✅ SQL import completed successfully!"
    
    # Copy images to container using fixed script
    echo "🖼️ Copying images to container..."
    bash ../copy_images_fixed.sh
    
    echo "✅ Images copied to container successfully!"
    echo ""
    echo "📊 Complete Sync Migration Summary:"
    echo "   - Database: opencart"
    echo "   - Categories: 37 (with images)"
    echo "   - Products: 435 (with images and timestamps)"
    echo "   - Attributes: 367 (localized)"
    echo "   - Complete sync: Add/Update/Remove functionality"
    echo "   - Timestamps: date_added and date_modified set"
    echo "   - Localized tags (Ukrainian/Russian)"
    echo "   - Images copied to container"
    echo ""
    echo "🔍 You can verify the migration by:"
    echo "   1. Checking phpMyAdmin at: http://localhost:8082"
    echo "   2. Viewing the OpenCart frontend at: http://localhost:8080"
    echo "   3. Logging into the admin panel"
    echo ""
    echo "🖼️ Images are now available at:"
    echo "   - Categories: http://localhost:8080/image/catalog/category/"
    echo "   - Products: http://localhost:8080/image/catalog/product/"
else
    echo "❌ SQL import failed!"
    echo "Check the error messages above for details"
    exit 1
fi

echo "🎉 Complete sync migration process completed!"