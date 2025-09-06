-- Basic Language Setup for OpenCart
-- This script uses only the most basic columns that should exist in any OpenCart

USE opencart;

-- Add Ukrainian language with only basic columns
INSERT IGNORE INTO oc_language (language_id, name, code, status) 
VALUES (2, 'Українська', 'ua', 1);

-- Add Russian language with only basic columns
INSERT IGNORE INTO oc_language (language_id, name, code, status) 
VALUES (3, 'Русский', 'ru', 1);

-- Ensure English is language_id = 1
UPDATE oc_language SET language_id = 1 WHERE code = 'en' AND language_id != 1;

-- Verify language setup
SELECT 'Languages configured:' as status;
SELECT language_id, name, code, status FROM oc_language ORDER BY language_id;