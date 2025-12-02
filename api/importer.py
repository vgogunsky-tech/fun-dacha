from __future__ import annotations

import csv
import time
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Dict, Iterable, List, Optional

from fastapi import HTTPException
from sqlalchemy import bindparam, text
from sqlalchemy.orm import Session

from .config import Settings
from .schemas import ImportOptions, ImportSummary
from .utils import batched, parse_date, slugify, to_html_paragraphs

PRICE_KEY = "price (цена)"
WEIGHT_KEY = "weight (вес)"


def _to_int(value: str | None) -> Optional[int]:
    if value is None:
        return None
    value = value.strip()
    if not value:
        return None
    return int(float(value))


def _to_decimal(value: str | None) -> Optional[Decimal]:
    if value is None:
        return None
    clean = value.replace(" ", "").replace(",", ".").strip()
    if not clean:
        return None
    try:
        return Decimal(clean)
    except InvalidOperation as exc:
        raise ValueError(f"Cannot parse decimal value '{value}'") from exc


def _split_list(value: str | None) -> List[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(",") if item.strip()]


@dataclass
class CsvProduct:
    row_number: int
    product_id: int
    name_uk: str
    name_ru: Optional[str]
    description_uk: Optional[str]
    description_ru: Optional[str]
    category_id: Optional[int]
    subcategory_id: Optional[int]
    product_code: str
    availability: int
    price: Decimal
    weight: Optional[Decimal]
    weight_class: Optional[str]
    year: Optional[int]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    seo: Optional[str]
    primary_image: Optional[str]
    secondary_images: List[str]
    tags: List[str]

    @classmethod
    def from_row(cls, row_number: int, raw: dict) -> "CsvProduct":
        name = (raw.get("name") or "").strip()
        if not name:
            raise ValueError("Missing product name")
        product_id = _to_int(raw.get("id"))
        if product_id is None:
            raise ValueError("Missing numeric id column")
        availability = _to_int(raw.get("availability")) or 0
        price = _to_decimal(raw.get(PRICE_KEY) or "0") or Decimal("0")
        weight = _to_decimal(raw.get(WEIGHT_KEY) or "") or None
        year = _to_int(raw.get("year"))
        created_at = parse_date(raw.get("created_at"))
        updated_at = parse_date(raw.get("updated_at"))
        return cls(
            row_number=row_number,
            product_id=product_id,
            name_uk=name,
            name_ru=(raw.get("name_ru") or "").strip() or None,
            description_uk=(raw.get("description") or "").strip() or None,
            description_ru=(raw.get("description_ru") or "").strip() or None,
            category_id=_to_int(raw.get("category_id")),
            subcategory_id=_to_int(raw.get("subcategory_id")),
            product_code=(raw.get("product_id") or "").strip() or f"SKU-{product_id}",
            availability=availability,
            price=price,
            weight=weight,
            weight_class=(raw.get("weight_class") or "").strip().lower() or None,
            year=year,
            created_at=created_at,
            updated_at=updated_at or created_at,
            seo=(raw.get("seo") or "").strip() or None,
            primary_image=(raw.get("primary_image") or "").strip() or None,
            secondary_images=_split_list(raw.get("secondary_images")),
            tags=_split_list(raw.get("tags")),
        )

    def category_ids(self) -> List[int]:
        categories: List[int] = []
        if self.category_id:
            categories.append(self.category_id)
        if self.subcategory_id and self.subcategory_id not in categories:
            categories.append(self.subcategory_id)
        return categories


class ProductImporter:
    def __init__(self, session: Session, settings: Settings):
        self.session = session
        self.settings = settings
        self.prefix = settings.table_prefix
        self.language_ids = self._load_language_ids(settings.default_language_codes)
        self.weight_class_cache: Dict[str, int] = {}
        self.category_cache: Dict[int, bool] = {}
        self.missing_categories: set[int] = set()
        self.seo_table = self._detect_seo_table()

    def import_from_csv(self, options: ImportOptions) -> ImportSummary:
        start = time.perf_counter()
        csv_path = Path(options.csv_path or self.settings.csv_path)
        if not csv_path.exists():
            raise HTTPException(status_code=404, detail=f"CSV file not found: {csv_path}")

        rows = self._read_csv(csv_path, options)
        dry_run = options.dry_run if options.dry_run is not None else self.settings.dry_run

        imported = updated = skipped = 0
        errors: List[str] = []

        if dry_run:
            for row in rows:
                try:
                    self._validate_row(row)
                except Exception as exc:
                    errors.append(f"Row {row.row_number}: {exc}")
            duration = int((time.perf_counter() - start) * 1000)
            return ImportSummary(
                total_rows=len(rows),
                imported=0,
                updated=0,
                skipped=0,
                dry_run=True,
                duration_ms=duration,
                missing_categories=sorted(self.missing_categories),
                errors=errors,
            )

        for batch in batched(rows, self.settings.batch_size):
            for row in batch:
                try:
                    with self.session.begin_nested():
                        action = self._upsert_product(row, options.skip_existing)
                    if action == "created":
                        imported += 1
                    elif action == "updated":
                        updated += 1
                    else:
                        skipped += 1
                except Exception as exc:
                    errors.append(
                        f"Row {row.row_number} (product {row.product_id}): {exc}"
                    )

        duration = int((time.perf_counter() - start) * 1000)
        return ImportSummary(
            total_rows=len(rows),
            imported=imported,
            updated=updated,
            skipped=skipped,
            dry_run=False,
            duration_ms=duration,
            missing_categories=sorted(self.missing_categories),
            errors=errors,
        )

    def _read_csv(self, csv_path: Path, options: ImportOptions) -> List[CsvProduct]:
        rows: List[CsvProduct] = []
        with csv_path.open(encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for idx, raw in enumerate(reader, start=2):
                try:
                    record = CsvProduct.from_row(idx, raw)
                except Exception as exc:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Unable to parse row {idx}: {exc}",
                    ) from exc
                if options.product_ids and record.product_id not in options.product_ids:
                    continue
                rows.append(record)
                if options.limit and len(rows) >= options.limit:
                    break
        return rows

    def _validate_row(self, row: CsvProduct) -> None:
        if not row.primary_image:
            raise ValueError("primary_image is required")
        if not row.category_ids():
            self.missing_categories.add(-1)
        for category_id in row.category_ids():
            if not self._category_exists(category_id):
                self.missing_categories.add(category_id)

    def _upsert_product(self, row: CsvProduct, skip_existing: bool) -> str:
        exists = self._product_exists(row.product_id)
        if exists and skip_existing:
            return "skipped"
        self._upsert_product_table(row)
        self._upsert_descriptions(row)
        self._sync_categories(row)
        self._sync_store(row)
        self._sync_images(row)
        self._sync_seo(row)
        return "updated" if exists else "created"

    def _product_exists(self, product_id: int) -> bool:
        sql = text(f"SELECT 1 FROM {self.prefix}product WHERE product_id=:pid LIMIT 1")
        return bool(self.session.execute(sql, {"pid": product_id}).scalar())

    def _upsert_product_table(self, row: CsvProduct) -> None:
        stock_status_id = (
            self.settings.in_stock_status_id
            if row.availability > 0
            else self.settings.out_of_stock_status_id
        )
        status = 1 if row.availability > 0 else 0
        weight_class_id = self._resolve_weight_class(row.weight_class)
        now = datetime.utcnow()
        sql = text(
            f"""
            INSERT INTO {self.prefix}product
            (product_id, model, sku, quantity, stock_status_id, image, price, status,
             tax_class_id, date_available, date_added, date_modified, weight, weight_class_id,
             minimum, shipping, subtract, sort_order, points, manufacturer_id)
            VALUES
            (:product_id, :model, :sku, :quantity, :stock_status_id, :image, :price, :status,
             :tax_class_id, :date_available, :date_added, :date_modified, :weight, :weight_class_id,
             :minimum, :shipping, :subtract, :sort_order, :points, :manufacturer_id)
            ON DUPLICATE KEY UPDATE
             model=VALUES(model),
             sku=VALUES(sku),
             quantity=VALUES(quantity),
             stock_status_id=VALUES(stock_status_id),
             image=VALUES(image),
             price=VALUES(price),
             status=VALUES(status),
             tax_class_id=VALUES(tax_class_id),
             date_available=VALUES(date_available),
             date_modified=VALUES(date_modified),
             weight=VALUES(weight),
             weight_class_id=VALUES(weight_class_id),
             minimum=VALUES(minimum),
             shipping=VALUES(shipping),
             subtract=VALUES(subtract),
             sort_order=VALUES(sort_order)
            """
        )
        params = {
            "product_id": row.product_id,
            "model": row.product_code,
            "sku": row.product_code,
            "quantity": row.availability,
            "stock_status_id": stock_status_id,
            "image": self._build_image_path(row.primary_image),
            "price": float(row.price),
            "status": status,
            "tax_class_id": self.settings.default_tax_class_id,
            "date_available": (row.created_at or now).date(),
            "date_added": row.created_at or now,
            "date_modified": row.updated_at or now,
            "weight": float(row.weight) if row.weight is not None else None,
            "weight_class_id": weight_class_id,
            "minimum": self.settings.default_minimum,
            "shipping": int(bool(self.settings.default_shipping)),
            "subtract": int(bool(self.settings.default_subtract)),
            "sort_order": row.product_id,
            "points": 0,
            "manufacturer_id": 0,
        }
        self.session.execute(sql, params)

    def _upsert_descriptions(self, row: CsvProduct) -> None:
        sql = text(
            f"""
            INSERT INTO {self.prefix}product_description
            (product_id, language_id, name, description, meta_title, meta_description, meta_keyword, tag)
            VALUES
            (:product_id, :language_id, :name, :description, :meta_title, :meta_description, :meta_keyword, :tag)
            ON DUPLICATE KEY UPDATE
              name=VALUES(name),
              description=VALUES(description),
              meta_title=VALUES(meta_title),
              meta_description=VALUES(meta_description),
              meta_keyword=VALUES(meta_keyword),
              tag=VALUES(tag)
            """
        )
        tag_string = ", ".join(row.tags)
        descriptions = {
            "uk-ua": (row.name_uk, row.description_uk),
            "ru-ru": (row.name_ru or row.name_uk, row.description_ru or row.description_uk),
        }
        for code, language_id in self.language_ids.items():
            if code not in descriptions:
                continue
            name, description = descriptions[code]
            if not name:
                name = row.name_uk
            description_html = to_html_paragraphs(description or row.description_uk or row.name_uk)
            meta_description = (description or row.description_uk or row.name_uk or "")[:240]
            params = {
                "product_id": row.product_id,
                "language_id": language_id,
                "name": name,
                "description": description_html,
                "meta_title": name,
                "meta_description": meta_description,
                "meta_keyword": tag_string,
                "tag": tag_string,
            }
            self.session.execute(sql, params)

    def _sync_categories(self, row: CsvProduct) -> None:
        delete_sql = text(
            f"DELETE FROM {self.prefix}product_to_category WHERE product_id=:product_id"
        )
        self.session.execute(delete_sql, {"product_id": row.product_id})
        insert_sql = text(
            f"""
            INSERT INTO {self.prefix}product_to_category (product_id, category_id)
            VALUES (:product_id, :category_id)
            """
        )
        for category_id in row.category_ids():
            if not self._category_exists(category_id):
                self.missing_categories.add(category_id)
                continue
            self.session.execute(insert_sql, {"product_id": row.product_id, "category_id": category_id})

    def _sync_store(self, row: CsvProduct) -> None:
        sql = text(
            f"""
            INSERT INTO {self.prefix}product_to_store (product_id, store_id)
            VALUES (:product_id, :store_id)
            ON DUPLICATE KEY UPDATE store_id=VALUES(store_id)
            """
        )
        self.session.execute(
            sql, {"product_id": row.product_id, "store_id": self.settings.default_store_id}
        )

    def _sync_images(self, row: CsvProduct) -> None:
        delete_sql = text(f"DELETE FROM {self.prefix}product_image WHERE product_id=:product_id")
        self.session.execute(delete_sql, {"product_id": row.product_id})
        if not row.secondary_images:
            return
        insert_sql = text(
            f"""
            INSERT INTO {self.prefix}product_image (product_id, image, sort_order)
            VALUES (:product_id, :image, :sort_order)
            """
        )
        for sort_order, image_name in enumerate(row.secondary_images, start=1):
            self.session.execute(
                insert_sql,
                {
                    "product_id": row.product_id,
                    "image": self._build_image_path(image_name),
                    "sort_order": sort_order,
                },
            )

    def _sync_seo(self, row: CsvProduct) -> None:
        query_value = f"product_id={row.product_id}"
        base_slug = row.seo or slugify(row.name_uk, fallback=f"product-{row.product_id}")
        if self.seo_table == "seo_url":
            delete_sql = text(
                f"DELETE FROM {self.prefix}seo_url WHERE query=:query"
            )
            self.session.execute(delete_sql, {"query": query_value})
            insert_sql = text(
                f"""
                INSERT INTO {self.prefix}seo_url (store_id, language_id, query, keyword)
                VALUES (:store_id, :language_id, :query, :keyword)
                """
            )
            for code, language_id in self.language_ids.items():
                keyword = base_slug if code == "uk-ua" else f"{base_slug}-{code}"
                self.session.execute(
                    insert_sql,
                    {
                        "store_id": self.settings.default_store_id,
                        "language_id": language_id,
                        "query": query_value,
                        "keyword": keyword,
                    },
                )
        else:
            delete_sql = text(
                f"DELETE FROM {self.prefix}url_alias WHERE query=:query"
            )
            self.session.execute(delete_sql, {"query": query_value})
            insert_sql = text(
                f"""
                INSERT INTO {self.prefix}url_alias (query, keyword)
                VALUES (:query, :keyword)
                """
            )
            keyword = base_slug
            self.session.execute(insert_sql, {"query": query_value, "keyword": keyword})

    def _load_language_ids(self, language_codes: Iterable[str]) -> Dict[str, int]:
        sql = (
            text(
                f"""
                SELECT code, language_id
                FROM {self.prefix}language
                WHERE code IN :codes
                """
            ).bindparams(bindparam("codes", expanding=True))
        )
        rows = self.session.execute(sql, {"codes": tuple(language_codes)}).mappings().all()
        mapping = {row["code"]: row["language_id"] for row in rows}
        missing = set(language_codes) - set(mapping)
        if missing:
            raise HTTPException(
                status_code=400,
                detail=f"Languages not found in database: {', '.join(sorted(missing))}",
            )
        return mapping

    def _resolve_weight_class(self, unit: Optional[str]) -> int:
        if not unit:
            return self.settings.fallback_weight_class_id
        normalized = unit.strip().lower()
        aliases = {
            "гр": "g",
            "г": "g",
            "грамм": "g",
            "кг": "kg",
            "kg": "kg",
            "шт": None,
            "pcs": None,
        }
        normalized = aliases.get(normalized, normalized)
        if normalized is None:
            return self.settings.fallback_weight_class_id
        if normalized in self.weight_class_cache:
            return self.weight_class_cache[normalized]
        sql = text(
            f"""
            SELECT wcd.weight_class_id
            FROM {self.prefix}weight_class_description AS wcd
            WHERE LOWER(wcd.unit) = :unit OR LOWER(wcd.title) = :unit
            LIMIT 1
            """
        )
        result = self.session.execute(sql, {"unit": normalized}).scalar()
        weight_class_id = result or self.settings.fallback_weight_class_id
        self.weight_class_cache[normalized] = weight_class_id
        return weight_class_id

    def _category_exists(self, category_id: int) -> bool:
        if category_id in self.category_cache:
            return self.category_cache[category_id]
        sql = text(
            f"SELECT category_id FROM {self.prefix}category WHERE category_id=:category_id LIMIT 1"
        )
        exists = bool(self.session.execute(sql, {"category_id": category_id}).scalar())
        self.category_cache[category_id] = exists
        return exists

    def _build_image_path(self, image_name: Optional[str]) -> Optional[str]:
        if not image_name:
            return None
        return f"{self.settings.image_base_path.rstrip('/')}/{image_name.strip()}"

    def _detect_seo_table(self) -> str:
        seo_table = f"{self.prefix}seo_url"
        url_alias_table = f"{self.prefix}url_alias"
        sql = text(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema=:schema AND table_name IN (:seo_url, :url_alias)
            """
        )
        result = self.session.execute(
            sql,
            {
                "schema": self.settings.db_name,
                "seo_url": seo_table,
                "url_alias": url_alias_table,
            },
        ).scalars().all()
        table_names = set(result)
        if seo_table in table_names:
            return "seo_url"
        if url_alias_table in table_names:
            return "url_alias"
        raise HTTPException(status_code=400, detail="Neither seo_url nor url_alias table exists")
