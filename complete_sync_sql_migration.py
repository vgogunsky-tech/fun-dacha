#!/usr/bin/env python3
"""
Complete Sync SQL Migration Generator
This script generates a complete SQL file for sync migration without requiring Python packages in container
"""

import csv
import json
from pathlib import Path
from datetime import datetime

def generate_complete_sync_sql():
    """Generate complete sync SQL migration file"""
    
    print("🔧 Generating complete sync SQL migration...")
    
    # Load tags mapping for localization
    tags_mapping = {}
    try:
        with open('data/tags.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                key = row.get('key', '')
                ua = row.get('ua', '')
                ru = row.get('ru', '')
                if key and ua and ru:
                    tags_mapping[key] = {'ua': ua, 'ru': ru}
        print(f"✅ Loaded {len(tags_mapping)} tags for localization")
    except Exception as e:
        print(f"⚠️ Warning: Could not load tags mapping: {e}")
    
    def localize_tags(tags_string, language_id):
        """Localize tags string based on language"""
        if not tags_string or not tags_mapping:
            return tags_string
        
        try:
            tags = [tag.strip() for tag in tags_string.split(',')]
            localized_tags = []
            
            for tag in tags:
                if tag in tags_mapping:
                    if language_id == 2:  # Ukrainian
                        localized_tags.append(tags_mapping[tag]['ua'])
                    else:  # Russian
                        localized_tags.append(tags_mapping[tag]['ru'])
                else:
                    localized_tags.append(tag)
            
            return ', '.join(localized_tags)
        except Exception as e:
            print(f"Error localizing tags '{tags_string}': {e}")
            return tags_string
    
    # Load CSV data
    categories = {}
    products = []
    inventory = {}
    attributes = []
    
    # Load categories
    try:
        with open('data/categories_list.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                old_id = int(row['id'])
                categories[old_id] = {
                    'name': row['name'],
                    'parent_id': int(row['parentId']) if row['parentId'] else 0,
                    'description': row.get('description (ukr)', ''),
                    'tag': row.get('tag', ''),
                    'image': row.get('primary_image', '')
                }
    except Exception as e:
        print(f"Error reading categories: {e}")
        return False
    
    # Load products
    try:
        with open('data/list.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                products.append(row)
    except Exception as e:
        print(f"Error reading products: {e}")
        return False
    
    # Load inventory
    try:
        with open('data/inventory.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                product_id = row.get('product_id', '').replace('p', '')
                if product_id.isdigit():
                    inventory[int(product_id)] = {
                        'price': float(row.get('original_price', 0)) if row.get('original_price') else 0.0,
                        'quantity': int(row.get('stock_qty', 0)) if row.get('stock_qty') else 0
                    }
    except Exception as e:
        print(f"Error reading inventory: {e}")
    
    # Load attributes
    try:
        with open('data/tags.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                attributes.append(row)
    except Exception as e:
        print(f"Error reading tags: {e}")
    
    # Generate SQL
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    sql_content = f"""-- Complete Sync OpenCart Migration SQL
-- Generated from actual CSV data with complete sync functionality
-- Generated at: {current_time}

USE opencart;

-- Complete sync: Remove all existing data first
-- Remove all product relationships and descriptions
DELETE FROM oc_product_to_category;
DELETE FROM oc_product_description;
DELETE FROM oc_product_to_store;
DELETE FROM oc_product_to_layout;
DELETE FROM oc_product_attribute;
DELETE FROM oc_product;

-- Remove all category relationships and descriptions
DELETE FROM oc_category_path;
DELETE FROM oc_category_description;
DELETE FROM oc_category_to_store;
DELETE FROM oc_category_to_layout;
DELETE FROM oc_category;

-- Remove all attributes
DELETE FROM oc_attribute_description;
DELETE FROM oc_attribute;

-- Reset auto-increment counters
ALTER TABLE oc_product AUTO_INCREMENT = 1;
ALTER TABLE oc_category AUTO_INCREMENT = 1;
ALTER TABLE oc_attribute AUTO_INCREMENT = 1;

-- Insert categories with images
"""
    
    # Add categories with images
    category_mapping = {}
    category_id = 1
    for old_id, cat_data in categories.items():
        category_mapping[old_id] = category_id
        image_path = f"catalog/category/{cat_data['image']}" if cat_data['image'] else ""
        sql_content += f"INSERT INTO oc_category (category_id, parent_id, sort_order, status, image) VALUES ({category_id}, {cat_data['parent_id']}, {category_id}, 1, '{image_path}');\n"
        category_id += 1
    
    sql_content += "\n-- Insert category descriptions (Ukrainian)\n"
    for old_id, cat_data in categories.items():
        cat_id = category_mapping[old_id]
        name = cat_data['name'].replace("'", "\\'")
        description = cat_data['description'].replace("'", "\\'")
        tag = cat_data['tag'].replace("'", "\\'")
        
        meta_desc = description[:250] if len(description) > 250 else description
        
        sql_content += f"INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES ({cat_id}, 2, '{name}', '{description}', '{name}', '{meta_desc}', '{tag}');\n"
    
    sql_content += "\n-- Insert category descriptions (Russian)\n"
    for old_id, cat_data in categories.items():
        cat_id = category_mapping[old_id]
        name = cat_data['name'].replace("'", "\\'")
        description = cat_data['description'].replace("'", "\\'")
        tag = cat_data['tag'].replace("'", "\\'")
        
        meta_desc = description[:250] if len(description) > 250 else description
        
        sql_content += f"INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES ({cat_id}, 1, '{name}', '{description}', '{name}', '{meta_desc}', '{tag}');\n"
    
    sql_content += "\n-- Insert category paths\n"
    for old_id in categories.keys():
        cat_id = category_mapping[old_id]
        sql_content += f"INSERT INTO oc_category_path (category_id, path_id, level) VALUES ({cat_id}, {cat_id}, 0);\n"
    
    # Add products with images and timestamps (respect new CSV fields)
    sql_content += "\n-- Insert products with images and timestamps\n"
    product_id = 1
    for product in products:
        # Get category ID from mapping
        category_id = 1  # default
        if product.get('category_id') and int(product['category_id']) in category_mapping:
            category_id = category_mapping[int(product['category_id'])]
        
        # Determine pricing and quantity
        # Prefer explicit CSV price if provided, else inventory
        price_csv = (product.get('price') or '').strip()
        price = float(price_csv) if price_csv not in (None, '',) else 0.0
        quantity = 10
        if product_id in inventory:
            if price == 0.0:
                price = inventory[product_id]['price']
            quantity = inventory[product_id]['quantity']
        
        # Get image path
        image_name = product.get('primary_image', '')
        image_path = f"catalog/product/{image_name}" if image_name else ""
        
        # Model from CSV 'model' or fallback to product_id
        model_val = (product.get('model') or product.get('product_id') or f'PROD-{product_id}').replace("'", "\\'")
        # Weight and dimensions from CSV if present
        weight_val = (product.get('weight') or '').strip()
        length_val = (product.get('length') or '').strip()
        width_val = (product.get('width') or '').strip()
        height_val = (product.get('height') or '').strip()
        weight_sql = float(weight_val) if weight_val not in ('', None) else 0.0
        length_sql = float(length_val) if length_val not in ('', None) else 0.0
        width_sql = float(width_val) if width_val not in ('', None) else 0.0
        height_sql = float(height_val) if height_val not in ('', None) else 0.0
        # OpenCart requires model; sku optional – set sku=model for visibility
        sql_content += f"INSERT INTO oc_product (product_id, model, sku, quantity, stock_status_id, manufacturer_id, shipping, price, points, tax_class_id, date_available, weight, length, width, height, subtract, minimum, sort_order, status, image, date_added, date_modified) VALUES ({product_id}, '{model_val}', '{model_val}', {quantity}, 5, 0, 1, {price}, 0, 0, '{current_date}', {weight_sql}, {length_sql}, {width_sql}, {height_sql}, 1, 1, {product_id}, 1, '{image_path}', '{current_time}', '{current_time}');\n"
        product_id += 1
    
    # Add product descriptions with localized tags
    sql_content += "\n-- Insert product descriptions (Ukrainian) with localized tags\n"
    product_id = 1
    for product in products:
        name_ua = product.get('Название (укр)', '').replace("'", "\\'")
        desc_ua = product.get('Описание (укр)', '').replace("'", "\\'")
        tags_string = product.get('tags', '')
        tags_ua = localize_tags(tags_string, 2).replace("'", "\\'")
        
        meta_desc_ua = desc_ua[:250] if len(desc_ua) > 250 else desc_ua
        
        sql_content += f"INSERT INTO oc_product_description (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword) VALUES ({product_id}, 2, '{name_ua}', '{desc_ua}', '{tags_ua}', '{name_ua}', '{meta_desc_ua}', '{tags_ua}');\n"
        product_id += 1
    
    sql_content += "\n-- Insert product descriptions (Russian) with localized tags\n"
    product_id = 1
    for product in products:
        name_ru = product.get('Название (рус)', '').replace("'", "\\'")
        desc_ru = product.get('Описание (рус)', '').replace("'", "\\'")
        tags_string = product.get('tags', '')
        tags_ru = localize_tags(tags_string, 1).replace("'", "\\'")
        
        meta_desc_ru = desc_ru[:250] if len(desc_ru) > 250 else desc_ru
        
        sql_content += f"INSERT INTO oc_product_description (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword) VALUES ({product_id}, 1, '{name_ru}', '{desc_ru}', '{tags_ru}', '{name_ru}', '{meta_desc_ru}', '{tags_ru}');\n"
        product_id += 1
    
    # Add product to category relationships and SEO URLs (if provided)
    sql_content += "\n-- Insert product to category relationships\n"
    product_id = 1
    for product in products:
        category_id = 1  # default
        if product.get('category_id') and int(product['category_id']) in category_mapping:
            category_id = category_mapping[int(product['category_id'])]
        sql_content += f"INSERT INTO oc_product_to_category (product_id, category_id) VALUES ({product_id}, {category_id});\n"
        # SEO keyword from CSV 'seo' (same for both languages if provided)
        seo_kw = (product.get('seo') or '').strip()
        if seo_kw:
            safe_kw = seo_kw.replace("'", "\\'")
            # Remove any existing for this query to avoid duplicates
            sql_content += f"DELETE FROM oc_seo_url WHERE query='product_id={product_id}';\n"
            sql_content += f"INSERT INTO oc_seo_url (store_id, language_id, query, keyword) VALUES (0, 1, 'product_id={product_id}', '{safe_kw}');\n"
            sql_content += f"INSERT INTO oc_seo_url (store_id, language_id, query, keyword) VALUES (0, 2, 'product_id={product_id}', '{safe_kw}');\n"
        product_id += 1
    
    # Add attributes with proper localization
    if attributes:
        sql_content += "\n-- Insert attributes with localization\n"
        attribute_id = 1
        attribute_groups = {}
        group_id = 1
        
        for attr in attributes:
            group_name = attr.get('group', '')
            if group_name not in attribute_groups:
                attribute_groups[group_name] = group_id
                group_id += 1
            
            sql_content += f"INSERT INTO oc_attribute (attribute_id, attribute_group_id, sort_order) VALUES ({attribute_id}, {attribute_groups[group_name]}, {attribute_id});\n"
            attribute_id += 1
        
        sql_content += "\n-- Insert attribute descriptions (Ukrainian)\n"
        attribute_id = 1
        for attr in attributes:
            name_ua = attr.get('ua', '').replace("'", "\\'")
            sql_content += f"INSERT INTO oc_attribute_description (attribute_id, language_id, name) VALUES ({attribute_id}, 2, '{name_ua}');\n"
            attribute_id += 1
        
        sql_content += "\n-- Insert attribute descriptions (Russian)\n"
        attribute_id = 1
        for attr in attributes:
            name_ru = attr.get('ru', '').replace("'", "\\'")
            sql_content += f"INSERT INTO oc_attribute_description (attribute_id, language_id, name) VALUES ({attribute_id}, 1, '{name_ru}');\n"
            attribute_id += 1
    
    # Add display fixes
    sql_content += f"""
-- Fix product display issues
UPDATE oc_product SET status = 1 WHERE product_id > 0;
UPDATE oc_category SET status = 1 WHERE category_id > 0;
INSERT IGNORE INTO oc_product_to_store (product_id, store_id) SELECT product_id, 0 FROM oc_product WHERE product_id > 0;
INSERT IGNORE INTO oc_category_to_store (category_id, store_id) SELECT category_id, 0 FROM oc_category WHERE category_id > 0;
UPDATE oc_product SET stock_status_id = 5 WHERE product_id > 0;
UPDATE oc_product SET date_available = '{current_date}' WHERE product_id > 0;
"""
    
    # Write SQL file
    with open('complete_sync_migration.sql', 'w', encoding='utf-8') as f:
        f.write(sql_content)
    
    print(f"✅ Generated complete_sync_migration.sql with:")
    print(f"   - {len(categories)} categories with images")
    print(f"   - {len(products)} products with images and timestamps")
    print(f"   - {len(attributes)} attributes with localization")
    print(f"   - Localized tags (Ukrainian/Russian)")
    print(f"   - Complete sync functionality (add/update/remove)")
    print(f"   - Proper timestamps (date_added: {current_time}, date_modified: {current_time})")
    print(f"   - Image paths: catalog/category/ and catalog/product/")
    
    return True

if __name__ == "__main__":
    generate_complete_sync_sql()