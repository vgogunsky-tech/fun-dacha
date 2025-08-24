#!/usr/bin/env python3
import csv
import os
from typing import Dict, List, Optional, Tuple

from flask import Flask, render_template, request, redirect, url_for, send_from_directory, abort, flash

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")
PRODUCTS_CSV = os.path.join(DATA_DIR, "list.csv")
CATEGORIES_CSV = os.path.join(DATA_DIR, "categories_list.csv")
CATEGORY_IMAGES_DIR = os.path.join(DATA_DIR, "images", "categories")
PRODUCT_IMAGES_DIR = os.path.join(DATA_DIR, "images", "products")

REQUIRED_PRODUCT_COLS = [
    "validated",
    "price",
    "quantity",
    "year",
    "weight",
    "availability",
]

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-secret-key")


# -------------------- CSV helpers --------------------

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


def ensure_product_columns() -> None:
    rows, fields = read_csv(PRODUCTS_CSV)
    changed = False
    for col in REQUIRED_PRODUCT_COLS:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = ""
            changed = True
    if changed:
        write_csv(PRODUCTS_CSV, rows, fields)


# -------------------- Data helpers --------------------

def load_categories() -> List[Dict[str, str]]:
    rows, _ = read_csv(CATEGORIES_CSV)
    return rows


def load_products() -> List[Dict[str, str]]:
    rows, _ = read_csv(PRODUCTS_CSV)
    return rows


def find_category_image(cid: str) -> Optional[str]:
    # Prefer c{cid}.jpg then {cid}.jpg
    candidates = [f"c{cid}.jpg", f"{cid}.jpg"]
    for name in candidates:
        path = os.path.join(CATEGORY_IMAGES_DIR, name)
        if os.path.isfile(path):
            return name
    return None


def build_product_image_name(category_id: str, product_id: str) -> str:
    # Build name p{category}{last3_of_id}.jpg
    try:
        cat_int = int(float(category_id))
    except Exception:
        cat_int = 0
    try:
        pid_int = int(float(product_id))
    except Exception:
        pid_int = 0
    cat3 = f"{cat_int:03d}"
    pid3 = f"{pid_int % 1000:03d}"
    return f"p{cat3}{pid3}.jpg"


def get_unvalidated_products_by_category(category_id: str) -> List[Dict[str, str]]:
    products = load_products()
    result: List[Dict[str, str]] = []
    for r in products:
        cat = (r.get("category_id") or "").strip()
        if cat != str(int(float(category_id))):
            # category_id is stored as int-like in CSV
            continue
        validated = (r.get("validated") or "").strip()
        if validated and validated != "0":
            continue
        result.append(r)
    # Sort by numeric id
    result.sort(key=lambda x: float(x.get("id", "0") or 0.0))
    return result


# -------------------- Routes to serve images --------------------

@app.route("/images/categories/<path:filename>")
def serve_category_image(filename: str):
    path = os.path.join(CATEGORY_IMAGES_DIR, filename)
    if not os.path.isfile(path):
        abort(404)
    return send_from_directory(CATEGORY_IMAGES_DIR, filename)


@app.route("/images/products/<path:filename>")
def serve_product_image(filename: str):
    path = os.path.join(PRODUCT_IMAGES_DIR, filename)
    if not os.path.isfile(path):
        abort(404)
    return send_from_directory(PRODUCT_IMAGES_DIR, filename)


# -------------------- UI Routes --------------------

@app.route("/")
def index():
    ensure_product_columns()
    cats = load_categories()
    # Only show categories where id ends with 0 (root categories)
    root_cats: List[Dict[str, str]] = []
    for c in cats:
        cid = (c.get("id") or "").strip()
        if not cid:
            continue
        try:
            cid_int = int(float(cid))
        except Exception:
            continue
        if cid_int % 10 != 0:
            continue
        img = find_category_image(str(cid_int))
        root_cats.append({
            "id": str(cid_int),
            "name": c.get("name") or "",
            "image": img,
        })
    root_cats.sort(key=lambda x: int(x["id"]))
    return render_template("index.html", categories=root_cats)


@app.route("/category/<int:category_id>")
def category(category_id: int):
    # Redirect to first unvalidated product in this category
    return redirect(url_for("product", category_id=category_id, index=0))


@app.route("/product")
def product():
    category_id = request.args.get("category_id", type=int)
    index = request.args.get("index", default=0, type=int)
    if category_id is None:
        return redirect(url_for("index"))

    products = get_unvalidated_products_by_category(str(category_id))
    total = len(products)
    if total == 0:
        flash("No unvalidated products in this category.")
        return render_template("product.html", category_id=category_id, product=None, index=0, total=0)

    if index < 0:
        index = 0
    if index >= total:
        index = total - 1

    p = products[index]

    # Build image URL if available
    img_name = (p.get("primary_image") or "").strip()
    img_url = None
    if img_name:
        if os.path.isfile(os.path.join(PRODUCT_IMAGES_DIR, img_name)):
            img_url = url_for("serve_product_image", filename=img_name)

    # Categories for selects
    cats = load_categories()
    # Subcategories mapping
    parent_to_children: Dict[str, List[Dict[str, str]]] = {}
    for c in cats:
        pid = (c.get("parentId") or "").strip()
        if pid:
            parent_to_children.setdefault(pid, []).append(c)

    return render_template(
        "product.html",
        category_id=category_id,
        product=p,
        index=index,
        total=total,
        image_url=img_url,
        categories=cats,
        parent_to_children=parent_to_children,
    )


@app.route("/product/save", methods=["POST"])
def product_save():
    form = request.form
    files = request.files

    product_id = form.get("id", "").strip()
    if not product_id:
        abort(400)

    # Load CSV
    rows, fields = read_csv(PRODUCTS_CSV)

    # Ensure required columns
    for col in REQUIRED_PRODUCT_COLS:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = ""

    # Update product row
    target: Optional[Dict[str, str]] = None
    for r in rows:
        if (r.get("id") or "").strip() == product_id:
            target = r
            break
    if target is None:
        abort(404)

    # Update editable fields
    # Titles/descriptions
    for key in [
        "Название (укр)",
        "Название (рус)",
        "Описание (укр)",
        "Описание (рус)",
    ]:
        if key in form:
            target[key] = form.get(key, "")

    # Category/subcategory
    if "category_id" in form and form.get("category_id"): 
        target["category_id"] = str(int(float(form.get("category_id"))))
    if "subcategory_id" in form:
        sub_val = form.get("subcategory_id", "").strip()
        target["subcategory_id"] = sub_val

    # Price, quantity, year
    target["price"] = form.get("price", "").strip()
    target["quantity"] = form.get("quantity", "").strip()
    target["year"] = form.get("year", "").strip()
    # Weight (grams) and availability (0/1/2)
    target["weight"] = form.get("weight", "").strip()
    target["availability"] = form.get("availability", "").strip()

    # Handle image upload
    image_file = files.get("image")
    if image_file and image_file.filename:
        # Compute destination filename
        dest_name = build_product_image_name(target.get("category_id", ""), target.get("id", ""))
        os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
        dest_path = os.path.join(PRODUCT_IMAGES_DIR, dest_name)
        image_file.save(dest_path)
        target["primary_image"] = dest_name

    # Mark validated
    target["validated"] = "1"

    write_csv(PRODUCTS_CSV, rows, fields)

    # Redirect to next product in category
    category_id = target.get("category_id", "")
    try:
        cat_int = int(float(category_id)) if category_id else None
    except Exception:
        cat_int = None
    next_index = (request.args.get("index", type=int) or 0) + 1
    if cat_int is None:
        return redirect(url_for("index"))
    return redirect(url_for("product", category_id=cat_int, index=next_index))


# -------------------- Category creation --------------------

@app.post("/categories/create")
def categories_create():
    form = request.form
    files = request.files

    cid_raw = (form.get("id") or "").strip()
    name = (form.get("name") or "").strip()
    parentId = (form.get("parentId") or "").strip()
    tag = (form.get("tag") or "").strip()
    description = (form.get("description") or "").strip()

    if not cid_raw or not name:
        flash("Category ID and name are required.")
        return redirect(url_for("index"))

    try:
        cid_int = int(float(cid_raw))
    except Exception:
        flash("Category ID must be an integer.")
        return redirect(url_for("index"))

    # Load existing categories
    rows, fields = read_csv(CATEGORIES_CSV)

    # Ensure primary_image column exists
    if "primary_image" not in fields:
        fields.append("primary_image")
        for r in rows:
            r["primary_image"] = ""

    # Check uniqueness
    for r in rows:
        if (r.get("id") or "").strip() == str(cid_int):
            flash("Category ID already exists.")
            return redirect(url_for("index"))

    # Handle optional image upload
    image_file = files.get("image")
    primary_image = ""
    if image_file and image_file.filename:
        os.makedirs(CATEGORY_IMAGES_DIR, exist_ok=True)
        primary_image = f"c{cid_int}.jpg"
        dest_path = os.path.join(CATEGORY_IMAGES_DIR, primary_image)
        image_file.save(dest_path)

    # Append new row
    new_row = {
        "id": str(cid_int),
        "name": name,
        "parentId": str(int(float(parentId))) if parentId else "",
        "tag": tag,
        "description (ukr)": description,
        "primary_image": primary_image,
    }
    rows.append(new_row)

    write_csv(CATEGORIES_CSV, rows, fields)
    flash("Category created.")
    return redirect(url_for("index"))


if __name__ == "__main__":
    os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
    os.makedirs(CATEGORY_IMAGES_DIR, exist_ok=True)
    ensure_product_columns()
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=True)