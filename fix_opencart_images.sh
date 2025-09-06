#!/bin/bash

# Fix OpenCart Images Script
# This script tries multiple approaches to fix image display issues

set -e

echo "🖼️ Fixing OpenCart image display issues..."

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

echo "🔍 Step 1: Checking current image setup..."

# Check if images exist in the container
docker compose exec web bash -c "
    echo 'Checking image files in container...'
    ls -la /var/www/html/image/catalog/product/p100001.jpg
    ls -la /var/www/html/image/catalog/category/c100.jpg
"

echo "🔧 Step 2: Testing different image path formats..."

# Test different path formats by updating the database
docker compose exec web bash -c "
    mysql -h db -u root -pexample opencart -e \"
    -- Test different image path formats
    UPDATE oc_product SET image = 'catalog/product/p100001.jpg' WHERE product_id = 1;
    UPDATE oc_product SET image = '/catalog/product/p100001.jpg' WHERE product_id = 2;
    UPDATE oc_product SET image = 'image/catalog/product/p100001.jpg' WHERE product_id = 3;
    UPDATE oc_product SET image = '/image/catalog/product/p100001.jpg' WHERE product_id = 4;
    UPDATE oc_product SET image = 'p100001.jpg' WHERE product_id = 5;
    \"
"

echo "🔧 Step 3: Creating symbolic links for alternative access..."

# Create symbolic links for different path formats
docker compose exec web bash -c "
    # Create symbolic links for different access patterns
    ln -sf /var/www/html/image/catalog/product /var/www/html/catalog/product
    ln -sf /var/www/html/image/catalog/category /var/www/html/catalog/category
    ln -sf /var/www/html/image/catalog/product /var/www/html/product
    ln -sf /var/www/html/image/catalog/category /var/www/html/category
    echo 'Symbolic links created'
"

echo "🔧 Step 4: Setting proper permissions..."

# Set proper permissions
docker compose exec web bash -c "
    chown -R www-data:www-data /var/www/html/image/
    chmod -R 755 /var/www/html/image/
    chown -R www-data:www-data /var/www/html/catalog/
    chmod -R 755 /var/www/html/catalog/
    echo 'Permissions updated'
"

echo "🔧 Step 5: Creating .htaccess for image access..."

# Create .htaccess file to ensure images are accessible
docker compose exec web bash -c "
    cat > /var/www/html/image/.htaccess << 'EOF'
# Allow access to images
<Files ~ \"\.(jpg|jpeg|png|gif|webp)$\">
    Order allow,deny
    Allow from all
</Files>

# Enable directory browsing for debugging
Options +Indexes
EOF
    echo '.htaccess created for image directory'
"

echo "🔧 Step 6: Testing image accessibility..."

# Test different URL patterns
echo "🌐 Testing image URLs:"
echo "   http://localhost:8080/image/catalog/product/p100001.jpg"
echo "   http://localhost:8080/catalog/product/p100001.jpg"
echo "   http://localhost:8080/product/p100001.jpg"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"
echo "   http://localhost:8080/catalog/category/c100.jpg"
echo "   http://localhost:8080/category/c100.jpg"

echo "🔧 Step 7: Checking OpenCart configuration..."

# Check if there's a config file that might affect image paths
docker compose exec web bash -c "
    if [ -f /var/www/html/config.php ]; then
        echo 'OpenCart config.php found'
        echo 'Checking for image-related configuration...'
        grep -i 'image\|url\|path' /var/www/html/config.php || echo 'No image config found'
    else
        echo 'config.php not found'
    fi
"

echo "🔧 Step 8: Creating test HTML page..."

# Create a test HTML page to verify image access
docker compose exec web bash -c "
    cat > /var/www/html/test-images.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>OpenCart Image Test</title>
</head>
<body>
    <h1>OpenCart Image Test</h1>
    
    <h2>Product Images</h2>
    <img src=\"image/catalog/product/p100001.jpg\" alt=\"Product 1\" style=\"max-width: 200px;\">
    <br>image/catalog/product/p100001.jpg
    <br><br>
    
    <img src=\"catalog/product/p100001.jpg\" alt=\"Product 1 Alt\" style=\"max-width: 200px;\">
    <br>catalog/product/p100001.jpg
    <br><br>
    
    <img src=\"product/p100001.jpg\" alt=\"Product 1 Alt2\" style=\"max-width: 200px;\">
    <br>product/p100001.jpg
    <br><br>
    
    <h2>Category Images</h2>
    <img src=\"image/catalog/category/c100.jpg\" alt=\"Category 1\" style=\"max-width: 200px;\">
    <br>image/catalog/category/c100.jpg
    <br><br>
    
    <img src=\"catalog/category/c100.jpg\" alt=\"Category 1 Alt\" style=\"max-width: 200px;\">
    <br>catalog/category/c100.jpg
    <br><br>
    
    <img src=\"category/c100.jpg\" alt=\"Category 1 Alt2\" style=\"max-width: 200px;\">
    <br>category/c100.jpg
</body>
</html>
EOF
    echo 'Test HTML page created at http://localhost:8080/test-images.html'
"

echo "✅ Image fix process completed!"
echo ""
echo "🔍 Manual verification steps:"
echo "1. Visit: http://localhost:8080/test-images.html"
echo "2. Check which image paths work"
echo "3. Visit the OpenCart frontend to see if images display"
echo ""
echo "📋 If images still don't work, the issue might be:"
echo "- OpenCart configuration in admin panel"
echo "- Web server configuration"
echo "- Database image path format"
echo "- Missing OpenCart image handling code"