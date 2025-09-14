-- Fix OpenCart Store Configuration
-- This script addresses the issue where products/categories exist in DB but don't show in UI

-- 1. Create default store if it doesn't exist
INSERT IGNORE INTO oc_store (store_id, name, url, ssl) 
VALUES (0, 'Default Store', 'http://localhost:8080/', 'http://localhost:8080/');

-- 2. Set up essential store settings
INSERT IGNORE INTO oc_setting (store_id, `code`, `key`, `value`, serialized) VALUES 
(0, 'config', 'config_language', 'uk-ua', 0),
(0, 'config', 'config_currency', 'UAH', 0),
(0, 'config', 'config_admin_language', 'uk-ua', 0),
(0, 'config', 'config_name', 'Fun Dacha', 0),
(0, 'config', 'config_owner', 'Fun Dacha', 0),
(0, 'config', 'config_address', 'Ukraine', 0),
(0, 'config', 'config_email', 'admin@fundacha.com', 0),
(0, 'config', 'config_telephone', '+380123456789', 0),
(0, 'config', 'config_status', '1', 0),
(0, 'config', 'config_meta_title', 'Fun Dacha - Семена и рассада', 0),
(0, 'config', 'config_meta_description', 'Качественные семена и рассада для вашего сада', 0),
(0, 'config', 'config_meta_keyword', 'семена, рассада, сад, огород', 0);

-- 3. Ensure all products are assigned to store 0
INSERT IGNORE INTO oc_product_to_store (product_id, store_id)
SELECT p.product_id, 0 FROM oc_product p 
WHERE NOT EXISTS (SELECT 1 FROM oc_product_to_store pts WHERE pts.product_id = p.product_id AND pts.store_id = 0);

-- 4. Ensure all categories are assigned to store 0
INSERT IGNORE INTO oc_category_to_store (category_id, store_id)
SELECT c.category_id, 0 FROM oc_category c 
WHERE NOT EXISTS (SELECT 1 FROM oc_category_to_store cts WHERE cts.category_id = c.category_id AND cts.store_id = 0);

-- 5. Create default layout
INSERT IGNORE INTO oc_layout (layout_id, name) VALUES (1, 'Home');

-- 6. Assign layout to store
INSERT IGNORE INTO oc_layout_route (layout_id, store_id, route) 
VALUES (1, 0, 'common/home');

-- 7. Set up default category layout
INSERT IGNORE INTO oc_layout_route (layout_id, store_id, route) 
VALUES (1, 0, 'product/category');

-- 8. Set up default product layout
INSERT IGNORE INTO oc_layout_route (layout_id, store_id, route) 
VALUES (1, 0, 'product/product');

-- 9. Ensure all products have proper status and are visible
UPDATE oc_product SET status = 1 WHERE status = 0;

-- 10. Ensure all categories have proper status and are visible
UPDATE oc_category SET status = 1 WHERE status = 0;

-- 11. Set up default store settings for SEO
INSERT IGNORE INTO oc_setting (store_id, `code`, `key`, `value`, serialized) VALUES 
(0, 'config', 'config_seo_url', '1', 0),
(0, 'config', 'config_robots', 'index,follow', 0);

-- 12. Set up default tax settings
INSERT IGNORE INTO oc_setting (store_id, `code`, `key`, `value`, serialized) VALUES 
(0, 'config', 'config_tax', '1', 0),
(0, 'config', 'config_tax_default', 'shipping', 0);

-- 13. Set up default customer settings
INSERT IGNORE INTO oc_setting (store_id, `code`, `key`, `value`, serialized) VALUES 
(0, 'config', 'config_customer_group_id', '1', 0),
(0, 'config', 'config_customer_online', '1', 0),
(0, 'config', 'config_customer_activity', '1', 0);

-- 14. Set up default checkout settings
INSERT IGNORE INTO oc_setting (store_id, `code`, `key`, `value`, serialized) VALUES 
(0, 'config', 'config_checkout_guest', '1', 0),
(0, 'config', 'config_checkout', '1', 0);

-- 15. Set up default stock settings
INSERT IGNORE INTO oc_setting (store_id, `code`, `key`, `value`, serialized) VALUES 
(0, 'config', 'config_stock_display', '1', 0),
(0, 'config', 'config_stock_warning', '1', 0),
(0, 'config', 'config_stock_checkout', '1', 0);

-- 16. Set up default image settings
INSERT IGNORE INTO oc_setting (store_id, `code`, `key`, `value`, serialized) VALUES 
(0, 'config', 'config_image_thumb_width', '228', 0),
(0, 'config', 'config_image_thumb_height', '228', 0),
(0, 'config', 'config_image_popup_width', '800', 0),
(0, 'config', 'config_image_popup_height', '800', 0),
(0, 'config', 'config_image_product_width', '228', 0),
(0, 'config', 'config_image_product_height', '228', 0),
(0, 'config', 'config_image_category_width', '228', 0),
(0, 'config', 'config_image_category_height', '228', 0);

-- 17. Verify the setup
SELECT 'Store Configuration' as check_type, COUNT(*) as count FROM oc_store;
SELECT 'Store Settings' as check_type, COUNT(*) as count FROM oc_setting WHERE store_id = 0;
SELECT 'Products in Store' as check_type, COUNT(*) as count FROM oc_product_to_store WHERE store_id = 0;
SELECT 'Categories in Store' as check_type, COUNT(*) as count FROM oc_category_to_store WHERE store_id = 0;
SELECT 'Layouts' as check_type, COUNT(*) as count FROM oc_layout;
SELECT 'Layout Routes' as check_type, COUNT(*) as count FROM oc_layout_route;