import csv
import os
from typing import List, Dict, Tuple, Set
from slugify import slugify


def read_csv(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []
    return rows, fields


def write_csv(path: str, rows: List[Dict[str, str]], fields: List[str]) -> None:
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)


def ensure_seo_for_categories(categories_csv: str) -> int:
    rows, fields = read_csv(categories_csv)
    changed = 0
    if "seo" not in fields:
        fields.append("seo")
        for r in rows:
            r["seo"] = ""
    existing: Set[str] = set()
    # collect existing seos to avoid duplicates
    for r in rows:
        s = (r.get("seo") or "").strip()
        if s:
            existing.add(s)
    for r in rows:
        if (r.get("seo") or "").strip():
            continue
        name = (r.get("name") or "").strip()
        tag = (r.get("tag") or "").strip()
        cid = (r.get("id") or "").strip()
        base = slugify(name or tag or f"category-{cid}")
        candidate = base
        # ensure uniqueness
        if candidate in existing:
            candidate = f"{base}-{cid}" if cid else f"{base}-cat"
        r["seo"] = candidate
        existing.add(candidate)
        changed += 1
    write_csv(categories_csv, rows, fields)
    return changed


def ensure_seo_for_products(list_csv: str) -> int:
    rows, fields = read_csv(list_csv)
    changed = 0
    if "seo" not in fields:
        fields.append("seo")
        for r in rows:
            r["seo"] = ""
    existing: Set[str] = set()
    for r in rows:
        s = (r.get("seo") or "").strip()
        if s:
            existing.add(s)
    for r in rows:
        if (r.get("seo") or "").strip():
            continue
        title = (r.get("Название (укр)") or r.get("Название (рус)") or "").strip()
        pid = (r.get("id") or "").strip()
        sku = (r.get("product_id") or "").strip()
        base = slugify(title) if title else (sku if sku else f"product-{pid}")
        candidate = base
        if candidate in existing:
            candidate = f"{base}-{pid}" if pid else f"{base}-p"
        r["seo"] = candidate
        existing.add(candidate)
        changed += 1
    write_csv(list_csv, rows, fields)
    return changed


def main() -> None:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    categories_csv = os.path.join(base_dir, "data", "categories_list.csv")
    list_csv = os.path.join(base_dir, "data", "list.csv")
    c = ensure_seo_for_categories(categories_csv)
    p = ensure_seo_for_products(list_csv)
    print(f"seo updated: categories={c}, products={p}")


if __name__ == "__main__":
    main()

