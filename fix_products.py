#!/usr/bin/env python3
import csv
import re
import os

def fix_product_data():
    """Fix product data by properly parsing titles and removing description_short column"""
    
    # Read the current products
    products = []
    with open('data/products.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            products.append(row)
    
    print(f"Loaded {len(products)} products")
    
    # Fix each product
    fixed_products = []
    for product in products:
        # Extract title from long description (before first dot or comma)
        long_desc = product.get('description_long', '')
        if long_desc:
            # Try to find title by looking for the first meaningful phrase
            # Look for text before first dot, comma, or newline
            title_match = re.search(r'^([^.,\n]+)', long_desc.strip())
            if title_match:
                title = title_match.group(1).strip()
                # Clean up the title - remove extra quotes and whitespace
                title = re.sub(r'^["\']+|["\']+$', '', title)
                title = re.sub(r'\s+', ' ', title)
                
                # If title is too long (more than 50 chars), try to find a shorter one
                if len(title) > 50:
                    # Look for a shorter title pattern
                    short_title_match = re.search(r'^([^.,\n]{10,40})', long_desc.strip())
                    if short_title_match:
                        title = short_title_match.group(1).strip()
                        title = re.sub(r'^["\']+|["\']+$', '', title)
                        title = re.sub(r'\s+', ' ', title)
                
                # Update the product
                product['title'] = title
                
                # Update description_long to remove the title part
                remaining_desc = long_desc[len(title):].strip()
                if remaining_desc.startswith('.') or remaining_desc.startswith(','):
                    remaining_desc = remaining_desc[1:].strip()
                product['description_long'] = remaining_desc
            else:
                # Fallback: use first 30 characters as title
                title = long_desc[:30].strip()
                product['title'] = title
                product['description_long'] = long_desc[30:].strip()
        else:
            # If no description, try to use image name to infer title
            image = product.get('image', '')
            if image:
                # Extract product info from image name
                image_match = re.search(r'p_(\d+)_(\d+)\.jpg', image)
                if image_match:
                    product['title'] = f"Product {image_match.group(1)}"
                else:
                    product['title'] = "Unknown Product"
            else:
                product['title'] = "Unknown Product"
        
        # Remove description_short column by not including it in the new structure
        fixed_product = {
            'id': product.get('id', ''),
            'title': product.get('title', ''),
            'description_long': product.get('description_long', ''),
            'category_id': product.get('category_id', ''),
            'category': product.get('category', ''),
            'subcategory': product.get('subcategory', ''),
            'tags': product.get('tags', ''),
            'weight': product.get('weight', ''),
            'price': product.get('price', ''),
            'image': product.get('image', '')
        }
        
        fixed_products.append(fixed_product)
    
    # Save the fixed products
    fieldnames = ['id', 'title', 'description_long', 'category_id', 'category', 'subcategory', 'tags', 'weight', 'price', 'image']
    
    with open('data/products.csv', 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(fixed_products)
    
    print(f"Fixed and saved {len(fixed_products)} products")
    
    # Show some examples
    print("\nFirst 3 fixed products:")
    for i, product in enumerate(fixed_products[:3]):
        print(f"{i+1}. ID: {product['id']}")
        print(f"   Title: {product['title']}")
        print(f"   Description: {product['description_long'][:100]}...")
        print()

if __name__ == "__main__":
    fix_product_data()