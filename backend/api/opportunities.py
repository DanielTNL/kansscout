"""GET /api/opportunities and /api/opportunities/{id}"""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from backend.core import db

router = APIRouter()


@router.get("/opportunities")
async def list_opportunities(
    category: str | None = Query(default=None, description="Filter by category name"),
    sort: str = Query(default="score", description="'score' or 'date'"),
    new_today: bool | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
):
    sort_col = "score_overall" if sort == "score" else "generated_at"
    rows = db.fetch_opportunities(
        category=category,
        sort_by=sort_col,
        new_today=new_today,
        page=page,
        page_size=page_size,
    )
    return {"page": page, "page_size": page_size, "results": rows}


@router.get("/opportunities/{opp_id}")
async def get_opportunity(opp_id: str):
    row = db.fetch_opportunity_by_id(opp_id)
    if not row:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    return row
