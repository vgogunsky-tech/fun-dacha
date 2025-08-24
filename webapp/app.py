#!/usr/bin/env python3
import csv
import os
import sys
import subprocess
from typing import Dict, List, Optional, Tuple

from flask import Flask, render_template, request, redirect, url_for, send_from_directory, abort, flash

if getattr(sys, "_MEIPASS", None):
    BASE_DIR = sys._MEIPASS
else:
    BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")
# Support either list.csv (current) or lists.csv (legacy)
PRODUCTS_CSV_PRIMARY = os.path.join(DATA_DIR, "list.csv")
PRODUCTS_CSV_ALT = os.path.join(DATA_DIR, "lists.csv")
CATEGORIES_CSV = os.path.join(DATA_DIR, "categories_list.csv")
CATEGORY_IMAGES_DIR = os.path.join(DATA_DIR, "images", "categories")
PRODUCT_IMAGES_DIR = os.path.join(DATA_DIR, "images", "products")

REQUIRED_PRODUCT_COLS = [
    "validated",
    "year",
    "availability",
    "SKU Number",
]

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-secret-key")

# -------------------- Git helpers --------------------

def _run_git(args: List[str]) -> Tuple[int, str, str]:
    try:
        result = subprocess.run(
            ["git"] + args,
            cwd=BASE_DIR,
            capture_output=True,
            text=True,
            check=False,
        )
        return result.returncode, (result.stdout or "").strip(), (result.stderr or "").strip()
    except Exception as e:
        return 1, "", str(e)


def _ensure_git_identity() -> None:
    code, out, _ = _run_git(["config", "--get", "user.name"])
    if code != 0 or not out:
        _run_git(["config", "user.name", os.environ.get("GIT_AUTHOR_NAME", "server-bot")])
    code, out, _ = _run_git(["config", "--get", "user.email"])
    if code != 0 or not out:
        _run_git(["config", "user.email", os.environ.get("GIT_AUTHOR_EMAIL", "server-bot@example.com")])


def commit_and_push(paths: List[str], message: str) -> None:
    try:
        _ensure_git_identity()
        target_remote = os.environ.get("GIT_TARGET_REMOTE", "origin")
        target_branch = os.environ.get("GIT_TARGET_BRANCH", "develop")
        # Stage specified paths
        _run_git(["add"] + paths)
        # Skip if nothing staged
        code, status, _ = _run_git(["status", "--porcelain"])
        if code != 0 or not (status or "").strip():
            return
        # Commit
        _run_git(["commit", "-m", message])
        # Push HEAD to target branch without changing current branch
        # This will create the branch on remote if it does not exist yet
        _run_git(["push", target_remote, f"HEAD:refs/heads/{target_branch}"])
    except Exception:
        # Never let git failures break the request path
        pass


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


def existing_product_csvs() -> List[str]:
    paths: List[str] = []
    if os.path.isfile(PRODUCTS_CSV_PRIMARY):
        paths.append(PRODUCTS_CSV_PRIMARY)
    if os.path.isfile(PRODUCTS_CSV_ALT):
        paths.append(PRODUCTS_CSV_ALT)
    if not paths:
        # default to primary if nothing exists yet
        paths.append(PRODUCTS_CSV_PRIMARY)
    return paths


def read_products_csv() -> Tuple[List[Dict[str, str]], List[str], str]:
    paths = existing_product_csvs()
    # Read from the first path
    rows, fields = read_csv(paths[0])
    return rows, fields, paths[0]


def write_products_csv(rows: List[Dict[str, str]], fields: List[str]) -> List[str]:
    paths = existing_product_csvs()
    for p in paths:
        # Ensure directory exists
        os.makedirs(os.path.dirname(p), exist_ok=True)
        write_csv(p, rows, fields)
    return paths


def ensure_product_columns() -> None:
    rows, fields, _ = read_products_csv()
    changed = False
    # Ensure essential columns
    for col in ["primary_image"] + REQUIRED_PRODUCT_COLS:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = ""
            changed = True
    if changed:
        write_products_csv(rows, fields)


# -------------------- Data helpers --------------------

def load_categories() -> List[Dict[str, str]]:
    rows, _ = read_csv(CATEGORIES_CSV)
    return rows


def load_products() -> List[Dict[str, str]]:
    rows, _, _ = read_products_csv()
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


def build_sku(category_id: str, product_id: str) -> str:
    try:
        cat_int = int(float(category_id))
    except Exception:
        cat_int = 0
    try:
        pid_int = int(float(product_id))
    except Exception:
        pid_int = 0
    return f"p{cat_int:03d}{pid_int % 1000:03d}"


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
    rows, fields, read_from = read_products_csv()

    # Ensure required columns
    for col in REQUIRED_PRODUCT_COLS + ["primary_image"]:
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

    # Year and availability
    target["year"] = form.get("year", "").strip()
    target["availability"] = form.get("availability", "").strip()

    # Handle image upload
    image_file = files.get("image")
    if image_file and image_file.filename:
        dest_name = build_product_image_name(target.get("category_id", ""), target.get("id", ""))
        os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
        dest_path = os.path.join(PRODUCT_IMAGES_DIR, dest_name)
        image_file.save(dest_path)
        target["primary_image"] = dest_name
        # Update SKU on image/category change
        target["SKU Number"] = build_sku(target.get("category_id", ""), target.get("id", ""))

    action = (form.get("action") or "").strip()
    advanced = False
    if action == "save_validate":
        target["validated"] = "1"
        advanced = True

    written_paths = write_products_csv(rows, fields)
    commit_and_push([DATA_DIR], f"Update product {product_id} via webapp")
    flash(("Saved and validated." if advanced else "Saved.") + " Files: " + ', '.join(os.path.relpath(p, BASE_DIR) for p in written_paths))

    # Redirect
    category_id = target.get("category_id", "")
    try:
        cat_int = int(float(category_id)) if category_id else None
    except Exception:
        cat_int = None
    if cat_int is None:
        return redirect(url_for("index"))

    if advanced:
        next_index = (request.args.get("index", type=int) or 0) + 1
    else:
        next_index = (request.args.get("index", type=int) or 0)
    return redirect(url_for("product", category_id=cat_int, index=next_index))


# -------------------- Product creation --------------------

@app.get("/product/new")
def product_new():
    category_id = request.args.get("category_id", type=int)
    cats = load_categories()
    parent_to_children: Dict[str, List[Dict[str, str]]] = {}
    for c in cats:
        pid = (c.get("parentId") or "").strip()
        if pid:
            parent_to_children.setdefault(pid, []).append(c)
    return render_template("product_new.html", category_id=category_id, categories=cats, parent_to_children=parent_to_children)


@app.post("/product/new")
def product_create():
    form = request.form
    files = request.files

    name_uk = (form.get("Название (укр)") or "").strip()
    desc_uk = (form.get("Описание (укр)") or "").strip()
    cat_id = (form.get("category_id") or "").strip()
    if not name_uk or not desc_uk or not cat_id:
        flash("Image, title and description and category are required.")
        return redirect(request.referrer or url_for('index'))

    image_file = files.get("image")
    if not image_file or not image_file.filename:
        flash("Image is required.")
        return redirect(request.referrer or url_for('index'))

    # Load existing
    rows, fields, _ = read_products_csv()
    # Ensure columns present
    for col in ["primary_image", "SKU Number"] + REQUIRED_PRODUCT_COLS:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = ""

    # Compute new unique id
    max_id = 0
    for r in rows:
        try:
            max_id = max(max_id, int(float((r.get("id") or "0").strip() or 0)))
        except Exception:
            pass
    new_id = max_id + 1

    # Save image and compute SKU
    image_name = build_product_image_name(cat_id, str(new_id))
    os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
    image_file.save(os.path.join(PRODUCT_IMAGES_DIR, image_name))

    sku = build_sku(cat_id, str(new_id))

    # Build new row
    new_row: Dict[str, str] = {
        "id": str(new_id),
        "Название (укр)": name_uk,
        "Название (рус)": (form.get("Название (рус)") or "").strip(),
        "Описание (укр)": desc_uk,
        "Описание (рус)": (form.get("Описание (рус)") or "").strip(),
        "primary_image": image_name,
        "category_id": str(int(float(cat_id))),
        "subcategory_id": (form.get("subcategory_id") or "").strip(),
        "SKU Number": sku,
        "validated": "0",
        "year": (form.get("year") or "").strip(),
        "availability": (form.get("availability") or "").strip(),
    }

    rows.append(new_row)
    write_products_csv(rows, fields)
    commit_and_push([DATA_DIR], f"Create product {new_id} via webapp")
    flash(f"Product created with ID {new_id}.")
    return redirect(url_for('product', category_id=int(float(cat_id)), index=0))


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
    return_to = (form.get("return_to") or "").strip()

    if not cid_raw or not name:
        flash("Category ID and name are required.")
        return redirect(return_to if return_to.startswith("/") else url_for("index"))

    try:
        cid_int = int(float(cid_raw))
    except Exception:
        flash("Category ID must be an integer.")
        return redirect(return_to if return_to.startswith("/") else url_for("index"))

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
            return redirect(return_to if return_to.startswith("/") else url_for("index"))

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
    commit_and_push([DATA_DIR], f"Create category {cid_int} via webapp")
    flash("Category created.")
    return redirect(return_to if return_to.startswith("/") else url_for("index"))

# -------------------- Category edit --------------------

@app.get("/category/<int:cid>/edit")
def category_edit(cid: int):
    rows, fields = read_csv(CATEGORIES_CSV)
    target: Optional[Dict[str, str]] = None
    for r in rows:
        try:
            if int(float((r.get("id") or "").strip() or 0)) == cid:
                target = r
                break
        except Exception:
            continue
    if target is None:
        abort(404)
    # Determine image
    img = target.get("primary_image") or ""
    if not img:
        # try to find by convention c{cid}.jpg
        candidate = f"c{cid}.jpg"
        if os.path.isfile(os.path.join(CATEGORY_IMAGES_DIR, candidate)):
            img = candidate
    return render_template("category_edit.html", category=target, cid=cid, image=img)


@app.post("/category/<int:cid>/edit")
def category_update(cid: int):
    form = request.form
    files = request.files

    rows, fields = read_csv(CATEGORIES_CSV)
    changed = False
    # Ensure primary_image column
    if "primary_image" not in fields:
        fields.append("primary_image")
        for r in rows:
            r["primary_image"] = ""
        changed = True

    target: Optional[Dict[str, str]] = None
    for r in rows:
        try:
            if int(float((r.get("id") or "").strip() or 0)) == cid:
                target = r
                break
        except Exception:
            continue
    if target is None:
        abort(404)

    # Update editable fields
    name = (form.get("name") or "").strip()
    descr = (form.get("description") or "").strip()
    tag = (form.get("tag") or "").strip()
    parentId = (form.get("parentId") or "").strip()

    if name:
        target["name"] = name
        changed = True
    target["description (ukr)"] = descr
    target["tag"] = tag
    target["parentId"] = str(int(float(parentId))) if parentId else ""

    # Image handling
    image_file = files.get("image")
    remove_image = (form.get("remove_image") or "") == "1"
    if remove_image:
        target["primary_image"] = ""
        changed = True
    if image_file and image_file.filename:
        os.makedirs(CATEGORY_IMAGES_DIR, exist_ok=True)
        dest_name = f"c{cid}.jpg"
        image_file.save(os.path.join(CATEGORY_IMAGES_DIR, dest_name))
        target["primary_image"] = dest_name
        changed = True

    if changed:
        write_csv(CATEGORIES_CSV, rows, fields)
        commit_and_push([DATA_DIR], f"Update category {cid} via webapp")
        flash("Category updated.")
    else:
        flash("No changes.")

    return redirect(url_for('index'))


if __name__ == "__main__":
    os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
    os.makedirs(CATEGORY_IMAGES_DIR, exist_ok=True)
    ensure_product_columns()
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=True)