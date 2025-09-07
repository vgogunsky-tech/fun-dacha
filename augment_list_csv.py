#!/usr/bin/env python3
import csv
from pathlib import Path
import re

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

_TRANS = {
	'а':'a','б':'b','в':'v','г':'h','ґ':'g','д':'d','е':'e','є':'ie','ж':'zh','з':'z','и':'y','і':'i','ї':'i','й':'i',
	'к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'kh','ц':'ts','ч':'ch',
	'ш':'sh','щ':'shch','ь':'','ю':'iu','я':'ia',
	'А':'a','Б':'b','В':'v','Г':'h','Ґ':'g','Д':'d','Е':'e','Є':'ie','Ж':'zh','З':'z','И':'y','І':'i','Ї':'i','Й':'i',
	'К':'k','Л':'l','М':'m','Н':'n','О':'o','П':'p','Р':'r','С':'s','Т':'t','У':'u','Ф':'f','Х':'kh','Ц':'ts','Ч':'ch',
	'Ш':'sh','Щ':'shch','Ь':'','Ю':'iu','Я':'ia',
	'ъ':'','Ъ':'','ё':'e','Ё':'e','э':'e','Э':'e','ы':'y','Ы':'y'
}

def slugify(text: str) -> str:
	if not text:
		return ''
	# transliterate
	buf = ''.join(_TRANS.get(ch, ch) for ch in text)
	# lower, replace non-alnum with hyphen
	buf = buf.lower()
	buf = re.sub(r"[^a-z0-9]+", "-", buf)
	buf = re.sub(r"-+", "-", buf).strip('-')
	return buf

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
		# Populate SEO if empty
		if not (r.get('seo') or '').strip():
			name = (r.get('Название (укр)') or r.get('Название (рус)') or '').strip()
			candidate = slugify(name)
			if not candidate:
				candidate = (r.get('product_id') or r.get('model') or '').lower()
			r['seo'] = candidate

	with LIST_PATH.open('w', encoding='utf-8', newline='') as f:
		writer = csv.DictWriter(f, fieldnames=new_headers)
		writer.writeheader()
		for r in rows:
			writer.writerow(r)
	print(f"Added columns: {', '.join(missing)}")

if __name__ == '__main__':
	main()