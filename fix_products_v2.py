#!/usr/bin/env python3
import csv
import re

def extract_better_title(description):
    """Extract a better title from the description"""
    if not description:
        return "Unknown Product"
    
    # Look for common seed product patterns
    patterns = [
        r'^([^.,\n]{5,30})\s*[.,]',  # Text before first dot/comma (5-30 chars)
        r'^([^.,\n]{5,25})',         # Text before first dot/comma (5-25 chars)
        r'^([^.,\n]{10,40})',        # Text before first dot/comma (10-40 chars)
    ]
    
    for pattern in patterns:
        match = re.search(pattern, description.strip())
        if match:
            title = match.group(1).strip()
            # Clean up the title
            title = re.sub(r'^["\']+|["\']+$', '', title)
            title = re.sub(r'\s+', ' ', title)
            
            # If title looks reasonable (not too short, not too long)
            if 5 <= len(title) <= 50:
                return title
    
    # Fallback: use first 20-30 characters
    fallback = description[:30].strip()
    fallback = re.sub(r'^["\']+|["\']+$', '', fallback)
    fallback = re.sub(r'\s+', ' ', fallback)
    return fallback

def fix_product_data():
    """Fix product data with better title extraction"""
    
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
        long_desc = product.get('description_long', '')
        
        # Extract better title
        title = extract_better_title(long_desc)
        product['title'] = title
        
        # Update description_long to remove the title part
        if long_desc and title in long_desc:
            remaining_desc = long_desc[len(title):].strip()
            if remaining_desc.startswith('.') or remaining_desc.startswith(','):
                remaining_desc = remaining_desc[1:].strip()
            product['description_long'] = remaining_desc
        
        # Create fixed product structure (without description_short)
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
    
    # Show examples
    print("\nFirst 5 fixed products:")
    for i, product in enumerate(fixed_products[:5]):
        print(f"{i+1}. ID: {product['id']}")
        print(f"   Title: {product['title']}")
        print(f"   Description: {product['description_long'][:80]}...")
        print()

if __name__ == "__main__":
    fix_product_data()