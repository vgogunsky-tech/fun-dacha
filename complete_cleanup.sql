-- Complete OpenCart Database Cleanup
-- This script completely removes all products, categories, and related data

USE opencart;

-- Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

-- Remove all product-related data
DELETE FROM oc_product_to_category;
DELETE FROM oc_product_description;
DELETE FROM oc_product_to_store;
DELETE FROM oc_product_to_layout;
DELETE FROM oc_product_attribute;
DELETE FROM oc_product_filter;
DELETE FROM oc_product_image;
DELETE FROM oc_product_option;
DELETE FROM oc_product_option_value;
DELETE FROM oc_product_related;
DELETE FROM oc_product_reward;
DELETE FROM oc_product_special;
DELETE FROM oc_product_to_download;
DELETE FROM oc_product_to_layout;
DELETE FROM oc_product_to_store;
DELETE FROM oc_product_viewed;
DELETE FROM oc_product;

-- Remove all category-related data
DELETE FROM oc_category_path;
DELETE FROM oc_category_description;
DELETE FROM oc_category_to_store;
DELETE FROM oc_category_to_layout;
DELETE FROM oc_category_filter;
DELETE FROM oc_category;

-- Remove all attribute-related data
DELETE FROM oc_attribute_description;
DELETE FROM oc_attribute_group_description;
DELETE FROM oc_attribute_group;
DELETE FROM oc_attribute;

-- Remove any other product-related tables that might exist
DELETE FROM oc_banner;
DELETE FROM oc_banner_image;
DELETE FROM oc_banner_image_description;

-- Reset auto-increment counters
ALTER TABLE oc_product AUTO_INCREMENT = 1;
ALTER TABLE oc_category AUTO_INCREMENT = 1;
ALTER TABLE oc_attribute AUTO_INCREMENT = 1;
ALTER TABLE oc_attribute_group AUTO_INCREMENT = 1;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Verify cleanup
SELECT 'Products remaining:' as status, COUNT(*) as count FROM oc_product;
SELECT 'Categories remaining:' as status, COUNT(*) as count FROM oc_category;
SELECT 'Product descriptions remaining:' as status, COUNT(*) as count FROM oc_product_description;
SELECT 'Category descriptions remaining:' as status, COUNT(*) as count FROM oc_category_description;