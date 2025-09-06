#!/usr/bin/env python3
"""
Test Image Paths Script
This script tests different image path formats to see which one works
"""

import pymysql
import sys

def test_image_paths():
    """Test different image path formats"""
    
    try:
        # Connect to database
        connection = pymysql.connect(
            host='localhost',
            port=3306,
            user='root',
            password='example',
            database='opencart',
            charset='utf8mb4'
        )
        cursor = connection.cursor()
        
        print("🔍 Testing different image path formats...")
        
        # Get a sample product
        cursor.execute("SELECT product_id, image FROM oc_product WHERE product_id = 1")
        result = cursor.fetchone()
        
        if result:
            product_id, current_image = result
            print(f"📋 Product {product_id} current image path: '{current_image}'")
            
            # Test different path formats
            test_paths = [
                "catalog/product/p100001.jpg",  # Current format
                "/catalog/product/p100001.jpg",  # With leading slash
                "image/catalog/product/p100001.jpg",  # With image prefix
                "/image/catalog/product/p100001.jpg",  # With image prefix and slash
                "p100001.jpg",  # Just filename
                "product/p100001.jpg",  # Without catalog
            ]
            
            print("\n🔧 Testing different path formats:")
            for i, test_path in enumerate(test_paths, 1):
                print(f"   {i}. '{test_path}'")
                
                # Update the product with test path
                cursor.execute("UPDATE oc_product SET image = %s WHERE product_id = %s", (test_path, product_id))
                connection.commit()
                
                print(f"      ✅ Updated product {product_id} with path: '{test_path}'")
                print(f"      🌐 Test URL: http://localhost:8080/{test_path}")
                print(f"      🌐 Alternative URL: http://localhost:8080/image/{test_path}")
                print()
        
        # Restore original path
        if result:
            cursor.execute("UPDATE oc_product SET image = %s WHERE product_id = %s", (current_image, 1))
            connection.commit()
            print(f"✅ Restored original image path: '{current_image}'")
        
        cursor.close()
        connection.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing image paths: {e}")
        return False

if __name__ == "__main__":
    success = test_image_paths()
    sys.exit(0 if success else 1)