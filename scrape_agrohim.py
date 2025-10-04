import csv
import os
import re
import sys
import time
from dataclasses import dataclass
from typing import List, Optional, Dict, Tuple

import requests
from bs4 import BeautifulSoup
from slugify import slugify
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type


BASE_URL = "https://agro-him.com.ua"
UA_BASE = f"{BASE_URL}/ua"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
    "Accept-Language": "uk-UA,uk;q=0.9,ru;q=0.8,en;q=0.7",
}


@retry(reraise=True, stop=stop_after_attempt(4), wait=wait_exponential(multiplier=1, min=1, max=8), retry=retry_if_exception_type((requests.RequestException,)))
def get(url: str) -> requests.Response:
    resp = requests.get(url, headers=HEADERS, timeout=20)
    resp.raise_for_status()
    return resp


def ensure_dirs() -> None:
    os.makedirs("data/images/categories", exist_ok=True)
    os.makedirs("data/images/products", exist_ok=True)


def read_categories_csv(path: str) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)
    return rows


def write_categories_csv(path: str, rows: List[Dict[str, str]]) -> None:
    # Preserve original headers order
    headers = ["id", "name", "parentId", "tag", "description (ukr)", "primary_image"]
    with open(path, "w", newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k, "") for k in headers})


def dedupe_categories_csv(path: str) -> None:
    rows = read_categories_csv(path)
    seen: Dict[str, Dict[str, str]] = {}
    desired = {
        "Гербіциди",
        "Інсектициди",
        "Фунгіциди",
        "Протруйники",
        "Біопрепарати",
        "Прилипачі",
        "Добрива та стимулятори",
        "Обробка саду",
        "Цибуля саджанка",
        "Проти побутових комах",
        "Родентициди",
        "Молюскоциди",
        "Насіння",
    }
    for r in rows:
        name = r.get("name", "")
        pid = r.get("parentId", "")
        if name in desired and pid == "400":
            if name not in seen:
                seen[name] = r
            else:
                # keep the one with smaller id
                try:
                    cur = int(seen[name].get("id", "0") or 0)
                    new = int(r.get("id", "0") or 0)
                except Exception:
                    cur, new = 0, 0
                if new < cur:
                    seen[name] = r
    # rebuild list: all non-desired or non-400 entries as-is + deduped desired
    kept_keys = set()
    deduped: List[Dict[str, str]] = []
    # first, include all rows that are not desired name under 400
    for r in rows:
        name = r.get("name", "")
        pid = r.get("parentId", "")
        if not (name in desired and pid == "400"):
            deduped.append(r)
    # then include the unique desired entries
    deduped.extend(seen[n] for n in sorted(seen.keys()))
    write_categories_csv(path, deduped)


def append_products_csv(path: str, product_rows: List[List[str]]) -> None:
    # Append rows exactly to existing CSV with the same header structure
    # We'll read the header line to compute number of columns and then write rows padded with empties
    with open(path, "r", encoding="utf-8") as f:
        header_line = f.readline().rstrip("\n")
    headers = header_line.split(",")
    num_cols = len(headers)

    with open(path, "a", newline='', encoding="utf-8") as f:
        writer = csv.writer(f)
        for row in product_rows:
            if len(row) < num_cols:
                row = row + [""] * (num_cols - len(row))
            elif len(row) > num_cols:
                row = row[:num_cols]
            writer.writerow(row)


def download_image(url: str, dest_path: str) -> Optional[str]:
    try:
        r = get(url)
        with open(dest_path, "wb") as f:
            f.write(r.content)
        return dest_path
    except Exception:
        return None


def build_category_id_map(home_cats: List[Tuple[str, str]]) -> Dict[str, int]:
    # Assign category IDs deterministically starting at 401 according to home order
    mapping: Dict[str, int] = {}
    next_id = 401
    for title, _ in home_cats:
        if title not in mapping:
            mapping[title] = next_id
            next_id += 1
    return mapping


def add_missing_categories(categories_csv: str) -> Dict[str, int]:
    existing = read_categories_csv(categories_csv)
    existing_names = {r.get("name", "") for r in existing}
    mapping: Dict[str, int] = {}
    # Preload existing mapping for ones already present (like 401 Гербіциди)
    for r in existing:
        name = r.get("name", "")
        try:
            cid = int(r.get("id", "0") or 0)
        except ValueError:
            continue
        if name:
            mapping[name] = cid

    home_cats = extract_home_categories()
    # Build deterministic IDs 401..
    deterministic_map = build_category_id_map(home_cats)
    rows_to_add: List[Dict[str, str]] = []
    for title, url in home_cats:
        if title in existing_names:
            # Preserve existing mapping if already present, else set deterministic
            continue
        cid = deterministic_map[title]
        mapping[title] = cid
        # primary_image filename convention c<ID>.jpg
        primary_image = f"c{cid}.jpg"
        rows_to_add.append({
            "id": str(cid),
            "name": title,
            "parentId": "400",
            "tag": "",
            "description (ukr)": title,
            "primary_image": primary_image,
        })
        seen_titles.add(title)
    if rows_to_add:
        # Keep original rows then append
        updated = existing + rows_to_add
        write_categories_csv(categories_csv, updated)
    return mapping


def parse_price_from_card(card: BeautifulSoup) -> Optional[str]:
    price = None
    # Try product-card__price .value
    pnode = card.select_one(".product-card__price .value")
    if pnode and pnode.text.strip():
        price = pnode.text.strip()
    return price


def parse_category_product_cards(cat_url: str, page_limit: Optional[int] = None) -> List[str]:
    # Return product URLs from one category page, handle pagination
    urls: List[str] = []
    page = 1
    while True:
        url = cat_url if page == 1 else f"{cat_url}/page-{page}"
        print(f"[info] fetching category page: {url}")
        sys.stdout.flush()
        html = get(url).text
        soup = BeautifulSoup(html, "html.parser")
        for a in soup.select(".product-card .product-card__name[href], .product-card a.product-card__photo[href]"):
            href = a.get("href")
            if href and href.startswith("http"):
                urls.append(href)
        print(f"[info] page {page} found {len(urls)} product urls so far")
        sys.stdout.flush()
        # pagination: look for global-pagination__pages active and next numbers
        pag = soup.select_one(".global-pagination__pages")
        if not pag:
            break
        max_page = page
        for a in pag.select("a.global-pagination__page[data-num]"):
            try:
                num = int(a.get("data-num", ""))
                if num > max_page:
                    max_page = num
            except ValueError:
                pass
        if page_limit is not None and page >= page_limit:
            break
        if page >= max_page:
            break
        page += 1
        time.sleep(0.5)
    # Deduplicate
    return list(dict.fromkeys(urls))


def extract_product(product_url: str) -> Optional[Dict[str, str]]:
    print(f"[info] fetch product: {product_url}")
    sys.stdout.flush()
    html = get(product_url).text
    soup = BeautifulSoup(html, "html.parser")

    # Title
    title_node = soup.select_one("h1.global-maintitle")
    title = title_node.get_text(strip=True) if title_node else None

    # Price via JSON-LD if present
    price: Optional[str] = None
    for script in soup.find_all("script", {"type": "application/ld+json"}):
        try:
            txt = script.string or script.text or ""
            if "\"@type\":\"Product\"" in txt or '"@type":"Product"' in txt:
                # crude extract price
                m = re.search(r'"price":\s*([0-9]+(?:\.[0-9]+)?)', txt)
                if m:
                    price = m.group(1)
        except Exception:
            pass

    # Description
    desc_node = soup.select_one(".product-page-about__description-info")
    description = desc_node.get_text(" ", strip=True) if desc_node else ""

    # Main image: prefer JSON-LD image if available
    image_url: Optional[str] = None
    for script in soup.find_all("script", {"type": "application/ld+json"}):
        txt = script.string or script.text or ""
        m = re.search(r'"image":\s*"(https?:[^\"]+)"', txt)
        if m:
            image_url = m.group(1)
            break
    if not image_url:
        # fallback: product-card on page or meta og:image
        og = soup.find("meta", {"property": "og:image"})
        if og and og.get("content"):
            image_url = og["content"]

    if not title:
        return None

    return {
        "title": title,
        "description": description,
        "price": price or "",
        "image_url": image_url or "",
    }


def allocate_product_ids(start_from: int, count: int) -> List[str]:
    # Create product_id like p<id> where id continues from the last one in list.csv
    return [f"p{start_from + i:06d}" for i in range(1, count + 1)]


def find_last_product_numeric_id(list_csv: str) -> int:
    last_num = 100000
    with open(list_csv, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            pid = r.get("product_id", "")
            if pid and pid.startswith("p"):
                try:
                    n = int(pid[1:])
                    if n > last_num:
                        last_num = n
                except Exception:
                    pass
    return last_num


def main() -> None:
    ensure_dirs()
    categories_csv = os.path.join("data", "categories_list.csv")
    list_csv = os.path.join("data", "list.csv")

    # 1) Cleanup duplicate category rows and ensure categories present
    try:
        dedupe_categories_csv(categories_csv)
    except Exception:
        pass
    mapping = add_missing_categories(categories_csv)
    print(f"[info] categories mapping prepared: {len(mapping)} entries")
    sys.stdout.flush()

    # 2) Enumerate target categories and crawl products
    home = extract_home_categories()
    # Optional filter: AGRO_ONLY (substring) or AGRO_CATS (comma-separated exact titles)
    only = os.environ.get("AGRO_ONLY")
    cats_env = os.environ.get("AGRO_CATS")
    if cats_env:
        wanted = {c.strip() for c in cats_env.split(",") if c.strip()}
        home = [(n, u) for n, u in home if n in wanted]
    elif only:
        home = [(n, u) for n, u in home if only.lower() in n.lower()]
    # Category URL might differ for some names; use what we extracted
    name_to_url = {name: url for name, url in home}

    # Prepare product rows to append to list.csv
    rows_to_append: List[List[str]] = []
    # Track per-category list index to form product_id p{cat}{index}
    category_index: Dict[int, int] = {}
    next_num = find_last_product_numeric_id(list_csv)

    for name, cat_url in home:
        cat_id = mapping.get(name)
        if not cat_id:
            # Should not happen; skip
            continue
        # Limit pages during initial run to avoid excessive time
        page_limit = int(os.environ.get("AGRO_PAGES", "2"))
        print(f"[info] processing category '{name}' (id={cat_id}) with page_limit={page_limit}")
        sys.stdout.flush()
        product_urls = parse_category_product_cards(cat_url, page_limit=page_limit)
        # Optional product cap per category
        max_products_env = os.environ.get("AGRO_MAX_PRODUCTS")
        if max_products_env:
            try:
                cap = int(max_products_env)
                product_urls = product_urls[:cap]
            except Exception:
                pass
        if not product_urls:
            continue

        # initialize category index if missing
        if cat_id not in category_index:
            category_index[cat_id] = 0

        product_ids = allocate_product_ids(next_num, len(product_urls))
        next_num += len(product_urls)

        # For category image, take first product image if not present
        cat_image_path = os.path.join("data", "images", "categories", f"c{cat_id}.jpg")
        category_image_saved = os.path.exists(cat_image_path)

        saved_rows = 0
        for p_url in product_urls:
            pdata = extract_product(p_url)
            if not pdata:
                continue
            category_index[cat_id] += 1
            idx_in_cat = category_index[cat_id]
            product_id = f"p{int(cat_id):03d}{idx_in_cat:03d}"

            # Download image to data/images/products/<product_id>.jpg
            img_name = f"{product_id}.jpg"
            img_path = os.path.join("data", "images", "products", img_name)
            image_url = pdata.get("image_url") or ""
            if image_url:
                # Convert thumbnail variants to 428x428 if needed
                image_url = image_url.replace("-12x178-product_thumb", "-428x428").replace("-228x228", "-428x428")
                downloaded = download_image(image_url, img_path)
                # also set category image if not yet saved
                if downloaded and not category_image_saved:
                    try:
                        # copy bytes to category image
                        with open(downloaded, "rb") as src, open(cat_image_path, "wb") as dst:
                            dst.write(src.read())
                        category_image_saved = True
                    except Exception:
                        pass

            # Prepare row matching list.csv header
            # Columns: id,Название (укр),Название (рус),Описание (укр),Описание (рус),primary_image,category_id,subcategory_id,product_id,validated,year,availability,images,tags,price,...
            row = [
                "",  # id (auto/incremental in existing, we leave empty)
                pdata.get("title", ""),  # Название (укр)
                "",  # Название (рус)
                pdata.get("description", ""),  # Описание (укр)
                "",  # Описание (рус)
                img_name,  # primary_image
                str(cat_id),  # category_id
                "",  # subcategory_id
                product_id,  # product_id
                "1",  # validated
                time.strftime("%Y"),  # year
                "1",  # availability
                "",  # images
                "",  # tags
                pdata.get("price", ""),  # price
            ]
            rows_to_append.append(row)
            saved_rows += 1
            # write immediately for quicker observable progress
            append_products_csv(list_csv, [row])
            print(f"[info] appended product {product_id} ({pdata.get('title','')})")
            sys.stdout.flush()
            # Be polite
            time.sleep(0.2)
        print(f"[info] category '{name}' saved rows: {saved_rows}")
        sys.stdout.flush()
        if rows_to_append:
            print(f"[info] appending {len(rows_to_append)} rows for category '{name}'")
            sys.stdout.flush()
            append_products_csv(list_csv, rows_to_append)
            rows_to_append = []

    if rows_to_append:
        print(f"[info] appending total rows: {len(rows_to_append)} to list.csv")
        sys.stdout.flush()
        append_products_csv(list_csv, rows_to_append)
        print("[info] append complete")
        sys.stdout.flush()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

