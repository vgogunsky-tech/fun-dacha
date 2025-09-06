#!/bin/bash

# Complete Sync Docker Migration Script
# This script runs the complete sync migration using Docker containers
# Features: Add/Update/Remove sync, Timestamps, Images, Localized tags

set -e

echo "🚀 Starting Complete Sync OpenCart Migration..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Check if migration script exists
if [ ! -f "complete_sync_migration.py" ]; then
    echo "❌ complete_sync_migration.py not found in current directory"
    exit 1
fi

echo "📋 Found complete sync migration script: complete_sync_migration.py"

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

# Install Python dependencies in the web container
echo "📦 Installing Python dependencies..."
docker compose exec web bash -c "
    apt-get update && 
    apt-get install -y python3 python3-pip &&
    pip3 install pymysql
"

# Copy migration script to the container
echo "📋 Copying complete sync migration script to container..."
docker compose cp ../complete_sync_migration.py web:/var/www/html/migration.py

# Copy data files to the container
echo "📋 Copying data files to container..."
docker compose cp ../data/list.csv web:/var/www/html/list.csv
docker compose cp ../data/categories_list.csv web:/var/www/html/categories_list.csv
docker compose cp ../data/inventory.csv web:/var/www/html/inventory.csv
docker compose cp ../data/tags.csv web:/var/www/html/tags.csv

# Update database configuration in the migration script for Docker environment
echo "🔧 Updating database configuration for Docker..."
docker compose exec web bash -c "
    sed -i 's/host.*localhost/host = \"db\"/' /var/www/html/migration.py &&
    sed -i 's|data/categories_list.csv|/var/www/html/categories_list.csv|' /var/www/html/migration.py &&
    sed -i 's|data/list.csv|/var/www/html/list.csv|' /var/www/html/migration.py &&
    sed -i 's|data/inventory.csv|/var/www/html/inventory.csv|' /var/www/html/migration.py &&
    sed -i 's|data/tags.csv|/var/www/html/tags.csv|' /var/www/html/migration.py
"

# Run the complete sync migration
echo "🔄 Running complete sync migration..."
docker compose exec web python3 /var/www/html/migration.py

if [ $? -eq 0 ]; then
    echo "✅ Complete sync migration completed successfully!"
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
    echo ""
    echo "📋 Complete sync features:"
    echo "   - ✅ Added new items from CSV"
    echo "   - ✅ Updated existing items in both CSV and DB"
    echo "   - ✅ Removed items not in CSV"
    echo "   - ✅ Updated date_added and date_modified timestamps"
    echo "   - ✅ Copied images to container"
    echo "   - ✅ Localized tags (Ukrainian/Russian)"
    echo "   - ✅ Real inventory and pricing data"
    echo "   - ✅ Fixed display issues"
    echo ""
    echo "🖼️ Images are now available at:"
    echo "   - Categories: http://localhost:8080/image/catalog/category/"
    echo "   - Products: http://localhost:8080/image/catalog/product/"
else
    echo "❌ Migration failed!"
    echo "Check the migration.log file in the container for details:"
    echo "docker compose exec web cat /var/www/html/complete_sync_migration.log"
    exit 1
fi

echo "🎉 Complete sync migration process completed!"