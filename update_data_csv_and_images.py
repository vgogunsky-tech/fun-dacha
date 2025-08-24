#!/usr/bin/env python3
import csv
import os
import re
import shutil
from typing import Dict, List, Optional, Tuple

BASE_DIR = "/workspace/data"
LIST_CSV = os.path.join(BASE_DIR, "list.csv")
CATEGORIES_LIST_CSV = os.path.join(BASE_DIR, "categories_list.csv")
PROD_IMG_DIR = os.path.join(BASE_DIR, "images", "products")
CAT_IMG_DIR = os.path.join(BASE_DIR, "images", "categories")

os.makedirs(PROD_IMG_DIR, exist_ok=True)
os.makedirs(CAT_IMG_DIR, exist_ok=True)


def read_csv(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []
    return rows, fields


def write_csv(path: str, rows: List[Dict[str, str]], fields: List[str]) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp, path)


def z3(n: float) -> str:
    try:
        i = int(float(n))
    except Exception:
        i = 0
    return f"{i % 1000:03d}"


def zcat(cat: str) -> Optional[str]:
    if not cat or str(cat).strip() == "":
        return None
    try:
        i = int(float(cat))
        return f"{i:03d}"
    except Exception:
        return None


def normalize_name(s: str) -> str:
    s = s or ""
    s = s.casefold()
    s = re.sub(r"\s+", "", s)
    s = s.replace("ё", "е")
    return s


def build_photo_index() -> Dict[str, str]:
    # Map of base filename -> absolute path for product images
    idx: Dict[str, str] = {}
    for name in os.listdir(PROD_IMG_DIR):
        path = os.path.join(PROD_IMG_DIR, name)
        if os.path.isfile(path):
            idx[name] = path
    return idx


def update_products_list() -> Tuple[int, int]:
    rows, fields = read_csv(LIST_CSV)

    # Ensure columns
    if "SKU Number" not in fields:
        fields.append("SKU Number")
        for r in rows:
            r["SKU Number"] = ""
    if "primary_image" not in fields:
        if "image" in fields:
            fields = ["primary_image" if c == "image" else c for c in fields]
            for r in rows:
                r["primary_image"] = r.pop("image")
        else:
            fields.append("primary_image")
            for r in rows:
                r["primary_image"] = ""

    photo_idx = build_photo_index()

    renamed = 0
    updated = 0

    for r in rows:
        pid = r.get("id", "").strip()
        cat = r.get("category_id", "").strip()
        if not pid or not cat:
            continue
        cat3 = zcat(cat)
        pid3 = z3(pid)
        if not cat3:
            continue
        sku = f"p{cat3}{pid3}"
        r["SKU Number"] = sku

        # Resolve current image filename
        cur = (r.get("primary_image") or "").strip()
        cur_base = os.path.basename(cur)
        src_path: Optional[str] = None
        if cur_base and cur_base in photo_idx:
            src_path = photo_idx[cur_base]
        elif cur_base and os.path.isfile(os.path.join(PROD_IMG_DIR, cur_base)):
            src_path = os.path.join(PROD_IMG_DIR, cur_base)
        else:
            # Try to find by photo_* prefix inside products images
            candidates = [n for n in photo_idx.keys() if normalize_name(n).startswith("photo_")]
            # Heuristic: skip, require explicit current mapping
            src_path = None

        if src_path and os.path.isfile(src_path):
            new_name = f"{sku}.jpg"
            dst = os.path.join(PROD_IMG_DIR, new_name)
            if os.path.abspath(src_path) != os.path.abspath(dst):
                shutil.copy2(src_path, dst)
                renamed += 1
            if r.get("primary_image") != new_name:
                r["primary_image"] = new_name
                updated += 1
        else:
            # No image found -> leave blank if not set to new scheme
            if r.get("primary_image") and not re.match(r"^p\d{6}\.jpg$", r["primary_image"], re.I):
                # Keep existing value as a fallback
                pass

    write_csv(LIST_CSV, rows, fields)
    return renamed, updated


def map_category_images() -> Tuple[int, int]:
    rows, fields = read_csv(CATEGORIES_LIST_CSV)
    if "primary_image" not in fields:
        fields.append("primary_image")
        for r in rows:
            r["primary_image"] = ""

    # Build candidate images index by normalized base name
    idx: Dict[str, str] = {}
    for name in os.listdir(CAT_IMG_DIR):
        path = os.path.join(CAT_IMG_DIR, name)
        if os.path.isfile(path):
            base = os.path.splitext(name)[0]
            idx[normalize_name(base)] = path

    updated = 0

    for r in rows:
        name = r.get("name", "")
        if not name:
            continue
        key = normalize_name(name)
        chosen: Optional[str] = None
        # Direct or contains match
        for idx_key, p in idx.items():
            if key in idx_key or idx_key in key:
                chosen = p
                break
        if chosen is None:
            # Try tag
            tag = normalize_name(r.get("tag", ""))
            if tag and tag in idx:
                chosen = idx[tag]

        if chosen is None:
            continue

        dest_name = os.path.basename(chosen)
        dest = os.path.join(CAT_IMG_DIR, dest_name)
        if not os.path.isfile(dest):
            shutil.copy2(chosen, dest)
        if r.get("primary_image") != dest_name:
            r["primary_image"] = dest_name
            updated += 1

    write_csv(CATEGORIES_LIST_CSV, rows, fields)
    return updated, updated


def main() -> int:
    prod_renamed, prod_updated = update_products_list()
    cat_mapped, _ = map_category_images()
    print(f"Products: renamed/copied {prod_renamed}, updated rows {prod_updated}. Categories updated {cat_mapped}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())