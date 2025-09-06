#!/usr/bin/env python3
"""
Image Migration Script for OpenCart
Copies product and category images to OpenCart image directory
"""

import os
import shutil
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def migrate_images():
    """Migrate images from data/images to OpenCart image directory"""
    
    # Source directories
    source_product_images = '/workspace/data/images/products'
    source_category_images = '/workspace/data/images/categories'
    
    # OpenCart image directories (adjust paths based on your OpenCart installation)
    opencart_image_dir = '/workspace/opencart-docker/opencart_data/image'
    opencart_product_dir = os.path.join(opencart_image_dir, 'catalog', 'product')
    opencart_category_dir = os.path.join(opencart_image_dir, 'catalog', 'category')
    
    # Create directories if they don't exist
    os.makedirs(opencart_product_dir, exist_ok=True)
    os.makedirs(opencart_category_dir, exist_ok=True)
    
    migrated_count = 0
    
    # Migrate product images
    if os.path.exists(source_product_images):
        logger.info(f"Migrating product images from {source_product_images}")
        for filename in os.listdir(source_product_images):
            if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp')):
                source_path = os.path.join(source_product_images, filename)
                dest_path = os.path.join(opencart_product_dir, filename)
                
                try:
                    shutil.copy2(source_path, dest_path)
                    logger.info(f"Copied product image: {filename}")
                    migrated_count += 1
                except Exception as e:
                    logger.error(f"Error copying {filename}: {e}")
    else:
        logger.warning(f"Product images directory not found: {source_product_images}")
    
    # Migrate category images
    if os.path.exists(source_category_images):
        logger.info(f"Migrating category images from {source_category_images}")
        for filename in os.listdir(source_category_images):
            if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp')):
                source_path = os.path.join(source_category_images, filename)
                dest_path = os.path.join(opencart_category_dir, filename)
                
                try:
                    shutil.copy2(source_path, dest_path)
                    logger.info(f"Copied category image: {filename}")
                    migrated_count += 1
                except Exception as e:
                    logger.error(f"Error copying {filename}: {e}")
    else:
        logger.warning(f"Category images directory not found: {source_category_images}")
    
    logger.info(f"Image migration completed. Total images migrated: {migrated_count}")
    return migrated_count

def migrate_images_docker():
    """Migrate images using Docker containers"""
    import subprocess
    
    logger.info("Migrating images using Docker...")
    
    # Source directories
    source_product_images = '/workspace/data/images/products'
    source_category_images = '/workspace/data/images/categories'
    
    # OpenCart container paths
    container_image_dir = '/var/www/html/image'
    container_product_dir = os.path.join(container_image_dir, 'catalog', 'product')
    container_category_dir = os.path.join(container_image_dir, 'catalog', 'category')
    
    migrated_count = 0
    
    try:
        # Create directories in container
        subprocess.run([
            'docker', 'compose', '-f', '/workspace/opencart-docker/docker-compose.yml', 
            'exec', 'web', 'mkdir', '-p', container_product_dir, container_category_dir
        ], check=True)
        
        # Copy product images
        if os.path.exists(source_product_images):
            for filename in os.listdir(source_product_images):
                if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp')):
                    source_path = os.path.join(source_product_images, filename)
                    dest_path = f"web:{container_product_dir}/{filename}"
                    
                    subprocess.run([
                        'docker', 'compose', '-f', '/workspace/opencart-docker/docker-compose.yml',
                        'cp', source_path, dest_path
                    ], check=True)
                    logger.info(f"Copied product image: {filename}")
                    migrated_count += 1
        
        # Copy category images
        if os.path.exists(source_category_images):
            for filename in os.listdir(source_category_images):
                if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp')):
                    source_path = os.path.join(source_category_images, filename)
                    dest_path = f"web:{container_category_dir}/{filename}"
                    
                    subprocess.run([
                        'docker', 'compose', '-f', '/workspace/opencart-docker/docker-compose.yml',
                        'cp', source_path, dest_path
                    ], check=True)
                    logger.info(f"Copied category image: {filename}")
                    migrated_count += 1
        
        logger.info(f"Docker image migration completed. Total images migrated: {migrated_count}")
        return migrated_count
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Error during Docker image migration: {e}")
        return 0

def main():
    """Main function"""
    print("🖼️  OpenCart Image Migration")
    print("=" * 40)
    
    # Check if Docker is available
    import shutil
    if shutil.which('docker'):
        print("🐳 Docker detected. Using Docker migration...")
        migrated_count = migrate_images_docker()
    else:
        print("📁 Docker not available. Using direct file migration...")
        migrated_count = migrate_images()
    
    if migrated_count > 0:
        print(f"✅ Successfully migrated {migrated_count} images!")
    else:
        print("❌ No images were migrated. Check the logs for details.")

if __name__ == "__main__":
    main()