#!/usr/bin/env python3
"""
Generate Enhanced Real Data SQL Migration
This script generates a SQL file from the actual CSV data with images and localized tags
"""

import csv
import json
from pathlib import Path

def generate_enhanced_real_data_sql():
    """Generate SQL migration file from real CSV data with images and localized tags"""
    
    print("🔧 Generating enhanced real data SQL migration with images and localized tags...")
    
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
                    localized_tags.append(tag)  # Keep original if no mapping found
            
            return ', '.join(localized_tags)
        except Exception as e:
            print(f"Error localizing tags '{tags_string}': {e}")
            return tags_string
    
    # Read categories
    categories = {}
    category_mapping = {}
    category_id = 1
    
    try:
        with open('data/categories_list.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                old_id = int(row['id'])
                category_mapping[old_id] = category_id
                categories[category_id] = {
                    'name': row['name'],
                    'parent_id': int(row['parentId']) if row['parentId'] else 0,
                    'description': row.get('description (ukr)', ''),
                    'tag': row.get('tag', ''),
                    'image': row.get('primary_image', '')
                }
                category_id += 1
    except Exception as e:
        print(f"Error reading categories: {e}")
        return False
    
    # Read products
    products = []
    try:
        with open('data/list.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                products.append(row)
    except Exception as e:
        print(f"Error reading products: {e}")
        return False
    
    # Read inventory
    inventory = {}
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
    
    # Read tags
    attributes = []
    try:
        with open('data/tags.csv', 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                attributes.append(row)
    except Exception as e:
        print(f"Error reading tags: {e}")
    
    # Generate SQL
    sql_content = """-- Enhanced Real Data OpenCart Migration SQL
-- Generated from actual CSV data with images and localized tags

USE opencart;

-- Clear existing data
DELETE FROM oc_product_to_category WHERE product_id > 0;
DELETE FROM oc_product_description WHERE product_id > 0;
DELETE FROM oc_product WHERE product_id > 0;
DELETE FROM oc_category_path WHERE category_id > 0;
DELETE FROM oc_category_description WHERE category_id > 0;
DELETE FROM oc_category WHERE category_id > 0;
DELETE FROM oc_product_attribute WHERE product_id > 0;
DELETE FROM oc_attribute_description WHERE attribute_id > 0;
DELETE FROM oc_attribute WHERE attribute_id > 0;

-- Insert categories with images
"""
    
    # Add categories with images
    for cat_id, cat_data in categories.items():
        image_path = f"catalog/categories/{cat_data['image']}" if cat_data['image'] else ""
        sql_content += f"INSERT INTO oc_category (category_id, parent_id, sort_order, status, image) VALUES ({cat_id}, {cat_data['parent_id']}, {cat_id}, 1, '{image_path}');\n"
    
    sql_content += "\n-- Insert category descriptions (Ukrainian)\n"
    for cat_id, cat_data in categories.items():
        name = cat_data['name'].replace("'", "\\'")
        description = cat_data['description'].replace("'", "\\'")
        tag = cat_data['tag'].replace("'", "\\'")
        
        # Truncate meta_description to fit database column (usually 255 chars)
        meta_desc = description[:250] if len(description) > 250 else description
        
        sql_content += f"INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES ({cat_id}, 2, '{name}', '{description}', '{name}', '{meta_desc}', '{tag}');\n"
    
    sql_content += "\n-- Insert category descriptions (Russian)\n"
    for cat_id, cat_data in categories.items():
        name = cat_data['name'].replace("'", "\\'")
        description = cat_data['description'].replace("'", "\\'")
        tag = cat_data['tag'].replace("'", "\\'")
        
        # Truncate meta_description to fit database column (usually 255 chars)
        meta_desc = description[:250] if len(description) > 250 else description
        
        sql_content += f"INSERT INTO oc_category_description (category_id, language_id, name, description, meta_title, meta_description, meta_keyword) VALUES ({cat_id}, 1, '{name}', '{description}', '{name}', '{meta_desc}', '{tag}');\n"
    
    sql_content += "\n-- Insert category paths\n"
    for cat_id in categories.keys():
        sql_content += f"INSERT INTO oc_category_path (category_id, path_id, level) VALUES ({cat_id}, {cat_id}, 0);\n"
    
    # Add products with images
    sql_content += "\n-- Insert products with images\n"
    product_id = 1
    for product in products:
        # Get category ID from mapping
        category_id = 1  # default
        if product.get('category_id') and int(product['category_id']) in category_mapping:
            category_id = category_mapping[int(product['category_id'])]
        
        # Get inventory data
        price = 0.0
        quantity = 10
        if product_id in inventory:
            price = inventory[product_id]['price']
            quantity = inventory[product_id]['quantity']
        
        # Get image path
        image_name = product.get('primary_image', '')
        image_path = f"catalog/products/{image_name}" if image_name else ""
        
        model = product.get('product_id', f'PROD-{product_id}').replace("'", "\\'")
        sql_content += f"INSERT INTO oc_product (product_id, model, sku, quantity, stock_status_id, manufacturer_id, shipping, price, points, tax_class_id, date_available, weight, weight_class_id, length, width, height, length_class_id, subtract, minimum, sort_order, status, image) VALUES ({product_id}, '{model}', '{model}', {quantity}, 5, 0, 1, {price}, 0, 0, CURDATE(), 0.0, 1, 0.0, 0.0, 0.0, 1, 1, 1, {product_id}, 1, '{image_path}');\n"
        product_id += 1
    
    # Add product descriptions with localized tags
    sql_content += "\n-- Insert product descriptions (Ukrainian) with localized tags\n"
    product_id = 1
    for product in products:
        name_ua = product.get('Название (укр)', '').replace("'", "\\'")
        desc_ua = product.get('Описание (укр)', '').replace("'", "\\'")
        tags_string = product.get('tags', '')
        tags_ua = localize_tags(tags_string, 2).replace("'", "\\'")
        
        # Truncate meta_description to fit database column (usually 255 chars)
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
        
        # Truncate meta_description to fit database column (usually 255 chars)
        meta_desc_ru = desc_ru[:250] if len(desc_ru) > 250 else desc_ru
        
        sql_content += f"INSERT INTO oc_product_description (product_id, language_id, name, description, tag, meta_title, meta_description, meta_keyword) VALUES ({product_id}, 1, '{name_ru}', '{desc_ru}', '{tags_ru}', '{name_ru}', '{meta_desc_ru}', '{tags_ru}');\n"
        product_id += 1
    
    # Add product to category relationships
    sql_content += "\n-- Insert product to category relationships\n"
    product_id = 1
    for product in products:
        category_id = 1  # default
        if product.get('category_id') and int(product['category_id']) in category_mapping:
            category_id = category_mapping[int(product['category_id'])]
        sql_content += f"INSERT INTO oc_product_to_category (product_id, category_id) VALUES ({product_id}, {category_id});\n"
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
    sql_content += """
-- Fix product display issues
UPDATE oc_product SET status = 1 WHERE product_id > 0;
UPDATE oc_category SET status = 1 WHERE category_id > 0;
INSERT IGNORE INTO oc_product_to_store (product_id, store_id) SELECT product_id, 0 FROM oc_product WHERE product_id > 0;
INSERT IGNORE INTO oc_category_to_store (category_id, store_id) SELECT category_id, 0 FROM oc_category WHERE category_id > 0;
UPDATE oc_product SET stock_status_id = 5 WHERE product_id > 0;
UPDATE oc_product SET date_available = CURDATE() WHERE product_id > 0;
"""
    
    # Write SQL file
    with open('enhanced_real_data_migration.sql', 'w', encoding='utf-8') as f:
        f.write(sql_content)
    
    print(f"✅ Generated enhanced_real_data_migration.sql with:")
    print(f"   - {len(categories)} categories with images")
    print(f"   - {len(products)} products with images")
    print(f"   - {len(attributes)} attributes with localization")
    print(f"   - Localized tags (Ukrainian/Russian)")
    print(f"   - Inventory data integrated")
    print(f"   - Image paths: catalog/categories/ and catalog/products/")
    
    return True

if __name__ == "__main__":
    generate_enhanced_real_data_sql()