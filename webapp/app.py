#!/usr/bin/env python3
import csv
import os
import sys
import subprocess
from typing import Dict, List, Optional, Tuple
import logging
import shutil
import base64
import json
from urllib import request as urlrequest
from urllib import parse as urlparse
from urllib.error import HTTPError, URLError

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
]

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-secret-key")
# Configure logging to ensure visibility on servers
logging.basicConfig(level=getattr(logging, os.environ.get("LOG_LEVEL", "INFO"), logging.INFO))
app.logger.setLevel(getattr(logging, os.environ.get("LOG_LEVEL", "INFO"), logging.INFO))


def _log_git(message: str) -> None:
    try:
        app.logger.info(message)
    except Exception:
        pass
    try:
        print(message, flush=True)
    except Exception:
        pass

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
        code = result.returncode
        out = (result.stdout or "").strip()
        err = (result.stderr or "").strip()
        _log_git(f"[git] cmd: git {' '.join(args)} | code={code}")
        if out:
            _log_git(f"[git] stdout: {out[:2000]}")
        if err:
            _log_git(f"[git] stderr: {err[:2000]}")
        return code, out, err
    except Exception as e:
        _log_git(f"[git] exception running git {' '.join(args)}: {e}")
        return 1, "", str(e)


def _ensure_git_identity() -> None:
    _log_git("[git] ensuring identity...")
    code, out, _ = _run_git(["config", "--get", "user.name"])
    if code != 0 or not out:
        _run_git(["config", "user.name", os.environ.get("GIT_AUTHOR_NAME", "server-bot")])
    code, out, _ = _run_git(["config", "--get", "user.email"])
    if code != 0 or not out:
        _run_git(["config", "user.email", os.environ.get("GIT_AUTHOR_EMAIL", "server-bot@example.com")])


def _has_git() -> bool:
    return bool(shutil.which("git"))


def commit_and_push(paths: List[str], message: str) -> None:
    try:
        _log_git("[git] commit_and_push start")
        if not _has_git():
            _log_git("[git] git executable not found in PATH; attempting GitHub API fallback")
            _github_api_commit(paths, message)
            return
        _ensure_git_identity()
        target_remote = os.environ.get("GIT_TARGET_REMOTE", "origin")
        target_branch = os.environ.get("GIT_TARGET_BRANCH", "develop")
        token_present = bool(os.environ.get("GIT_AUTH_TOKEN"))
        _log_git(f"[git] remote={target_remote} branch={target_branch} token_present={token_present}")
        # Show remote url but redact token if present
        code, remote_url, _ = _run_git(["remote", "get-url", target_remote])
        if code == 0 and remote_url:
            redacted = remote_url
            if "x-access-token:" in redacted:
                redacted = "https://x-access-token:***@" + redacted.split("@", 1)[-1]
            _log_git(f"[git] remote url: {redacted}")
        # Stage specified paths
        _run_git(["add"] + paths)
        # Check status
        code, status, _ = _run_git(["status", "--porcelain"])
        if code != 0:
            _log_git("[git] status failed; skip commit")
            return
        if not (status or "").strip():
            _log_git("[git] nothing to commit")
            return
        # Commit
        _run_git(["commit", "-m", message])
        # Push HEAD to target branch
        code, out, err = _run_git(["push", target_remote, f"HEAD:refs/heads/{target_branch}"])
        _log_git(f"[git] push done code={code}")
    except Exception as e:
        # Never let git failures break the request path
        _log_git(f"[git] commit_and_push exception: {e}")
        pass


# -------------------- GitHub API fallback --------------------

def _github_api_headers(token: str) -> Dict[str, str]:
    return {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "fun-dacha-webapp",
        "X-GitHub-Api-Version": "2022-11-28",
        "Content-Type": "application/json",
    }


def _github_http(method: str, url: str, headers: Dict[str, str], payload: Optional[Dict] = None) -> Tuple[int, str, Dict[str, str]]:
    data_bytes = None
    if payload is not None:
        data_bytes = json.dumps(payload).encode("utf-8")
    req = urlrequest.Request(url, data=data_bytes, method=method)
    for k, v in headers.items():
        req.add_header(k, v)
    try:
        with urlrequest.urlopen(req, timeout=30) as resp:
            status = resp.getcode()
            body = (resp.read() or b"").decode("utf-8", errors="replace")
            return status, body, dict(resp.headers)
    except HTTPError as e:
        body = (e.read() or b"").decode("utf-8", errors="replace")
        return e.code, body, dict(e.headers or {})
    except URLError as e:
        return 0, str(e), {}


def _github_api_repo() -> Optional[str]:
    repo = os.environ.get("GIT_REPOSITORY", "").strip()
    if repo:
        return repo
    # Try to infer from Procfile remote url if present
    try:
        proc = os.path.join(BASE_DIR, "Procfile")
        if os.path.isfile(proc):
            with open(proc, "r", encoding="utf-8") as f:
                content = f.read()
            # look for github.com/{owner}/{repo}.git
            import re
            m = re.search(r"github\.com/([\w.-]+/[\w.-]+)\.git", content)
            if m:
                return m.group(1)
    except Exception:
        pass
    return None


def _github_api_ensure_branch(repo: str, token: str, branch: str) -> None:
    headers = _github_api_headers(token)
    # Check branch exists
    status, body, _ = _github_http("GET", f"https://api.github.com/repos/{repo}/git/ref/heads/{urlparse.quote(branch)}", headers)
    if status == 200:
        return
    # Get repo default branch
    status, body, _ = _github_http("GET", f"https://api.github.com/repos/{repo}", headers)
    if status != 200:
        _log_git(f"[api] failed to load repo metadata: {status} {body[:500]}")
        return
    try:
        meta = json.loads(body)
        default_branch = meta.get("default_branch") or "main"
    except Exception:
        default_branch = "main"
    # Get default branch head SHA
    status, body, _ = _github_http("GET", f"https://api.github.com/repos/{repo}/git/ref/heads/{urlparse.quote(default_branch)}", headers)
    if status != 200:
        _log_git(f"[api] failed to load default branch ref: {status} {body[:500]}")
        return
    try:
        ref = json.loads(body)
        sha = ref.get("object", {}).get("sha")
    except Exception:
        sha = None
    if not sha:
        _log_git("[api] could not determine base sha for new branch")
        return
    # Create branch
    payload = {"ref": f"refs/heads/{branch}", "sha": sha}
    status, body, _ = _github_http("POST", f"https://api.github.com/repos/{repo}/git/refs", headers, payload)
    if status not in (200, 201):
        _log_git(f"[api] failed to create branch {branch}: {status} {body[:500]}")


def _github_api_get_file_sha(repo: str, token: str, path_rel: str, branch: str) -> Optional[str]:
    headers = _github_api_headers(token)
    url = f"https://api.github.com/repos/{repo}/contents/{urlparse.quote(path_rel)}?ref={urlparse.quote(branch)}"
    status, body, _ = _github_http("GET", url, headers)
    if status == 200:
        try:
            data = json.loads(body)
            return data.get("sha")
        except Exception:
            return None
    return None


def _github_api_put_file(repo: str, token: str, branch: str, local_path: str, path_rel: str, message: str) -> None:
    headers = _github_api_headers(token)
    # Read content
    try:
        with open(local_path, "rb") as f:
            content_b64 = base64.b64encode(f.read()).decode("ascii")
    except Exception as e:
        _log_git(f"[api] skip {path_rel}: read error {e}")
        return
    sha = _github_api_get_file_sha(repo, token, path_rel, branch)
    # If remote has same content, skip
    if sha:
        # Fetch current content to compare
        status, body, _ = _github_http("GET", f"https://api.github.com/repos/{repo}/contents/{urlparse.quote(path_rel)}?ref={urlparse.quote(branch)}", headers)
        if status == 200:
            try:
                data = json.loads(body)
                remote_content_b64 = data.get("content", "").replace("\n", "")
                if remote_content_b64 == content_b64:
                    _log_git(f"[api] SKIP {path_rel}: unchanged")
                    return
            except Exception:
                pass
    payload = {
        "message": message,
        "content": content_b64,
        "branch": branch,
    }
    if sha:
        payload["sha"] = sha
    url = f"https://api.github.com/repos/{repo}/contents/{urlparse.quote(path_rel)}"
    status, body, _ = _github_http("PUT", url, headers, payload)
    if status not in (200, 201):
        _log_git(f"[api] PUT {path_rel} failed: {status} {body[:500]}")
    else:
        _log_git(f"[api] PUT {path_rel} ok: {status}")


def _github_api_commit(paths: List[str], message: str) -> None:
    token = os.environ.get("GIT_AUTH_TOKEN", "").strip()
    repo = _github_api_repo()
    branch = os.environ.get("GIT_TARGET_BRANCH", "develop")
    if not token:
        _log_git("[api] GIT_AUTH_TOKEN missing; cannot push via API")
        return
    if not repo:
        _log_git("[api] GIT_REPOSITORY missing and could not infer; cannot push via API")
        return
    _log_git(f"[api] push via API repo={repo} branch={branch}")
    # Ensure branch exists
    _github_api_ensure_branch(repo, token, branch)
    # Collect files
    sent: Dict[str, bool] = {}
    uploaded_any = False
    for p in paths:
        abs_p = p
        if not os.path.isabs(abs_p):
            abs_p = os.path.join(BASE_DIR, p)
        if not os.path.exists(abs_p):
            continue
        if os.path.isdir(abs_p):
            for root, _, files in os.walk(abs_p):
                for fname in files:
                    local_path = os.path.join(root, fname)
                    rel = os.path.relpath(local_path, BASE_DIR)
                    if rel.replace(os.sep, "/").startswith(".git/"):
                        continue
                    rel = rel.replace(os.sep, "/")
                    if sent.get(rel):
                        continue
                    before = len(sent)
                    _github_api_put_file(repo, token, branch, local_path, rel, message)
                    uploaded_any = uploaded_any or (len(sent) != before)
                    sent[rel] = True
        else:
            rel = os.path.relpath(abs_p, BASE_DIR).replace(os.sep, "/")
            if not sent.get(rel):
                before = len(sent)
                _github_api_put_file(repo, token, branch, abs_p, rel, message)
                uploaded_any = uploaded_any or (len(sent) != before)
                sent[rel] = True
    if not uploaded_any:
        _log_git("[api] no changes uploaded; skipping commit")


def _redact_remote(url: str) -> str:
    if not url:
        return url
    if "@" in url and "://" in url:
        try:
            prefix, rest = url.split("://", 1)
            creds, host = rest.split("@", 1)
            return f"{prefix}://***@{host}"
        except Exception:
            pass
    if "x-access-token:" in url:
        return "https://x-access-token:***@" + url.split("@", 1)[-1]
    return url


@app.get("/debug/git")
def debug_git():
    target_remote = os.environ.get("GIT_TARGET_REMOTE", "origin")
    target_branch = os.environ.get("GIT_TARGET_BRANCH", "develop")
    token_present = bool(os.environ.get("GIT_AUTH_TOKEN"))
    which_git = shutil.which("git") or "<not found>"
    path_env = os.environ.get("PATH", "")

    info: Dict[str, Tuple[int, str, str]] = {}
    if _has_git():
        info["git_version"] = _run_git(["--version"])
        info["remote_get_url"] = _run_git(["remote", "get-url", target_remote])
        info["rev_parse_head"] = _run_git(["rev-parse", "--abbrev-ref", "HEAD"]) 
        info["last_commit"] = _run_git(["log", "-1", "--oneline"]) 
        info["status"] = _run_git(["status", "--porcelain"]) 
        info["remotes_v"] = _run_git(["remote", "-v"]) 
        info["push_dryrun"] = _run_git(["push", "--dry-run", target_remote, f"HEAD:refs/heads/{target_branch}"]) 

    redacted_remote = _redact_remote(info["remote_get_url"][1]) if info.get("remote_get_url") else ""

    return render_template(
        "debug_git.html",
        target_remote=target_remote,
        target_branch=target_branch,
        token_present=token_present,
        redacted_remote=redacted_remote,
        which_git=which_git,
        path_env=path_env,
        info=info,
    )


# -------------------- CSV helpers --------------------

def read_csv(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []
    return rows, fields


def write_csv(path: str, rows: List[Dict[str, str]], fields: List[str]) -> None:
    """Write CSV only if content changes to avoid unnecessary commits."""
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    # Compare with existing file (if any)
    try:
        if os.path.isfile(path):
            with open(path, "rb") as old, open(tmp, "rb") as new:
                if old.read() == new.read():
                    # No change; remove tmp and return
                    os.remove(tmp)
                    return
    except Exception:
        # If compare fails, proceed to replace
        pass
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
    for col in ["primary_image", "images"] + REQUIRED_PRODUCT_COLS:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = ""
            changed = True
    # Migrate legacy "SKU Number" to lowercase "id" and drop the legacy column
    if "SKU Number" in fields:
        if "id" not in fields:
            fields.append("id")
        for r in rows:
            legacy_val = (r.get("SKU Number") or "").strip()
            if legacy_val:
                r["id"] = legacy_val
        try:
            fields.remove("SKU Number")
        except ValueError:
            pass
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


def build_secondary_image_name(category_id: str, product_id: str, seq: int) -> str:
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
    return f"p{cat3}{pid3}_{seq}.jpg"


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


@app.get("/products")
def products_list():
    """List all products with filters, sorting, and search."""
    ensure_product_columns()
    # Query params
    q = (request.args.get("q") or "").strip()
    filter_category = (request.args.get("category_id") or "").strip()
    sort_key = (request.args.get("sort") or "").strip()  # "name" or "category"
    sort_order = (request.args.get("order") or "asc").strip()  # "asc" or "desc"

    rows, fields, _ = read_products_csv()
    categories = load_categories()
    # Map category id -> name
    category_name_by_id: Dict[str, str] = {}
    for c in categories:
        cid = (c.get("id") or "").strip()
        if cid:
            category_name_by_id[cid] = c.get("name") or ""

    # Filter by search query in Ukrainian name
    if q:
        q_low = q.lower()
        rows = [r for r in rows if (r.get("Название (укр)") or "").lower().find(q_low) != -1]

    # Filter by category id
    if filter_category:
        try:
            filter_cat_norm = str(int(float(filter_category)))
        except Exception:
            filter_cat_norm = filter_category
        rows = [r for r in rows if (r.get("category_id") or "").strip() == filter_cat_norm]

    # Sorting
    reverse = sort_order == "desc"
    if sort_key == "name":
        rows.sort(key=lambda r: (r.get("Название (укр)") or "").lower())
    elif sort_key == "category":
        rows.sort(key=lambda r: ((r.get("category_id") or ""), (r.get("Название (укр)") or "").lower()))
    else:
        # default sort by numeric id
        def _id_key(r: Dict[str, str]) -> float:
            try:
                return float(r.get("id", "0") or 0.0)
            except Exception:
                return 0.0
        rows.sort(key=_id_key)
    if reverse:
        rows.reverse()

    # Build image URLs for preview
    def _image_url(name: str) -> Optional[str]:
        name = (name or "").strip()
        if not name:
            return None
        if os.path.isfile(os.path.join(PRODUCT_IMAGES_DIR, name)):
            return url_for("serve_product_image", filename=name)
        return None

    # Compute visible fields (remove RU/UA descriptions, image filename, and legacy SKU)
    hidden_fields = {"Название (рус)", "Описание (рус)", "Описание (укр)", "primary_image", "SKU Number"}
    visible_fields = [f for f in fields if f not in hidden_fields]

    rows_with_images: List[Dict[str, str]] = []
    for r in rows:
        augmented = dict(r)
        augmented["_image_url"] = _image_url(r.get("primary_image") or "")
        # Precompute integer product id tolerant to values like "123.0"
        try:
            augmented["_pid"] = int(float((r.get("id") or "0").strip() or 0))
        except Exception:
            augmented["_pid"] = 0
        # Mark not validated (anything other than explicit "1")
        val = (r.get("validated") or "").strip()
        augmented["_not_validated"] = not (val == "1")
        rows_with_images.append(augmented)

    return render_template(
        "products_list.html",
        rows=rows_with_images,
        fields=visible_fields,
        categories=categories,
        category_name_by_id=category_name_by_id,
        q=q,
        filter_category=filter_category,
        sort_key=sort_key,
        sort_order=sort_order,
    )


@app.get("/product/<int:pid>")
def product_by_id(pid: int):
    """Open product edit page for a specific product id."""
    ensure_product_columns()
    rows, fields, _ = read_products_csv()
    target: Optional[Dict[str, str]] = None
    for r in rows:
        try:
            if int(float((r.get("id") or "0").strip() or 0)) == pid:
                target = r
                break
        except Exception:
            continue
    if target is None:
        abort(404)

    # Image URL
    img_name = (target.get("primary_image") or "").strip()
    img_url = None
    if img_name and os.path.isfile(os.path.join(PRODUCT_IMAGES_DIR, img_name)):
        img_url = url_for("serve_product_image", filename=img_name)

    cats = load_categories()
    parent_to_children: Dict[str, List[Dict[str, str]]] = {}
    for c in cats:
        pid_val = (c.get("parentId") or "").strip()
        if pid_val:
            parent_to_children.setdefault(pid_val, []).append(c)

    # Determine category id for header
    category_id = None
    try:
        category_id = int(float(target.get("category_id", "") or 0))
    except Exception:
        category_id = None

    # Secondary images
    sec_names = [s.strip() for s in (target.get("images") or "").split(",") if s.strip()]
    secondary_items: List[Dict[str, str]] = []
    for name in sec_names:
        if os.path.isfile(os.path.join(PRODUCT_IMAGES_DIR, name)):
            secondary_items.append({
                "name": name,
                "url": url_for("serve_product_image", filename=name),
            })

    return render_template(
        "product.html",
        category_id=category_id or 0,
        product=target,
        index=0,
        total=1,
        image_url=img_url,
        secondary_items=secondary_items,
        categories=cats,
        parent_to_children=parent_to_children,
    )


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

    # Secondary images
    sec_names = [s.strip() for s in (p.get("images") or "").split(",") if s.strip()]
    secondary_items: List[Dict[str, str]] = []
    for name in sec_names:
        if os.path.isfile(os.path.join(PRODUCT_IMAGES_DIR, name)):
            secondary_items.append({
                "name": name,
                "url": url_for("serve_product_image", filename=name),
            })

    return render_template(
        "product.html",
        category_id=category_id,
        product=p,
        index=index,
        total=total,
        image_url=img_url,
        secondary_items=secondary_items,
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

    changed_paths: List[str] = []
    # Handle primary image remove
    if (form.get("remove_primary_image") or "") == "1":
        target["primary_image"] = ""
    # Handle primary image upload
    image_file = files.get("image")
    if image_file and image_file.filename:
        dest_name = build_product_image_name(target.get("category_id", ""), target.get("id", ""))
        os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
        dest_path = os.path.join(PRODUCT_IMAGES_DIR, dest_name)
        image_file.save(dest_path)
        target["primary_image"] = dest_name
        # Update SKU on image/category change
        target["ID"] = build_sku(target.get("category_id", ""), target.get("id", ""))
        changed_paths.append(dest_path)

    # Handle up to 5 secondary images
    existing_sec = [s.strip() for s in (target.get("images") or "").split(",") if s.strip()]
    # Remove selected
    # From checkboxes in UI
    remove_list = request.form.getlist("remove_images_list")
    to_remove = set(remove_list)
    to_remove = {s.strip() for s in to_remove if s.strip()}
    existing_sec = [s for s in existing_sec if s not in to_remove]
    # Add new uploads
    for idx in range(1, 6):
        f = files.get(f"image_secondary_{idx}")
        if f and f.filename:
            dest_name = build_secondary_image_name(target.get("category_id", ""), target.get("id", ""), idx)
            os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
            dest_path = os.path.join(PRODUCT_IMAGES_DIR, dest_name)
            f.save(dest_path)
            if dest_name not in existing_sec:
                existing_sec.append(dest_name)
            changed_paths.append(dest_path)
    # Ensure at most 5 secondary
    existing_sec = existing_sec[:5]
    target["images"] = ",".join(existing_sec)

    action = (form.get("action") or "").strip()
    advanced = False
    if action == "save_validate":
        target["validated"] = "1"
        advanced = True

    written_paths = write_products_csv(rows, fields)
    changed_paths.extend(written_paths)
    commit_and_push(changed_paths, f"Update product {product_id} via webapp")
    flash(("Saved and validated." if advanced else "Saved.") + " Files: " + ', '.join(os.path.relpath(p, BASE_DIR) for p in written_paths))

    # Redirect
    return_to = (form.get("return_to") or "").strip()
    if return_to.startswith("/"):
        return redirect(return_to)
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
    for col in ["primary_image", "images"] + REQUIRED_PRODUCT_COLS:
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
        "images": "",
        "category_id": str(int(float(cat_id))),
        "subcategory_id": (form.get("subcategory_id") or "").strip(),
        "id": str(new_id),
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
    commit_and_push([CATEGORIES_CSV, os.path.join(CATEGORY_IMAGES_DIR, primary_image) if primary_image else CATEGORIES_CSV], f"Create category {cid_int} via webapp")
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
        changed_paths: List[str] = [CATEGORIES_CSV]
        # If image updated or removed, include potential image path
        if target.get("primary_image"):
            changed_paths.append(os.path.join(CATEGORY_IMAGES_DIR, target.get("primary_image")))
        commit_and_push(changed_paths, f"Update category {cid} via webapp")
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