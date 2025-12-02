from __future__ import annotations

import html
import re
from datetime import datetime
from itertools import islice
from typing import Iterable, Iterator, List, TypeVar

from unidecode import unidecode

T = TypeVar("T")

DATE_FORMATS = ("%m/%d/%Y", "%Y-%m-%d", "%d.%m.%Y")


def slugify(value: str, fallback: str = "item") -> str:
    """Create SEO friendly slug that works with OpenCart."""
    ascii_value = unidecode(value or "").lower()
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_value).strip("-")
    return slug or fallback


def batched(iterable: Iterable[T], size: int) -> Iterator[List[T]]:
    iterator = iter(iterable)
    while True:
        batch = list(islice(iterator, size))
        if not batch:
            break
        yield batch


def parse_date(value: str | None) -> datetime | None:
    if not value:
        return None
    value = value.strip()
    if not value:
        return None
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    raise ValueError(f"Unsupported date format: {value}")


def to_html_paragraphs(text: str | None) -> str:
    if not text:
        return ""
    parts = []
    for block in text.split("\n"):
        content = block.strip()
        if not content:
            continue
        parts.append(f"<p>{html.escape(content)}</p>")
    return "\n".join(parts)
