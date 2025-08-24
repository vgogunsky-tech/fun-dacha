#!/usr/bin/env python3
import csv
import os
import re
import sys
from typing import Dict, List, Tuple, Optional

WORKSPACE_DIR = "/workspace"
CSV_PATH = os.path.join(WORKSPACE_DIR, "list.csv")
HTML_PATH = os.path.join(WORKSPACE_DIR, "SourceData", "messages.html")
PHOTOS_DIR = os.path.join(WORKSPACE_DIR, "SourceData", "photos")

# Compile regex to extract photo filename and adjacent text in the same message block
PHOTO_TEXT_PATTERN = re.compile(
    r"<a\s+class=\"photo_wrap[^>]*?href=\"photos/([^\"]+)\"[\s\S]*?</a>[\s\S]*?<div\s+class=\"text\">\s*(.*?)\s*</div>",
    re.IGNORECASE,
)

TAG_STRIPPER = re.compile(r"<[^>]+>")
WHITESPACE_NORMALIZER = re.compile(r"\s+")


def normalize_text(text: str) -> str:
    if text is None:
        return ""
    # Remove HTML tags, normalize whitespace, lower-case for comparison
    no_tags = TAG_STRIPPER.sub(" ", text)
    normalized = WHITESPACE_NORMALIZER.sub(" ", no_tags).strip().casefold()
    return normalized


def extract_photo_to_text(html: str) -> List[Tuple[str, str]]:
    pairs: List[Tuple[str, str]] = []
    for match in PHOTO_TEXT_PATTERN.finditer(html):
        filename = match.group(1)
        raw_text = match.group(2)
        text_norm = normalize_text(raw_text)
        if not filename or not text_norm:
            continue
        pairs.append((filename, text_norm))
    return pairs


def load_csv_rows(csv_path: str) -> Tuple[List[Dict[str, str]], List[str]]:
    with open(csv_path, "r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fieldnames = reader.fieldnames or []
    return rows, fieldnames


def write_csv_rows(csv_path: str, rows: List[Dict[str, str]], fieldnames: List[str]) -> None:
    tmp_path = csv_path + ".tmp"
    with open(tmp_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, quoting=csv.QUOTE_MINIMAL)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)
    os.replace(tmp_path, csv_path)


def best_match_for_descriptions(
    message_text: str,
    names: List[str],
    descriptions: List[str],
) -> int:
    # Compute a score: prioritize long substring matches on descriptions, then names
    score = 0
    for desc in descriptions:
        desc_norm = normalize_text(desc)
        if not desc_norm:
            continue
        if desc_norm and desc_norm in message_text:
            # Full description contained
            score = max(score, min(100, 50 + len(desc_norm) // 10))
        else:
            # Try prefix overlap if description is long
            prefix_len = 40 if len(desc_norm) >= 80 else 25 if len(desc_norm) >= 50 else 18
            prefix = desc_norm[:prefix_len]
            if prefix and prefix in message_text:
                score = max(score, 35 + prefix_len // 5)
    for name in names:
        name_norm = normalize_text(name)
        if not name_norm:
            continue
        if name_norm and name_norm in message_text:
            score = max(score, 30 + min(20, len(name_norm) // 2))
    return score


def map_products_to_photos(
    rows: List[Dict[str, str]],
    photo_texts: List[Tuple[str, str]],
) -> Dict[int, str]:
    # Build a mapping from row index to photo filename
    mapping: Dict[int, str] = {}

    for row_index, row in enumerate(rows):
        name_uk = row.get("Название (укр)", "")
        name_ru = row.get("Название (рус)", "")
        desc_uk = row.get("Описание (укр)", "")
        desc_ru = row.get("Описание (рус)", "")

        names = [name_uk, name_ru]
        descriptions = [desc_uk, desc_ru]

        best_score = 0
        best_photo: Optional[str] = None

        for photo_filename, message_text in photo_texts:
            score = best_match_for_descriptions(message_text, names, descriptions)
            if score > best_score:
                best_score = score
                best_photo = photo_filename

        # Only accept sufficiently confident matches
        if best_photo and best_score >= 45:
            mapping[row_index] = best_photo

    return mapping


def main() -> int:
    if not os.path.exists(CSV_PATH):
        print(f"CSV not found: {CSV_PATH}")
        return 1
    if not os.path.exists(HTML_PATH):
        print(f"HTML not found: {HTML_PATH}")
        return 1
    if not os.path.isdir(PHOTOS_DIR):
        print(f"Photos dir not found: {PHOTOS_DIR}")
        return 1

    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()

    photo_texts = extract_photo_to_text(html)
    # Filter only photos that actually exist on disk
    available_photos = set(os.listdir(PHOTOS_DIR))
    photo_texts = [pt for pt in photo_texts if pt[0] in available_photos]

    rows, fieldnames = load_csv_rows(CSV_PATH)

    # Ensure image column exists
    image_col = "image"
    if image_col not in fieldnames:
        fieldnames.append(image_col)
        for r in rows:
            r[image_col] = ""

    mapping = map_products_to_photos(rows, photo_texts)

    updated = 0
    for idx, photo in mapping.items():
        prev = rows[idx].get(image_col, "")
        if not prev:
            rows[idx][image_col] = photo
            updated += 1
        else:
            # If already set and different, prefer keeping existing; could be overridden if desired
            if prev != photo:
                # Overwrite only if our confidence is likely high; for now, keep existing
                pass

    write_csv_rows(CSV_PATH, rows, fieldnames)

    print(f"Found {len(photo_texts)} photo+text posts. Updated {updated} rows with image filenames.")
    return 0


if __name__ == "__main__":
    sys.exit(main())