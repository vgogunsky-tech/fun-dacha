import csv

LIST_CSV_PATH = "data/list.csv"


def parse_int(value: str) -> int:
    try:
        return int((value or "").strip())
    except Exception:
        return -1


def reindex_from_840(path: str) -> int:
    with open(path, encoding="utf-8") as f:
        rows = list(csv.reader(f))
    if not rows:
        return 0
    header = rows[0]
    data = rows[1:]

    fixed = 0
    # Keep ids < 840 as-is; reassign all others (missing or >= 840) starting at 840
    next_id = 840
    for row in data:
        if not row:
            continue
        cur_id = parse_int(row[0] if len(row) > 0 else "")
        if cur_id >= 0 and cur_id < 840:
            # keep
            continue
        # assign new sequential id
        if len(row) == 0:
            row.append(str(next_id))
        else:
            row[0] = str(next_id)
        next_id += 1
        fixed += 1

    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(data)
    return fixed


def main():
    fixed = reindex_from_840(LIST_CSV_PATH)
    print(f"Reindexed {fixed} rows from id 840")


if __name__ == "__main__":
    main()

