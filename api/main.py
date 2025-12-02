from __future__ import annotations

from fastapi import Depends, FastAPI
from sqlalchemy.orm import Session

from .config import Settings, get_settings
from .db import get_session
from .importer import ProductImporter
from .schemas import HealthResponse, ImportOptions, ImportSummary

app = FastAPI(
    title="FUN DACHA OpenCart Import API",
    description="Uploads rows from list.csv into the OpenCart database.",
    version="0.1.0",
)


@app.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    return HealthResponse()


@app.post("/api/import/products", response_model=ImportSummary)
def import_products(
    options: ImportOptions,
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> ImportSummary:
    importer = ProductImporter(session=session, settings=settings)
    return importer.import_from_csv(options)
