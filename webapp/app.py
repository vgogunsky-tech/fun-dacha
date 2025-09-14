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
import threading
from urllib import request as urlrequest
from urllib import parse as urlparse
from urllib.error import HTTPError, URLError

from flask import Flask, render_template, request, redirect, url_for, send_from_directory, abort, flash
from flask import jsonify

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
INVENTORY_CSV = os.path.join(DATA_DIR, "inventory.csv")
INVENTORY_TEMPLATES_JSON = os.path.join(DATA_DIR, "inventory_templates.json")

REQUIRED_PRODUCT_COLS = [
    "validated",
    "year",
    "availability",
    "product_id",
]

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-secret-key")
# Configure logging to ensure visibility on servers
logging.basicConfig(level=getattr(logging, os.environ.get("LOG_LEVEL", "INFO"), logging.INFO))
app.logger.setLevel(getattr(logging, os.environ.get("LOG_LEVEL", "INFO"), logging.INFO))


# -------------------- Translation helpers --------------------

def _http_json_post(url: str, payload: Dict[str, str]) -> Tuple[int, str]:
    data = json.dumps(payload).encode("utf-8")
    req = urlrequest.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    req.add_header("User-Agent", "fun-dacha-webapp")
    try:
        with urlrequest.urlopen(req, timeout=25) as resp:
            status = resp.getcode()
            body = (resp.read() or b"").decode("utf-8", errors="replace")
            return status, body
    except HTTPError as e:
        body = (e.read() or b"").decode("utf-8", errors="replace")
        return e.code, body
    except URLError as e:
        return 0, str(e)


def _translate_via_libretranslate(text: str) -> Optional[str]:
    if not text:
        return ""
    endpoints = [
        "https://libretranslate.de/translate",
        "https://translate.argosopentech.com/translate",
    ]
    for ep in endpoints:
        try:
            status, body = _http_json_post(ep, {
                "q": text,
                "source": "ru",
                "target": "uk",
                "format": "text",
            })
            if status == 200 and body:
                try:
                    data = json.loads(body)
                    translated = data.get("translatedText")
                    if isinstance(translated, str) and translated.strip():
                        return translated.strip()
                except Exception:
                    pass
        except Exception:
            continue
    return None


def _translate_via_mymemory(text: str) -> Optional[str]:
    if not text:
        return ""
    try:
        params = {
            "q": text,
            "langpair": "ru|uk",
        }
        url = "https://api.mymemory.translated.net/get?" + urlparse.urlencode(params)
        req = urlrequest.Request(url, method="GET")
        req.add_header("Accept", "application/json")
        req.add_header("User-Agent", "fun-dacha-webapp")
        with urlrequest.urlopen(req, timeout=25) as resp:
            status = resp.getcode()
            body = (resp.read() or b"").decode("utf-8", errors="replace")
        if status == 200 and body:
            try:
                data = json.loads(body)
                translated = (data.get("responseData") or {}).get("translatedText")
                if isinstance(translated, str) and translated.strip():
                    return translated.strip()
            except Exception:
                pass
    except Exception:
        return None
    return None


def translate_text_ru_to_uk(text: str) -> Optional[str]:
    if not (text or "").strip():
        return ""
    # Try LibreTranslate first for better consistency, then fall back to MyMemory
    res = _translate_via_libretranslate(text)
    if isinstance(res, str) and res.strip():
        return res
    res = _translate_via_mymemory(text)
    if isinstance(res, str) and res.strip():
        return res
    return None


@app.post("/api/translate/ru-ua")
def api_translate_ru_ua():
    try:
        data = request.get_json(silent=True) or {}
        text = (data.get("text") or "").strip()
        if not text:
            return jsonify({"translated": "", "error": "empty"}), 200
        translated = translate_text_ru_to_uk(text)
        if isinstance(translated, str) and translated.strip():
            return jsonify({"translated": translated}), 200
        return jsonify({"translated": "", "error": "failed"}), 200
    except Exception as e:
        return jsonify({"translated": "", "error": "exception"}), 200


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


def commit_and_push_async(paths: List[str], message: str) -> None:
    """Run commit_and_push in a background thread to avoid blocking the UI."""
    def _run_commit():
        try:
            commit_and_push(paths, message)
        except Exception as e:
            _log_git(f"[git] async commit_and_push exception: {e}")
    
    thread = threading.Thread(target=_run_commit, daemon=True)
    thread.start()
    _log_git("[git] started async commit_and_push")


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


# -------------------- Inventory API --------------------

@app.get("/api/inventory/<int:pid>")
def api_inventory_get(pid: int):
    try:
        ensure_product_columns()
        inv = load_inventory_json_for_product(pid)
        return jsonify(inv), 200
    except Exception as e:
        return jsonify({"error": "failed"}), 500


@app.post("/api/inventory/<int:pid>")
def api_inventory_post(pid: int):
    try:
        payload = request.get_json(silent=True) or {}
        # Accept either direct structure or under key 'inventory'
        if "inventory" in payload and isinstance(payload.get("inventory"), dict):
            inv = payload.get("inventory")
        else:
            inv = payload
        save_inventory_json_for_product(pid, inv)
        # Commit
        try:
            commit_and_push_async([INVENTORY_CSV], f"Update inventory for product {pid} via webapp")
        except Exception:
            pass
        return jsonify({"ok": True}), 200
    except Exception as e:
        return jsonify({"ok": False, "error": "failed"}), 500


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


# -------------------- Inventory CSV helpers --------------------

INVENTORY_FIELDS = [
    "id",  # row id in inventory
    "pid",  # numeric product id from products CSV
    "product_id",  # sku like p100001
    "variant_id",  # computed variant id
    "title_ua",
    "title_ru",
    "original_price",
    "sale_price",
    "currency",
    "stock_qty",
    "value",
    "unit",
    "type",
    "values_json",
]


def _ensure_inventory_file() -> None:
    try:
        os.makedirs(os.path.dirname(INVENTORY_CSV), exist_ok=True)
        if not os.path.isfile(INVENTORY_CSV):
            write_csv(INVENTORY_CSV, [], INVENTORY_FIELDS)
        else:
            # Ensure headers include all fields; add missing columns with blanks
            rows, fields = read_csv(INVENTORY_CSV)
            changed = False
            for col in INVENTORY_FIELDS:
                if col not in fields:
                    fields.append(col)
                    for r in rows:
                        r[col] = ""
                    changed = True
            if changed:
                write_csv(INVENTORY_CSV, rows, fields)
    except Exception:
        pass


def read_inventory_csv() -> Tuple[List[Dict[str, str]], List[str]]:
    _ensure_inventory_file()
    rows, fields = read_csv(INVENTORY_CSV)
    return rows, fields


def write_inventory_csv(rows: List[Dict[str, str]], fields: Optional[List[str]] = None) -> None:
    _ensure_inventory_file()
    if fields is None:
        fields = INVENTORY_FIELDS
        # ensure new fields are present in rows
        for r in rows:
            for col in fields:
                if col not in r:
                    r[col] = ""
    write_csv(INVENTORY_CSV, rows, fields)


def _inventory_next_id(rows: List[Dict[str, str]]) -> int:
    max_id = 0
    for r in rows:
        try:
            max_id = max(max_id, int(float((r.get("id") or "0").strip() or 0)))
        except Exception:
            pass
    return max_id + 1


# -------------------- Inventory templates helpers --------------------

def load_inventory_templates() -> List[Dict]:
    defaults: List[Dict] = [
        {
            "title": {"ua": "Маленький пакет", "ru": "Маленький пакет"},
            "type": "quantity",
            "unit": "pcs",
            "values": [10, 15, 20, 25, 30],
            "original_price": 10,
            "sale_price": None,
            "currency": "UAH",
        },
        {
            "title": {"ua": "Великий пакет", "ru": "Большой пакет"},
            "type": "weight",
            "unit": "g",
            "values": [50, 100, 250, 500],
            "original_price": 10,
            "sale_price": None,
            "currency": "UAH",
        },
    ]
    path = INVENTORY_TEMPLATES_JSON
    try:
        if os.path.isfile(path):
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if isinstance(data, list):
                return data
    except Exception:
        pass
    return defaults


def ensure_product_columns() -> None:
    rows, fields, _ = read_products_csv()
    changed = False
    # Ensure essential columns
    for col in ["primary_image", "images", "tags"] + REQUIRED_PRODUCT_COLS:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = ""
            changed = True
    # Rename legacy "SKU Number" to "product_id" without altering existing numeric id
    if "SKU Number" in fields and "product_id" not in fields:
        # Append new column name and copy values
        fields.append("product_id")
        for r in rows:
            r["product_id"] = r.get("SKU Number", "")
        # Remove legacy field from header
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


def load_tag_ua_map(category_id: int) -> Dict[str, str]:
    """Load mapping of tag key -> UA display name for a given category.

    Falls back to empty mapping if tags.csv is missing.
    """
    tags_path = os.path.join(DATA_DIR, "tags.csv")
    mapping: Dict[str, str] = {}
    try:
        with open(tags_path, "r", encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            # Normalize category id like other code: tolerate values like "100.0"
            try:
                cat_norm = str(int(float(category_id)))
            except Exception:
                cat_norm = str(category_id)
            for row in reader:
                if (row.get("category") or "").strip() != cat_norm:
                    continue
                key = (row.get("key") or "").strip()
                ua = (row.get("ua") or "").strip()
                if key and ua:
                    mapping[key] = ua
    except FileNotFoundError:
        pass
    except Exception:
        # Be resilient in UI if tags file has unexpected issues
        pass
    return mapping


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


# -------------------- Inventory domain helpers --------------------

def _find_product_by_id_numeric(pid_numeric: int) -> Optional[Dict[str, str]]:
    rows, _, _ = read_products_csv()
    for r in rows:
        try:
            if int(float((r.get("id") or "0").strip() or 0)) == pid_numeric:
                return r
        except Exception:
            continue
    return None


def _inventory_rows_for_pid(pid_numeric: int) -> List[Dict[str, str]]:
    rows, _ = read_inventory_csv()
    result: List[Dict[str, str]] = []
    for r in rows:
        try:
            if int(float((r.get("pid") or "0").strip() or 0)) == pid_numeric:
                result.append(r)
        except Exception:
            continue
    return result


def load_inventory_json_for_product(pid_numeric: int) -> Dict:
    product = _find_product_by_id_numeric(pid_numeric)
    sku = (product.get("product_id") if product else "") if product else ""
    items_rows = _inventory_rows_for_pid(pid_numeric)
    items: List[Dict] = []
    for r in items_rows:
        # Parse values_json
        try:
            values_parsed = json.loads(r.get("values_json") or "[]")
            if not isinstance(values_parsed, list):
                values_parsed = []
        except Exception:
            values_parsed = []
        # Convert numeric fields
        def _to_num(v):
            try:
                return float(v)
            except Exception:
                return None
        items.append({
            "id": r.get("variant_id") or "",
            "title": {
                "ua": r.get("title_ua") or "",
                "ru": r.get("title_ru") or "",
            },
            "original_price": _to_num(r.get("original_price")),
            "sale_price": _to_num(r.get("sale_price")),
            "currency": (r.get("currency") or "UAH") or "UAH",
            "stock_qty": int(float(r.get("stock_qty") or 0)) if (r.get("stock_qty") or "").strip() != "" else 0,
            "value": _to_num(r.get("value")),
            "unit": r.get("unit") or "",
            "type": r.get("type") or "",
            "values": values_parsed,
        })
    inv = {
        "id": pid_numeric,
        "product_id": sku,
        "items": items,
    }
    return inv


def save_inventory_json_for_product(pid_numeric: int, payload: Dict) -> None:
    rows_all, fields = read_inventory_csv()
    # Remove existing rows for pid
    kept: List[Dict[str, str]] = []
    for r in rows_all:
        try:
            if int(float((r.get("pid") or "0").strip() or 0)) != pid_numeric:
                kept.append(r)
        except Exception:
            kept.append(r)
    product = _find_product_by_id_numeric(pid_numeric)
    sku = (product.get("product_id") if product else "") if product else ""
    items = payload.get("items") or []
    if not isinstance(items, list):
        items = []
    # next id counter
    next_id = _inventory_next_id(rows_all)
    new_rows: List[Dict[str, str]] = []
    for it in items:
        title = it.get("title") or {}
        values = it.get("values") if isinstance(it.get("values"), list) else []
        def _num(v):
            try:
                return float(v)
            except Exception:
                return None
        def _int(v):
            try:
                return int(float(v))
            except Exception:
                return 0
        # compute variant id if missing
        variant_id = (it.get("id") or "").strip()
        if not variant_id:
            unit = (it.get("unit") or "").strip()
            value = it.get("value")
            suffix = ""
            try:
                if value is not None:
                    # Avoid decimal point if value is int-like
                    val_int = int(float(value))
                    if float(val_int) == float(value):
                        suffix = f"{val_int}{(unit or '').upper()[:1]}"
                    else:
                        suffix = f"{value}{(unit or '').upper()[:1]}"
            except Exception:
                suffix = f"{value}{(unit or '').upper()[:1]}"
            variant_id = f"{(sku or '').upper()}-{suffix}" if suffix else (sku or '')
        row = {
            "id": str(next_id),
            "pid": str(pid_numeric),
            "product_id": sku or "",
            "variant_id": variant_id,
            "title_ua": (title.get("ua") or ""),
            "title_ru": (title.get("ru") or ""),
            "original_price": "" if it.get("original_price") in (None, "") else str(_num(it.get("original_price")) or ""),
            "sale_price": "" if it.get("sale_price") in (None, "") else str(_num(it.get("sale_price")) or ""),
            "currency": (it.get("currency") or "UAH") or "UAH",
            "stock_qty": str(_int(it.get("stock_qty"))),
            "value": "" if it.get("value") in (None, "") else str(_num(it.get("value")) or ""),
            "unit": (it.get("unit") or ""),
            "type": (it.get("type") or ""),
            "values_json": json.dumps(values, ensure_ascii=False),
        }
        new_rows.append(row)
        next_id += 1
    final_rows = kept + new_rows
    write_inventory_csv(final_rows, fields)


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


# -------------------- Image Library API Routes --------------------

@app.route("/api/images/<category>")
def api_images_by_category(category: str):
    """Get list of images for a specific category"""
    try:
        image_dir = os.path.join(DATA_DIR, "imageLibrary", category)
        if not os.path.exists(image_dir):
            return jsonify([])
        
        images = []
        for filename in os.listdir(image_dir):
            if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                images.append({
                    'filename': filename,
                    'category': category
                })
        
        # Sort by filename
        images.sort(key=lambda x: x['filename'])
        return jsonify(images)
    except Exception as e:
        app.logger.error(f"Error loading images for category {category}: {e}")
        return jsonify([]), 500

@app.route("/api/images/categories")
def api_image_categories():
    """Get list of available image categories with counts"""
    try:
        image_library_dir = os.path.join(DATA_DIR, "imageLibrary")
        if not os.path.exists(image_library_dir):
            return jsonify([])
        
        categories = []
        for category_name in os.listdir(image_library_dir):
            category_path = os.path.join(image_library_dir, category_name)
            if os.path.isdir(category_path):
                # Count images in this category
                image_count = 0
                for filename in os.listdir(category_path):
                    if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                        image_count += 1
                
                if image_count > 0:
                    # Get display name from category mapping
                    display_name = get_category_display_name(category_name)
                    categories.append({
                        'name': category_name,
                        'display_name': display_name,
                        'count': image_count
                    })
        
        # Sort by display name
        categories.sort(key=lambda x: x['display_name'])
        return jsonify(categories)
    except Exception as e:
        app.logger.error(f"Error loading image categories: {e}")
        return jsonify([]), 500

@app.route("/images/<category>/<path:filename>")
def serve_image_library_image(category: str, filename: str):
    """Serve images from the image library"""
    try:
        image_dir = os.path.join(DATA_DIR, "imageLibrary", category)
        return send_from_directory(image_dir, filename)
    except Exception as e:
        app.logger.error(f"Error serving image {category}/{filename}: {e}")
        abort(404)

def get_category_display_name(category_name: str):
    """Get display name for category from mapping"""
    # Load category mapping if available
    mapping_file = os.path.join(BASE_DIR, "category_library_mapping.csv")
    if os.path.exists(mapping_file):
        try:
            import csv
            with open(mapping_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    if row['library_folder'] == category_name:
                        return row['name_ukr']
        except Exception:
            pass
    
    # Fallback to category name with some basic translations
    translations = {
        'pomidori': 'Томати',
        'ogirki': 'Огірки',
        'kapusta': 'Капуста',
        'baklazhan': 'Баклажани',
        'morkva': 'Морква',
        'buryak': 'Буряк',
        'kavun': 'Кавуни',
        'dinya': 'Дині',
        'garbuz': 'Гарбузи',
        'kabachok': 'Кабачки',
        'goroh': 'Горох',
        'kvaso': 'Квасоля',
        'kukurudza': 'Кукурудза',
        'kviti': 'Квіти',
        'redis-redka': 'Редис',
        'perets': 'Перець',
        'patis': 'Патисони',
        'salat': 'Салат',
        'zelen-pryanoschi': 'Зелені приправи',
        'trava-gazonna': 'Газонні трави',
        'tsibulya': 'Цибуля',
        'krip': 'Кріп',
        'petrushka': 'Петрушка'
    }
    
    return translations.get(category_name, category_name.title())

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


@app.get("/inventory/<int:pid>")
def inventory_edit(pid: int):
    ensure_product_columns()
    product = _find_product_by_id_numeric(pid)
    if product is None:
        abort(404)
    # Product image
    img_url = None
    img_name = (product.get("primary_image") or "").strip()
    if img_name and os.path.isfile(os.path.join(PRODUCT_IMAGES_DIR, img_name)):
        img_url = url_for("serve_product_image", filename=img_name)

    cats = load_categories()
    try:
        category_id = int(float(product.get("category_id", "") or 0))
    except Exception:
        category_id = 0

    inv_json = load_inventory_json_for_product(pid)
    return_to = (request.args.get("return_to") or "").strip()
    return render_template(
        "inventory.html",
        product=product,
        image_url=img_url,
        inventory=inv_json,
        categories=cats,
        category_id=category_id,
        inventory_templates=load_inventory_templates(),
        return_to=return_to,
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

    # Tag UA map for this product's category
    tag_ua_map = {}
    try:
        if category_id is not None:
            tag_ua_map = load_tag_ua_map(int(float(category_id)))
    except Exception:
        tag_ua_map = {}

    inv_json = load_inventory_json_for_product(pid)
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
        tag_ua_map=tag_ua_map,
        inventory=inv_json,
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

    # Tag UA map for this category
    tag_ua_map = {}
    try:
        tag_ua_map = load_tag_ua_map(int(float(category_id)))
    except Exception:
        tag_ua_map = {}

    inv_json = None
    try:
        inv_json = load_inventory_json_for_product(int(float(p.get("id") or 0)))
    except Exception:
        inv_json = None
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
        tag_ua_map=tag_ua_map,
        inventory=inv_json,
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
    for col in REQUIRED_PRODUCT_COLS + ["primary_image", "price", "weight"]:
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
        "tags",
        "price",
        "weight",
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
        # Update product_id on image/category change
        target["product_id"] = build_sku(target.get("category_id", ""), target.get("id", ""))
        changed_paths.append(dest_path)
    
    # Handle selected library image
    selected_library_image = form.get("selected_library_image", "").strip()
    if selected_library_image:
        try:
            import json
            image_data = json.loads(selected_library_image)
            source_path = os.path.join(DATA_DIR, "imageLibrary", image_data["category"], image_data["filename"])
            if os.path.exists(source_path):
                dest_name = build_product_image_name(target.get("category_id", ""), target.get("id", ""))
                os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
                dest_path = os.path.join(PRODUCT_IMAGES_DIR, dest_name)
                shutil.copy2(source_path, dest_path)
                target["primary_image"] = dest_name
                # Update product_id on image/category change
                target["product_id"] = build_sku(target.get("category_id", ""), target.get("id", ""))
                changed_paths.append(dest_path)
        except Exception as e:
            app.logger.error(f"Error copying library image: {e}")
            flash("Помилка копіювання зображення з бібліотеки", "error")

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

    # Inventory save (optional if provided as hidden input)
    inv_raw = (form.get("inventory_json") or "").strip()
    if inv_raw:
        try:
            inv_obj = json.loads(inv_raw)
            try:
                pid_int = int(float(product_id))
            except Exception:
                pid_int = None
            if pid_int is not None and isinstance(inv_obj, dict):
                save_inventory_json_for_product(pid_int, inv_obj)
                changed_paths.append(INVENTORY_CSV)
        except Exception:
            pass

    written_paths = write_products_csv(rows, fields)
    changed_paths.extend(written_paths)
    commit_and_push_async(changed_paths, f"Update product {product_id} via webapp")
    flash(("Saved and validated." if advanced else "Saved.") + " Files: " + ', '.join(os.path.relpath(p, BASE_DIR) for p in written_paths) + " (changes are being saved to git in the background)")

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
        "product_id": sku,
        "validated": "0",
        "year": (form.get("year") or "").strip(),
        "availability": (form.get("availability") or "").strip(),
    }

    rows.append(new_row)
    write_products_csv(rows, fields)
    commit_and_push_async([DATA_DIR], f"Create product {new_id} via webapp")
    flash(f"Product created with ID {new_id}. Changes are being saved to git in the background.")
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
    commit_and_push_async([CATEGORIES_CSV, os.path.join(CATEGORY_IMAGES_DIR, primary_image) if primary_image else CATEGORIES_CSV], f"Create category {cid_int} via webapp")
    flash("Category created. Changes are being saved to git in the background.")
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
        commit_and_push_async(changed_paths, f"Update category {cid} via webapp")
        flash("Category updated. Changes are being saved to git in the background.")
    else:
        flash("No changes.")

    return redirect(url_for('index'))


# -------------------- Bulk operations --------------------

@app.post("/products/bulk-update-category")
def bulk_update_category():
    """Update category for multiple products at once."""
    form = request.form
    
    product_ids_str = (form.get("product_ids") or "").strip()
    category_id = (form.get("category_id") or "").strip()
    subcategory_id = (form.get("subcategory_id") or "").strip()
    
    if not product_ids_str or not category_id:
        flash("Product IDs and category are required.")
        return redirect(url_for('products_list'))
    
    try:
        # Parse product IDs
        product_ids = [int(pid.strip()) for pid in product_ids_str.split(",") if pid.strip()]
        if not product_ids:
            flash("No valid product IDs provided.")
            return redirect(url_for('products_list'))
        
        # Validate category ID
        category_id_int = int(float(category_id))
        
        # Load products
        rows, fields, _ = read_products_csv()
        
        # Update products
        updated_count = 0
        for row in rows:
            try:
                row_pid = int(float((row.get("id") or "0").strip() or 0))
                if row_pid in product_ids:
                    row["category_id"] = str(category_id_int)
                    if subcategory_id:
                        row["subcategory_id"] = subcategory_id
                    else:
                        row["subcategory_id"] = ""
                    updated_count += 1
            except Exception:
                continue
        
        if updated_count > 0:
            # Save changes
            write_products_csv(rows, fields)
            
            # Commit and push to git - use a more specific path and handle timeouts
            try:
                # Use a more specific path to avoid hanging
                csv_path = os.path.join(DATA_DIR, "list.csv")
                commit_and_push_async([csv_path], f"Bulk update category for {updated_count} products to {category_id}")
                flash(f"Successfully updated category for {updated_count} products. Changes are being saved to git in the background.")
            except Exception as git_error:
                # If git operation fails, still show success but warn about git
                flash(f"Products updated successfully, but git commit failed: {str(git_error)}")
                # Log the error for debugging
                app.logger.error(f"Git commit failed in bulk update: {git_error}")
        else:
            flash("No products were updated.")
            
    except Exception as e:
        flash(f"Error updating products: {str(e)}")
        app.logger.error(f"Bulk update error: {e}")
    
    return redirect(url_for('products_list'))


if __name__ == "__main__":
    os.makedirs(PRODUCT_IMAGES_DIR, exist_ok=True)
    os.makedirs(CATEGORY_IMAGES_DIR, exist_ok=True)
    ensure_product_columns()
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=True)