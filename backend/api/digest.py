"""GET /api/digest/latest and /api/digest/history"""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from backend.core import db

router = APIRouter()


@router.get("/digest/latest")
async def get_latest_digest():
    digest = db.fetch_latest_digest()
    if not digest:
        raise HTTPException(status_code=404, detail="No digest available yet")
    return digest


@router.get("/digest/history")
async def get_digest_history(days: int = Query(default=7, ge=1, le=90)):
    return db.fetch_digest_history(days=days)
