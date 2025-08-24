#!/usr/bin/env python3
import csv
import os
import re
import shutil
from typing import Dict, List, Optional, Tuple

BASE_DIR = "/workspace/data"
PRODUCTS_CSV = os.path.join(BASE_DIR, "products.csv")
CATEGORIES_CSV = os.path.join(BASE_DIR, "categories.csv")
IMAGES_DIR = os.path.join(BASE_DIR, "images")
PRODUCT_IMAGES_DIR = os.path.join(IMAGES_DIR, "products")
CATEGORY_IMAGES_DIR = os.path.join(IMAGES_DIR, "categories")

# Patterns for likely product image filenames when CSV has legacy naming
LEGACY_PRODUCT_PATTERNS = [
    "p_{id}_1.jpg",
    "p_{id}.jpg",
]


def ensure_dirs() -> None:
    os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
    os.makedirs(CATEGORY_IMAGES_DIR, exist_ok=True)


def load_csv(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
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


def zfill3(value: Optional[str]) -> Optional[str]:
    if value is None or str(value).strip() == "":
        return None
    try:
        n = int(str(value).strip())
    except Exception:
        return None
    return f"{n:03d}"


def product_id_last3(pid: str) -> Optional[str]:
    if not pid:
        return None
    try:
        n = int(pid)
    except Exception:
        return None
    return f"{n % 1000:03d}"


def find_product_image_file(image_value: str, product_id: str) -> Optional[str]:
    # 1) If CSV has an image filename and it exists in IMAGES_DIR, use it
    if image_value:
        candidate = os.path.join(IMAGES_DIR, image_value)
        if os.path.isfile(candidate):
            return candidate
        # Sometimes value may include a path like photos/..., ignore
        base = os.path.basename(image_value)
        candidate = os.path.join(IMAGES_DIR, base)
        if os.path.isfile(candidate):
            return candidate
    # 2) Try legacy patterns
    for pat in LEGACY_PRODUCT_PATTERNS:
        base = pat.format(id=product_id)
        candidate = os.path.join(IMAGES_DIR, base)
        if os.path.isfile(candidate):
            return candidate
    # 3) Fallback: search by prefix p_{id}
    prefix = f"p_{product_id}"
    for name in os.listdir(IMAGES_DIR):
        if name.lower().startswith(prefix.lower()) and name.lower().endswith(".jpg"):
            return os.path.join(IMAGES_DIR, name)
    return None


def update_products() -> Tuple[int, int]:
    rows, fields = load_csv(PRODUCTS_CSV)

    # Rename 'image' column to 'primary_image'
    if "primary_image" not in fields:
        if "image" in fields:
            fields = ["primary_image" if c == "image" else c for c in fields]
            for r in rows:
                r["primary_image"] = r.pop("image")
        else:
            fields.append("primary_image")
            for r in rows:
                r["primary_image"] = ""

    # Add SKU Number column
    if "SKU Number" not in fields:
        fields.append("SKU Number")
        for r in rows:
            r["SKU Number"] = ""

    moved = 0
    updated = 0

    for r in rows:
        pid = (r.get("id") or "").strip()
        cat3 = zfill3(r.get("category_id"))
        last3 = product_id_last3(pid)
        if not cat3 or not last3:
            # Cannot compute SKU without category and id
            continue
        sku = f"p{cat3}{last3}"
        r["SKU Number"] = sku

        # Locate source image
        src_img = find_product_image_file(r.get("primary_image", ""), pid)
        if src_img and os.path.isfile(src_img):
            # Destination filename
            dest_filename = f"{sku}.jpg"
            dest_img = os.path.join(PRODUCT_IMAGES_DIR, dest_filename)
            # Copy/move
            if os.path.abspath(src_img) != os.path.abspath(dest_img):
                os.makedirs(os.path.dirname(dest_img), exist_ok=True)
                shutil.copy2(src_img, dest_img)
                moved += 1
            # Update CSV to the new filename (no path)
            if r.get("primary_image") != dest_filename:
                r["primary_image"] = dest_filename
                updated += 1
        else:
            # If no image found, leave primary_image as-is
            pass

    write_csv(PRODUCTS_CSV, rows, fields)
    return moved, updated


def normalize(s: str) -> str:
    s = s.casefold()
    s = re.sub(r"\s+", "", s)
    s = s.replace("ё", "е")
    return s


def collect_category_candidate_images() -> Dict[str, str]:
    # Return map basename_normalized -> absolute_path for non-product images in IMAGES_DIR
    files = {}
    for name in os.listdir(IMAGES_DIR):
        path = os.path.join(IMAGES_DIR, name)
        if not os.path.isfile(path):
            continue
        # Skip product-like images
        if re.match(r"^p_[0-9]+(_\d+)?\.jpg$", name, re.IGNORECASE):
            continue
        if re.match(r"^p\d{6}\.jpg$", name, re.IGNORECASE):
            continue
        base_no_ext = os.path.splitext(name)[0]
        files[normalize(base_no_ext)] = path
    return files


def map_category_images() -> Tuple[int, int]:
    rows, fields = load_csv(CATEGORIES_CSV)
    if "primary_image" not in fields:
        fields.append("primary_image")
        for r in rows:
            r["primary_image"] = ""

    # Build product images lookup by category
    prod_rows, _ = load_csv(PRODUCTS_CSV)
    cat_to_product_image: Dict[str, str] = {}
    for pr in prod_rows:
        cid = (pr.get("category_id") or "").strip()
        img = (pr.get("primary_image") or "").strip()
        if cid and img:
            cat_to_product_image.setdefault(cid, img)

    candidate_images = collect_category_candidate_images()

    moved = 0
    updated = 0

    for r in rows:
        name = (r.get("name") or "").strip()
        cid = (r.get("id") or "").strip()
        if not name:
            continue
        chosen_abs: Optional[str] = None

        norm = normalize(name)
        # Direct match by name
        for key, path in candidate_images.items():
            if norm in key or key in norm:
                chosen_abs = path
                break

        # Fallback: use any product image in this category
        if chosen_abs is None and cid in cat_to_product_image:
            prod_img_name = cat_to_product_image[cid]
            prod_img_path = os.path.join(PRODUCT_IMAGES_DIR, prod_img_name)
            if os.path.isfile(prod_img_path):
                chosen_abs = prod_img_path

        if chosen_abs is None:
            continue

        # Move/copy chosen image into categories folder
        dest_filename = os.path.basename(chosen_abs)
        dest_path = os.path.join(CATEGORY_IMAGES_DIR, dest_filename)
        if os.path.abspath(chosen_abs) != os.path.abspath(dest_path):
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            shutil.copy2(chosen_abs, dest_path)
            moved += 1

        if r.get("primary_image") != dest_filename:
            r["primary_image"] = dest_filename
            updated += 1

    write_csv(CATEGORIES_CSV, rows, fields)
    return moved, updated


def main() -> int:
    ensure_dirs()
    prod_moved, prod_updated = update_products()
    cat_moved, cat_updated = map_category_images()
    print(
        f"Products: moved/copied {prod_moved} images; updated {prod_updated} rows.\n"
        f"Categories: moved/copied {cat_moved} images; updated {cat_updated} rows."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())