#!/usr/bin/env python3
"""
OpenCart Migration Script (without Docker)
This script can be used if you have direct database access
"""

import sys
import os
sys.path.append('/workspace')

from opencart_migration import OpenCartMigrator

def main():
    print("🚀 OpenCart Migration (Direct Database Access)")
    print("=" * 50)
    
    # Get database configuration from user
    print("Please provide database connection details:")
    host = input("Database host [localhost]: ").strip() or "localhost"
    port = input("Database port [3306]: ").strip() or "3306"
    user = input("Database user [root]: ").strip() or "root"
    password = input("Database password: ").strip()
    database = input("Database name [opencart]: ").strip() or "opencart"
    
    # Database configuration
    db_config = {
        'host': host,
        'port': int(port),
        'user': user,
        'password': password,
        'database': database,
        'charset': 'utf8mb4',
        'collation': 'utf8mb4_general_ci'
    }
    
    # File paths
    categories_file = '/workspace/data/categories_list.csv'
    products_file = '/workspace/data/list.csv'
    
    # Verify files exist
    if not os.path.exists(categories_file):
        print(f"❌ Categories file not found: {categories_file}")
        return False
    
    if not os.path.exists(products_file):
        print(f"❌ Products file not found: {products_file}")
        return False
    
    # Create migrator instance
    migrator = OpenCartMigrator(db_config)
    
    # Run migration
    success = migrator.migrate(categories_file, products_file)
    
    if success:
        print("✅ Migration completed successfully!")
        print("Check migration.log for detailed information.")
    else:
        print("❌ Migration failed!")
        print("Check migration.log for error details.")
        return False
    
    return True

if __name__ == "__main__":
    main()