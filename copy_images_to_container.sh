#!/bin/bash

# Copy Images to Container Script
# This script copies images from local opencart_data to the Docker container

set -e

echo "🖼️ Copying images to Docker container..."

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

echo "🔍 Step 1: Checking local image files..."
if [ -d "opencart_data/image/catalog/product" ]; then
    echo "✅ Product images found locally"
    ls opencart_data/image/catalog/product/ | head -5
else
    echo "❌ Product images not found locally"
    exit 1
fi

if [ -d "opencart_data/image/catalog/category" ]; then
    echo "✅ Category images found locally"
    ls opencart_data/image/catalog/category/ | head -5
else
    echo "❌ Category images not found locally"
    exit 1
fi

echo "🔧 Step 2: Copying images to container..."

# Copy product images to container
echo "📋 Copying product images..."
docker compose cp opencart_data/image/catalog/product web:/var/www/html/image/catalog/product

# Copy category images to container
echo "📋 Copying category images..."
docker compose cp opencart_data/image/catalog/category web:/var/www/html/image/catalog/category

echo "🔧 Step 3: Setting proper permissions..."
docker compose exec web bash -c "
    chown -R www-data:www-data /var/www/html/image/
    chmod -R 755 /var/www/html/image/
    echo 'Permissions updated'
"

echo "🔍 Step 4: Verifying images in container..."
docker compose exec web bash -c "
    echo 'Checking product images in container:'
    ls -la /var/www/html/image/catalog/product/ | head -5
    echo 'Checking category images in container:'
    ls -la /var/www/html/image/catalog/category/ | head -5
"

echo "🔧 Step 5: Creating symbolic links for alternative access..."
docker compose exec web bash -c "
    # Create symbolic links for different access patterns
    ln -sf /var/www/html/image/catalog/product /var/www/html/catalog/product
    ln -sf /var/www/html/image/catalog/category /var/www/html/catalog/category
    ln -sf /var/www/html/image/catalog/product /var/www/html/product
    ln -sf /var/www/html/image/catalog/category /var/www/html/category
    echo 'Symbolic links created'
"

echo "🔧 Step 6: Creating .htaccess for image access..."
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

echo "🔧 Step 7: Creating test HTML page..."
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

echo "✅ Images copied to container successfully!"
echo ""
echo "🔍 Test the images:"
echo "1. Visit: http://localhost:8080/test-images.html"
echo "2. Check which image paths work"
echo "3. Visit the OpenCart frontend to see if images display"
echo ""
echo "🌐 Direct image URLs to test:"
echo "   http://localhost:8080/image/catalog/product/p100001.jpg"
echo "   http://localhost:8080/catalog/product/p100001.jpg"
echo "   http://localhost:8080/product/p100001.jpg"
echo "   http://localhost:8080/image/catalog/category/c100.jpg"
echo "   http://localhost:8080/catalog/category/c100.jpg"
echo "   http://localhost:8080/category/c100.jpg"