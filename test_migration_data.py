#!/usr/bin/env python3
"""
Test script to verify CSV data before migration
"""

import csv
import json
import os

def test_csv_data():
    """Test and display CSV data structure"""
    
    print("🔍 Testing CSV data structure...")
    print("=" * 50)
    
    # Test categories
    categories_file = '/workspace/data/categories_list.csv'
    if os.path.exists(categories_file):
        print(f"\n📁 Categories file: {categories_file}")
        with open(categories_file, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            categories = list(reader)
            print(f"   Total categories: {len(categories)}")
            print("   Sample categories:")
            for i, cat in enumerate(categories[:3]):
                print(f"     {i+1}. ID: {cat['id']}, Name: {cat['name']}, Parent: {cat['parentId']}")
    else:
        print(f"❌ Categories file not found: {categories_file}")
    
    # Test products
    products_file = '/workspace/data/list.csv'
    if os.path.exists(products_file):
        print(f"\n📁 Products file: {products_file}")
        with open(products_file, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            products = list(reader)
            print(f"   Total products: {len(products)}")
            print("   Sample products:")
            for i, product in enumerate(products[:3]):
                print(f"     {i+1}. ID: {product['id']}")
                print(f"        Ukrainian: {product['Название (укр)']}")
                print(f"        Russian: {product['Название (рус)']}")
                print(f"        Category: {product['category_id']}")
                print(f"        Image: {product['primary_image']}")
                print(f"        Tags: {product['tags']}")
    else:
        print(f"❌ Products file not found: {products_file}")
    
    # Check for images
    images_dir = '/workspace/data/images'
    if os.path.exists(images_dir):
        print(f"\n📁 Images directory: {images_dir}")
        product_images = os.path.join(images_dir, 'products')
        if os.path.exists(product_images):
            image_files = [f for f in os.listdir(product_images) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.gif'))]
            print(f"   Product images found: {len(image_files)}")
        else:
            print("   No product images directory found")
    else:
        print(f"❌ Images directory not found: {images_dir}")
    
    print("\n" + "=" * 50)
    print("✅ Data structure test completed!")

if __name__ == "__main__":
    test_csv_data()