import csv
import os
import re
from typing import Dict, List, Tuple

from bs4 import BeautifulSoup
import requests

BASE_URL = "https://agro-him.com.ua"
UA_BASE = f"{BASE_URL}/ua"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
    "Accept-Language": "uk-UA,uk;q=0.9,ru;q=0.8,en;q=0.7",
}


def http_get(url: str) -> str:
    r = requests.get(url, headers=HEADERS, timeout=20)
    r.raise_for_status()
    return r.text


def extract_home_categories() -> List[Tuple[str, str]]:
    html = http_get(UA_BASE)
    soup = BeautifulSoup(html, "html.parser")
    titles: Dict[str, str] = {}
    for a in soup.select("a.catalog-section-card"):
        name_node = a.select_one(".catalog-section-card__name")
        if not name_node:
            continue
        title = name_node.get_text(strip=True)
        href = a.get("href")
        if not href:
            continue
        if title not in titles:
            titles[title] = href
    desired_order = [
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
    ]
    return [(t, titles[t]) for t in desired_order if t in titles]


def read_categories_csv(path: str) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)
    return rows


def write_categories_csv(path: str, rows: List[Dict[str, str]]) -> None:
    headers = ["id", "name", "parentId", "tag", "description (ukr)", "primary_image"]
    with open(path, "w", newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k, "") for k in headers})


def normalize_categories(categories_csv: str) -> Dict[str, int]:
    rows = read_categories_csv(categories_csv)
    desired = extract_home_categories()
    # Build name->new id mapping starting at 401
    name_to_id: Dict[str, int] = {}
    next_id = 401
    for title, _url in desired:
        name_to_id[title] = next_id
        next_id += 1

    # Rebuild CSV: keep all rows not under parentId 400, then add desired in order with new IDs
    new_rows: List[Dict[str, str]] = [r for r in rows if r.get("parentId", "") != "400"]
    for title, _url in desired:
        cid = name_to_id[title]
        new_rows.append({
            "id": str(cid),
            "name": title,
            "parentId": "400",
            "tag": "",
            "description (ukr)": title,
            "primary_image": f"c{cid}.jpg",
        })

    write_categories_csv(categories_csv, new_rows)

    # Rename existing category images c5xx -> c4xx if present
    img_dir = os.path.join("data", "images", "categories")
    for title, _url in desired:
        cid = name_to_id[title]
        target = os.path.join(img_dir, f"c{cid}.jpg")
        if os.path.exists(target):
            continue
        # try to find any existing image for this title with id starting with 5
        for name in os.listdir(img_dir):
            if not name.endswith(".jpg"):
                continue
            # no robust link title->image mapping; skip if no suitable source
        # we don't delete or move unknown images to avoid data loss

    return name_to_id


def read_list_csv(path: str) -> Tuple[List[str], List[List[str]]]:
    with open(path, encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
    header = rows[0]
    data = rows[1:]
    return header, data


def write_list_csv(path: str, header: List[str], data: List[List[str]]) -> None:
    with open(path, "w", newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(data)


def normalize_products(list_csv: str, name_to_id: Dict[str, int]) -> None:
    header, rows = read_list_csv(list_csv)
    # Column indices
    col_idx = {name: i for i, name in enumerate(header)}
    def gi(name: str) -> int:
        return col_idx.get(name, -1)

    id_i = gi("id")
    primary_i = gi("primary_image")
    cat_i = gi("category_id")
    pid_i = gi("product_id")

    if min(id_i, primary_i, cat_i, pid_i) < 0:
        raise RuntimeError("list.csv missing required columns")

    # find current max id
    max_id = 0
    for r in rows:
        try:
            rid = int((r[id_i] or "0").strip())
            if rid > max_id:
                max_id = rid
        except Exception:
            pass

    prod_img_dir = os.path.join("data", "images", "products")
    os.makedirs(prod_img_dir, exist_ok=True)

    for r in rows:
        # assign missing id
        if not r[id_i].strip():
            max_id += 1
            r[id_i] = str(max_id)
        try:
            rid = int(r[id_i])
        except Exception:
            continue
        cat = (r[cat_i] or "").strip()
        if not cat:
            continue
        # Ensure product_id pattern p{cat}{rid:03d}
        new_pid = f"p{int(cat):03d}{rid:03d}"
        old_pid = r[pid_i]
        r[pid_i] = new_pid
        # primary_image rename
        old_img = r[primary_i]
        new_img = f"{new_pid}.jpg"
        if old_img != new_img:
            old_path = os.path.join(prod_img_dir, old_img)
            new_path = os.path.join(prod_img_dir, new_img)
            if os.path.exists(old_path) and not os.path.exists(new_path):
                try:
                    os.rename(old_path, new_path)
                except Exception:
                    pass
            r[primary_i] = new_img

    write_list_csv(list_csv, header, rows)


def main() -> None:
    categories_csv = os.path.join("data", "categories_list.csv")
    list_csv = os.path.join("data", "list.csv")
    mapping = normalize_categories(categories_csv)
    normalize_products(list_csv, mapping)
    print("Migration complete")


if __name__ == "__main__":
    main()

