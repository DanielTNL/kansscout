"""GET /api/categories"""

from __future__ import annotations

from fastapi import APIRouter

from backend.core import db

router = APIRouter()


@router.get("/categories")
async def list_categories():
    return db.fetch_categories()
