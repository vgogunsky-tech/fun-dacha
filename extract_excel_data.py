#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Excel Product Data Extractor
Extracts product information from the structured Excel file
"""

import zipfile
import xml.etree.ElementTree as ET
import re
import csv

def extract_excel_data():
    """Extract product data from Excel file"""
    print("Extracting data from Excel file...")
    
    products = []
    
    try:
        with zipfile.ZipFile('list.xlsx', 'r') as zip_file:
            # Read shared strings
            shared_strings = {}
            if 'xl/sharedStrings.xml' in zip_file.namelist():
                shared_strings_content = zip_file.read('xl/sharedStrings.xml').decode('utf-8')
                shared_strings_root = ET.fromstring(shared_strings_content)
                
                for i, si in enumerate(shared_strings_root.findall('.//si')):
                    t = si.find('t')
                    if t is not None and t.text:
                        shared_strings[i] = t.text.strip()
            
            print(f"Found {len(shared_strings)} shared strings")
            
            # Process each worksheet
            worksheet_files = [f for f in zip_file.namelist() if 'xl/worksheets/sheet' in f and f.endswith('.xml')]
            
            for sheet_file in worksheet_files:
                print(f"\nProcessing {sheet_file}...")
                
                sheet_content = zip_file.read(sheet_file).decode('utf-8')
                sheet_root = ET.fromstring(sheet_content)
                
                # Extract data from worksheet
                sheet_data = extract_sheet_data(sheet_root, shared_strings)
                
                if sheet_data:
                    products.extend(sheet_data)
                    print(f"  Found {len(sheet_data)} products in {sheet_file}")
    
    except Exception as e:
        print(f"Error processing Excel file: {e}")
        return []
    
    print(f"\nTotal products extracted from Excel: {len(products)}")
    return products

def extract_sheet_data(sheet_root, shared_strings):
    """Extract data from a single worksheet"""
    products = []
    
    # Find all rows
    rows = sheet_root.findall('.//row')
    
    if not rows:
        return []
    
    # First row might be headers
    headers = []
    if rows:
        header_row = rows[0]
        for cell in header_row.findall('.//c'):
            value = get_cell_value(cell, shared_strings)
            if value:
                headers.append(value)
    
    print(f"  Headers: {headers}")
    
    # Process data rows (skip header)
    for row in rows[1:]:
        row_data = {}
        cells = row.findall('.//c')
        
        for i, cell in enumerate(cells):
            value = get_cell_value(cell, shared_strings)
            if value and i < len(headers):
                row_data[headers[i]] = value
        
        if row_data:
            # Try to identify if this is a product row
            if is_product_row(row_data):
                product = create_product_from_row(row_data)
                if product:
                    products.append(product)
    
    return products

def get_cell_value(cell, shared_strings):
    """Get the value from a cell, handling shared strings"""
    value = cell.get('v')
    if value is None:
        return None
    
    # Check if it's a shared string
    if cell.get('t') == 's':
        try:
            index = int(value)
            return shared_strings.get(index, '')
        except ValueError:
            return value
    else:
        return value

def is_product_row(row_data):
    """Check if a row contains product data"""
    # Look for key fields that indicate this is a product
    key_fields = ['id', 'Название', 'Название (укр)', 'Название (рус)', 'image']
    
    for field in key_fields:
        if any(key.startswith(field) for key in row_data.keys()):
            return True
    
    return False

def create_product_from_row(row_data):
    """Create a product object from row data"""
    try:
        # Extract product information
        product_id = row_data.get('id', '')
        ukr_name = row_data.get('Название (укр)', '') or row_data.get('Название', '')
        rus_name = row_data.get('Название (рус)', '')
        ukr_desc = row_data.get('Описание (укр)', '')
        rus_desc = row_data.get('Описание (рус)', '')
        ukr_short = row_data.get('Короткое Описание (укр)', '')
        rus_short = row_data.get('Короткое Описание (рус)', '')
        image = row_data.get('image', '')
        
        # Use Ukrainian name if available, otherwise Russian
        name = ukr_name if ukr_name else rus_name
        description = ukr_desc if ukr_desc else rus_desc
        short_desc = ukr_short if ukr_short else rus_short
        
        if not name:
            return None
        
        # Try to extract product number from name or ID
        product_number = extract_product_number(name, product_id)
        
        return {
            'id': product_id,
            'number': product_number,
            'name': name,
            'description': description,
            'short_description': short_desc,
            'image': image,
            'ukr_name': ukr_name,
            'rus_name': rus_name,
            'ukr_desc': ukr_desc,
            'rus_desc': rus_desc,
            'ukr_short': ukr_short,
            'rus_short': rus_short
        }
    
    except Exception as e:
        print(f"Error creating product from row: {e}")
        return None

def extract_product_number(name, product_id):
    """Try to extract product number from name or ID"""
    # Look for patterns like "123. Product Name" or "Product 123"
    patterns = [
        r'^(\d+)\.\s*',  # "123. Product Name"
        r'\s+(\d+)\s*$',  # "Product Name 123"
        r'(\d+)',          # Any number
    ]
    
    for pattern in patterns:
        match = re.search(pattern, name)
        if match:
            try:
                return int(match.group(1))
            except ValueError:
                continue
    
    # Try to extract from ID
    if product_id:
        match = re.search(r'(\d+)', str(product_id))
        if match:
            try:
                return int(match.group(1))
            except ValueError:
                pass
    
    return 0

def save_to_csv(products, filename):
    """Save products to CSV file"""
    if not products:
        print("No products to save")
        return
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        # Get all possible fieldnames
        fieldnames = set()
        for product in products:
            fieldnames.update(product.keys())
        
        fieldnames = sorted(list(fieldnames))
        
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for product in products:
            writer.writerow(product)
    
    print(f"Saved {len(products)} products to {filename}")

def main():
    print("Starting Excel data extraction...")
    
    # Extract products from Excel
    products = extract_excel_data()
    
    if products:
        # Save to CSV
        save_to_csv(products, 'excel_products.csv')
        
        # Print sample products
        print(f"\nSample products from Excel:")
        for i, product in enumerate(products[:5]):
            print(f"  {i+1}. {product.get('name', 'N/A')} (ID: {product.get('id', 'N/A')})")
        
        # Print summary
        print(f"\nExcel Extraction Summary:")
        print(f"Total products: {len(products)}")
        
        # Count products with different languages
        ukr_count = sum(1 for p in products if p.get('ukr_name'))
        rus_count = sum(1 for p in products if p.get('rus_name'))
        print(f"Products with Ukrainian names: {ukr_count}")
        print(f"Products with Russian names: {rus_count}")
        
    else:
        print("No products extracted from Excel")

if __name__ == "__main__":
    main()