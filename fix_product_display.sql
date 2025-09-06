-- Fix Product Display Issues
-- This script fixes common issues that prevent products from showing in OpenCart

USE opencart;

-- Ensure products are enabled
UPDATE oc_product SET status = 1 WHERE product_id > 0;

-- Ensure categories are enabled
UPDATE oc_category SET status = 1 WHERE category_id > 0;

-- Add products to store (if oc_product_to_store table exists)
INSERT IGNORE INTO oc_product_to_store (product_id, store_id) 
SELECT product_id, 0 FROM oc_product WHERE product_id > 0;

-- Add categories to store (if oc_category_to_store table exists)
INSERT IGNORE INTO oc_category_to_store (category_id, store_id) 
SELECT category_id, 0 FROM oc_category WHERE category_id > 0;

-- Set proper stock status
UPDATE oc_product SET stock_status_id = 5 WHERE product_id > 0; -- In Stock

-- Set proper quantity
UPDATE oc_product SET quantity = 10 WHERE product_id > 0;

-- Set proper date available
UPDATE oc_product SET date_available = CURDATE() WHERE product_id > 0;

-- Set proper sort order
UPDATE oc_product SET sort_order = product_id WHERE product_id > 0;
UPDATE oc_category SET sort_order = category_id WHERE category_id > 0;

-- Ensure products have proper SEO URLs (if oc_seo_url table exists)
INSERT IGNORE INTO oc_seo_url (store_id, language_id, query, keyword) 
SELECT 0, 1, CONCAT('product_id=', product_id), CONCAT('product-', product_id) 
FROM oc_product WHERE product_id > 0;

INSERT IGNORE INTO oc_seo_url (store_id, language_id, query, keyword) 
SELECT 0, 1, CONCAT('category_id=', category_id), CONCAT('category-', category_id) 
FROM oc_category WHERE category_id > 0;

-- Set proper layout for categories (if oc_category_to_layout table exists)
INSERT IGNORE INTO oc_category_to_layout (category_id, store_id, layout_id) 
SELECT category_id, 0, 0 FROM oc_category WHERE category_id > 0;

-- Set proper layout for products (if oc_product_to_layout table exists)
INSERT IGNORE INTO oc_product_to_layout (product_id, store_id, layout_id) 
SELECT product_id, 0, 0 FROM oc_product WHERE product_id > 0;