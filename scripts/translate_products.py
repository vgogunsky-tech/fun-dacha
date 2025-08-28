#!/usr/bin/env python3
import csv
import json
import os
import sys
import time
from typing import Dict, List, Optional, Tuple
from urllib import request as urlrequest
from urllib import parse as urlparse
from urllib.error import HTTPError, URLError


BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")
PRODUCTS_CSV_PRIMARY = os.path.join(DATA_DIR, "list.csv")
PRODUCTS_CSV_ALT = os.path.join(DATA_DIR, "lists.csv")


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


def read_csv(path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    if not os.path.isfile(path):
        return [], []
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows: List[Dict[str, str]] = [dict(r) for r in reader]
        fields: List[str] = list(reader.fieldnames or [])
        return rows, fields


def write_csv(path: str, rows: List[Dict[str, str]], fields: List[str]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k, "") for k in fields})
    os.replace(tmp, path)


def _http_json_post(url: str, payload: Dict[str, str]) -> Tuple[int, str]:
    data = json.dumps(payload).encode("utf-8")
    req = urlrequest.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    req.add_header("User-Agent", "fun-dacha-batch")
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
        req.add_header("User-Agent", "fun-dacha-batch")
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
    res = _translate_via_libretranslate(text)
    if isinstance(res, str) and res.strip():
        return res
    # small delay before fallback to avoid hammering
    time.sleep(0.3)
    res = _translate_via_mymemory(text)
    if isinstance(res, str) and res.strip():
        return res
    return None


def process_file(path: str) -> bool:
    print(f"Processing {path}...")
    rows, fields = read_csv(path)
    if not rows:
        print("  No rows found; skipping")
        return False
    # Ensure required columns exist
    for col in ["Название (укр)", "Название (рус)", "Описание (укр)", "Описание (рус)"]:
        if col not in fields:
            fields.append(col)
            for r in rows:
                r[col] = r.get(col, "")

    updated = 0
    for idx, r in enumerate(rows):
        name_ru = (r.get("Название (рус)") or "").strip()
        descr_ru = (r.get("Описание (рус)") or "").strip()

        # Translate and replace UA name if RU exists
        if name_ru:
            t = translate_text_ru_to_uk(name_ru)
            if isinstance(t, str):
                r["Название (укр)"] = t
                updated += 1
                time.sleep(0.25)

        # Translate and replace UA description if RU exists
        if descr_ru:
            t = translate_text_ru_to_uk(descr_ru)
            if isinstance(t, str):
                r["Описание (укр)"] = t
                updated += 1
                time.sleep(0.25)

        if (idx + 1) % 20 == 0:
            print(f"  ... {idx + 1}/{len(rows)} processed, {updated} updates so far")

    if updated:
        write_csv(path, rows, fields)
        print(f"  Wrote updates to {path} ({updated} field updates)")
        return True
    else:
        print("  No updates needed")
        return False


def main() -> int:
    any_updates = False
    for p in existing_product_csvs():
        try:
            changed = process_file(p)
            any_updates = any_updates or changed
        except KeyboardInterrupt:
            print("Interrupted by user")
            return 130
        except Exception as e:
            print(f"Error processing {p}: {e}")
    if any_updates:
        print("✅ Batch translation completed. Files updated.")
    else:
        print("ℹ️  Batch translation completed. No changes detected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

