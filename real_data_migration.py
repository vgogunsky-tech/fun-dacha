#!/usr/bin/env python3
"""
Real Data OpenCart Migration Script
This script performs CSV to SQL migration using actual data from CSV files
"""

import csv
import json
import os
import sys
import logging
from datetime import datetime
import hashlib
from pathlib import Path
import pymysql

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('real_data_migration.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class RealDataOpenCartMigrator:
    def __init__(self, host='localhost', port=3306, user='root', password='example', database='opencart'):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.database = database
        self.connection = None
        self.cursor = None
        
    def connect_to_database(self):
        """Connect to MySQL database"""
        try:
            # First connect without database to create it if needed
            self.connection = pymysql.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                charset='utf8mb4'
            )
            self.cursor = self.connection.cursor()
            
            # Create database if it doesn't exist
            self.cursor.execute(f"CREATE DATABASE IF NOT EXISTS {self.database} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
            self.cursor.execute(f"USE {self.database}")
            
            logger.info(f"Connected to MySQL database: {self.database}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to MySQL database: {e}")
            return False
    
    def migrate_categories(self):
        """Migrate categories from categories_list.csv"""
        try:
            logger.info("Migrating categories from categories_list.csv...")
            
            # Clear existing data
            self.cursor.execute("DELETE FROM oc_product_to_category WHERE product_id > 0")
            self.cursor.execute("DELETE FROM oc_product_description WHERE product_id > 0")
            self.cursor.execute("DELETE FROM oc_product WHERE product_id > 0")
            self.cursor.execute("DELETE FROM oc_category_path WHERE category_id > 0")
            self.cursor.execute("DELETE FROM oc_category_description WHERE category_id > 0")
            self.cursor.execute("DELETE FROM oc_category WHERE category_id > 0")
            
            categories_csv = Path("data/categories_list.csv")
            if not categories_csv.exists():
                logger.error("categories_list.csv not found")
                return False
            
            category_id = 1
            category_mapping = {}  # Map old IDs to new IDs
            
            with open(categories_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        old_id = int(row['id'])
                        category_mapping[old_id] = category_id
                        
                        # Insert category
                        self.cursor.execute("""
                            INSERT INTO oc_category (category_id, parent_id, sort_order, status)
                            VALUES (%s, %s, %s, %s)
                        """, (
                            category_id,
                            int(row['parentId']) if row['parentId'] else 0,
                            category_id,
                            1  # status = enabled
                        ))
                        
                        # Insert category description (Ukrainian)
                        self.cursor.execute("""
                            INSERT INTO oc_category_description 
                            (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """, (
                            category_id,
                            2,  # Ukrainian
                            row['name'],
                            row.get('description (ukr)', ''),
                            row['name'],
                            row.get('description (ukr)', ''),
                            row.get('tag', '')
                        ))
                        
                        # Insert category description (Russian/English)
                        self.cursor.execute("""
                            INSERT INTO oc_category_description 
                            (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """, (
                            category_id,
                            1,  # English (using Russian as English for now)
                            row['name'],
                            row.get('description (ukr)', ''),
                            row['name'],
                            row.get('description (ukr)', ''),
                            row.get('tag', '')
                        ))
                        
                        # Insert category path
                        self.cursor.execute("""
                            INSERT INTO oc_category_path (category_id, path_id, level)
                            VALUES (%s, %s, %s)
                        """, (category_id, category_id, 0))
                        
                        category_id += 1
                        
                    except Exception as e:
                        logger.error(f"Error migrating category {row}: {e}")
                        continue
            
            self.connection.commit()
            logger.info(f"Successfully migrated {category_id - 1} categories")
            return category_mapping
            
        except Exception as e:
            logger.error(f"Failed to migrate categories: {e}")
            return False
    
    def migrate_products(self, category_mapping):
        """Migrate products from list.csv"""
        try:
            logger.info("Migrating products from list.csv...")
            
            products_csv = Path("data/list.csv")
            if not products_csv.exists():
                logger.error("list.csv not found")
                return False
            
            product_id = 1
            with open(products_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        # Get category ID from mapping
                        category_id = 1  # default
                        if row.get('category_id') and int(row['category_id']) in category_mapping:
                            category_id = category_mapping[int(row['category_id'])]
                        
                        # Insert product
                        self.cursor.execute("""
                            INSERT INTO oc_product 
                            (product_id, model, sku, quantity, stock_status_id, manufacturer_id, shipping, price, points, tax_class_id, date_available, weight, weight_class_id, length, width, height, length_class_id, subtract, minimum, sort_order, status)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            product_id,
                            row.get('product_id', f'PROD-{product_id}'),
                            row.get('product_id', f'SKU-{product_id}'),
                            10,  # quantity
                            5,   # stock_status_id (in stock)
                            0,   # manufacturer_id
                            1,   # shipping
                            0.0, # price (will be updated from inventory)
                            0,   # points
                            0,   # tax_class_id
                            datetime.now().date(),
                            0.0, # weight
                            1,   # weight_class_id
                            0.0, 0.0, 0.0,  # length, width, height
                            1,   # length_class_id
                            1,   # subtract
                            1,   # minimum
                            product_id,  # sort_order
                            1    # status
                        ))
                        
                        # Insert product description (Ukrainian)
                        self.cursor.execute("""
                            INSERT INTO oc_product_description 
                            (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            product_id,
                            2,  # Ukrainian
                            row.get('Название (укр)', ''),
                            row.get('Описание (укр)', ''),
                            row.get('tags', ''),
                            row.get('Название (укр)', ''),
                            row.get('Описание (укр)', ''),
                            row.get('tags', '')
                        ))
                        
                        # Insert product description (Russian/English)
                        self.cursor.execute("""
                            INSERT INTO oc_product_description 
                            (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            product_id,
                            1,  # English (using Russian as English for now)
                            row.get('Название (рус)', ''),
                            row.get('Описание (рус)', ''),
                            row.get('tags', ''),
                            row.get('Название (рус)', ''),
                            row.get('Описание (рус)', ''),
                            row.get('tags', '')
                        ))
                        
                        # Insert product to category relationship
                        self.cursor.execute("""
                            INSERT INTO oc_product_to_category (product_id, category_id)
                            VALUES (%s, %s)
                        """, (product_id, category_id))
                        
                        product_id += 1
                        
                    except Exception as e:
                        logger.error(f"Error migrating product {row}: {e}")
                        continue
            
            self.connection.commit()
            logger.info(f"Successfully migrated {product_id - 1} products")
            return True
            
        except Exception as e:
            logger.error(f"Failed to migrate products: {e}")
            return False
    
    def migrate_inventory(self):
        """Migrate inventory data from inventory.csv"""
        try:
            logger.info("Migrating inventory from inventory.csv...")
            
            inventory_csv = Path("data/inventory.csv")
            if not inventory_csv.exists():
                logger.warning("inventory.csv not found, skipping inventory migration")
                return True
            
            with open(inventory_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        product_id = row.get('product_id', '').replace('p', '')
                        if not product_id.isdigit():
                            continue
                        
                        product_id = int(product_id)
                        price = float(row.get('original_price', 0)) if row.get('original_price') else 0.0
                        quantity = int(row.get('stock_qty', 0)) if row.get('stock_qty') else 0
                        
                        # Update product with inventory data
                        self.cursor.execute("""
                            UPDATE oc_product 
                            SET price = %s, quantity = %s 
                            WHERE product_id = %s
                        """, (price, quantity, product_id))
                        
                    except Exception as e:
                        logger.error(f"Error migrating inventory {row}: {e}")
                        continue
            
            self.connection.commit()
            logger.info("Successfully migrated inventory data")
            return True
            
        except Exception as e:
            logger.error(f"Failed to migrate inventory: {e}")
            return False
    
    def migrate_attributes(self):
        """Migrate attributes from tags.csv"""
        try:
            logger.info("Migrating attributes from tags.csv...")
            
            # Clear existing attributes
            self.cursor.execute("DELETE FROM oc_product_attribute WHERE product_id > 0")
            self.cursor.execute("DELETE FROM oc_attribute_description WHERE attribute_id > 0")
            self.cursor.execute("DELETE FROM oc_attribute WHERE attribute_id > 0")
            
            tags_csv = Path("data/tags.csv")
            if not tags_csv.exists():
                logger.warning("tags.csv not found, skipping attributes migration")
                return True
            
            attribute_id = 1
            attribute_groups = {}
            group_id = 1
            
            with open(tags_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        group_name = row.get('group', '')
                        if group_name not in attribute_groups:
                            attribute_groups[group_name] = group_id
                            group_id += 1
                        
                        # Insert attribute
                        self.cursor.execute("""
                            INSERT INTO oc_attribute (attribute_id, attribute_group_id, sort_order)
                            VALUES (%s, %s, %s)
                        """, (attribute_id, attribute_groups[group_name], attribute_id))
                        
                        # Insert attribute description (Ukrainian)
                        self.cursor.execute("""
                            INSERT INTO oc_attribute_description (attribute_id, language_id, name)
                            VALUES (%s, %s, %s)
                        """, (attribute_id, 2, row.get('ua', '')))
                        
                        # Insert attribute description (Russian/English)
                        self.cursor.execute("""
                            INSERT INTO oc_attribute_description (attribute_id, language_id, name)
                            VALUES (%s, %s, %s)
                        """, (attribute_id, 1, row.get('ru', '')))
                        
                        attribute_id += 1
                        
                    except Exception as e:
                        logger.error(f"Error migrating attribute {row}: {e}")
                        continue
            
            self.connection.commit()
            logger.info(f"Successfully migrated {attribute_id - 1} attributes")
            return True
            
        except Exception as e:
            logger.error(f"Failed to migrate attributes: {e}")
            return False
    
    def fix_product_display(self):
        """Fix common issues that prevent products from showing"""
        try:
            logger.info("Fixing product display issues...")
            
            # Ensure products are enabled
            self.cursor.execute("UPDATE oc_product SET status = 1 WHERE product_id > 0")
            
            # Ensure categories are enabled
            self.cursor.execute("UPDATE oc_category SET status = 1 WHERE category_id > 0")
            
            # Add products to store (if table exists)
            self.cursor.execute("""
                INSERT IGNORE INTO oc_product_to_store (product_id, store_id) 
                SELECT product_id, 0 FROM oc_product WHERE product_id > 0
            """)
            
            # Add categories to store (if table exists)
            self.cursor.execute("""
                INSERT IGNORE INTO oc_category_to_store (category_id, store_id) 
                SELECT category_id, 0 FROM oc_category WHERE category_id > 0
            """)
            
            # Set proper stock status
            self.cursor.execute("UPDATE oc_product SET stock_status_id = 5 WHERE product_id > 0")
            
            # Set proper date available
            self.cursor.execute("UPDATE oc_product SET date_available = CURDATE() WHERE product_id > 0")
            
            self.connection.commit()
            logger.info("Product display fixes applied successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to fix product display: {e}")
            return False
    
    def close_connection(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Database connection closed")

def main():
    """Main migration function"""
    logger.info("Starting Real Data OpenCart migration...")
    
    # Initialize migrator
    migrator = RealDataOpenCartMigrator()
    
    try:
        # Connect to database
        if not migrator.connect_to_database():
            return False
        
        # Migrate data
        category_mapping = migrator.migrate_categories()
        if not category_mapping:
            return False
        
        if not migrator.migrate_products(category_mapping):
            return False
        
        if not migrator.migrate_inventory():
            return False
        
        if not migrator.migrate_attributes():
            return False
        
        if not migrator.fix_product_display():
            return False
        
        logger.info("Real data migration completed successfully!")
        return True
        
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        return False
    
    finally:
        migrator.close_connection()

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)