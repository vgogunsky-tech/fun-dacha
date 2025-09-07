#!/usr/bin/env python3
import csv
from collections import defaultdict
from pathlib import Path

INVENTORY_PATH = Path('data/inventory.csv')
OUT_SQL = Path('inventory_options.sql')

SMALL_UA = 'Маленький пакет'
MEDIUM_UA = 'Середній пакет'
LARGE_UA = 'Великий пакет'

SMALL_RU = 'Маленький  пакет'
MEDIUM_RU = 'Средний  пакет'
LARGE_RU = 'Большой  пакет'

LANG_UA = 2
LANG_RU = 3

HEADERS_REQUIRED = {
	'product_id', 'title_ua', 'title_ru', 'original_price', 'stock_qty'
}


def load_inventory():
	if not INVENTORY_PATH.exists():
		raise SystemExit('data/inventory.csv not found')
	with INVENTORY_PATH.open('r', encoding='utf-8') as f:
		reader = csv.DictReader(f)
		missing = HEADERS_REQUIRED - set(reader.fieldnames or [])
		if missing:
			raise SystemExit(f'inventory.csv missing columns: {missing}')
		by_prod = defaultdict(list)
		for row in reader:
			pid = (row.get('product_id') or '').strip()
			if not pid:
				continue
			by_prod[pid].append(row)
		return by_prod


def write_sql(by_prod):
	lines = []
	lines.append("USE opencart;\n")
	# Ensure stock statuses exist is assumed set outside.
	# Create/find 'Пакет' option
	lines += [
		"-- Ensure option 'Пакет' exists",
		"INSERT INTO oc_option (type, sort_order) SELECT 'select', 0 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM oc_option_description WHERE name='Пакет' LIMIT 1);",
		"SET @opt_id := (SELECT option_id FROM oc_option_description WHERE name='Пакет' LIMIT 1);",
		f"INSERT IGNORE INTO oc_option_description (option_id, language_id, name) VALUES (@opt_id, {LANG_UA}, 'Пакет');",
		f"INSERT IGNORE INTO oc_option_description (option_id, language_id, name) VALUES (@opt_id, {LANG_RU}, 'Пакет');",
		"",
		"-- Ensure option values exist for the option",
		f"INSERT INTO oc_option_value (option_id, image, sort_order) SELECT @opt_id, '', 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM oc_option_value_description WHERE name='{SMALL_UA}' AND option_id=@opt_id LIMIT 1);",
		f"SET @ov_small := (SELECT ov.option_value_id FROM oc_option_value_description ovd JOIN oc_option_value ov ON ovd.option_value_id=ov.option_value_id WHERE ovd.option_id=@opt_id AND ovd.name='{SMALL_UA}' LIMIT 1);",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_small, {LANG_UA}, @opt_id, '{SMALL_UA}');",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_small, {LANG_RU}, @opt_id, '{SMALL_RU}');",
		"",
		f"INSERT INTO oc_option_value (option_id, image, sort_order) SELECT @opt_id, '', 2 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM oc_option_value_description WHERE name='{MEDIUM_UA}' AND option_id=@opt_id LIMIT 1);",
		f"SET @ov_medium := (SELECT ov.option_value_id FROM oc_option_value_description ovd JOIN oc_option_value ov ON ovd.option_value_id=ov.option_value_id WHERE ovd.option_id=@opt_id AND ovd.name='{MEDIUM_UA}' LIMIT 1);",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_medium, {LANG_UA}, @opt_id, '{MEDIUM_UA}');",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_medium, {LANG_RU}, @opt_id, '{MEDIUM_RU}');",
		"",
		f"INSERT INTO oc_option_value (option_id, image, sort_order) SELECT @opt_id, '', 3 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM oc_option_value_description WHERE name='{LARGE_UA}' AND option_id=@opt_id LIMIT 1);",
		f"SET @ov_large := (SELECT ov.option_value_id FROM oc_option_value_description ovd JOIN oc_option_value ov ON ovd.option_value_id=ov.option_value_id WHERE ovd.option_id=@opt_id AND ovd.name='{LARGE_UA}' LIMIT 1);",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_large, {LANG_UA}, @opt_id, '{LARGE_UA}');",
		f"INSERT IGNORE INTO oc_option_value_description (option_value_id, language_id, option_id, name) VALUES (@ov_large, {LANG_RU}, @opt_id, '{LARGE_RU}');",
		""
	]

	# Per product, attach option and its values with prices
	for model, variants in by_prod.items():
		lines += [
			f"-- Attach options for product model={model}",
			f"SET @pid := (SELECT product_id FROM oc_product WHERE model='{model}' LIMIT 1);",
			"SET @poid := NULL;",
			"IF @pid IS NOT NULL THEN",
			"  SET @poid := (SELECT product_option_id FROM oc_product_option WHERE product_id=@pid AND option_id=@opt_id LIMIT 1);",
			"  IF @poid IS NULL THEN",
			"    INSERT INTO oc_product_option (product_id, option_id, required) VALUES (@pid, @opt_id, 1);",
			"    SET @poid := LAST_INSERT_ID();",
			"  END IF;",
		]
		# Remove existing product option values for clean reattach
		lines.append("  DELETE FROM oc_product_option_value WHERE product_id=@pid AND option_id=@opt_id;")

		# Determine presence of titles in this product's variants and their prices
		# Build a map title -> price
		def parse_price(s):
			try:
				return float(s)
			except:
				return 0.0

		present = {}
		for v in variants:
			tua = (v.get('title_ua') or '').strip()
			price = parse_price(v.get('original_price'))
			qty = int((v.get('stock_qty') or '0') or 0)
			present[tua] = (price, qty)

		# Always ensure at least small and large; use defaults if missing
		pairs = [
			(SMALL_UA, '@ov_small'),
			(MEDIUM_UA, '@ov_medium'),
			(LARGE_UA, '@ov_large'),
		]
		for name, ov_var in pairs:
			price, qty = present.get(name, (0.0, 0))
			# Insert row only if present or if it's small/large to guarantee two options
			must_have = name in (SMALL_UA, LARGE_UA)
			if must_have or name in present:
				# price_prefix '=' sets absolute price; if 0 price, we fall back to product price in UI
				lines.append(
					f"  INSERT INTO oc_product_option_value (product_option_id, product_id, option_id, option_value_id, quantity, subtract, price, price_prefix, points, points_prefix, weight, weight_prefix) "
					f"VALUES (@poid, @pid, @opt_id, {ov_var}, {max(qty, 0)}, 1, {price:.2f}, '=', 0, '+', 0, '+');"
				)

		lines.append("END IF;\n")

	OUT_SQL.write_text("\n".join(lines), encoding='utf-8')
	print(f"Wrote SQL to {OUT_SQL}")


def main():
	by_prod = load_inventory()
	write_sql(by_prod)

if __name__ == '__main__':
	main()