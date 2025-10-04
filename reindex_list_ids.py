import csv

LIST_CSV_PATH = "data/list.csv"


def reindex_ids_by_row(path: str) -> int:
    with open(path, encoding="utf-8") as f:
        rows = list(csv.reader(f))
    if not rows:
        return 0
    header = rows[0]
    data = rows[1:]

    # Ensure 'id' is the first column as in current schema
    # Populate only missing ids, based on row order (1-based across data rows)
    fixed = 0
    for idx, row in enumerate(data, start=1):
        if len(row) == 0:
            continue
        if not (row[0] or "").strip():
            row[0] = str(idx)
            fixed += 1

    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(data)
    return fixed


def main():
    fixed = reindex_ids_by_row(LIST_CSV_PATH)
    print(f"Fixed {fixed} missing ids")


if __name__ == "__main__":
    main()

