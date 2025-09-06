#!/usr/bin/env python3
"""
MySQL OpenCart Migration Script
This script performs CSV to SQL migration for MySQL/MariaDB database
Creates database structure and migrates all data from CSV files
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
        logging.FileHandler('mysql_migration.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class MySQLOpenCartMigrator:
    def __init__(self, host='localhost', port=3306, user='root', password='root', database='opencart'):
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
    
    def create_tables(self):
        """Create OpenCart database tables"""
        try:
            logger.info("Creating OpenCart database tables...")
            
            # Create categories table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_category (
                    category_id int(11) NOT NULL AUTO_INCREMENT,
                    image varchar(255) DEFAULT NULL,
                    parent_id int(11) NOT NULL DEFAULT '0',
                    top tinyint(1) NOT NULL,
                    column int(3) NOT NULL,
                    sort_order int(3) NOT NULL DEFAULT '0',
                    status tinyint(1) NOT NULL,
                    date_added datetime NOT NULL,
                    date_modified datetime NOT NULL,
                    PRIMARY KEY (category_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create category description table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_category_description (
                    category_id int(11) NOT NULL,
                    language_id int(11) NOT NULL,
                    name varchar(255) NOT NULL,
                    description text NOT NULL,
                    meta_title varchar(255) NOT NULL,
                    meta_description varchar(255) NOT NULL,
                    meta_keyword varchar(255) NOT NULL,
                    PRIMARY KEY (category_id, language_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create category path table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_category_path (
                    category_id int(11) NOT NULL,
                    path_id int(11) NOT NULL,
                    level int(11) NOT NULL,
                    PRIMARY KEY (category_id, path_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create products table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_product (
                    product_id int(11) NOT NULL AUTO_INCREMENT,
                    model varchar(64) NOT NULL,
                    sku varchar(64) NOT NULL,
                    upc varchar(12) NOT NULL,
                    ean varchar(14) NOT NULL,
                    jan varchar(13) NOT NULL,
                    isbn varchar(17) NOT NULL,
                    mpn varchar(64) NOT NULL,
                    location varchar(128) NOT NULL,
                    quantity int(4) NOT NULL DEFAULT '0',
                    stock_status_id int(11) NOT NULL,
                    image varchar(255) DEFAULT NULL,
                    manufacturer_id int(11) NOT NULL,
                    shipping tinyint(1) NOT NULL DEFAULT '1',
                    price decimal(15,4) NOT NULL DEFAULT '0.0000',
                    points int(8) NOT NULL DEFAULT '0',
                    tax_class_id int(11) NOT NULL,
                    date_available date NOT NULL,
                    weight decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    weight_class_id int(11) NOT NULL DEFAULT '0',
                    length decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    width decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    height decimal(15,8) NOT NULL DEFAULT '0.00000000',
                    length_class_id int(11) NOT NULL DEFAULT '0',
                    subtract tinyint(1) NOT NULL DEFAULT '1',
                    minimum int(11) NOT NULL DEFAULT '1',
                    sort_order int(11) NOT NULL DEFAULT '0',
                    status tinyint(1) NOT NULL DEFAULT '0',
                    viewed int(5) NOT NULL DEFAULT '0',
                    date_added datetime NOT NULL,
                    date_modified datetime NOT NULL,
                    PRIMARY KEY (product_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create product description table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_product_description (
                    product_id int(11) NOT NULL,
                    language_id int(11) NOT NULL,
                    name varchar(255) NOT NULL,
                    description text NOT NULL,
                    tag text NOT NULL,
                    meta_title varchar(255) NOT NULL,
                    meta_description varchar(255) NOT NULL,
                    meta_keyword varchar(255) NOT NULL,
                    PRIMARY KEY (product_id, language_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create product to category table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_product_to_category (
                    product_id int(11) NOT NULL,
                    category_id int(11) NOT NULL,
                    main_category tinyint(1) NOT NULL DEFAULT '0',
                    PRIMARY KEY (product_id, category_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create attributes table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_attribute (
                    attribute_id int(11) NOT NULL AUTO_INCREMENT,
                    attribute_group_id int(11) NOT NULL,
                    sort_order int(3) NOT NULL,
                    PRIMARY KEY (attribute_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create attribute description table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_attribute_description (
                    attribute_id int(11) NOT NULL,
                    language_id int(11) NOT NULL,
                    name varchar(64) NOT NULL,
                    PRIMARY KEY (attribute_id, language_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create product attribute table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_product_attribute (
                    product_id int(11) NOT NULL,
                    attribute_id int(11) NOT NULL,
                    language_id int(11) NOT NULL,
                    text text NOT NULL,
                    PRIMARY KEY (product_id, attribute_id, language_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            # Create product option table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS oc_product_option (
                    product_option_id int(11) NOT NULL AUTO_INCREMENT,
                    product_id int(11) NOT NULL,
                    option_id int(11) NOT NULL,
                    value text NOT NULL,
                    required tinyint(1) NOT NULL,
                    PRIMARY KEY (product_option_id)
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            
            logger.info("Database tables created successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create tables: {e}")
            return False
    
    def migrate_categories(self):
        """Migrate categories from CSV"""
        try:
            logger.info("Migrating categories...")
            
            # Clear existing data
            self.cursor.execute("DELETE FROM oc_category")
            self.cursor.execute("DELETE FROM oc_category_description")
            self.cursor.execute("DELETE FROM oc_category_path")
            
            categories_csv = Path("data/categories_list.csv")
            if not categories_csv.exists():
                logger.warning("categories_list.csv not found, skipping categories migration")
                return True
            
            category_id = 1
            with open(categories_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        # Insert category
                        self.cursor.execute("""
                            INSERT INTO oc_category 
                            (category_id, image, parent_id, top, column, sort_order, status, date_added, date_modified)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            category_id,
                            '',  # image
                            0,   # parent_id
                            1,   # top
                            1,   # column
                            category_id,  # sort_order
                            1,   # status
                            datetime.now(),
                            datetime.now()
                        ))
                        
                        # Insert category description (English)
                        self.cursor.execute("""
                            INSERT INTO oc_category_description 
                            (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """, (
                            category_id,
                            1,  # English
                            row.get('name', ''),
                            row.get('description', ''),
                            row.get('name', ''),
                            row.get('description', ''),
                            row.get('name', '')
                        ))
                        
                        # Insert category description (Ukrainian)
                        self.cursor.execute("""
                            INSERT INTO oc_category_description 
                            (category_id, language_id, name, description, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """, (
                            category_id,
                            2,  # Ukrainian
                            row.get('name_ua', row.get('name', '')),
                            row.get('description_ua', row.get('description', '')),
                            row.get('name_ua', row.get('name', '')),
                            row.get('description_ua', row.get('description', '')),
                            row.get('name_ua', row.get('name', ''))
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
            return True
            
        except Exception as e:
            logger.error(f"Failed to migrate categories: {e}")
            return False
    
    def migrate_products(self):
        """Migrate products from CSV"""
        try:
            logger.info("Migrating products...")
            
            # Clear existing data
            self.cursor.execute("DELETE FROM oc_product")
            self.cursor.execute("DELETE FROM oc_product_description")
            self.cursor.execute("DELETE FROM oc_product_to_category")
            
            products_csv = Path("data/list.csv")
            if not products_csv.exists():
                logger.warning("list.csv not found, skipping products migration")
                return True
            
            product_id = 1
            with open(products_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        # Get category ID (assuming first category for now)
                        category_id = 1
                        if 'category_id' in row and row['category_id']:
                            try:
                                category_id = int(row['category_id'])
                            except:
                                category_id = 1
                        
                        # Insert product
                        self.cursor.execute("""
                            INSERT INTO oc_product 
                            (product_id, model, sku, upc, ean, jan, isbn, mpn, location, quantity, 
                             stock_status_id, image, manufacturer_id, shipping, price, points, 
                             tax_class_id, date_available, weight, weight_class_id, length, width, 
                             height, length_class_id, subtract, minimum, sort_order, status, 
                             viewed, date_added, date_modified)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            product_id,
                            row.get('model', f'PROD-{product_id}'),
                            row.get('sku', f'SKU-{product_id}'),
                            '', '', '', '', '',  # upc, ean, jan, isbn, mpn
                            '',  # location
                            0,   # quantity
                            5,   # stock_status_id (in stock)
                            '',  # image
                            0,   # manufacturer_id
                            1,   # shipping
                            float(row.get('price', 0)) if row.get('price') else 0.0,
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
                            1,   # status
                            0,   # viewed
                            datetime.now(),
                            datetime.now()
                        ))
                        
                        # Insert product description (English)
                        self.cursor.execute("""
                            INSERT INTO oc_product_description 
                            (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            product_id,
                            1,  # English
                            row.get('name', ''),
                            row.get('description', ''),
                            row.get('tags', ''),
                            row.get('name', ''),
                            row.get('description', ''),
                            row.get('tags', '')
                        ))
                        
                        # Insert product description (Ukrainian)
                        self.cursor.execute("""
                            INSERT INTO oc_product_description 
                            (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            product_id,
                            2,  # Ukrainian
                            row.get('name_ua', row.get('name', '')),
                            row.get('description_ua', row.get('description', '')),
                            row.get('tags_ua', row.get('tags', '')),
                            row.get('name_ua', row.get('name', '')),
                            row.get('description_ua', row.get('description', '')),
                            row.get('tags_ua', row.get('tags', ''))
                        ))
                        
                        # Insert product to category relationship
                        self.cursor.execute("""
                            INSERT INTO oc_product_to_category (product_id, category_id, main_category)
                            VALUES (%s, %s, %s)
                        """, (product_id, category_id, 1))
                        
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
    
    def migrate_attributes(self):
        """Migrate attributes from tags.csv"""
        try:
            logger.info("Migrating attributes...")
            
            # Clear existing data
            self.cursor.execute("DELETE FROM oc_attribute")
            self.cursor.execute("DELETE FROM oc_attribute_description")
            self.cursor.execute("DELETE FROM oc_product_attribute")
            
            tags_csv = Path("data/tags.csv")
            if not tags_csv.exists():
                logger.warning("tags.csv not found, skipping attributes migration")
                return True
            
            attribute_id = 1
            with open(tags_csv, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        # Insert attribute
                        self.cursor.execute("""
                            INSERT INTO oc_attribute (attribute_id, attribute_group_id, sort_order)
                            VALUES (%s, %s, %s)
                        """, (attribute_id, 1, attribute_id))
                        
                        # Insert attribute description (English)
                        self.cursor.execute("""
                            INSERT INTO oc_attribute_description (attribute_id, language_id, name)
                            VALUES (%s, %s, %s)
                        """, (attribute_id, 1, row.get('name', '')))
                        
                        # Insert attribute description (Ukrainian)
                        self.cursor.execute("""
                            INSERT INTO oc_attribute_description (attribute_id, language_id, name)
                            VALUES (%s, %s, %s)
                        """, (attribute_id, 2, row.get('name_ua', row.get('name', ''))))
                        
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
    
    def close_connection(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Database connection closed")

def main():
    """Main migration function"""
    logger.info("Starting MySQL OpenCart migration...")
    
    # Initialize migrator
    migrator = MySQLOpenCartMigrator()
    
    try:
        # Connect to database
        if not migrator.connect_to_database():
            return False
        
        # Create tables
        if not migrator.create_tables():
            return False
        
        # Migrate data
        if not migrator.migrate_categories():
            return False
        
        if not migrator.migrate_products():
            return False
        
        if not migrator.migrate_attributes():
            return False
        
        logger.info("Migration completed successfully!")
        return True
        
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        return False
    
    finally:
        migrator.close_connection()

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)