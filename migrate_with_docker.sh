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

# Import main migration SQL
echo "📥 Importing main migration SQL..."
docker compose exec -T db mysql -u root -pexample opencart < ../complete_sync_migration.sql

# Apply inventory options SQL
echo "🧩 Applying inventory options SQL..."
docker compose exec -T db mysql -u root -pexample opencart < ../inventory_options.sql

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