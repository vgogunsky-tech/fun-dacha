#!/usr/bin/env python3
"""
Complete Sync Migration Script
This script performs complete CSV to OpenCart database synchronization:
- Adds new items from CSV
- Removes items not in CSV
- Updates existing items
- Handles timestamps (date_added, date_modified)
- Copies images to container
- Localizes tags properly
"""

import csv
import json
import os
import sys
import logging
import subprocess
from datetime import datetime
import hashlib
from pathlib import Path
import pymysql

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('complete_sync_migration.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class CompleteSyncMigrator:
    def __init__(self, host='localhost', port=3306, user='root', password='example', database='opencart'):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.database = database
        self.connection = None
        self.cursor = None
        self.tags_mapping = {}
        self.csv_categories = {}
        self.csv_products = {}
        self.csv_inventory = {}
        self.csv_attributes = []
        
    def connect_to_database(self):
        """Connect to MySQL database"""
        try:
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
    
    def load_csv_data(self):
        """Load all CSV data into memory"""
        try:
            logger.info("Loading CSV data...")
            
            # Load tags mapping
            self.load_tags_mapping()
            
            # Load categories
            self.load_categories()
            
            # Load products
            self.load_products()
            
            # Load inventory
            self.load_inventory()
            
            # Load attributes
            self.load_attributes()
            
            logger.info(f"Loaded CSV data: {len(self.csv_categories)} categories, {len(self.csv_products)} products, {len(self.csv_attributes)} attributes")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load CSV data: {e}")
            return False
    
    def load_tags_mapping(self):
        """Load tags mapping for localization"""
        try:
            tags_csv = Path("data/tags.csv")
            if not tags_csv.exists():
                logger.warning("tags.csv not found, skipping tags mapping")
                return
            
            with open(tags_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    key = row.get('key', '')
                    ua = row.get('ua', '')
                    ru = row.get('ru', '')
                    if key and ua and ru:
                        self.tags_mapping[key] = {'ua': ua, 'ru': ru}
            
            logger.info(f"Loaded {len(self.tags_mapping)} tags for localization")
            
        except Exception as e:
            logger.error(f"Failed to load tags mapping: {e}")
    
    def load_categories(self):
        """Load categories from CSV"""
        try:
            categories_csv = Path("data/categories_list.csv")
            if not categories_csv.exists():
                logger.error("categories_list.csv not found")
                return
            
            with open(categories_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    old_id = int(row['id'])
                    self.csv_categories[old_id] = {
                        'name': row['name'],
                        'parent_id': int(row['parentId']) if row['parentId'] else 0,
                        'description': row.get('description (ukr)', ''),
                        'tag': row.get('tag', ''),
                        'image': row.get('primary_image', '')
                    }
            
            logger.info(f"Loaded {len(self.csv_categories)} categories from CSV")
            
        except Exception as e:
            logger.error(f"Failed to load categories: {e}")
    
    def load_products(self):
        """Load products from CSV"""
        try:
            products_csv = Path("data/list.csv")
            if not products_csv.exists():
                logger.error("list.csv not found")
                return
            
            with open(products_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    product_id = row.get('product_id', '')
                    if product_id:
                        self.csv_products[product_id] = row
            
            logger.info(f"Loaded {len(self.csv_products)} products from CSV")
            
        except Exception as e:
            logger.error(f"Failed to load products: {e}")
    
    def load_inventory(self):
        """Load inventory data from CSV"""
        try:
            inventory_csv = Path("data/inventory.csv")
            if not inventory_csv.exists():
                logger.warning("inventory.csv not found, skipping inventory")
                return
            
            with open(inventory_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    product_id = row.get('product_id', '').replace('p', '')
                    if product_id.isdigit():
                        self.csv_inventory[int(product_id)] = {
                            'price': float(row.get('original_price', 0)) if row.get('original_price') else 0.0,
                            'quantity': int(row.get('stock_qty', 0)) if row.get('stock_qty') else 0
                        }
            
            logger.info(f"Loaded {len(self.csv_inventory)} inventory items from CSV")
            
        except Exception as e:
            logger.error(f"Failed to load inventory: {e}")
    
    def load_attributes(self):
        """Load attributes from CSV"""
        try:
            tags_csv = Path("data/tags.csv")
            if not tags_csv.exists():
                logger.warning("tags.csv not found, skipping attributes")
                return
            
            with open(tags_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    self.csv_attributes.append(row)
            
            logger.info(f"Loaded {len(self.csv_attributes)} attributes from CSV")
            
        except Exception as e:
            logger.error(f"Failed to load attributes: {e}")
    
    def localize_tags(self, tags_string, language_id):
        """Localize tags string based on language"""
        if not tags_string or not self.tags_mapping:
            return tags_string
        
        try:
            tags = [tag.strip() for tag in tags_string.split(',')]
            localized_tags = []
            
            for tag in tags:
                if tag in self.tags_mapping:
                    if language_id == 2:  # Ukrainian
                        localized_tags.append(self.tags_mapping[tag]['ua'])
                    else:  # Russian
                        localized_tags.append(self.tags_mapping[tag]['ru'])
                else:
                    localized_tags.append(tag)
            
            return ', '.join(localized_tags)
        except Exception as e:
            logger.error(f"Error localizing tags '{tags_string}': {e}")
            return tags_string
    
    def sync_categories(self):
        """Sync categories: add new, update existing, remove old"""
        try:
            logger.info("Syncing categories...")
            
            # Get existing categories from database
            self.cursor.execute("SELECT category_id FROM oc_category")
            existing_categories = {row[0] for row in self.cursor.fetchall()}
            
            # Create category mapping (old CSV ID -> new DB ID)
            category_mapping = {}
            new_category_id = max(existing_categories) + 1 if existing_categories else 1
            
            # Process CSV categories
            for old_id, cat_data in self.csv_categories.items():
                # Check if category already exists (by name)
                self.cursor.execute("SELECT category_id FROM oc_category_description WHERE name = %s AND language_id = 2", (cat_data['name'],))
                result = self.cursor.fetchone()
                
                if result:
                    category_id = result[0]
                    logger.info(f"Updating existing category: {cat_data['name']} (ID: {category_id})")
                    
                    # Update category
                    image_path = f"catalog/category/{cat_data['image']}" if cat_data['image'] else ""
                    self.cursor.execute("""
                        UPDATE oc_category 
                        SET parent_id = %s, sort_order = %s, status = 1, image = %s
                        WHERE category_id = %s
                    """, (cat_data['parent_id'], category_id, image_path, category_id))
                    
                    # Update descriptions
                    desc_ua = cat_data['description']
                    meta_desc_ua = desc_ua[:250] if len(desc_ua) > 250 else desc_ua
                    
                    self.cursor.execute("""
                        UPDATE oc_category_description 
                        SET description = %s, meta_description = %s, meta_keyword = %s
                        WHERE category_id = %s AND language_id = 2
                    """, (desc_ua, meta_desc_ua, cat_data['tag'], category_id))
                    
                    self.cursor.execute("""
                        UPDATE oc_category_description 
                        SET description = %s, meta_description = %s, meta_keyword = %s
                        WHERE category_id = %s AND language_id = 1
                    """, (desc_ua, meta_desc_ua, cat_data['tag'], category_id))
                    
                else:
                    category_id = new_category_id
                    new_category_id += 1
                    logger.info(f"Adding new category: {cat_data['name']} (ID: {category_id})")
                    
                    # Insert new category
                    image_path = f"catalog/category/{cat_data['image']}" if cat_data['image'] else ""
                    self.cursor.execute("""
                        INSERT INTO oc_category (category_id, parent_id, sort_order, status, image)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (category_id, cat_data['parent_id'], category_id, 1, image_path))
                    
                    # Insert descriptions
                    desc_ua = cat_data['description']
                    meta_desc_ua = desc_ua[:250] if len(desc_ua) > 250 else desc_ua
                    
                    self.cursor.execute("""
                        INSERT INTO oc_category_description 
                        (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (category_id, 2, cat_data['name'], desc_ua, cat_data['name'], meta_desc_ua, cat_data['tag']))
                    
                    self.cursor.execute("""
                        INSERT INTO oc_category_description 
                        (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (category_id, 1, cat_data['name'], desc_ua, cat_data['name'], meta_desc_ua, cat_data['tag']))
                    
                    # Insert category path
                    self.cursor.execute("""
                        INSERT INTO oc_category_path (category_id, path_id, level)
                        VALUES (%s, %s, %s)
                    """, (category_id, category_id, 0))
                
                category_mapping[old_id] = category_id
            
            # Remove categories not in CSV
            csv_category_ids = set(category_mapping.values())
            categories_to_remove = existing_categories - csv_category_ids
            
            if categories_to_remove:
                logger.info(f"Removing {len(categories_to_remove)} categories not in CSV")
                for cat_id in categories_to_remove:
                    self.cursor.execute("DELETE FROM oc_category_path WHERE category_id = %s", (cat_id,))
                    self.cursor.execute("DELETE FROM oc_category_description WHERE category_id = %s", (cat_id,))
                    self.cursor.execute("DELETE FROM oc_category WHERE category_id = %s", (cat_id,))
            
            self.connection.commit()
            logger.info(f"Category sync completed: {len(category_mapping)} categories")
            return category_mapping
            
        except Exception as e:
            logger.error(f"Failed to sync categories: {e}")
            return False
    
    def sync_products(self, category_mapping):
        """Sync products: add new, update existing, remove old"""
        try:
            logger.info("Syncing products...")
            
            # Get existing products from database
            self.cursor.execute("SELECT product_id FROM oc_product")
            existing_products = {row[0] for row in self.cursor.fetchall()}
            
            new_product_id = max(existing_products) + 1 if existing_products else 1
            csv_product_ids = set()
            
            # Process CSV products
            for product_id_str, product_data in self.csv_products.items():
                # Get category ID from mapping
                category_id = 1  # default
                if product_data.get('category_id') and int(product_data['category_id']) in category_mapping:
                    category_id = category_mapping[int(product_data['category_id'])]
                
                # Get inventory data
                price = 0.0
                quantity = 10
                if product_id_str.replace('p', '').isdigit():
                    prod_id = int(product_id_str.replace('p', ''))
                    if prod_id in self.csv_inventory:
                        price = self.csv_inventory[prod_id]['price']
                        quantity = self.csv_inventory[prod_id]['quantity']
                
                # Check if product already exists (by model/SKU)
                model = product_data.get('product_id', product_id_str)
                self.cursor.execute("SELECT product_id FROM oc_product WHERE model = %s", (model,))
                result = self.cursor.fetchone()
                
                current_time = datetime.now()
                
                if result:
                    product_id = result[0]
                    csv_product_ids.add(product_id)
                    logger.info(f"Updating existing product: {model} (ID: {product_id})")
                    
                    # Update product
                    image_path = f"catalog/product/{product_data.get('primary_image', '')}" if product_data.get('primary_image') else ""
                    self.cursor.execute("""
                        UPDATE oc_product 
                        SET quantity = %s, price = %s, image = %s, date_modified = %s
                        WHERE product_id = %s
                    """, (quantity, price, image_path, current_time, product_id))
                    
                    # Update descriptions
                    desc_ua = product_data.get('Описание (укр)', '')
                    desc_ru = product_data.get('Описание (рус)', '')
                    meta_desc_ua = desc_ua[:250] if len(desc_ua) > 250 else desc_ua
                    meta_desc_ru = desc_ru[:250] if len(desc_ru) > 250 else desc_ru
                    
                    tags_string = product_data.get('tags', '')
                    tags_ua = self.localize_tags(tags_string, 2)
                    tags_ru = self.localize_tags(tags_string, 1)
                    
                    self.cursor.execute("""
                        UPDATE oc_product_description 
                        SET name = %s, description = %s, tag = %s, meta_title = %s, meta_description = %s, meta_keyword = %s
                        WHERE product_id = %s AND language_id = 2
                    """, (product_data.get('Название (укр)', ''), desc_ua, tags_ua, product_data.get('Название (укр)', ''), meta_desc_ua, tags_ua, product_id))
                    
                    self.cursor.execute("""
                        UPDATE oc_product_description 
                        SET name = %s, description = %s, tag = %s, meta_title = %s, meta_description = %s, meta_keyword = %s
                        WHERE product_id = %s AND language_id = 1
                    """, (product_data.get('Название (рус)', ''), desc_ru, tags_ru, product_data.get('Название (рус)', ''), meta_desc_ru, tags_ru, product_id))
                    
                    # Update category relationship
                    self.cursor.execute("DELETE FROM oc_product_to_category WHERE product_id = %s", (product_id,))
                    self.cursor.execute("INSERT INTO oc_product_to_category (product_id, category_id) VALUES (%s, %s)", (product_id, category_id))
                    
                else:
                    product_id = new_product_id
                    new_product_id += 1
                    csv_product_ids.add(product_id)
                    logger.info(f"Adding new product: {model} (ID: {product_id})")
                    
                    # Insert new product
                    image_path = f"catalog/product/{product_data.get('primary_image', '')}" if product_data.get('primary_image') else ""
                    self.cursor.execute("""
                        INSERT INTO oc_product 
                        (product_id, model, sku, quantity, stock_status_id, manufacturer_id, shipping, price, points, tax_class_id, date_available, weight, weight_class_id, length, width, height, length_class_id, subtract, minimum, sort_order, status, image, date_added, date_modified)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, (product_id, model, model, quantity, 5, 0, 1, price, 0, 0, current_time.date(), 0.0, 1, 0.0, 0.0, 0.0, 1, 1, 1, product_id, 1, image_path, current_time, current_time))
                    
                    # Insert descriptions
                    desc_ua = product_data.get('Описание (укр)', '')
                    desc_ru = product_data.get('Описание (рус)', '')
                    meta_desc_ua = desc_ua[:250] if len(desc_ua) > 250 else desc_ua
                    meta_desc_ru = desc_ru[:250] if len(desc_ru) > 250 else desc_ru
                    
                    tags_string = product_data.get('tags', '')
                    tags_ua = self.localize_tags(tags_string, 2)
                    tags_ru = self.localize_tags(tags_string, 1)
                    
                    self.cursor.execute("""
                        INSERT INTO oc_product_description 
                        (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """, (product_id, 2, product_data.get('Название (укр)', ''), desc_ua, tags_ua, product_data.get('Название (укр)', ''), meta_desc_ua, tags_ua))
                    
                    self.cursor.execute("""
                        INSERT INTO oc_product_description 
                        (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """, (product_id, 1, product_data.get('Название (рус)', ''), desc_ru, tags_ru, product_data.get('Название (рус)', ''), meta_desc_ru, tags_ru))
                    
                    # Insert category relationship
                    self.cursor.execute("INSERT INTO oc_product_to_category (product_id, category_id) VALUES (%s, %s)", (product_id, category_id))
            
            # Remove products not in CSV
            products_to_remove = existing_products - csv_product_ids
            
            if products_to_remove:
                logger.info(f"Removing {len(products_to_remove)} products not in CSV")
                for prod_id in products_to_remove:
                    self.cursor.execute("DELETE FROM oc_product_to_category WHERE product_id = %s", (prod_id,))
                    self.cursor.execute("DELETE FROM oc_product_description WHERE product_id = %s", (prod_id,))
                    self.cursor.execute("DELETE FROM oc_product WHERE product_id = %s", (prod_id,))
            
            self.connection.commit()
            logger.info(f"Product sync completed: {len(csv_product_ids)} products")
            return True
            
        except Exception as e:
            logger.error(f"Failed to sync products: {e}")
            return False
    
    def sync_attributes(self):
        """Sync attributes: clear and reload from CSV"""
        try:
            logger.info("Syncing attributes...")
            
            # Clear existing attributes
            self.cursor.execute("DELETE FROM oc_product_attribute WHERE product_id > 0")
            self.cursor.execute("DELETE FROM oc_attribute_description WHERE attribute_id > 0")
            self.cursor.execute("DELETE FROM oc_attribute WHERE attribute_id > 0")
            
            if not self.csv_attributes:
                logger.info("No attributes to sync")
                return True
            
            attribute_id = 1
            attribute_groups = {}
            group_id = 1
            
            for attr in self.csv_attributes:
                group_name = attr.get('group', '')
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
                """, (attribute_id, 2, attr.get('ua', '')))
                
                # Insert attribute description (Russian)
                self.cursor.execute("""
                    INSERT INTO oc_attribute_description (attribute_id, language_id, name)
                    VALUES (%s, %s, %s)
                """, (attribute_id, 1, attr.get('ru', '')))
                
                attribute_id += 1
            
            self.connection.commit()
            logger.info(f"Attribute sync completed: {attribute_id - 1} attributes")
            return True
            
        except Exception as e:
            logger.error(f"Failed to sync attributes: {e}")
            return False
    
    def fix_display_issues(self):
        """Fix common display issues"""
        try:
            logger.info("Fixing display issues...")
            
            # Ensure products are enabled
            self.cursor.execute("UPDATE oc_product SET status = 1 WHERE product_id > 0")
            
            # Ensure categories are enabled
            self.cursor.execute("UPDATE oc_category SET status = 1 WHERE category_id > 0")
            
            # Add products to store
            self.cursor.execute("""
                INSERT IGNORE INTO oc_product_to_store (product_id, store_id) 
                SELECT product_id, 0 FROM oc_product WHERE product_id > 0
            """)
            
            # Add categories to store
            self.cursor.execute("""
                INSERT IGNORE INTO oc_category_to_store (category_id, store_id) 
                SELECT category_id, 0 FROM oc_category WHERE category_id > 0
            """)
            
            # Set proper stock status
            self.cursor.execute("UPDATE oc_product SET stock_status_id = 5 WHERE product_id > 0")
            
            # Set proper date available
            self.cursor.execute("UPDATE oc_product SET date_available = CURDATE() WHERE product_id > 0")
            
            self.connection.commit()
            logger.info("Display fixes applied successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to fix display issues: {e}")
            return False
    
    def copy_images_to_container(self):
        """Copy images to Docker container"""
        try:
            logger.info("Copying images to Docker container...")
            
            # Check if we're in the right directory
            if not Path("opencart-docker").exists():
                logger.error("opencart-docker directory not found")
                return False
            
            # Run the image copy script
            result = subprocess.run([
                "bash", "copy_images_to_container.sh"
            ], capture_output=True, text=True, cwd=".")
            
            if result.returncode == 0:
                logger.info("Images copied to container successfully")
                return True
            else:
                logger.error(f"Failed to copy images: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to copy images to container: {e}")
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
    logger.info("Starting Complete Sync Migration...")
    
    # Initialize migrator
    migrator = CompleteSyncMigrator()
    
    try:
        # Connect to database
        if not migrator.connect_to_database():
            return False
        
        # Load CSV data
        if not migrator.load_csv_data():
            return False
        
        # Sync data
        category_mapping = migrator.sync_categories()
        if not category_mapping:
            return False
        
        if not migrator.sync_products(category_mapping):
            return False
        
        if not migrator.sync_attributes():
            return False
        
        if not migrator.fix_display_issues():
            return False
        
        # Copy images to container
        if not migrator.copy_images_to_container():
            logger.warning("Failed to copy images to container, but migration completed")
        
        logger.info("Complete sync migration completed successfully!")
        logger.info("Features: Add/Update/Remove sync, Timestamps, Images, Localized tags")
        return True
        
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        return False
    
    finally:
        migrator.close_connection()

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)