#!/usr/bin/env python3
"""
Check Database Images Script
This script checks what image paths are actually stored in the database
"""

import pymysql
import sys

def check_database_images():
    """Check image paths in the database"""
    
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
        
        print("🔍 Checking image paths in database...")
        
        # Check category images
        print("\n📋 Category Images:")
        cursor.execute("SELECT category_id, image FROM oc_category WHERE image IS NOT NULL AND image != '' LIMIT 10")
        categories = cursor.fetchall()
        
        for cat_id, image_path in categories:
            print(f"   Category {cat_id}: {image_path}")
        
        # Check product images
        print("\n📋 Product Images:")
        cursor.execute("SELECT product_id, image FROM oc_product WHERE image IS NOT NULL AND image != '' LIMIT 10")
        products = cursor.fetchall()
        
        for prod_id, image_path in products:
            print(f"   Product {prod_id}: {image_path}")
        
        # Check if there are any products without images
        cursor.execute("SELECT COUNT(*) FROM oc_product WHERE image IS NULL OR image = ''")
        no_image_count = cursor.fetchone()[0]
        print(f"\n📊 Products without images: {no_image_count}")
        
        # Check total products
        cursor.execute("SELECT COUNT(*) FROM oc_product")
        total_products = cursor.fetchone()[0]
        print(f"📊 Total products: {total_products}")
        
        cursor.close()
        connection.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Error checking database: {e}")
        return False

if __name__ == "__main__":
    success = check_database_images()
    sys.exit(0 if success else 1)