from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import List

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

REPO_ROOT = Path(__file__).resolve().parents[1].parent
DATA_DIR = REPO_ROOT / "data"


class Settings(BaseSettings):
    """Application-wide configuration loaded from environment variables."""

    # Database connection
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_user: str = "root"
    db_password: str = ""
    db_name: str = "bitnami_opencart"
    table_prefix: str = "oc_"

    # OpenCart specific defaults
    default_store_id: int = 0
    default_language_codes: List[str] = Field(default_factory=lambda: ["uk-ua", "ru-ru"])
    default_weight_class_unit: str = "g"
    fallback_weight_class_id: int = 1
    in_stock_status_id: int = 7
    out_of_stock_status_id: int = 5
    default_tax_class_id: int = 0
    default_minimum: int = 1
    default_shipping: bool = True
    default_subtract: bool = True

    # Import behaviour
    csv_path: Path = DATA_DIR / "list.csv"
    batch_size: int = 100
    image_base_path: str = "catalog/products"
    dry_run: bool = False

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @field_validator("table_prefix")
    @classmethod
    def _normalize_prefix(cls, value: str) -> str:
        return value if value.endswith("_") else f"{value}_"

    @field_validator("csv_path", mode="before")
    @classmethod
    def _resolve_csv_path(cls, value) -> Path:
        if isinstance(value, Path):
            return value
        candidate = Path(value).expanduser()
        if not candidate.is_absolute():
            candidate = REPO_ROOT / candidate
        return candidate


@lru_cache()
def get_settings() -> Settings:
    return Settings()
