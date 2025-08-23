#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Working Excel Product Data Extractor
Extracts product information from the structured Excel file with proper shared string handling
"""

import zipfile
import xml.etree.ElementTree as ET
import re
import csv

def extract_shared_strings(zip_file):
    """Extract shared strings from Excel file"""
    shared_strings = {}
    
    try:
        shared_content = zip_file.read('xl/sharedStrings.xml').decode('utf-8')
        
        # Parse shared strings manually since ET might have issues
        si_tags = shared_content.split('<si>')
        
        for i, si_content in enumerate(si_tags[1:], 0):  # Skip first empty element
            # Extract text between <t> and </t>
            t_start = si_content.find('<t')
            if t_start != -1:
                t_end = si_content.find('</t>')
                if t_end != -1:
                    # Find the actual text content
                    text_start = si_content.find('>', t_start) + 1
                    text = si_content[text_start:t_end].strip()
                    
                    # Handle xml:space="preserve" cases
                    if text.startswith('xml:space="preserve"'):
                        # Find the actual text after the attribute
                        text_start = text.find('>') + 1
                        text = text[text_start:].strip()
                    
                    shared_strings[i] = text
        
        print(f"Extracted {len(shared_strings)} shared strings")
        return shared_strings
        
    except Exception as e:
        print(f"Error extracting shared strings: {e}")
        return {}

def extract_worksheet_data(zip_file, sheet_name, shared_strings):
    """Extract data from a specific worksheet"""
    try:
        sheet_content = zip_file.read(sheet_name).decode('utf-8')
        
        # Find sheetData section
        if '<sheetData>' not in sheet_content:
            return []
        
        # Extract sheetData content
        start = sheet_content.find('<sheetData>')
        end = sheet_content.find('</sheetData>')
        if start == -1 or end == -1:
            return []
        
        sheet_data = sheet_content[start:end+12]
        
        # Parse rows
        rows = []
        row_tags = sheet_data.split('<row')
        
        for row_content in row_tags[1:]:  # Skip first empty element
            # Extract cells from row
            cells = []
            cell_tags = row_content.split('<c')
            
            for cell_content in cell_tags[1:]:  # Skip first empty element
                # Extract cell reference and value
                ref_match = re.search(r'r="([A-Z]+)(\d+)"', cell_content)
                value_match = re.search(r'<v>(\d+)</v>', cell_content)
                type_match = re.search(r't="([^"]*)"', cell_content)
                
                if ref_match and value_match:
                    col = ref_match.group(1)
                    row_num = int(ref_match.group(2))
                    value = int(value_match.group(1))
                    cell_type = type_match.group(1) if type_match else ''
                    
                    cells.append({
                        'col': col,
                        'row': row_num,
                        'value': value,
                        'type': cell_type
                    })
            
            if cells:
                rows.append(cells)
        
        return rows
        
    except Exception as e:
        print(f"Error processing {sheet_name}: {e}")
        return []

def process_worksheet_data(rows, shared_strings):
    """Process worksheet data into products"""
    products = []
    
    if not rows:
        return products
    
    # First row should be headers
    header_row = rows[0]
    headers = []
    
    # Extract headers from first row
    for cell in header_row:
        if cell['type'] == 's':  # Shared string
            header_text = shared_strings.get(cell['value'], '')
            headers.append(header_text)
        else:
            headers.append(str(cell['value']))
    
    print(f"Headers: {headers}")
    
    # Process data rows
    for row in rows[1:]:
        if len(row) < len(headers):
            continue
        
        # Create product data
        product_data = {}
        for i, cell in enumerate(row):
            if i < len(headers):
                header = headers[i]
                if cell['type'] == 's':  # Shared string
                    value = shared_strings.get(cell['value'], '')
                else:
                    value = str(cell['value'])
                
                product_data[header] = value
        
        # Check if this is a product row
        if is_product_row(product_data):
            product = create_product_from_data(product_data)
            if product:
                products.append(product)
    
    return products

def is_product_row(product_data):
    """Check if row contains product data"""
    # Look for key fields
    key_fields = ['id', 'Название', 'image']
    
    for field in key_fields:
        if any(key.startswith(field) for key in product_data.keys()):
            return True
    
    return False

def create_product_from_data(product_data):
    """Create product object from row data"""
    try:
        # Extract basic information
        product_id = product_data.get('id', '')
        ukr_name = product_data.get('Название (укр)', '') or product_data.get('Название', '')
        rus_name = product_data.get('Название (рус)', '')
        ukr_desc = product_data.get('Описание (укр)', '')
        rus_desc = product_data.get('Описание (рус)', '')
        ukr_short = product_data.get('Короткое Описание (укр)', '')
        rus_short = product_data.get('Короткое Описание (рус)', '')
        image = product_data.get('image', '')
        
        # Use Ukrainian name if available, otherwise Russian
        name = ukr_name if ukr_name else rus_name
        description = ukr_desc if ukr_desc else rus_desc
        short_desc = ukr_short if ukr_short else rus_short
        
        if not name:
            return None
        
        # Try to extract product number
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
        print(f"Error creating product: {e}")
        return None

def extract_product_number(name, product_id):
    """Extract product number from name or ID"""
    # Look for patterns like "123. Product Name"
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
    
    products = []
    
    try:
        with zipfile.ZipFile('list.xlsx', 'r') as zip_file:
            # Extract shared strings
            shared_strings = extract_shared_strings(zip_file)
            
            if not shared_strings:
                print("No shared strings found, cannot proceed")
                return
            
            # Process each worksheet
            worksheet_files = [f for f in zip_file.namelist() if 'xl/worksheets/sheet' in f and f.endswith('.xml')]
            
            for sheet_file in worksheet_files:
                print(f"\nProcessing {sheet_file}...")
                
                # Extract raw data from worksheet
                rows = extract_worksheet_data(zip_file, sheet_file, shared_strings)
                
                if rows:
                    # Process the data into products
                    sheet_products = process_worksheet_data(rows, shared_strings)
                    products.extend(sheet_products)
                    print(f"  Found {len(sheet_products)} products in {sheet_file}")
                else:
                    print(f"  No data found in {sheet_file}")
    
    except Exception as e:
        print(f"Error processing Excel file: {e}")
        return
    
    if products:
        # Save to CSV
        save_to_csv(products, 'excel_products_working.csv')
        
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
        
        # Show unique IDs
        unique_ids = set(p.get('id') for p in products if p.get('id'))
        print(f"Unique product IDs: {len(unique_ids)}")
        
    else:
        print("No products extracted from Excel")

if __name__ == "__main__":
    main()