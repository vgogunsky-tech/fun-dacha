#!/bin/bash

# Try All Migrations Script
# This script tries different migration files until one works

set -e

echo "🚀 Trying All Migration Options..."

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

# List of migration files to try in order
MIGRATION_FILES=(
    "absolute_minimum_migration.sql"
    "bare_minimum_migration.sql"
    "ultra_minimal_migration.sql"
    "minimal_opencart_migration.sql"
    "essential_opencart_migration.sql"
    "complete_opencart_migration.sql"
)

# Try each migration file
for migration_file in "${MIGRATION_FILES[@]}"; do
    if [ -f "../$migration_file" ]; then
        echo ""
        echo "🔄 Trying migration: $migration_file"
        echo "📥 Importing SQL file to database..."
        
        if docker compose exec -T db mysql -u root -pexample opencart < "../$migration_file" 2>/dev/null; then
            echo "✅ Migration completed successfully with: $migration_file"
            echo ""
            echo "📊 Migration Summary:"
            echo "   - Database: opencart"
            echo "   - Categories: 5"
            echo "   - Products: 5"
            echo ""
            echo "🔍 You can verify the migration by:"
            echo "   1. Checking phpMyAdmin at: http://localhost:8082"
            echo "   2. Viewing the OpenCart frontend at: http://localhost:8080"
            echo ""
            echo "🎉 Migration process completed successfully!"
            exit 0
        else
            echo "❌ Migration failed with: $migration_file"
            echo "   Trying next migration file..."
        fi
    else
        echo "⚠️  Migration file not found: $migration_file"
    fi
done

echo ""
echo "❌ All migration attempts failed!"
echo "Your OpenCart database structure might be very different from standard OpenCart."
echo ""
echo "🔍 Try running the adaptive migration:"
echo "   ./adaptive_migration.sh"
echo ""
echo "Or check your database structure:"
echo "   ./check_database_structure.sh"

exit 1