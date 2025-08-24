#!/usr/bin/env python3
import csv
import os

BASE = "/workspace/data"
CATS = os.path.join(BASE, "categories_list.csv")
IMG_DIR = os.path.join(BASE, "images", "categories")

MAPPING = {
    190: "Арбузы.jpg",
    150: "Баклажан.jpg",
    200: "Дыни.jpg",
    220: "Кабачки.jpg",
    120: "капуста.jpg",
    121: "капустабелокачанная.jpg",
    123: "капустакраснокачанная.jpg",
    122: "капустацветная.jpg",
    160: "Лук.jpg",
    170: "Морковь.jpg",
    110: "огурцы.jpg",
    230: "Патиссон.jpg",
    140: "перец.jpg",
    141: "Перец сладкий..jpg",
    142: "Перец горький.jpg",
    130: "редис.jpg",
    100: "томаты.jpg",
    101: "Томатывысокорослые.jpg",
    102: "среднерослыетоматы.jpg",
    210: "Тыквы.jpg",
    280: "Фасоль.jpg",
    281: "Фасоль спаржевая..jpg",
    282: "Фасоль зерновая.jpg",
}


def main() -> int:
    with open(CATS, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = reader.fieldnames or []

    if "primary_image" not in fields:
        fields.append("primary_image")
        for r in rows:
            r["primary_image"] = ""

    updated = 0
    for r in rows:
        try:
            cid = int(float(r.get("id", "").strip()))
        except Exception:
            continue
        if cid in MAPPING:
            filename = MAPPING[cid]
            # Only set if file exists to avoid dead links
            if os.path.isfile(os.path.join(IMG_DIR, filename)):
                if r.get("primary_image") != filename:
                    r["primary_image"] = filename
                    updated += 1

    tmp = CATS + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    os.replace(tmp, CATS)

    print(f"Updated primary_image for {updated} categories.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())