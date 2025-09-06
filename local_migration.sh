#!/bin/bash

# Local OpenCart Migration Script
# This script runs the migration on your local machine

set -e

echo "🚀 Starting Local OpenCart Migration..."

# Check if we're in the right directory
if [ ! -f "complete_migration.py" ]; then
    echo "❌ complete_migration.py not found in current directory"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed or not in PATH"
    exit 1
fi

# Install required Python package
echo "📦 Installing Python dependencies..."
pip3 install pymysql --break-system-packages 2>/dev/null || pip3 install pymysql

# Check if data files exist
if [ ! -d "data" ]; then
    echo "❌ Data directory not found"
    exit 1
fi

echo "📋 Found data files:"
ls -la data/

# Run the migration
echo "🔄 Running migration..."
python3 complete_migration.py

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
    echo ""
    echo "📊 Migration Summary:"
    echo "   - Database: opencart"
    echo "   - Categories: Migrated from categories_list.csv"
    echo "   - Products: Migrated from list.csv"
    echo "   - Attributes: Migrated from tags.csv"
    echo "   - Banners: Created with product images"
    echo "   - Featured products: Automatically selected"
    echo ""
    echo "🔍 You can verify the migration by:"
    echo "   1. Checking phpMyAdmin at: http://localhost:8082"
    echo "   2. Viewing the OpenCart frontend"
    echo "   3. Logging into the admin panel"
else
    echo "❌ Migration failed!"
    echo "Check the complete_migration.log file for details"
    exit 1
fi

echo "🎉 Migration process completed!"