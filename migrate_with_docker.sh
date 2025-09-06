#!/bin/bash

# OpenCart Migration Script using Docker
# This script runs the migration inside the OpenCart Docker environment

set -e

echo "🚀 Starting OpenCart Product Migration..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Navigate to opencart-docker directory
cd /workspace/opencart-docker

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

# Install Python dependencies in the web container
echo "📦 Installing Python dependencies..."
docker compose exec web bash -c "
    apt-get update && 
    apt-get install -y python3 python3-pip &&
    pip3 install pymysql
"

# Copy migration script to the container
echo "📋 Copying migration script to container..."
docker compose cp /workspace/complete_migration.py web:/var/www/html/migration.py

# Copy data files to the container
echo "📋 Copying data files to container..."
docker compose cp /workspace/data/list.csv web:/var/www/html/list.csv
docker compose cp /workspace/data/categories_list.csv web:/var/www/html/categories_list.csv
docker compose cp /workspace/data/inventory.csv web:/var/www/html/inventory.csv
docker compose cp /workspace/data/tags.csv web:/var/www/html/tags.csv

# Update database configuration in the migration script for Docker environment
echo "🔧 Updating database configuration for Docker..."
docker compose exec web bash -c "
    sed -i 's/host.*localhost/host = \"db\"/' /var/www/html/migration.py &&
    sed -i 's|/workspace/data/categories_list.csv|/var/www/html/categories_list.csv|' /var/www/html/migration.py &&
    sed -i 's|/workspace/data/list.csv|/var/www/html/list.csv|' /var/www/html/migration.py &&
    sed -i 's|/workspace/data/inventory.csv|/var/www/html/inventory.csv|' /var/www/html/migration.py &&
    sed -i 's|/workspace/data/tags.csv|/var/www/html/tags.csv|' /var/www/html/migration.py
"

# Run the migration
echo "🔄 Running migration..."
docker compose exec web python3 /var/www/html/migration.py

# Migrate images
echo "🖼️  Migrating images..."
docker compose cp /workspace/migrate_images.py web:/var/www/html/migrate_images.py
docker compose exec web python3 /var/www/html/migrate_images.py

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
else
    echo "❌ Migration failed!"
    echo "Check the migration.log file in the container for details:"
    echo "docker compose exec web cat /var/www/html/migration.log"
    exit 1
fi

echo "🎉 Migration process completed!"