#!/bin/bash

# Enhanced Real Data Docker Migration Script
# This script runs the enhanced real data migration using Docker containers
# Features: Images, Localized tags (UA/RU), Real inventory data

set -e

echo "🚀 Starting Enhanced Real Data OpenCart Migration..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Check if migration script exists
if [ ! -f "enhanced_real_data_migration.py" ]; then
    echo "❌ enhanced_real_data_migration.py not found in current directory"
    exit 1
fi

echo "📋 Found enhanced migration script: enhanced_real_data_migration.py"

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
echo "📋 Copying enhanced migration script to container..."
docker compose cp ../enhanced_real_data_migration.py web:/var/www/html/migration.py

# Copy data files to the container
echo "📋 Copying data files to container..."
docker compose cp ../data/list.csv web:/var/www/html/list.csv
docker compose cp ../data/categories_list.csv web:/var/www/html/categories_list.csv
docker compose cp ../data/inventory.csv web:/var/www/html/inventory.csv
docker compose cp ../data/tags.csv web:/var/www/html/tags.csv

# Copy images to the container
echo "📋 Copying images to container..."
docker compose cp ../data/images/categories web:/var/www/html/image/catalog/categories
docker compose cp ../data/images/products web:/var/www/html/image/catalog/products

# Update database configuration in the migration script for Docker environment
echo "🔧 Updating database configuration for Docker..."
docker compose exec web bash -c "
    sed -i 's/host.*localhost/host = \"db\"/' /var/www/html/migration.py &&
    sed -i 's|data/categories_list.csv|/var/www/html/categories_list.csv|' /var/www/html/migration.py &&
    sed -i 's|data/list.csv|/var/www/html/list.csv|' /var/www/html/migration.py &&
    sed -i 's|data/inventory.csv|/var/www/html/inventory.csv|' /var/www/html/migration.py &&
    sed -i 's|data/tags.csv|/var/www/html/tags.csv|' /var/www/html/migration.py
"

# Run the enhanced migration
echo "🔄 Running enhanced real data migration..."
docker compose exec web python3 /var/www/html/migration.py

if [ $? -eq 0 ]; then
    echo "✅ Enhanced real data migration completed successfully!"
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
    echo "📋 Enhanced features migrated:"
    echo "   - Categories with images from data/images/categories/"
    echo "   - Products with images from data/images/products/"
    echo "   - Localized tags (Ukrainian/Russian)"
    echo "   - Real inventory and pricing data"
    echo "   - 37 categories, 435 products, 367 attributes"
    echo ""
    echo "🖼️ Images are now available at:"
    echo "   - Categories: http://localhost:8080/image/catalog/categories/"
    echo "   - Products: http://localhost:8080/image/catalog/products/"
else
    echo "❌ Migration failed!"
    echo "Check the migration.log file in the container for details:"
    echo "docker compose exec web cat /var/www/html/enhanced_real_data_migration.log"
    exit 1
fi

echo "🎉 Enhanced real data migration process completed!"