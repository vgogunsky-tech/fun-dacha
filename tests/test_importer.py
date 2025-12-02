from decimal import Decimal

from api.importer import PRICE_KEY, WEIGHT_KEY, CsvProduct
from api.utils import slugify


def build_row(**overrides):
    row = {
        "id": "1",
        "name": "Амурський тигр",
        "primary_image": "p100001.jpg",
        "category_id": "100",
        "subcategory_id": "101",
        "product_id": "SKU-1001",
        "availability": "25",
        PRICE_KEY: "99,5",
        WEIGHT_KEY: "1.2",
        "weight_class": "кг",
        "year": "2026",
        "created_at": "09/15/2025",
        "updated_at": "11/30/2025",
        "seo": "amurskyi-tyhr",
        "secondary_images": "p100001_1.jpg, p100001_2.jpg",
        "tags": "tall,sweet",
        "description": "UA description",
        "name_ru": "Амурский тигр",
        "description_ru": "RU description",
    }
    row.update(overrides)
    return row


def test_csv_product_parses_expected_fields():
    product = CsvProduct.from_row(2, build_row())
    assert product.product_id == 1
    assert product.category_ids() == [100, 101]
    assert product.secondary_images == ["p100001_1.jpg", "p100001_2.jpg"]
    assert product.price == Decimal("99.5")
    assert product.weight == Decimal("1.2")
    assert product.tags == ["tall", "sweet"]
    assert product.name_ru == "Амурский тигр"
    assert product.description_ru == "RU description"


def test_slugify_transliterates_and_normalizes():
    slug = slugify("Чорний принц 2025")
    assert slug.endswith("2025")
    assert slug.replace("-", "").isalnum()
    assert slug == slug.lower()
    assert slugify("", fallback="product-1") == "product-1"
