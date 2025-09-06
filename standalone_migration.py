#!/usr/bin/env python3
"""
Standalone OpenCart Migration Script
This script performs CSV to SQL migration without requiring Docker
Creates database structure and migrates all data from CSV files
"""

import csv
import json
import os
import sys
import sqlite3
import logging
from datetime import datetime
import hashlib
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('migration.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class StandaloneOpenCartMigrator:
    def __init__(self, db_path):
        self.db_path = db_path
        self.connection = None
        self.cursor = None
        
    def connect_to_database(self):
        """Connect to SQLite database"""
        try:
            self.connection = sqlite3.connect(self.db_path)
            self.cursor = self.connection.cursor()
            logger.info(f"Successfully connected to database: {self.db_path}")
            return True
        except Exception as e:
            logger.error(f"Error connecting to database: {e}")
            return False
    
    def disconnect_from_database(self):
        """Disconnect from database"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
            logger.info("Database connection closed")
    
    def create_tables_if_not_exist(self):
        """Create necessary tables if they don't exist"""
        tables_sql = {
            'oc_product': """
                CREATE TABLE IF NOT EXISTS `oc_product` (
                    `product_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `model` TEXT NOT NULL,
                    `sku` TEXT NOT NULL,
                    `upc` TEXT NOT NULL,
                    `ean` TEXT NOT NULL,
                    `jan` TEXT NOT NULL,
                    `isbn` TEXT NOT NULL,
                    `mpn` TEXT NOT NULL,
                    `location` TEXT NOT NULL,
                    `quantity` INTEGER NOT NULL DEFAULT 0,
                    `stock_status_id` INTEGER NOT NULL,
                    `image` TEXT DEFAULT NULL,
                    `manufacturer_id` INTEGER NOT NULL,
                    `shipping` INTEGER NOT NULL DEFAULT 1,
                    `price` REAL NOT NULL DEFAULT 0.0,
                    `points` INTEGER NOT NULL DEFAULT 0,
                    `tax_class_id` INTEGER NOT NULL,
                    `date_available` TEXT NOT NULL,
                    `weight` REAL NOT NULL DEFAULT 0.0,
                    `weight_class_id` INTEGER NOT NULL DEFAULT 0,
                    `length` REAL NOT NULL DEFAULT 0.0,
                    `width` REAL NOT NULL DEFAULT 0.0,
                    `height` REAL NOT NULL DEFAULT 0.0,
                    `length_class_id` INTEGER NOT NULL DEFAULT 0,
                    `subtract` INTEGER NOT NULL DEFAULT 1,
                    `minimum` INTEGER NOT NULL DEFAULT 1,
                    `sort_order` INTEGER NOT NULL DEFAULT 0,
                    `status` INTEGER NOT NULL DEFAULT 0,
                    `viewed` INTEGER NOT NULL DEFAULT 0,
                    `date_added` TEXT NOT NULL,
                    `date_modified` TEXT NOT NULL
                );
            """,
            'oc_product_description': """
                CREATE TABLE IF NOT EXISTS `oc_product_description` (
                    `product_id` INTEGER NOT NULL,
                    `language_id` INTEGER NOT NULL,
                    `name` TEXT NOT NULL,
                    `description` TEXT NOT NULL,
                    `tag` TEXT NOT NULL,
                    `meta_title` TEXT NOT NULL,
                    `meta_description` TEXT NOT NULL,
                    `meta_keyword` TEXT NOT NULL,
                    PRIMARY KEY (`product_id`,`language_id`)
                );
            """,
            'oc_product_to_category': """
                CREATE TABLE IF NOT EXISTS `oc_product_to_category` (
                    `product_id` INTEGER NOT NULL,
                    `category_id` INTEGER NOT NULL,
                    PRIMARY KEY (`product_id`,`category_id`)
                );
            """,
            'oc_product_image': """
                CREATE TABLE IF NOT EXISTS `oc_product_image` (
                    `product_image_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `product_id` INTEGER NOT NULL,
                    `image` TEXT DEFAULT NULL,
                    `sort_order` INTEGER NOT NULL DEFAULT 0
                );
            """,
            'oc_category': """
                CREATE TABLE IF NOT EXISTS `oc_category` (
                    `category_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `image` TEXT DEFAULT NULL,
                    `parent_id` INTEGER NOT NULL DEFAULT 0,
                    `top` INTEGER NOT NULL,
                    `column` INTEGER NOT NULL,
                    `sort_order` INTEGER NOT NULL DEFAULT 0,
                    `status` INTEGER NOT NULL,
                    `date_added` TEXT NOT NULL,
                    `date_modified` TEXT NOT NULL
                );
            """,
            'oc_category_description': """
                CREATE TABLE IF NOT EXISTS `oc_category_description` (
                    `category_id` INTEGER NOT NULL,
                    `language_id` INTEGER NOT NULL,
                    `name` TEXT NOT NULL,
                    `description` TEXT NOT NULL,
                    `meta_title` TEXT NOT NULL,
                    `meta_description` TEXT NOT NULL,
                    `meta_keyword` TEXT NOT NULL,
                    PRIMARY KEY (`category_id`,`language_id`)
                );
            """,
            'oc_language': """
                CREATE TABLE IF NOT EXISTS `oc_language` (
                    `language_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `name` TEXT NOT NULL,
                    `code` TEXT NOT NULL,
                    `locale` TEXT NOT NULL,
                    `image` TEXT NOT NULL,
                    `directory` TEXT NOT NULL,
                    `sort_order` INTEGER NOT NULL DEFAULT 0,
                    `status` INTEGER NOT NULL
                );
            """,
            'oc_attribute': """
                CREATE TABLE IF NOT EXISTS `oc_attribute` (
                    `attribute_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `attribute_group_id` INTEGER NOT NULL,
                    `sort_order` INTEGER NOT NULL
                );
            """,
            'oc_attribute_description': """
                CREATE TABLE IF NOT EXISTS `oc_attribute_description` (
                    `attribute_id` INTEGER NOT NULL,
                    `language_id` INTEGER NOT NULL,
                    `name` TEXT NOT NULL,
                    PRIMARY KEY (`attribute_id`,`language_id`)
                );
            """,
            'oc_attribute_group': """
                CREATE TABLE IF NOT EXISTS `oc_attribute_group` (
                    `attribute_group_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `sort_order` INTEGER NOT NULL
                );
            """,
            'oc_attribute_group_description': """
                CREATE TABLE IF NOT EXISTS `oc_attribute_group_description` (
                    `attribute_group_id` INTEGER NOT NULL,
                    `language_id` INTEGER NOT NULL,
                    `name` TEXT NOT NULL,
                    PRIMARY KEY (`attribute_group_id`,`language_id`)
                );
            """,
            'oc_product_attribute': """
                CREATE TABLE IF NOT EXISTS `oc_product_attribute` (
                    `product_id` INTEGER NOT NULL,
                    `attribute_id` INTEGER NOT NULL,
                    `language_id` INTEGER NOT NULL,
                    `text` TEXT NOT NULL,
                    PRIMARY KEY (`product_id`,`attribute_id`,`language_id`)
                );
            """,
            'oc_product_option': """
                CREATE TABLE IF NOT EXISTS `oc_product_option` (
                    `product_option_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `product_id` INTEGER NOT NULL,
                    `option_id` INTEGER NOT NULL,
                    `value` TEXT NOT NULL,
                    `required` INTEGER NOT NULL
                );
            """,
            'oc_product_option_value': """
                CREATE TABLE IF NOT EXISTS `oc_product_option_value` (
                    `product_option_value_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `product_option_id` INTEGER NOT NULL,
                    `product_id` INTEGER NOT NULL,
                    `option_id` INTEGER NOT NULL,
                    `option_value_id` INTEGER NOT NULL,
                    `quantity` INTEGER NOT NULL,
                    `subtract` INTEGER NOT NULL,
                    `price` REAL NOT NULL,
                    `price_prefix` TEXT NOT NULL,
                    `points` INTEGER NOT NULL,
                    `points_prefix` TEXT NOT NULL,
                    `weight` REAL NOT NULL,
                    `weight_prefix` TEXT NOT NULL
                );
            """,
            'oc_option': """
                CREATE TABLE IF NOT EXISTS `oc_option` (
                    `option_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `type` TEXT NOT NULL,
                    `sort_order` INTEGER NOT NULL
                );
            """,
            'oc_option_description': """
                CREATE TABLE IF NOT EXISTS `oc_option_description` (
                    `option_id` INTEGER NOT NULL,
                    `language_id` INTEGER NOT NULL,
                    `name` TEXT NOT NULL,
                    PRIMARY KEY (`option_id`,`language_id`)
                );
            """,
            'oc_option_value': """
                CREATE TABLE IF NOT EXISTS `oc_option_value` (
                    `option_value_id` INTEGER PRIMARY KEY AUTOINCREMENT,
                    `option_id` INTEGER NOT NULL,
                    `image` TEXT NOT NULL,
                    `sort_order` INTEGER NOT NULL
                );
            """,
            'oc_option_value_description': """
                CREATE TABLE IF NOT EXISTS `oc_option_value_description` (
                    `option_value_id` INTEGER NOT NULL,
                    `language_id` INTEGER NOT NULL,
                    `option_id` INTEGER NOT NULL,
                    `name` TEXT NOT NULL,
                    PRIMARY KEY (`option_value_id`,`language_id`)
                );
            """
        }
        
        for table_name, sql in tables_sql.items():
            try:
                self.cursor.execute(sql)
                logger.info(f"Table {table_name} created/verified successfully")
            except Exception as e:
                logger.error(f"Error creating table {table_name}: {e}")
    
    def setup_languages(self):
        """Setup default languages (Ukrainian and Russian)"""
        languages = [
            (1, 'Ukrainian', 'uk', 'uk_UA.UTF-8', 'uk.png', 'ukrainian', 1, 1),
            (2, 'Russian', 'ru', 'ru_RU.UTF-8', 'ru.png', 'russian', 2, 1)
        ]
        
        for lang in languages:
            try:
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_language 
                    (language_id, name, code, locale, image, directory, sort_order, status) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, lang)
            except Exception as e:
                logger.error(f"Error inserting language {lang[1]}: {e}")
        
        self.connection.commit()
        logger.info("Languages setup completed")
    
    def load_categories(self, categories_file):
        """Load categories from CSV file"""
        categories = {}
        try:
            with open(categories_file, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    category_id = int(row['id'])
                    categories[category_id] = {
                        'name': row['name'],
                        'parent_id': int(row['parentId']) if row['parentId'] else 0,
                        'tag': row['tag'],
                        'description_ukr': row['description (ukr)'],
                        'primary_image': row['primary_image']
                    }
            logger.info(f"Loaded {len(categories)} categories")
            return categories
        except Exception as e:
            logger.error(f"Error loading categories: {e}")
            return {}
    
    def insert_categories(self, categories):
        """Insert categories into database"""
        for category_id, category_data in categories.items():
            try:
                # Insert main category record
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_category 
                    (category_id, image, parent_id, top, column, sort_order, status, date_added, date_modified)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    category_id,
                    category_data['primary_image'],
                    category_data['parent_id'],
                    1 if category_data['parent_id'] == 0 else 0,
                    1,
                    category_id,
                    1,
                    datetime.now().isoformat(),
                    datetime.now().isoformat()
                ))
                
                # Insert category descriptions for both languages
                for lang_id in [1, 2]:  # Ukrainian and Russian
                    self.cursor.execute("""
                        INSERT OR IGNORE INTO oc_category_description 
                        (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, (
                        category_id,
                        lang_id,
                        category_data['name'],
                        category_data['description_ukr'],
                        category_data['name'],
                        category_data['description_ukr'][:160] if len(category_data['description_ukr']) > 160 else category_data['description_ukr'],
                        category_data['tag']
                    ))
                
                logger.info(f"Inserted category: {category_data['name']}")
                
            except Exception as e:
                logger.error(f"Error inserting category {category_id}: {e}")
        
        self.connection.commit()
        logger.info("Categories insertion completed")
    
    def load_products(self, products_file):
        """Load products from CSV file"""
        products = []
        try:
            with open(products_file, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    products.append(row)
            logger.info(f"Loaded {len(products)} products")
            return products
        except Exception as e:
            logger.error(f"Error loading products: {e}")
            return []
    
    def insert_products(self, products):
        """Insert products into database"""
        for product in products:
            try:
                product_id = int(product['id'])
                
                # Insert main product record
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_product 
                    (product_id, model, sku, upc, ean, jan, isbn, mpn, location, quantity, 
                     stock_status_id, image, manufacturer_id, shipping, price, points, 
                     tax_class_id, date_available, weight, weight_class_id, length, width, 
                     height, length_class_id, subtract, minimum, sort_order, status, 
                     viewed, date_added, date_modified)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    product_id,
                    product['product_id'],
                    product['product_id'],
                    '', '', '', '', '', '',
                    int(product.get('availability', 1)),
                    5,  # In Stock
                    product.get('primary_image', ''),
                    0,  # No manufacturer
                    1,  # Requires shipping
                    0.00,  # Default price
                    0,  # No points
                    0,  # No tax class
                    datetime.now().date().isoformat(),
                    0.00, 0, 0.00, 0.00, 0.00, 0, 1, 1, 0, 1, 0, 
                    datetime.now().isoformat(), 
                    datetime.now().isoformat()
                ))
                
                # Insert product descriptions for both languages
                descriptions = [
                    (1, product['Название (укр)'], product['Описание (укр)']),  # Ukrainian
                    (2, product['Название (рус)'], product['Описание (рус)'])   # Russian
                ]
                
                for lang_id, name, description in descriptions:
                    self.cursor.execute("""
                        INSERT OR IGNORE INTO oc_product_description 
                        (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        product_id,
                        lang_id,
                        name,
                        description,
                        product.get('tags', ''),
                        name,
                        description[:160] if len(description) > 160 else description,
                        product.get('tags', '')
                    ))
                
                # Insert product to category mapping
                category_id = int(product.get('category_id', 100))
                subcategory_id = product.get('subcategory_id')
                
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_product_to_category 
                    (product_id, category_id)
                    VALUES (?, ?)
                """, (product_id, category_id))
                
                if subcategory_id and subcategory_id.strip():
                    self.cursor.execute("""
                        INSERT OR IGNORE INTO oc_product_to_category 
                        (product_id, category_id)
                        VALUES (?, ?)
                    """, (product_id, int(subcategory_id)))
                
                # Insert product image
                if product.get('primary_image'):
                    self.cursor.execute("""
                        INSERT OR IGNORE INTO oc_product_image 
                        (product_id, image, sort_order)
                        VALUES (?, ?, ?)
                    """, (product_id, product['primary_image'], 0))
                
                logger.info(f"Inserted product: {product['Название (укр)']}")
                
            except Exception as e:
                logger.error(f"Error inserting product {product.get('id', 'unknown')}: {e}")
        
        self.connection.commit()
        logger.info("Products insertion completed")
    
    def load_inventory(self, inventory_file):
        """Load inventory data from CSV file"""
        inventory = []
        try:
            with open(inventory_file, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    inventory.append(row)
            logger.info(f"Loaded {len(inventory)} inventory records")
            return inventory
        except Exception as e:
            logger.error(f"Error loading inventory: {e}")
            return []
    
    def load_tags(self, tags_file):
        """Load tags data from CSV file"""
        tags = {}
        try:
            with open(tags_file, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    category_id = int(row['category'])
                    if category_id not in tags:
                        tags[category_id] = []
                    tags[category_id].append({
                        'group': row['group'],
                        'key': row['key'],
                        'ua': row['ua'],
                        'ru': row['ru']
                    })
            logger.info(f"Loaded tags for {len(tags)} categories")
            return tags
        except Exception as e:
            logger.error(f"Error loading tags: {e}")
            return {}
    
    def insert_tags_as_attributes(self, tags):
        """Insert tags as attributes for filtering"""
        attribute_group_id = 1
        
        # Create attribute group for tags
        try:
            self.cursor.execute("""
                INSERT OR IGNORE INTO oc_attribute_group 
                (attribute_group_id, sort_order)
                VALUES (?, ?)
            """, (attribute_group_id, 1))
            
            # Insert attribute group descriptions
            for lang_id in [1, 2]:
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_attribute_group_description 
                    (attribute_group_id, language_id, name)
                    VALUES (?, ?, ?)
                """, (attribute_group_id, lang_id, "Фільтри" if lang_id == 1 else "Фильтры"))
            
            # Process tags for each category
            for category_id, tag_list in tags.items():
                for tag in tag_list:
                    attribute_id = abs(hash(tag['key'])) % 1000000  # Generate unique ID
                    
                    # Insert attribute
                    self.cursor.execute("""
                        INSERT OR IGNORE INTO oc_attribute 
                        (attribute_id, attribute_group_id, sort_order)
                        VALUES (?, ?, ?)
                    """, (attribute_id, attribute_group_id, 1))
                    
                    # Insert attribute descriptions
                    for lang_id in [1, 2]:
                        name = tag['ua'] if lang_id == 1 else tag['ru']
                        self.cursor.execute("""
                            INSERT OR IGNORE INTO oc_attribute_description 
                            (attribute_id, language_id, name)
                            VALUES (?, ?, ?)
                        """, (attribute_id, lang_id, name))
            
            self.connection.commit()
            logger.info("Tags inserted as attributes successfully")
            
        except Exception as e:
            logger.error(f"Error inserting tags as attributes: {e}")
    
    def insert_inventory_as_options(self, inventory):
        """Insert inventory data as product options (variants)"""
        option_id = 1
        
        # Create option for quantity/packaging
        try:
            self.cursor.execute("""
                INSERT OR IGNORE INTO oc_option 
                (option_id, type, sort_order)
                VALUES (?, ?, ?)
            """, (option_id, 'select', 1))
            
            # Insert option descriptions
            for lang_id in [1, 2]:
                name = "Розмір упаковки" if lang_id == 1 else "Размер упаковки"
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_option_description 
                    (option_id, language_id, name)
                    VALUES (?, ?, ?)
                """, (option_id, lang_id, name))
            
            # Process inventory records
            for inv_record in inventory:
                if not inv_record.get('pid') or not inv_record.get('product_id'):
                    continue
                
                product_id = int(inv_record['pid'])
                variant_id = inv_record.get('variant_id', '')
                title_ua = inv_record.get('title_ua', '')
                title_ru = inv_record.get('title_ru', '')
                original_price = float(inv_record.get('original_price', 0))
                stock_qty = int(inv_record.get('stock_qty', 0))
                value = float(inv_record.get('value', 1))
                
                # Create option value
                option_value_id = abs(hash(variant_id)) % 1000000
                
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_option_value 
                    (option_value_id, option_id, image, sort_order)
                    VALUES (?, ?, ?, ?)
                """, (option_value_id, option_id, '', 1))
                
                # Insert option value descriptions
                for lang_id in [1, 2]:
                    name = title_ua if lang_id == 1 else title_ru
                    self.cursor.execute("""
                        INSERT OR IGNORE INTO oc_option_value_description 
                        (option_value_id, language_id, option_id, name)
                        VALUES (?, ?, ?, ?)
                    """, (option_value_id, lang_id, option_id, name))
                
                # Create product option
                product_option_id = abs(hash(f"{product_id}_{option_id}")) % 1000000
                
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_product_option 
                    (product_option_id, product_id, option_id, value, required)
                    VALUES (?, ?, ?, ?, ?)
                """, (product_option_id, product_id, option_id, '', 1))
                
                # Create product option value with pricing
                product_option_value_id = abs(hash(f"{product_id}_{option_value_id}")) % 1000000
                
                self.cursor.execute("""
                    INSERT OR IGNORE INTO oc_product_option_value 
                    (product_option_value_id, product_option_id, product_id, option_id, option_value_id,
                     quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    product_option_value_id, product_option_id, product_id, option_id, option_value_id,
                    stock_qty, 1, original_price, '+', 0, '+', value, '+'
                ))
            
            self.connection.commit()
            logger.info("Inventory inserted as product options successfully")
            
        except Exception as e:
            logger.error(f"Error inserting inventory as options: {e}")
    
    def migrate(self, categories_file, products_file, inventory_file=None, tags_file=None):
        """Main migration function"""
        logger.info("Starting OpenCart migration...")
        
        if not self.connect_to_database():
            return False
        
        try:
            # Create tables
            self.create_tables_if_not_exist()
            
            # Setup languages
            self.setup_languages()
            
            # Load and insert categories
            categories = self.load_categories(categories_file)
            if categories:
                self.insert_categories(categories)
            
            # Load and insert products
            products = self.load_products(products_file)
            if products:
                self.insert_products(products)
            
            # Load and insert inventory as product options
            if inventory_file and os.path.exists(inventory_file):
                inventory = self.load_inventory(inventory_file)
                if inventory:
                    self.insert_inventory_as_options(inventory)
            
            # Load and insert tags as attributes
            if tags_file and os.path.exists(tags_file):
                tags = self.load_tags(tags_file)
                if tags:
                    self.insert_tags_as_attributes(tags)
            
            logger.info("Migration completed successfully!")
            return True
            
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            return False
        finally:
            self.disconnect_from_database()

def main():
    # Database path
    db_path = '/workspace/opencart-docker/opencart.db'
    
    # File paths
    categories_file = '/workspace/data/categories_list.csv'
    products_file = '/workspace/data/list.csv'
    inventory_file = '/workspace/data/inventory.csv'
    tags_file = '/workspace/data/tags.csv'
    
    # Create migrator instance
    migrator = StandaloneOpenCartMigrator(db_path)
    
    # Run migration
    success = migrator.migrate(categories_file, products_file, inventory_file, tags_file)
    
    if success:
        print("✅ Migration completed successfully!")
        print(f"Database created at: {db_path}")
        print("Check migration.log for detailed information.")
    else:
        print("❌ Migration failed!")
        print("Check migration.log for error details.")
        sys.exit(1)

if __name__ == "__main__":
    main()