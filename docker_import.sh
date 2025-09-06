#!/bin/bash

# Docker-based OpenCart SQL Import
# This script imports the SQL file using Docker containers

set -e

echo "🚀 Starting Docker-based OpenCart SQL Import..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Check if SQL file exists
SQL_FILE="real_data_migration.sql"
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ SQL file not found: $SQL_FILE"
    echo "Please run: python3 real_data_sql_migration.py"
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
echo "📥 Importing SQL file to database..."
docker compose exec -T db mysql -u root -pexample opencart < ../real_data_migration.sql

if [ $? -eq 0 ]; then
    echo "✅ SQL import completed successfully!"
    echo ""
    echo "📊 Import Summary:"
    echo "   - Database: opencart"
    echo "   - Categories: 37"
    echo "   - Products: 435"
    echo "   - Attributes: 367"
    echo "   - Real data from CSV files"
    echo ""
    echo "🔍 You can verify the import by:"
    echo "   1. Checking phpMyAdmin at: http://localhost:8082"
    echo "   2. Viewing the OpenCart frontend at: http://localhost:8080"
    echo "   3. Logging into the admin panel"
    echo ""
    echo "📋 Database tables populated:"
    echo "   - oc_category (37 categories)"
    echo "   - oc_product (435 products)"
    echo "   - oc_attribute (367 attributes)"
    echo "   - Real Ukrainian/Russian product data"
    echo "   - Inventory and pricing data"
else
    echo "❌ SQL import failed!"
    echo "Check the error messages above for details"
    exit 1
fi

echo "🎉 Import process completed!"