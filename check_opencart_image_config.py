#!/usr/bin/env python3
"""
Check OpenCart Image Configuration
This script checks how OpenCart is configured to serve images
"""

import pymysql
import sys

def check_opencart_image_config():
    """Check OpenCart image configuration"""
    
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
        
        print("🔍 Checking OpenCart image configuration...")
        
        # Check if there's a setting table that might contain image configuration
        cursor.execute("SHOW TABLES LIKE '%setting%'")
        setting_tables = cursor.fetchall()
        
        if setting_tables:
            print(f"📋 Found setting tables: {[table[0] for table in setting_tables]}")
            
            # Check for image-related settings
            for table in setting_tables:
                table_name = table[0]
                print(f"\n🔍 Checking {table_name} for image settings...")
                
                try:
                    cursor.execute(f"SELECT * FROM {table_name} WHERE `key` LIKE '%image%' OR `key` LIKE '%url%' OR `key` LIKE '%path%'")
                    settings = cursor.fetchall()
                    
                    if settings:
                        for setting in settings:
                            print(f"   {setting}")
                    else:
                        print("   No image-related settings found")
                        
                except Exception as e:
                    print(f"   Error querying {table_name}: {e}")
        
        # Check the actual image paths in products and categories
        print("\n📋 Current image paths in database:")
        
        # Check category images
        cursor.execute("SELECT category_id, image FROM oc_category WHERE image IS NOT NULL AND image != '' LIMIT 5")
        categories = cursor.fetchall()
        print("Categories:")
        for cat_id, image_path in categories:
            print(f"   Category {cat_id}: '{image_path}'")
        
        # Check product images
        cursor.execute("SELECT product_id, image FROM oc_product WHERE image IS NOT NULL AND image != '' LIMIT 5")
        products = cursor.fetchall()
        print("Products:")
        for prod_id, image_path in products:
            print(f"   Product {prod_id}: '{image_path}'")
        
        # Check if there are any URL-related settings
        print("\n🔍 Checking for URL-related settings...")
        for table in setting_tables:
            table_name = table[0]
            try:
                cursor.execute(f"SELECT * FROM {table_name} WHERE `key` LIKE '%url%' OR `key` LIKE '%domain%' OR `key` LIKE '%http%'")
                url_settings = cursor.fetchall()
                
                if url_settings:
                    print(f"\n{table_name} URL settings:")
                    for setting in url_settings:
                        print(f"   {setting}")
                        
            except Exception as e:
                print(f"   Error querying {table_name}: {e}")
        
        cursor.close()
        connection.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Error checking OpenCart configuration: {e}")
        return False

if __name__ == "__main__":
    success = check_opencart_image_config()
    sys.exit(0 if success else 1)