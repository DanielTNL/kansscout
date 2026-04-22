"""Thin Supabase client wrapper for reading and writing KansScout data."""

from __future__ import annotations

import os

from supabase import Client, create_client

_client: Client | None = None


def get_client() -> Client:
    global _client
    if _client is None:
        url = os.environ["SUPABASE_URL"]
        key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ["SUPABASE_ANON_KEY"]
        _client = create_client(url, key)
    return _client


# ---------------------------------------------------------------------------
# Writers (used by the daily job with the service role key)
# ---------------------------------------------------------------------------

def upsert_opportunities(opportunities: list[dict]) -> None:
    client = get_client()
    rows = [_opportunity_to_row(o) for o in opportunities]
    if rows:
        client.table("opportunities").upsert(rows, on_conflict="id").execute()
        print(f"[db] Upserted {len(rows)} opportunities")


def insert_digest(digest: dict) -> None:
    client = get_client()
    row = {
        "date": digest["date"],
        "headline_insight": digest.get("headline_insight", ""),
        "top_opportunity_ids": digest.get("top_opportunities", []),
        "market_mood": digest.get("market_mood", "Stable"),
        "dutch_context_note": digest.get("dutch_context_note", ""),
        "weekly_prompt_question": digest.get("weekly_prompt", {}).get("question", ""),
        "weekly_prompt_category": digest.get("weekly_prompt", {}).get("category", ""),
    }
    client.table("daily_digests").upsert(row, on_conflict="date").execute()
    print(f"[db] Inserted digest for {digest['date']}")


# ---------------------------------------------------------------------------
# Readers (used by the API with the anon key)
# ---------------------------------------------------------------------------

def fetch_opportunities(
    category: str | None = None,
    sort_by: str = "score_overall",
    new_today: bool | None = None,
    page: int = 1,
    page_size: int = 20,
) -> list[dict]:
    client = get_client()
    query = client.table("opportunities").select("*")

    if category:
        query = query.eq("category", category)
    if new_today is not None:
        query = query.eq("is_new_today", new_today)

    query = query.order(sort_by, desc=True)
    offset = (page - 1) * page_size
    query = query.range(offset, offset + page_size - 1)

    result = query.execute()
    return result.data or []


def fetch_opportunity_by_id(opp_id: str) -> dict | None:
    client = get_client()
    result = client.table("opportunities").select("*").eq("id", opp_id).single().execute()
    return result.data


def fetch_latest_digest() -> dict | None:
    client = get_client()
    result = (
        client.table("daily_digests")
        .select("*")
        .order("date", desc=True)
        .limit(1)
        .execute()
    )
    data = result.data
    return data[0] if data else None


def fetch_digest_history(days: int = 7) -> list[dict]:
    client = get_client()
    result = (
        client.table("daily_digests")
        .select("*")
        .order("date", desc=True)
        .limit(days)
        .execute()
    )
    return result.data or []


def fetch_categories() -> list[dict]:
    client = get_client()
    result = client.table("opportunities").select("category, score_overall").execute()
    rows = result.data or []

    summary: dict[str, dict] = {}
    for row in rows:
        cat = row.get("category", "Other")
        if cat not in summary:
            summary[cat] = {"category": cat, "count": 0, "total_score": 0.0}
        summary[cat]["count"] += 1
        summary[cat]["total_score"] += float(row.get("score_overall") or 0)

    categories = []
    for cat, data in summary.items():
        avg = data["total_score"] / data["count"] if data["count"] else 0
        categories.append({"category": cat, "count": data["count"], "avg_score": round(avg, 2)})

    return sorted(categories, key=lambda c: c["count"], reverse=True)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _opportunity_to_row(o: dict) -> dict:
    scores = o.get("scores", {})
    cap = o.get("capital_estimate_eur", {})
    return {
        "id": o["id"],
        "title": o.get("title", ""),
        "category": o.get("category", "Other"),
        "description": o.get("description", ""),
        "usp": o.get("usp", ""),
        "capital_min": cap.get("min"),
        "capital_max": cap.get("max"),
        "score_capital": scores.get("capital"),
        "score_scalability": scores.get("scalability"),
        "score_uniqueness": scores.get("uniqueness"),
        "score_regulatory": scores.get("regulatory_complexity"),
        "score_knowledge": scores.get("knowledge_barrier"),
        "score_market_timing": scores.get("market_timing"),
        "score_overall": scores.get("overall"),
        "knowledge_required": o.get("knowledge_required", []),
        "regulatory_flags": o.get("regulatory_flags", []),
        "actionable_steps": o.get("actionable_first_steps", []),
        "sources": o.get("sources", []),
        "generated_at": o.get("generated_at"),
        "is_new_today": o.get("is_new_today", False),
        "date": o.get("generated_at", "")[:10],
    }
