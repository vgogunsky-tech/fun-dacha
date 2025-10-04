import csv
import os
import re
import sys
import time
from typing import Dict, List, Tuple, Optional

import requests
from bs4 import BeautifulSoup
from PIL import Image
from io import BytesIO

BASE_URL = "https://agro-him.com.ua"
UA_BASE = f"{BASE_URL}/ua"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
    "Accept-Language": "uk-UA,uk;q=0.9,ru;q=0.8,en;q=0.7",
}


def get(url: str) -> requests.Response:
    resp = requests.get(url, headers=HEADERS, timeout=20)
    resp.raise_for_status()
    return resp


def download_as_jpeg(url: str, dest_path: str) -> bool:
    try:
        r = get(url)
        content = r.content
        try:
            img = Image.open(BytesIO(content))
            rgb = img.convert("RGB")
            rgb.save(dest_path, format="JPEG", quality=90)
        except Exception:
            with open(dest_path, "wb") as f:
                f.write(content)
        return True
    except Exception:
        return False


DEFAULT_BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.environ.get("FUN_DATAROOT", DEFAULT_BASE_DIR)


def ensure_dirs() -> None:
    os.makedirs(os.path.join(BASE_DIR, "data", "images", "products"), exist_ok=True)


def read_list_rows(path: str) -> Tuple[List[str], List[List[str]]]:
    with open(path, encoding="utf-8") as f:
        rows = list(csv.reader(f))
    return rows[0], rows[1:]


def write_list_rows(path: str, header: List[str], data: List[List[str]]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(data)


def parse_category_product_urls(cat_url: str) -> Dict[str, str]:
    title_to_url: Dict[str, str] = {}
    page = 1
    while True:
        url = cat_url if page == 1 else f"{cat_url}/page-{page}"
        html = get(url).text
        soup = BeautifulSoup(html, "html.parser")
        for a in soup.select(".product-card .product-card__name[href], .product-card a.product-card__photo[href]"):
            href = a.get("href")
            # Title can be inside span
            name_node = a.select_one("span") or a
            title = name_node.get_text(strip=True) if name_node else None
            if href and title:
                title_to_url.setdefault(title, href)
        pag = soup.select_one(".global-pagination__pages")
        if not pag:
            break
        max_page = page
        for a in pag.select("a.global-pagination__page[data-num]"):
            try:
                n = int(a.get("data-num", ""))
                if n > max_page:
                    max_page = n
            except Exception:
                pass
        if page >= max_page:
            break
        page += 1
        time.sleep(0.2)
    return title_to_url


def extract_product_image(product_url: str) -> Optional[str]:
    try:
        html = get(product_url).text
        soup = BeautifulSoup(html, "html.parser")
        # Prefer JSON-LD image
        for script in soup.find_all("script", {"type": "application/ld+json"}):
            txt = script.string or script.text or ""
            m = re.search(r'"image":\s*"(https?:[^\"]+)"', txt)
            if m:
                return m.group(1)
        # Fallback og:image
        og = soup.find("meta", {"property": "og:image"})
        if og and og.get("content"):
            return og["content"]
    except Exception:
        return None
    return None


def backfill_for_category(list_csv: str, category_id: int, cat_url: str) -> Tuple[int, int]:
    header, rows = read_list_rows(list_csv)
    col = {name: i for i, name in enumerate(header)}
    ix_name = col.get("Название (укр)")
    ix_cat = col.get("category_id")
    ix_img = col.get("primary_image")
    ix_pid = col.get("product_id")
    ix_id = col.get("id")
    if None in (ix_name, ix_cat, ix_img, ix_pid, ix_id) or -1 in (ix_name, ix_cat, ix_img, ix_pid, ix_id):
        return (0, 0)

    ensure_dirs()
    prod_dir = os.path.join(BASE_DIR, "data", "images", "products")
    added = 0
    checked = 0

    # Build title -> product page URL map
    title_to_url = parse_category_product_urls(cat_url)

    for row in rows:
        # Only process new products (id >= 840) and matching category
        try:
            rid = int((row[ix_id] or "0").strip())
        except Exception:
            rid = 0
        if rid < 840:
            continue
        if (row[ix_cat] or "").strip() != str(category_id):
            continue
        checked += 1
        title = (row[ix_name] or "").strip()
        pid = (row[ix_pid] or "").strip()
        if not pid:
            continue
        img_name = (row[ix_img] or f"{pid}.jpg").strip()
        if not img_name:
            img_name = f"{pid}.jpg"
            row[ix_img] = img_name
        dest = os.path.join(prod_dir, img_name)
        # If file exists and is a valid image, skip
        if os.path.exists(dest):
            try:
                Image.open(dest).verify()
                continue
            except Exception:
                pass
        # Find URL by title
        purl = title_to_url.get(title)
        if not purl:
            continue
        # Extract main image URL
        img_url = extract_product_image(purl)
        if not img_url:
            continue
        # Normalize to 428x428 where possible
        img_url = img_url.replace("-12x178-product_thumb", "-428x428").replace("-228x228", "-428x428")
        if download_as_jpeg(img_url, dest):
            added += 1
        time.sleep(0.15)

    write_list_rows(list_csv, header, rows)
    return (checked, added)


def main():
    list_csv = os.path.join(BASE_DIR, "data", "list.csv")
    # Category 401 (Гербіциди)
    checked, added = backfill_for_category(list_csv, 401, f"{UA_BASE}/gerbicidi")
    print(f"Category 401: checked={checked}, added_images={added}")


if __name__ == "__main__":
    main()

