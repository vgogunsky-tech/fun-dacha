#!/bin/bash

# Import OpenCart Migration SQL to MySQL
# This script imports the complete migration SQL file to your MySQL database

set -e

echo "🚀 Starting OpenCart SQL Import..."

# Database connection details
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="root"
DB_PASSWORD="example"
DB_NAME="opencart"

# Check if MySQL client is available
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL client is not installed or not in PATH"
    echo "Please install MySQL client and try again"
    exit 1
fi

# Check if SQL file exists
SQL_FILE="/workspace/complete_opencart_migration.sql"
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ SQL file not found: $SQL_FILE"
    exit 1
fi

echo "📋 Found SQL file: $SQL_FILE"

# Test database connection
echo "🔍 Testing database connection..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to database. Please check your connection details."
    echo "   Host: $DB_HOST"
    echo "   Port: $DB_PORT"
    echo "   User: $DB_USER"
    echo "   Database: $DB_NAME"
    exit 1
fi

echo "✅ Database connection successful"

# Import the SQL file
echo "📥 Importing SQL file to database..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo "✅ SQL import completed successfully!"
    echo ""
    echo "📊 Import Summary:"
    echo "   - Database: $DB_NAME"
    echo "   - Categories: 5"
    echo "   - Products: 5"
    echo "   - Banners: 1 (with 8 images)"
    echo "   - Featured products: 1"
    echo "   - Attributes: 4"
    echo ""
    echo "🔍 You can verify the import by:"
    echo "   1. Checking phpMyAdmin at: http://localhost:8082"
    echo "   2. Viewing the OpenCart frontend"
    echo "   3. Logging into the admin panel"
else
    echo "❌ SQL import failed!"
    echo "Check the error messages above for details"
    exit 1
fi

echo "🎉 Import process completed!"