#!/usr/bin/env python3
import csv
from pathlib import Path

LIST_PATH = Path('data/list.csv')

NEEDED_COLUMNS = [
	'price',
	'weight',
	'length',
	'width',
	'height',
	'model',
	'seo'
]

DEFAULTS = {
	'price': '',
	'weight': '',
	'length': '',
	'width': '',
	'height': '',
	'model': '',
	'seo': ''
}

def main():
	if not LIST_PATH.exists():
		raise SystemExit('data/list.csv not found')

	with LIST_PATH.open('r', encoding='utf-8') as f:
		reader = csv.DictReader(f)
		rows = list(reader)
		headers = reader.fieldnames or []

	missing = [c for c in NEEDED_COLUMNS if c not in headers]
	if not missing:
		print('No header changes needed.')
		return

	new_headers = headers + missing
	for r in rows:
		for m in missing:
			if m not in r:
				r[m] = DEFAULTS.get(m, '')
		# Populate model with product_id if empty
		if (not r.get('model')) and r.get('product_id'):
			r['model'] = r['product_id']

	with LIST_PATH.open('w', encoding='utf-8', newline='') as f:
		writer = csv.DictWriter(f, fieldnames=new_headers)
		writer.writeheader()
		for r in rows:
			writer.writerow(r)
	print(f"Added columns: {', '.join(missing)}")

if __name__ == '__main__':
	main()