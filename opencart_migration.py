#!/usr/bin/env python3
"""
OpenCart Product Migration Script
Migrates product data from CSV files to OpenCart database
"""

import csv
import json
import os
import sys
import mysql.connector
from mysql.connector import Error
import logging
from datetime import datetime
import hashlib

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

class OpenCartMigrator:
    def __init__(self, db_config):
        self.db_config = db_config
        self.connection = None
        self.cursor = None
        
    def connect_to_database(self):
        """Connect to OpenCart database"""
        try:
            self.connection = mysql.connector.connect(**self.db_config)
            self.cursor = self.connection.cursor(dictionary=True)
            logger.info("Successfully connected to OpenCart database")
            return True
        except Error as e:
            logger.error(f"Error connecting to database: {e}")
            return False
    
    def disconnect_from_database(self):
        """Disconnect from database"""
        if self.cursor:
            self.cursor.close()
        if self.connection and self.connection.is_connected():
            self.connection.close()
            logger.info("Database connection closed")
    
    def create_tables_if_not_exist(self):
        """Create necessary tables if they don't exist"""
        tables_sql = {
            'oc_product': """
                CREATE TABLE IF NOT EXISTS `oc_product` (
                    `product_id` int(11) NOT NULL AUTO_INCREMENT,
                    `model` varchar(64) NOT NULL,
                    `sku` varchar(64) NOT NULL,
                    `upc` varchar(12) NOT NULL,
                    `ean` varchar(14) NOT NULL,
                    `jan` varchar(13) NOT NULL,
                    `isbn` varchar(17) NOT NULL,
                    `mpn` varchar(64) NOT NULL,
                    `location` varchar(128) NOT NULL,
                    `quantity` int(4) NOT NULL DEFAULT '0',
                    `stock_status_id` int(11) NOT NULL,
                    `image` varchar(255) DEFAULT NULL,
                    `manufacturer_id` int(11) NOT NULL,
                    `shipping` tinyint(1) NOT NULL DEFAULT '1',
                    `price` decimal(15,4) NOT NULL DEFAULT '0.0000',
                    `points` int(8) NOT NULL DEFAULT '0',
                    `tax_class_id` int(11) NOT NULL,
                    `date_available` date NOT NULL,
                    `weight` decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    `weight_class_id` int(11) NOT NULL DEFAULT '0',
                    `length` decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    `width` decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    `height` decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    `length_class_id` int(11) NOT NULL DEFAULT '0',
                    `subtract` tinyint(1) NOT NULL DEFAULT '1',
                    `minimum` int(11) NOT NULL DEFAULT '1',
                    `sort_order` int(11) NOT NULL DEFAULT '0',
                    `status` tinyint(1) NOT NULL DEFAULT '0',
                    `viewed` int(5) NOT NULL DEFAULT '0',
                    `date_added` datetime NOT NULL,
                    `date_modified` datetime NOT NULL,
                    PRIMARY KEY (`product_id`)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
            """,
            'oc_product_description': """
                CREATE TABLE IF NOT EXISTS `oc_product_description` (
                    `product_id` int(11) NOT NULL,
                    `language_id` int(11) NOT NULL,
                    `name` varchar(255) NOT NULL,
                    `description` text NOT NULL,
                    `tag` text NOT NULL,
                    `meta_title` varchar(255) NOT NULL,
                    `meta_description` varchar(255) NOT NULL,
                    `meta_keyword` varchar(255) NOT NULL,
                    PRIMARY KEY (`product_id`,`language_id`)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
            """,
            'oc_product_to_category': """
                CREATE TABLE IF NOT EXISTS `oc_product_to_category` (
                    `product_id` int(11) NOT NULL,
                    `category_id` int(11) NOT NULL,
                    PRIMARY KEY (`product_id`,`category_id`)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
            """,
            'oc_product_image': """
                CREATE TABLE IF NOT EXISTS `oc_product_image` (
                    `product_image_id` int(11) NOT NULL AUTO_INCREMENT,
                    `product_id` int(11) NOT NULL,
                    `image` varchar(255) DEFAULT NULL,
                    `sort_order` int(3) NOT NULL DEFAULT '0',
                    PRIMARY KEY (`product_image_id`)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
            """,
            'oc_category': """
                CREATE TABLE IF NOT EXISTS `oc_category` (
                    `category_id` int(11) NOT NULL AUTO_INCREMENT,
                    `image` varchar(255) DEFAULT NULL,
                    `parent_id` int(11) NOT NULL DEFAULT '0',
                    `top` tinyint(1) NOT NULL,
                    `column` int(3) NOT NULL,
                    `sort_order` int(3) NOT NULL DEFAULT '0',
                    `status` tinyint(1) NOT NULL,
                    `date_added` datetime NOT NULL,
                    `date_modified` datetime NOT NULL,
                    PRIMARY KEY (`category_id`)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
            """,
            'oc_category_description': """
                CREATE TABLE IF NOT EXISTS `oc_category_description` (
                    `category_id` int(11) NOT NULL,
                    `language_id` int(11) NOT NULL,
                    `name` varchar(255) NOT NULL,
                    `description` text NOT NULL,
                    `meta_title` varchar(255) NOT NULL,
                    `meta_description` varchar(255) NOT NULL,
                    `meta_keyword` varchar(255) NOT NULL,
                    PRIMARY KEY (`category_id`,`language_id`)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
            """,
            'oc_language': """
                CREATE TABLE IF NOT EXISTS `oc_language` (
                    `language_id` int(11) NOT NULL AUTO_INCREMENT,
                    `name` varchar(32) NOT NULL,
                    `code` varchar(5) NOT NULL,
                    `locale` varchar(255) NOT NULL,
                    `image` varchar(64) NOT NULL,
                    `directory` varchar(32) NOT NULL,
                    `sort_order` int(3) NOT NULL DEFAULT '0',
                    `status` tinyint(1) NOT NULL,
                    PRIMARY KEY (`language_id`)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
            """
        }
        
        for table_name, sql in tables_sql.items():
            try:
                self.cursor.execute(sql)
                logger.info(f"Table {table_name} created/verified successfully")
            except Error as e:
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
                    INSERT IGNORE INTO oc_language 
                    (language_id, name, code, locale, image, directory, sort_order, status) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, lang)
            except Error as e:
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
        """Insert categories into OpenCart database"""
        for category_id, category_data in categories.items():
            try:
                # Insert main category record
                self.cursor.execute("""
                    INSERT IGNORE INTO oc_category 
                    (category_id, image, parent_id, top, column, sort_order, status, date_added, date_modified)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    category_id,
                    category_data['primary_image'],
                    category_data['parent_id'],
                    1 if category_data['parent_id'] == 0 else 0,
                    1,
                    category_id,
                    1,
                    datetime.now(),
                    datetime.now()
                ))
                
                # Insert category descriptions for both languages
                for lang_id in [1, 2]:  # Ukrainian and Russian
                    self.cursor.execute("""
                        INSERT IGNORE INTO oc_category_description 
                        (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
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
                
            except Error as e:
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
        """Insert products into OpenCart database"""
        for product in products:
            try:
                product_id = int(product['id'])
                
                # Insert main product record
                self.cursor.execute("""
                    INSERT IGNORE INTO oc_product 
                    (product_id, model, sku, upc, ean, jan, isbn, mpn, location, quantity, 
                     stock_status_id, image, manufacturer_id, shipping, price, points, 
                     tax_class_id, date_available, weight, weight_class_id, length, width, 
                     height, length_class_id, subtract, minimum, sort_order, status, 
                     viewed, date_added, date_modified)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
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
                    datetime.now().date(),
                    0.00, 0, 0.00, 0.00, 0.00, 0, 1, 1, 0, 1, 0, datetime.now(), datetime.now()
                ))
                
                # Insert product descriptions for both languages
                descriptions = [
                    (1, product['Название (укр)'], product['Описание (укр)']),  # Ukrainian
                    (2, product['Название (рус)'], product['Описание (рус)'])   # Russian
                ]
                
                for lang_id, name, description in descriptions:
                    self.cursor.execute("""
                        INSERT IGNORE INTO oc_product_description 
                        (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
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
                    INSERT IGNORE INTO oc_product_to_category 
                    (product_id, category_id)
                    VALUES (%s, %s)
                """, (product_id, category_id))
                
                if subcategory_id and subcategory_id.strip():
                    self.cursor.execute("""
                        INSERT IGNORE INTO oc_product_to_category 
                        (product_id, category_id)
                        VALUES (%s, %s)
                    """, (product_id, int(subcategory_id)))
                
                # Insert product image
                if product.get('primary_image'):
                    self.cursor.execute("""
                        INSERT IGNORE INTO oc_product_image 
                        (product_id, image, sort_order)
                        VALUES (%s, %s, %s)
                    """, (product_id, product['primary_image'], 0))
                
                logger.info(f"Inserted product: {product['Название (укр)']}")
                
            except Error as e:
                logger.error(f"Error inserting product {product.get('id', 'unknown')}: {e}")
        
        self.connection.commit()
        logger.info("Products insertion completed")
    
    def migrate(self, categories_file, products_file):
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
            
            logger.info("Migration completed successfully!")
            return True
            
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            return False
        finally:
            self.disconnect_from_database()

def main():
    # Database configuration
    db_config = {
        'host': 'localhost',
        'port': 3306,
        'user': 'root',
        'password': 'example',
        'database': 'opencart',
        'charset': 'utf8mb4',
        'collation': 'utf8mb4_general_ci'
    }
    
    # File paths
    categories_file = '/workspace/data/categories_list.csv'
    products_file = '/workspace/data/list.csv'
    
    # Create migrator instance
    migrator = OpenCartMigrator(db_config)
    
    # Run migration
    success = migrator.migrate(categories_file, products_file)
    
    if success:
        print("✅ Migration completed successfully!")
        print("Check migration.log for detailed information.")
    else:
        print("❌ Migration failed!")
        print("Check migration.log for error details.")
        sys.exit(1)

if __name__ == "__main__":
    main()