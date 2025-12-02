from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class ImportOptions(BaseModel):
    csv_path: Optional[str] = Field(
        default=None, description="Override path to CSV file, defaults to settings.csv_path"
    )
    limit: Optional[int] = Field(default=None, description="Limit how many rows are imported")
    dry_run: Optional[bool] = Field(default=None, description="Run validation without touching the DB")
    product_ids: Optional[List[int]] = Field(
        default=None, description="Only import specific product ids from the CSV"
    )
    skip_existing: bool = Field(
        default=False, description="Skip rows where product_id already exists in the database"
    )


class ImportSummary(BaseModel):
    total_rows: int
    imported: int
    updated: int
    skipped: int
    dry_run: bool
    duration_ms: int
    missing_categories: List[int] = Field(default_factory=list)
    errors: List[str] = Field(default_factory=list)


class ProductSnapshot(BaseModel):
    product_id: int
    name: str
    updated_at: datetime
    seo_keyword: str
    categories: List[int]
    slug: str


class HealthResponse(BaseModel):
    status: str = "ok"
    timestamp: datetime = Field(default_factory=datetime.utcnow)
