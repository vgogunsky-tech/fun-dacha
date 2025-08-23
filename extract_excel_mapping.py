#!/usr/bin/env python3
import csv
import zipfile
import xml.etree.ElementTree as ET
import re

def extract_excel_mapping():
    """Extract Ukrainian names and Russian descriptions from Excel for product mapping"""
    
    products = []
    
    try:
        with zipfile.ZipFile('list.xlsx', 'r') as zip_file:
            # Read shared strings
            shared_strings = {}
            if 'xl/sharedStrings.xml' in zip_file.namelist():
                with zip_file.open('xl/sharedStrings.xml') as f:
                    tree = ET.parse(f)
                    root = tree.getroot()
                    for i, si in enumerate(root.findall('.//{*}si')):
                        text_parts = []
                        for t in si.findall('.//{*}t'):
                            text_parts.append(t.text or '')
                        shared_strings[i] = ''.join(text_parts)
            
            # Read sheet data
            if 'xl/worksheets/sheet1.xml' in zip_file.namelist():
                with zip_file.open('xl/worksheets/sheet1.xml') as f:
                    tree = ET.parse(f)
                    root = tree.getroot()
                    
                    # Find all rows
                    rows = root.findall('.//{*}row')
                    
                    for row in rows:
                        cells = row.findall('.//{*}c')
                        row_data = []
                        
                        for cell in cells:
                            value = ''
                            if cell.find('.//{*}v') is not None:
                                cell_value = cell.find('.//{*}v').text
                                if cell.get('t') == 's':  # Shared string
                                    value = shared_strings.get(int(cell_value), '')
                                else:
                                    value = cell_value or ''
                            row_data.append(value)
                        
                        # Check if this row contains product data (has Ukrainian name)
                        if len(row_data) >= 4 and row_data[1] and 'Название' not in row_data[1]:
                            # This looks like a product row
                            product = {
                                'ukrainian_name': row_data[1].strip(),
                                'russian_name': row_data[2].strip() if len(row_data) > 2 and row_data[2] else '',
                                'ukrainian_description': row_data[3].strip() if len(row_data) > 3 and row_data[3] else '',
                                'russian_description': row_data[4].strip() if len(row_data) > 4 and row_data[4] else '',
                                'row_number': len(products) + 1
                            }
                            products.append(product)
    
    except Exception as e:
        print(f"Error reading Excel file: {e}")
        return []
    
    print(f"Extracted {len(products)} products from Excel with Ukrainian names and Russian descriptions")
    
    # Show some examples
    print("\nFirst 5 extracted products:")
    for i, p in enumerate(products[:5]):
        print(f"{i+1}. Ukrainian: {p['ukrainian_name']}")
        print(f"   Russian: {p['russian_name']}")
        print(f"   UA Desc: {p['ukrainian_description'][:80]}...")
        print(f"   RU Desc: {p['russian_description'][:80]}...")
        print()
    
    return products

def map_to_existing_products():
    """Map Excel data to existing products"""
    
    # Extract Excel data
    excel_products = extract_excel_mapping()
    
    # Read existing products
    existing_products = []
    with open('data/products.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            existing_products.append(row)
    
    print(f"\nLoaded {len(existing_products)} existing products")
    
    # Try to map Excel products to existing ones
    mapped_count = 0
    
    for excel_prod in excel_products:
        ukr_name = excel_prod['ukrainian_name'].lower()
        ukr_desc = excel_prod['ukrainian_description'].lower()
        
        # Try to find matching existing product
        for existing_prod in existing_products:
            existing_title = existing_prod['title'].lower()
            existing_desc = existing_prod['description_long'].lower()
            
            # Check for name matches
            if (ukr_name in existing_title or 
                existing_title in ukr_name or
                any(word in existing_title for word in ukr_name.split()) or
                any(word in ukr_name for word in existing_title.split())):
                
                # Update existing product with Excel data
                existing_prod['title'] = excel_prod['ukrainian_name']  # Use Ukrainian name
                existing_prod['description_long'] = excel_prod['ukrainian_description']  # Use Ukrainian description
                
                # Add Russian description as additional info
                if excel_prod['russian_description']:
                    existing_prod['description_long'] += f"\n\nRU: {excel_prod['russian_description']}"
                
                mapped_count += 1
                break
    
    print(f"Mapped {mapped_count} Excel products to existing products")
    
    # Save updated products
    with open('data/products.csv', 'w', encoding='utf-8', newline='') as f:
        fieldnames = ['id', 'title', 'description_long', 'category_id', 'subcategory_id', 'tags', 'weight', 'price', 'image']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(existing_products)
    
    print(f"Saved updated products with Excel mapping")
    
    # Show some examples of updated products
    print("\nFirst 3 updated products:")
    for i, p in enumerate(existing_products[:3]):
        print(f"{i+1}. ID: {p['id']}")
        print(f"   Title: {p['title']}")
        print(f"   Description: {p['description_long'][:100]}...")
        print()

if __name__ == "__main__":
    map_to_existing_products()