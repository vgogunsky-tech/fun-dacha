#!/bin/bash

# Fix Product Display Issues
# This script fixes common issues that prevent products from showing in OpenCart

set -e

echo "🔧 Fixing Product Display Issues..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
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

# Apply the fix
echo "📥 Applying product display fixes..."
docker compose exec -T db mysql -u root -pexample opencart < ../fix_product_display.sql

if [ $? -eq 0 ]; then
    echo "✅ Product display fixes applied successfully!"
    echo ""
    echo "🔍 Now check your OpenCart frontend:"
    echo "   1. Go to: http://localhost:8080"
    echo "   2. Check the categories menu"
    echo "   3. Look for the products we added"
    echo ""
    echo "📋 If products still don't show, try:"
    echo "   1. Clear OpenCart cache (if you have access to admin)"
    echo "   2. Check if the store is in maintenance mode"
    echo "   3. Verify the theme is properly configured"
else
    echo "❌ Failed to apply fixes!"
    echo "Check the error messages above for details"
    exit 1
fi

echo "🎉 Fix process completed!"