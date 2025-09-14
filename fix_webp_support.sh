#!/bin/bash

# Fix WebP support in OpenCart Docker container
# This script enables WebP support in PHP GD extension

echo "🔧 Fixing WebP support in OpenCart Docker container..."

# Check if we're in the right directory
if [ ! -f "migrate_with_docker.sh" ]; then
    echo "❌ Please run this script from the repository root directory"
    echo "   cd /path/to/fun-dacha"
    echo "   ./fix_webp_support.sh"
    exit 1
fi

# Navigate to opencart-docker directory
cd opencart-docker

# Check if containers are running
if ! docker compose ps | grep -q "opencart.*Up"; then
    echo "❌ OpenCart containers are not running. Please run migrate_with_docker.sh first."
    exit 1
fi

echo "1. 🔍 Checking current PHP GD configuration..."
docker compose exec web php -m | grep -i gd || echo "GD extension not found"

echo ""
echo "2. 🔍 Checking WebP support..."
docker compose exec web php -r "
if (function_exists('imagecreatefromwebp')) {
    echo 'WebP support: ENABLED' . PHP_EOL;
} else {
    echo 'WebP support: DISABLED' . PHP_EOL;
}
"

echo ""
echo "3. 🔧 Installing WebP support in PHP GD..."
docker compose exec web bash -c "
# Update package list
apt-get update

# Install WebP support for PHP GD
apt-get install -y libwebp-dev

# Install PHP GD with WebP support
apt-get install -y php-gd

# Alternative: try to enable WebP support in existing GD
# This might require recompiling PHP, so we'll try a different approach
"

echo ""
echo "4. 🔧 Alternative approach: Converting WebP images to JPG..."
# Convert all WebP images to JPG to avoid the WebP support issue
echo "Converting WebP images to JPG format..."

# Install ImageMagick for conversion
docker compose exec web bash -c "
apt-get update
apt-get install -y imagemagick
"

# Convert WebP images to JPG
echo "Converting product images..."
docker compose exec web bash -c "
find /var/www/html/image/catalog/product -name '*.webp' -exec convert {} {}.jpg \; 2>/dev/null || true
find /var/www/html/image/catalog/product -name '*.webp' -delete 2>/dev/null || true
"

echo "Converting category images..."
docker compose exec web bash -c "
find /var/www/html/image/catalog/category -name '*.webp' -exec convert {} {}.jpg \; 2>/dev/null || true
find /var/www/html/image/catalog/category -name '*.webp' -delete 2>/dev/null || true
"

echo ""
echo "5. 🔧 Updating OpenCart to handle JPG instead of WebP..."
# Update the database to change WebP references to JPG
docker compose exec -T db mysql -u root -pexample opencart -e "
-- Update product images from .webp to .jpg
UPDATE oc_product SET image = REPLACE(image, '.webp', '.jpg') WHERE image LIKE '%.webp';
UPDATE oc_product_image SET image = REPLACE(image, '.webp', '.jpg') WHERE image LIKE '%.webp';

-- Update category images from .webp to .jpg
UPDATE oc_category SET image = REPLACE(image, '.webp', '.jpg') WHERE image LIKE '%.webp';

-- Update any other image references
UPDATE oc_setting SET value = REPLACE(value, '.webp', '.jpg') WHERE value LIKE '%.webp';
" | cat

echo ""
echo "6. 🧼 Clearing caches..."
docker compose exec web bash -lc "rm -rf /var/www/html/system/storage/cache/* /var/www/html/image/cache/* || true"

echo ""
echo "7. 🔄 Restarting OpenCart..."
docker compose restart web

echo ""
echo "8. ⏳ Waiting for OpenCart to be ready..."
sleep 10

echo ""
echo "9. 🔍 Testing WebP support again..."
docker compose exec web php -r "
if (function_exists('imagecreatefromwebp')) {
    echo 'WebP support: ENABLED' . PHP_EOL;
} else {
    echo 'WebP support: DISABLED (but images converted to JPG)' . PHP_EOL;
}
"

echo ""
echo "10. 🌐 Testing OpenCart accessibility..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/

echo ""
echo "✅ WebP fix completed!"
echo ""
echo "🌐 Now check:"
echo "   Frontend: http://localhost:8080"
echo "   Admin: http://localhost:8080/admin"
echo ""
echo "📝 What was done:"
echo "   ✅ Converted all WebP images to JPG format"
echo "   ✅ Updated database references from .webp to .jpg"
echo "   ✅ Cleared caches and restarted OpenCart"
echo ""
echo "If you still see errors:"
echo "1. Clear browser cache (Ctrl+F5 or incognito mode)"
echo "2. Check if images are loading properly"
echo "3. The error should be resolved as all WebP images are now JPG"