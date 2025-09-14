USE opencart;

-- Ensure option exists and capture @opt_id
SET @opt_id := (SELECT option_id FROM oc_option_description WHERE name IN ('Пакет','Package') LIMIT 1);
INSERT INTO oc_option (type, sort_order) SELECT 'select', 0 FROM DUAL WHERE @opt_id IS NULL;
SET @opt_id := (SELECT option_id FROM oc_option ORDER BY option_id DESC LIMIT 1);
INSERT IGNORE INTO oc_option_description (option_id, language_id, name) VALUES (@opt_id, 1, 'Package');
INSERT IGNORE INTO oc_option_description (option_id, language_id, name) VALUES (@opt_id, 2, 'Пакет');
INSERT IGNORE INTO oc_option_description (option_id, language_id, name) VALUES (@opt_id, 3, 'Пакет');

-- Ensure option values exist and capture their ids (SMALL)
SET @ov_small := (SELECT ovd.option_value_id FROM oc_option_value_description ovd WHERE ovd.option_id=@opt_id AND ovd.name IN ('Маленький пакет','Small pack') LIMIT 1);
INSERT INTO oc_option_value (option_id, sort_order) SELECT @opt_id, 1 FROM DUAL WHERE @ov_small IS NULL;
SET @ov_small := (SELECT option_value_id FROM oc_option_value WHERE option_id=@opt_id AND sort_order=1 ORDER BY option_value_id DESC LIMIT 1);
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_small, 1, @opt_id, 'Small pack');
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_small, 2, @opt_id, 'Маленький пакет');
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_small, 3, @opt_id, 'Маленький  пакет');

-- MEDIUM
SET @ov_medium := (SELECT ovd.option_value_id FROM oc_option_value_description ovd WHERE ovd.option_id=@opt_id AND ovd.name IN ('Середній пакет','Medium pack') LIMIT 1);
INSERT INTO oc_option_value (option_id, sort_order) SELECT @opt_id, 2 FROM DUAL WHERE @ov_medium IS NULL;
SET @ov_medium := (SELECT option_value_id FROM oc_option_value WHERE option_id=@opt_id AND sort_order=2 ORDER BY option_value_id DESC LIMIT 1);
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_medium, 1, @opt_id, 'Medium pack');
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_medium, 2, @opt_id, 'Середній пакет');
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_medium, 3, @opt_id, 'Средний  пакет');

-- LARGE
SET @ov_large := (SELECT ovd.option_value_id FROM oc_option_value_description ovd WHERE ovd.option_id=@opt_id AND ovd.name IN ('Великий пакет','Large pack') LIMIT 1);
INSERT INTO oc_option_value (option_id, sort_order) SELECT @opt_id, 3 FROM DUAL WHERE @ov_large IS NULL;
SET @ov_large := (SELECT option_value_id FROM oc_option_value WHERE option_id=@opt_id AND sort_order=3 ORDER BY option_value_id DESC LIMIT 1);
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_large, 1, @opt_id, 'Large pack');
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_large, 2, @opt_id, 'Великий пакет');
INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_large, 3, @opt_id, 'Большой  пакет');

-- Attach options for product model=p100001
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100001' OR sku='p100001' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100002
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100002' OR sku='p100002' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100003
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100003' OR sku='p100003' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100004
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100004' OR sku='p100004' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100005
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100005' OR sku='p100005' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100006
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100006' OR sku='p100006' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100007
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100007' OR sku='p100007' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100008
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100008' OR sku='p100008' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100009
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100009' OR sku='p100009' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100010
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100010' OR sku='p100010' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100011
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100011' OR sku='p100011' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100012
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100012' OR sku='p100012' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100013
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100013' OR sku='p100013' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100014
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100014' OR sku='p100014' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100015
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100015' OR sku='p100015' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100016
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100016' OR sku='p100016' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100017
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100017' OR sku='p100017' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100018
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100018' OR sku='p100018' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100019
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100019' OR sku='p100019' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100020
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100020' OR sku='p100020' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100021
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100021' OR sku='p100021' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100022
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100022' OR sku='p100022' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100023
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100023' OR sku='p100023' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100024
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100024' OR sku='p100024' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100025
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100025' OR sku='p100025' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100026
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100026' OR sku='p100026' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100027
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100027' OR sku='p100027' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100028
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100028' OR sku='p100028' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100029
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100029' OR sku='p100029' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100030
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100030' OR sku='p100030' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100031
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100031' OR sku='p100031' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100032
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100032' OR sku='p100032' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100033
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100033' OR sku='p100033' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100034
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100034' OR sku='p100034' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100035
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100035' OR sku='p100035' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100036
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100036' OR sku='p100036' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100037
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100037' OR sku='p100037' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100038
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100038' OR sku='p100038' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100039
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100039' OR sku='p100039' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100040
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100040' OR sku='p100040' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100041
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100041' OR sku='p100041' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100042
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100042' OR sku='p100042' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100043
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100043' OR sku='p100043' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100044
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100044' OR sku='p100044' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100045
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100045' OR sku='p100045' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100046
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100046' OR sku='p100046' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100047
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100047' OR sku='p100047' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100048
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100048' OR sku='p100048' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100049
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100049' OR sku='p100049' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100050
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100050' OR sku='p100050' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100051
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100051' OR sku='p100051' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100052
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100052' OR sku='p100052' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100053
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100053' OR sku='p100053' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100054
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100054' OR sku='p100054' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100055
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100055' OR sku='p100055' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100056
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100056' OR sku='p100056' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100057
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100057' OR sku='p100057' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100058
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100058' OR sku='p100058' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100059
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100059' OR sku='p100059' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100060
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100060' OR sku='p100060' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100061
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100061' OR sku='p100061' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100062
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100062' OR sku='p100062' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100063
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100063' OR sku='p100063' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100064
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100064' OR sku='p100064' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100065
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100065' OR sku='p100065' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100066
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100066' OR sku='p100066' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100067
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100067' OR sku='p100067' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100068
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100068' OR sku='p100068' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100069
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100069' OR sku='p100069' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100070
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100070' OR sku='p100070' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100071
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100071' OR sku='p100071' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100072
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100072' OR sku='p100072' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100073
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100073' OR sku='p100073' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100074
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100074' OR sku='p100074' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100075
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100075' OR sku='p100075' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100076
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100076' OR sku='p100076' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100077
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100077' OR sku='p100077' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100078
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100078' OR sku='p100078' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100079
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100079' OR sku='p100079' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100080
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100080' OR sku='p100080' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100081
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100081' OR sku='p100081' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100082
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100082' OR sku='p100082' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100083
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100083' OR sku='p100083' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100084
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100084' OR sku='p100084' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100085
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100085' OR sku='p100085' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100086
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100086' OR sku='p100086' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100087
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100087' OR sku='p100087' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100088
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100088' OR sku='p100088' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100089
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100089' OR sku='p100089' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100090
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100090' OR sku='p100090' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100091
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100091' OR sku='p100091' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100093
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100093' OR sku='p100093' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100094
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100094' OR sku='p100094' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100095
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100095' OR sku='p100095' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100096
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100096' OR sku='p100096' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 100, 1, 5.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 300, stock_status_id = (CASE WHEN 300 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100097
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100097' OR sku='p100097' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p100099
SET @pid := (SELECT product_id FROM oc_product WHERE model='p100099' OR sku='p100099' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p330100
SET @pid := (SELECT product_id FROM oc_product WHERE model='p330100' OR sku='p330100' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110101
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110101' OR sku='p110101' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110102
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110102' OR sku='p110102' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110103
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110103' OR sku='p110103' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110104
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110104' OR sku='p110104' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110105
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110105' OR sku='p110105' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110106
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110106' OR sku='p110106' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110107
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110107' OR sku='p110107' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110108
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110108' OR sku='p110108' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110109
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110109' OR sku='p110109' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110110
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110110' OR sku='p110110' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110111
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110111' OR sku='p110111' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110112
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110112' OR sku='p110112' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110113
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110113' OR sku='p110113' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110114
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110114' OR sku='p110114' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110115
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110115' OR sku='p110115' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110116
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110116' OR sku='p110116' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110117
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110117' OR sku='p110117' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110118
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110118' OR sku='p110118' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110119
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110119' OR sku='p110119' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110120
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110120' OR sku='p110120' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110121
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110121' OR sku='p110121' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110122
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110122' OR sku='p110122' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110123
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110123' OR sku='p110123' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110124
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110124' OR sku='p110124' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110125
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110125' OR sku='p110125' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110126
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110126' OR sku='p110126' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110127
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110127' OR sku='p110127' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110128
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110128' OR sku='p110128' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110129
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110129' OR sku='p110129' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110130
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110130' OR sku='p110130' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110131
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110131' OR sku='p110131' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110133
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110133' OR sku='p110133' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110134
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110134' OR sku='p110134' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110135
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110135' OR sku='p110135' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110136
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110136' OR sku='p110136' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110137
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110137' OR sku='p110137' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110138
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110138' OR sku='p110138' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110139
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110139' OR sku='p110139' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110140
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110140' OR sku='p110140' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110141
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110141' OR sku='p110141' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110142
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110142' OR sku='p110142' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110143
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110143' OR sku='p110143' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110144
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110144' OR sku='p110144' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110145
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110145' OR sku='p110145' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110146
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110146' OR sku='p110146' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110147
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110147' OR sku='p110147' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110148
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110148' OR sku='p110148' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110149
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110149' OR sku='p110149' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110150
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110150' OR sku='p110150' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110151
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110151' OR sku='p110151' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110152
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110152' OR sku='p110152' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110153
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110153' OR sku='p110153' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110154
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110154' OR sku='p110154' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110155
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110155' OR sku='p110155' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110156
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110156' OR sku='p110156' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110157
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110157' OR sku='p110157' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110158
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110158' OR sku='p110158' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110159
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110159' OR sku='p110159' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110160
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110160' OR sku='p110160' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110161
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110161' OR sku='p110161' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110162
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110162' OR sku='p110162' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110163
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110163' OR sku='p110163' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110164
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110164' OR sku='p110164' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110165
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110165' OR sku='p110165' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110166
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110166' OR sku='p110166' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110167
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110167' OR sku='p110167' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110168
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110168' OR sku='p110168' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110169
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110169' OR sku='p110169' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110170
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110170' OR sku='p110170' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110171
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110171' OR sku='p110171' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110172
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110172' OR sku='p110172' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110173
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110173' OR sku='p110173' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110174
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110174' OR sku='p110174' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110175
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110175' OR sku='p110175' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110176
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110176' OR sku='p110176' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110177
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110177' OR sku='p110177' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110178
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110178' OR sku='p110178' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110179
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110179' OR sku='p110179' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110180
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110180' OR sku='p110180' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110181
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110181' OR sku='p110181' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110182
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110182' OR sku='p110182' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110183
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110183' OR sku='p110183' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110184
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110184' OR sku='p110184' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110185
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110185' OR sku='p110185' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110186
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110186' OR sku='p110186' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110187
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110187' OR sku='p110187' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110188
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110188' OR sku='p110188' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110189
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110189' OR sku='p110189' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110190
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110190' OR sku='p110190' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110191
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110191' OR sku='p110191' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110192
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110192' OR sku='p110192' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110193
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110193' OR sku='p110193' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110194
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110194' OR sku='p110194' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110195
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110195' OR sku='p110195' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110196
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110196' OR sku='p110196' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110197
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110197' OR sku='p110197' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110198
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110198' OR sku='p110198' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110199
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110199' OR sku='p110199' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p110200
SET @pid := (SELECT product_id FROM oc_product WHERE model='p110200' OR sku='p110200' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120201
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120201' OR sku='p120201' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120202
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120202' OR sku='p120202' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120203
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120203' OR sku='p120203' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120204
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120204' OR sku='p120204' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120205
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120205' OR sku='p120205' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120206
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120206' OR sku='p120206' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120207
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120207' OR sku='p120207' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120208
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120208' OR sku='p120208' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120209
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120209' OR sku='p120209' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120210
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120210' OR sku='p120210' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120211
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120211' OR sku='p120211' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120212
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120212' OR sku='p120212' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120213
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120213' OR sku='p120213' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120214
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120214' OR sku='p120214' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120215
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120215' OR sku='p120215' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120216
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120216' OR sku='p120216' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120217
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120217' OR sku='p120217' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120218
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120218' OR sku='p120218' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120219
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120219' OR sku='p120219' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120220
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120220' OR sku='p120220' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120221
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120221' OR sku='p120221' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120222
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120222' OR sku='p120222' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120223
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120223' OR sku='p120223' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120224
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120224' OR sku='p120224' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120225
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120225' OR sku='p120225' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120226
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120226' OR sku='p120226' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120227
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120227' OR sku='p120227' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120228
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120228' OR sku='p120228' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120229
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120229' OR sku='p120229' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120230
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120230' OR sku='p120230' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120231
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120231' OR sku='p120231' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120232
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120232' OR sku='p120232' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120233
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120233' OR sku='p120233' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120234
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120234' OR sku='p120234' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120235
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120235' OR sku='p120235' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120236
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120236' OR sku='p120236' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120237
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120237' OR sku='p120237' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120238
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120238' OR sku='p120238' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120239
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120239' OR sku='p120239' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p120240
SET @pid := (SELECT product_id FROM oc_product WHERE model='p120240' OR sku='p120240' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130241
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130241' OR sku='p130241' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130242
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130242' OR sku='p130242' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130243
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130243' OR sku='p130243' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130244
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130244' OR sku='p130244' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130245
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130245' OR sku='p130245' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130246
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130246' OR sku='p130246' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130248
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130248' OR sku='p130248' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130249
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130249' OR sku='p130249' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130250
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130250' OR sku='p130250' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130251
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130251' OR sku='p130251' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130252
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130252' OR sku='p130252' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130253
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130253' OR sku='p130253' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130254
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130254' OR sku='p130254' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130255
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130255' OR sku='p130255' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130256
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130256' OR sku='p130256' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130257
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130257' OR sku='p130257' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130258
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130258' OR sku='p130258' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130259
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130259' OR sku='p130259' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130260
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130260' OR sku='p130260' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130261
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130261' OR sku='p130261' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130262
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130262' OR sku='p130262' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130263
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130263' OR sku='p130263' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130264
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130264' OR sku='p130264' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130265
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130265' OR sku='p130265' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130266
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130266' OR sku='p130266' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130267
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130267' OR sku='p130267' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130268
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130268' OR sku='p130268' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130269
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130269' OR sku='p130269' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130270
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130270' OR sku='p130270' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130271
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130271' OR sku='p130271' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130272
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130272' OR sku='p130272' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130273
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130273' OR sku='p130273' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p130274
SET @pid := (SELECT product_id FROM oc_product WHERE model='p130274' OR sku='p130274' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140275
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140275' OR sku='p140275' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140276
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140276' OR sku='p140276' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140277
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140277' OR sku='p140277' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140278
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140278' OR sku='p140278' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140279
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140279' OR sku='p140279' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140280
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140280' OR sku='p140280' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140281
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140281' OR sku='p140281' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140282
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140282' OR sku='p140282' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140283
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140283' OR sku='p140283' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140284
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140284' OR sku='p140284' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140285
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140285' OR sku='p140285' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140286
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140286' OR sku='p140286' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140287
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140287' OR sku='p140287' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140288
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140288' OR sku='p140288' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140289
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140289' OR sku='p140289' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140290
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140290' OR sku='p140290' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140291
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140291' OR sku='p140291' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140292
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140292' OR sku='p140292' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140293
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140293' OR sku='p140293' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140294
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140294' OR sku='p140294' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p140295
SET @pid := (SELECT product_id FROM oc_product WHERE model='p140295' OR sku='p140295' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150296
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150296' OR sku='p150296' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150297
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150297' OR sku='p150297' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150298
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150298' OR sku='p150298' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150299
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150299' OR sku='p150299' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150300
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150300' OR sku='p150300' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150301
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150301' OR sku='p150301' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150302
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150302' OR sku='p150302' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p150303
SET @pid := (SELECT product_id FROM oc_product WHERE model='p150303' OR sku='p150303' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160304
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160304' OR sku='p160304' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160305
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160305' OR sku='p160305' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160306
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160306' OR sku='p160306' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160307
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160307' OR sku='p160307' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160308
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160308' OR sku='p160308' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160309
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160309' OR sku='p160309' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160310
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160310' OR sku='p160310' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160311
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160311' OR sku='p160311' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160312
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160312' OR sku='p160312' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160313
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160313' OR sku='p160313' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160314
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160314' OR sku='p160314' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160315
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160315' OR sku='p160315' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160316
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160316' OR sku='p160316' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160317
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160317' OR sku='p160317' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160318
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160318' OR sku='p160318' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160319
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160319' OR sku='p160319' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160320
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160320' OR sku='p160320' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160321
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160321' OR sku='p160321' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160322
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160322' OR sku='p160322' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160323
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160323' OR sku='p160323' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p160324
SET @pid := (SELECT product_id FROM oc_product WHERE model='p160324' OR sku='p160324' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170325
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170325' OR sku='p170325' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170326
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170326' OR sku='p170326' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170327
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170327' OR sku='p170327' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170328
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170328' OR sku='p170328' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170329
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170329' OR sku='p170329' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170330
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170330' OR sku='p170330' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170331
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170331' OR sku='p170331' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170332
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170332' OR sku='p170332' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170333
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170333' OR sku='p170333' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170334
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170334' OR sku='p170334' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170335
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170335' OR sku='p170335' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170336
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170336' OR sku='p170336' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170337
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170337' OR sku='p170337' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170338
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170338' OR sku='p170338' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170339
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170339' OR sku='p170339' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170340
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170340' OR sku='p170340' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170341
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170341' OR sku='p170341' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170342
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170342' OR sku='p170342' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p170343
SET @pid := (SELECT product_id FROM oc_product WHERE model='p170343' OR sku='p170343' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180344
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180344' OR sku='p180344' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180345
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180345' OR sku='p180345' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180346
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180346' OR sku='p180346' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180347
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180347' OR sku='p180347' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180348
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180348' OR sku='p180348' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180349
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180349' OR sku='p180349' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180350
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180350' OR sku='p180350' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180351
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180351' OR sku='p180351' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180352
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180352' OR sku='p180352' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180353
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180353' OR sku='p180353' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180354
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180354' OR sku='p180354' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180355
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180355' OR sku='p180355' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180356
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180356' OR sku='p180356' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180357
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180357' OR sku='p180357' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180358
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180358' OR sku='p180358' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180359
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180359' OR sku='p180359' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180360
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180360' OR sku='p180360' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180361
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180361' OR sku='p180361' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180362
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180362' OR sku='p180362' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180363
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180363' OR sku='p180363' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180364
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180364' OR sku='p180364' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180365
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180365' OR sku='p180365' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180366
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180366' OR sku='p180366' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180367
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180367' OR sku='p180367' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180368
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180368' OR sku='p180368' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180369
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180369' OR sku='p180369' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p180370
SET @pid := (SELECT product_id FROM oc_product WHERE model='p180370' OR sku='p180370' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190371
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190371' OR sku='p190371' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190372
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190372' OR sku='p190372' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190373
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190373' OR sku='p190373' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190374
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190374' OR sku='p190374' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190375
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190375' OR sku='p190375' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190376
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190376' OR sku='p190376' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190377
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190377' OR sku='p190377' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190378
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190378' OR sku='p190378' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190379
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190379' OR sku='p190379' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190380
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190380' OR sku='p190380' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190381
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190381' OR sku='p190381' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190382
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190382' OR sku='p190382' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190383
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190383' OR sku='p190383' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190384
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190384' OR sku='p190384' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190385
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190385' OR sku='p190385' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190386
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190386' OR sku='p190386' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190387
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190387' OR sku='p190387' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190388
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190388' OR sku='p190388' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p190389
SET @pid := (SELECT product_id FROM oc_product WHERE model='p190389' OR sku='p190389' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200390
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200390' OR sku='p200390' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200391
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200391' OR sku='p200391' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200392
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200392' OR sku='p200392' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200393
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200393' OR sku='p200393' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200394
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200394' OR sku='p200394' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200395
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200395' OR sku='p200395' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200396
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200396' OR sku='p200396' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200397
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200397' OR sku='p200397' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200398
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200398' OR sku='p200398' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200399
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200399' OR sku='p200399' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200400
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200400' OR sku='p200400' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200401
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200401' OR sku='p200401' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200402
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200402' OR sku='p200402' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200403
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200403' OR sku='p200403' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200404
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200404' OR sku='p200404' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p200405
SET @pid := (SELECT product_id FROM oc_product WHERE model='p200405' OR sku='p200405' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210406
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210406' OR sku='p210406' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210407
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210407' OR sku='p210407' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210408
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210408' OR sku='p210408' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210409
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210409' OR sku='p210409' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210410
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210410' OR sku='p210410' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210411
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210411' OR sku='p210411' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210412
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210412' OR sku='p210412' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p210413
SET @pid := (SELECT product_id FROM oc_product WHERE model='p210413' OR sku='p210413' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220414
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220414' OR sku='p220414' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220415
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220415' OR sku='p220415' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220416
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220416' OR sku='p220416' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 990.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 20.00, quantity = 400, stock_status_id = (CASE WHEN 400 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220417
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220417' OR sku='p220417' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220418
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220418' OR sku='p220418' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220419
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220419' OR sku='p220419' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220421
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220421' OR sku='p220421' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220422
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220422' OR sku='p220422' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220423
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220423' OR sku='p220423' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220424
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220424' OR sku='p220424' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220425
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220425' OR sku='p220425' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220426
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220426' OR sku='p220426' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220427
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220427' OR sku='p220427' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220428
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220428' OR sku='p220428' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p220429
SET @pid := (SELECT product_id FROM oc_product WHERE model='p220429' OR sku='p220429' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p230430
SET @pid := (SELECT product_id FROM oc_product WHERE model='p230430' OR sku='p230430' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p230431
SET @pid := (SELECT product_id FROM oc_product WHERE model='p230431' OR sku='p230431' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p230432
SET @pid := (SELECT product_id FROM oc_product WHERE model='p230432' OR sku='p230432' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p230433
SET @pid := (SELECT product_id FROM oc_product WHERE model='p230433' OR sku='p230433' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p240434
SET @pid := (SELECT product_id FROM oc_product WHERE model='p240434' OR sku='p240434' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p240435
SET @pid := (SELECT product_id FROM oc_product WHERE model='p240435' OR sku='p240435' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p240436
SET @pid := (SELECT product_id FROM oc_product WHERE model='p240436' OR sku='p240436' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p240437
SET @pid := (SELECT product_id FROM oc_product WHERE model='p240437' OR sku='p240437' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p240438
SET @pid := (SELECT product_id FROM oc_product WHERE model='p240438' OR sku='p240438' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;

-- Attach options for product model=p240439
SET @pid := (SELECT product_id FROM oc_product WHERE model='p240439' OR sku='p240439' LIMIT 1);
INSERT INTO oc_product_option (product_id, option_id, required) SELECT @pid, @opt_id, 1 FROM DUAL WHERE @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id);
SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);
DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_small, 100, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_medium, 0, 1, 0.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 0=1));
INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) SELECT @poid, @pid, @opt_id, @ov_large, 100, 1, 10.00, '+', 0, '+', 0, '+' FROM DUAL WHERE @poid IS NOT NULL AND ((SELECT 1 FROM DUAL WHERE 1=1) OR 1=1);
UPDATE oc_product SET price = 10.00, quantity = 200, stock_status_id = (CASE WHEN 200 > 0 THEN 5 ELSE 8 END) WHERE product_id=@pid;
