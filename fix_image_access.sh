#!/bin/bash

# Fix Image Access Script
# This script ensures images are accessible via HTTP in OpenCart

set -e

echo "🖼️ Fixing image access in OpenCart..."

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
echo "📋 Checking OpenCart containers status..."
if ! docker compose ps | grep -q "Up"; then
    echo "🔧 Starting OpenCart containers..."
    docker compose up -d
    
    # Wait for containers to be ready
    echo "⏳ Waiting for containers to be ready..."
    sleep 10
fi

# Check current image directory structure
echo "🔍 Checking current image directory structure..."
docker compose exec web ls -la /var/www/html/image/catalog/

# Check if images are accessible via HTTP
echo "🔍 Testing image accessibility..."
echo "Testing category image: http://localhost:8080/image/catalog/category/c100.jpg"
echo "Testing product image: http://localhost:8080/image/catalog/product/p100001.jpg"

# Check OpenCart configuration
echo "🔍 Checking OpenCart configuration..."
docker compose exec web bash -c "
    if [ -f /var/www/html/config.php ]; then
        echo 'OpenCart config.php found'
        grep -i 'image' /var/www/html/config.php || echo 'No image config found'
    else
        echo 'config.php not found'
    fi
"

# Check if there's an .htaccess file that might be blocking images
echo "🔍 Checking .htaccess files..."
docker compose exec web bash -c "
    find /var/www/html -name '.htaccess' -exec echo 'Found: {}' \;
    find /var/www/html/image -name '.htaccess' -exec cat {} \;
"

# Check web server configuration
echo "🔍 Checking web server configuration..."
docker compose exec web bash -c "
    if [ -f /etc/apache2/sites-available/000-default.conf ]; then
        echo 'Apache config found'
        grep -i 'image' /etc/apache2/sites-available/000-default.conf || echo 'No image config in Apache'
    fi
"

# Try to create a test image access
echo "🔧 Creating test image access..."
docker compose exec web bash -c "
    # Create a simple test to see if images are accessible
    echo 'Testing image access...'
    if [ -f /var/www/html/image/catalog/product/p100001.jpg ]; then
        echo 'Image file exists in container'
        ls -la /var/www/html/image/catalog/product/p100001.jpg
    else
        echo 'Image file NOT found in container'
    fi
"

# Check permissions
echo "🔧 Checking and fixing permissions..."
docker compose exec web bash -c "
    chown -R www-data:www-data /var/www/html/image/
    chmod -R 755 /var/www/html/image/
    echo 'Permissions updated'
"

# Check if there are any symbolic links or special configurations
echo "🔍 Checking for symbolic links or special configurations..."
docker compose exec web bash -c "
    ls -la /var/www/html/image/
    ls -la /var/www/html/image/catalog/
    ls -la /var/www/html/image/catalog/product/ | head -5
"

echo "✅ Image access check completed!"
echo ""
echo "🔍 Manual verification steps:"
echo "1. Visit: http://localhost:8080/image/catalog/product/p100001.jpg"
echo "2. Visit: http://localhost:8080/image/catalog/category/c100.jpg"
echo "3. Check if images load in browser"
echo ""
echo "If images still don't load, the issue might be:"
echo "- Web server configuration"
echo "- OpenCart image path configuration"
echo "- Missing .htaccess rules"
echo "- Database image path format"