#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Complete Excel Product Extractor
Extracts ALL products from the Excel file in all possible formats
"""

import zipfile
import re
import csv

def extract_all_products():
    """Extract ALL products from the Excel file"""
    print("Starting comprehensive Excel product extraction...")
    
    all_products = []
    
    try:
        with zipfile.ZipFile('list.xlsx', 'r') as zip_file:
            # Extract shared strings
            shared_strings = extract_shared_strings(zip_file)
            print(f"Extracted {len(shared_strings)} shared strings")
            
            # Process each worksheet
            worksheet_files = [f for f in zip_file.namelist() if 'xl/worksheets/sheet' in f and f.endswith('.xml')]
            
            for sheet_file in worksheet_files:
                print(f"\nProcessing {sheet_file}...")
                
                # Extract products from this worksheet
                sheet_products = extract_from_worksheet(zip_file, sheet_file, shared_strings)
                all_products.extend(sheet_products)
                print(f"  Found {len(sheet_products)} products in {sheet_file}")
            
            # Also look for products directly in shared strings
            string_products = extract_from_shared_strings(shared_strings)
            all_products.extend(string_products)
            print(f"\nFound {len(string_products)} products directly in shared strings")
            
            # Remove duplicates based on product number
            unique_products = remove_duplicates(all_products)
            print(f"\nTotal unique products after deduplication: {len(unique_products)}")
            
            return unique_products
            
    except Exception as e:
        print(f"Error processing Excel file: {e}")
        return []

def extract_shared_strings(zip_file):
    """Extract shared strings from Excel file"""
    shared_strings = {}
    
    try:
        shared_content = zip_file.read('xl/sharedStrings.xml').decode('utf-8')
        
        # Parse shared strings manually
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
        
        return shared_strings
        
    except Exception as e:
        print(f"Error extracting shared strings: {e}")
        return {}

def extract_from_worksheet(zip_file, sheet_name, shared_strings):
    """Extract products from a specific worksheet"""
    products = []
    
    try:
        sheet_content = zip_file.read(sheet_name).decode('utf-8')
        
        # Find sheetData section
        if '<sheetData>' not in sheet_content:
            return products
        
        # Extract sheetData content
        start = sheet_content.find('<sheetData>')
        end = sheet_content.find('</sheetData>')
        if start == -1 or end == -1:
            return products
        
        sheet_data = sheet_content[start:end+12]
        
        # Parse rows
        rows = []
        row_tags = sheet_data.split('<row')
        
        for row_content in row_tags[1:]:  # Skip first empty element
            # Extract row number
            row_match = re.search(r'r="(\d+)"', row_content)
            if not row_match:
                continue
            
            row_num = int(row_match.group(1))
            
            # Extract cells from row
            cells = []
            cell_tags = row_content.split('<c')
            
            for cell_content in cell_tags[1:]:  # Skip first empty element
                # Extract cell reference and value
                ref_match = re.search(r'r="([A-Z]+)(\d+)"', cell_content)
                value_match = re.search(r'<v>([^<]+)</v>', cell_content)
                type_match = re.search(r't="([^"]*)"', cell_content)
                
                if ref_match:
                    col = ref_match.group(1)
                    cell_row = int(ref_match.group(2))
                    value = value_match.group(1) if value_match else ''
                    cell_type = type_match.group(1) if type_match else ''
                    
                    cells.append({
                        'col': col,
                        'row': cell_row,
                        'value': value,
                        'type': cell_type
                    })
            
            if cells:
                rows.append({
                    'row_num': row_num,
                    'cells': cells
                })
        
        # Process rows to find products
        if rows:
            products = process_worksheet_rows(rows, shared_strings, sheet_name)
        
        return products
        
    except Exception as e:
        print(f"Error processing {sheet_name}: {e}")
        return []

def process_worksheet_rows(rows, shared_strings, sheet_name):
    """Process worksheet rows to find products"""
    products = []
    
    if not rows:
        return products
    
    # First row should be headers
    header_row = rows[0]
    headers = []
    
    # Extract headers from first row
    for cell in header_row['cells']:
        if cell['type'] == 's':  # Shared string
            try:
                index = int(cell['value'])
                header_text = shared_strings.get(index, '')
            except ValueError:
                header_text = cell['value']
            headers.append(header_text)
        else:
            headers.append(str(cell['value']))
    
    print(f"  Headers: {headers}")
    
    # Process data rows
    for row in rows[1:]:
        if len(row['cells']) < len(headers):
            continue
        
        # Create product data
        product_data = {}
        for i, cell in enumerate(row['cells']):
            if i < len(headers):
                header = headers[i]
                if cell['type'] == 's':  # Shared string
                    try:
                        index = int(cell['value'])
                        value = shared_strings.get(index, '')
                    except ValueError:
                        value = cell['value']
                else:
                    value = str(cell['value'])
                
                product_data[header] = value
        
        # Check if this is a product row
        if is_product_row(product_data):
            product = create_product_from_data(product_data, sheet_name)
            if product:
                products.append(product)
    
    return products

def extract_from_shared_strings(shared_strings):
    """Extract products directly from shared strings"""
    products = []
    
    # Look for numbered products in shared strings
    for index, text in shared_strings.items():
        # Look for patterns like "123. Product Name" or "123 Product Name"
        patterns = [
            r'^(\d+)\.\s*([А-Я][^.\n]*?)(?:\.|$|\n)',
            r'^(\d+)\s+([А-Я][^.\n]*?)(?:\.|$|\n)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.MULTILINE | re.DOTALL)
            if match:
                try:
                    product_number = int(match.group(1))
                    product_name = match.group(2).strip()
                    
                    if len(product_name) < 3:
                        continue
                    
                    # Clean up product name
                    product_name = re.sub(r'[^\w\s-]', '', product_name)
                    product_name = product_name.strip()
                    
                    if len(product_name) < 3:
                        continue
                    
                    # Create product entry
                    product = {
                        'id': f"000{product_number:03d}",
                        'number': product_number,
                        'title': product_name,
                        'short_description': product_name,
                        'long_description': text,
                        'category_id': 1,  # Default category
                        'subcategory': '',
                        'weight': '',
                        'price': '',
                        'image': f"p_000{product_number:03d}_1.jpg",
                        'source': 'shared_strings',
                        'excel_id': str(index),
                        'ukr_name': product_name,
                        'rus_name': product_name
                    }
                    
                    products.append(product)
                    break  # Only process first match per text
                    
                except Exception as e:
                    print(f"Error processing shared string {index}: {e}")
                    continue
    
    return products

def is_product_row(product_data):
    """Check if row contains product data"""
    # Look for key fields
    key_fields = ['id', 'Название', 'image', 'Name', 'name', '№', 'ID']
    
    for field in key_fields:
        if any(key.startswith(field) for key in product_data.keys()):
            return True
    
    return False

def create_product_from_data(product_data, sheet_name):
    """Create product object from row data"""
    try:
        # Extract basic information - try different possible field names
        product_id = (product_data.get('id', '') or 
                     product_data.get('ID', '') or 
                     product_data.get('№', ''))
        
        # Try different name field variations
        ukr_name = (product_data.get('Название (укр)', '') or 
                   product_data.get('Название', '') or
                   product_data.get('name (ukr)', '') or
                   product_data.get('name', '') or
                   product_data.get('Name', ''))
        
        rus_name = (product_data.get('Название (рус)', '') or
                   product_data.get('name (ru)', ''))
        
        ukr_desc = (product_data.get('Описание (укр)', '') or
                   product_data.get('description (ukr)', '') or
                   product_data.get('Description', ''))
        
        rus_desc = (product_data.get('Описание (рус)', '') or
                   product_data.get('description (ru)', ''))
        
        ukr_short = (product_data.get('Короткое Описание (укр)', '') or
                     product_data.get('Short description', ''))
        
        rus_short = product_data.get('Короткое Описание (рус)', '')
        
        image = (product_data.get('image', '') or
                product_data.get('Images', '') or
                product_data.get('productImageUrl', ''))
        
        # Use Ukrainian name if available, otherwise Russian, otherwise any available
        name = ukr_name if ukr_name else rus_name
        description = ukr_desc if ukr_desc else rus_desc
        short_desc = ukr_short if ukr_short else rus_desc
        
        if not name:
            return None
        
        # Try to extract product number
        product_number = extract_product_number(name, product_id)
        
        # Determine category
        category_id = determine_category(name, description)
        
        return {
            'id': f"{category_id:02d}{product_number:03d}",
            'number': product_number,
            'title': name.strip(),
            'short_description': short_desc[:100] + "..." if short_desc and len(short_desc) > 100 else short_desc,
            'long_description': description,
            'category_id': category_id,
            'subcategory': determine_subcategory(name, description),
            'weight': extract_weight(description),
            'price': '',
            'image': f"p_{category_id:02d}{product_number:03d}_1.jpg",
            'source': f'excel_{sheet_name}',
            'excel_id': product_id,
            'ukr_name': ukr_name,
            'rus_name': rus_name
        }
    
    except Exception as e:
        print(f"Error creating product: {e}")
        return None

def determine_category(product_name, description):
    """Determine product category based on name and description"""
    text = (product_name + " " + description).lower()
    
    category_mapping = {
        'томат': 19,  # томаты
        'огур': 33,   # огурцы
        'перец': 10,  # перец
        'капуст': 4, # капуста
        'редис': 31,  # редис
        'свекл': 13,  # свекла
        'тыкв': 3,   # тыквы
        'фасол': 29,  # фасоль
        'цвет': 21,   # цветы
        'лук': 37,   # лук
        'морков': 34, # морковь
        'кабач': 32, # кабачки
        'кукуруз': 26, # кукуруза
        'арбуз': 36, # арбузы
        'баклажан': 1, # баклажан
        'дын': 14,   # дыни
        'земляник': 17, # земляника
        'лекарствен': 15, # лекарственные растения
        'пряно': 20, # пряно-вкусовые культуры
        'газон': 12, # газонные травы
        'многолет': 5, # многолетники
        'однолет': 7, # однолетники
        'лукович': 30, # луковичные
        'патиссон': 2, # патиссон
        'салат': 8,   # салат
        'шпинат': 8,  # салат
        'щавел': 8,   # салат
        'петрушк': 20, # пряно-вкусовые культуры
        'кинз': 20,   # пряно-вкусовые культуры
        'укроп': 20,  # пряно-вкусовые культуры
        'базилик': 20, # пряно-вкусовые культуры
        'майоран': 20, # пряно-вкусовые культуры
        'тимьян': 20, # пряно-вкусовые культуры
        'розмарин': 20, # пряно-вкусовые культуры
        'орегано': 20, # пряно-вкусовые культуры
        'мята': 20,   # пряно-вкусовые культуры
        'мелисса': 20, # пряно-вкусовые культуры
        'лаванда': 20, # пряно-вкусовые культуры
        'шалфей': 20, # пряно-вкусовые культуры
        'ромашка': 15, # лекарственные растения
        'календула': 15, # лекарственные растения
        'эхинацея': 15, # лекарственные растения
        'зверобой': 15, # лекарственные растения
        'пустырник': 15, # лекарственные растения
        'валериана': 15, # лекарственные растения
        'мать-и-мачеха': 15, # лекарственные растения
        'подорожник': 15, # лекарственные растения
        'крапива': 15, # лекарственные растения
        'одуванчик': 15, # лекарственные растения
        'полынь': 15, # лекарственные растения
        'тысячелистник': 15, # лекарственные растения
        'чистотел': 15, # лекарственные растения
        'золототысячник': 15, # лекарственные растения
        'бессмертник': 15, # лекарственные растения
        'пижма': 15, # лекарственные растения
        'девясил': 15, # лекарственные растения
        'алтей': 15, # лекарственные растения
        'солодка': 15, # лекарственные растения
        'душица': 20, # пряно-вкусовые культуры
        'чабер': 20, # пряно-вкусовые культуры
        'майоран': 20, # пряно-вкусовые культуры
        'кориандр': 20, # пряно-вкусовые культуры
        'тмин': 20,   # пряно-вкусовые культуры
        'анис': 20,   # пряно-вкусовые культуры
        'фенхель': 20, # пряно-вкусовые культуры
        'укроп': 20,  # пряно-вкусовые культуры
        'базилик': 20, # пряно-вкусовые культуры
        'мята': 20,   # пряно-вкусовые культуры
        'мелисса': 20, # пряно-вкусовые культуры
        'лаванда': 20, # пряно-вкусовые культуры
        'шалфей': 20, # пряно-вкусовые культуры
        'розмарин': 20, # пряно-вкусовые культуры
        'тимьян': 20, # пряно-вкусовые культуры
        'орегано': 20, # пряно-вкусовые культуры
        'майоран': 20, # пряно-вкусовые культуры
        'чабер': 20, # пряно-вкусовые культуры
        'кориандр': 20, # пряно-вкусовые культуры
        'тмин': 20,   # пряно-вкусовые культуры
        'анис': 20,   # пряно-вкусовые культуры
        'фенхель': 20, # пряно-вкусовые культуры
    }
    
    for keyword, cat_id in category_mapping.items():
        if keyword in text:
            return cat_id
    
    # Default to first category if no match found
    return 1

def determine_subcategory(product_name, description):
    """Determine product subcategory"""
    text = (product_name + " " + description).lower()
    
    subcategories = {
        'гибрид': 'Гибрид',
        'f1': 'Гибрид F1',
        'раннеспел': 'Раннеспелый',
        'среднеспел': 'Среднеспелый',
        'позднеспел': 'Позднеспелый',
        'ультраскороспел': 'Ультраскороспелый',
        'скороспел': 'Скороспелый',
        'салатн': 'Салатный',
        'засолочн': 'Засолочный',
        'консервн': 'Консервный',
        'универсал': 'Универсальный',
        'детерминант': 'Детерминантный',
        'индетерминант': 'Индетерминантный',
        'партенокарп': 'Партенокарпический',
        'пчелоопыля': 'Пчелоопыляемый',
        'самоопыля': 'Самоопыляемый'
    }
    
    for keyword, subcat in subcategories.items():
        if keyword in text:
            return subcat
    
    return ''

def extract_weight(description):
    """Extract weight information from description"""
    if not description:
        return ''
    
    weight_patterns = [
        r'массой\s+(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
        r'весом\s+(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
        r'масса\s+(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
        r'(\d+(?:-\d+)?)\s*(?:гр?|г|кг)',
    ]
    
    for pattern in weight_patterns:
        match = re.search(pattern, description, re.IGNORECASE)
        if match:
            weight = match.group(1)
            if 'кг' in description.lower():
                try:
                    if '-' in weight:
                        parts = weight.split('-')
                        weight = f"{float(parts[0])*1000:.0f}-{float(parts[1])*1000:.0f}"
                    else:
                        weight = f"{float(weight)*1000:.0f}"
                except:
                    pass
            return weight
    
    return ''

def extract_product_number(name, product_id):
    """Extract product number from name or ID"""
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

def remove_duplicates(products):
    """Remove duplicate products based on product number"""
    unique_products = {}
    
    for product in products:
        product_number = product.get('number', 0)
        if product_number not in unique_products:
            unique_products[product_number] = product
        else:
            # Keep the one with more complete data
            existing = unique_products[product_number]
            if len(product.get('long_description', '')) > len(existing.get('long_description', '')):
                unique_products[product_number] = product
    
    return list(unique_products.values())

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
    print("Starting complete Excel product extraction...")
    
    # Extract all products from Excel
    all_products = extract_all_products()
    
    if all_products:
        # Save to CSV
        save_to_csv(all_products, 'excel_all_products.csv')
        
        # Print sample products
        print(f"\nSample products from Excel:")
        for i, product in enumerate(all_products[:5]):
            print(f"  {i+1}. {product.get('title', 'N/A')} (ID: {product.get('id', 'N/A')}, Source: {product.get('source', 'N/A')})")
        
        # Print summary
        print(f"\nComplete Excel Extraction Summary:")
        print(f"Total products: {len(all_products)}")
        
        # Count products by source
        source_counts = {}
        for product in all_products:
            source = product.get('source', 'unknown')
            source_counts[source] = source_counts.get(source, 0) + 1
        
        print(f"\nProducts by source:")
        for source, count in source_counts.items():
            print(f"  {source}: {count}")
        
        # Show product number range
        numbers = [p.get('number', 0) for p in all_products if p.get('number', 0) > 0]
        if numbers:
            print(f"\nProduct number range: {min(numbers)} - {max(numbers)}")
        
    else:
        print("No products extracted from Excel")

if __name__ == "__main__":
    main()