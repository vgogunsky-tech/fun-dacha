#!/bin/bash

# Single Migration Runner Script
# This is the ONE script you need to run for complete migration

set -e

echo "🚀 OpenCart Complete Migration Runner"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "complete_sync_migration.py" ]; then
    echo "❌ Migration script not found. Please run this from the project root directory."
    exit 1
fi

# Check if data directory exists
if [ ! -d "data" ]; then
    echo "❌ Data directory not found. Please ensure CSV files are in the data/ directory."
    exit 1
fi

echo "📋 Found migration script and data directory"
echo ""

# Check if Docker is available
if command -v docker &> /dev/null; then
    echo "🐳 Docker detected - running Docker-based migration..."
    echo ""
    ./complete_sync_docker_migration.sh
else
    echo "⚠️ Docker not available - running local migration..."
    echo "Note: This requires local MySQL server and may not copy images to container."
    echo ""
    python3 complete_sync_migration.py
fi

echo ""
echo "🎉 Migration completed!"
echo ""
echo "📋 What was done:"
echo "   ✅ Synced all data from CSV files"
echo "   ✅ Added new items from CSV"
echo "   ✅ Updated existing items"
echo "   ✅ Removed items not in CSV"
echo "   ✅ Updated timestamps (date_added, date_modified)"
echo "   ✅ Copied images to container (if Docker available)"
echo "   ✅ Localized tags (Ukrainian/Russian)"
echo "   ✅ Fixed display issues"
echo ""
echo "🔍 Next steps:"
echo "   1. Visit http://localhost:8080 to see your OpenCart store"
echo "   2. Check http://localhost:8080/admin for admin panel"
echo "   3. Use http://localhost:8082 for phpMyAdmin"