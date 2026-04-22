"""Claude-powered analysis engine: turns raw signals into structured opportunities and a daily digest."""

from __future__ import annotations

import json
import os
import uuid
from datetime import datetime

from anthropic import Anthropic

from backend.core.scraper import RawSignal
from backend.core.scorer import score_opportunities

_client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))

_SYSTEM_PROMPT = """\
You are a Dutch market business intelligence analyst. Your role is to identify
low-capital, solo-scalable business opportunities suited to the Dutch market.

Evaluation criteria (score each 1–10):
1. Capital requirement: inverse score — lower cost scores higher. Max budget €10,000.
2. Scalability: can a solo person scale this using AI tools and cloud services?
3. Uniqueness: how defensible is the USP? Generic/copyable ideas score low.
4. Regulatory complexity: flag industries requiring certifications or approvals
   (food, cosmetics, financial products, childcare, etc.).
5. Knowledge barrier: assess required technical expertise. Flag if ML training or
   specialised engineering is required.
6. Market timing: is this rising, stable, or declining in the Dutch context?

Do NOT include opportunities that require >€10,000 startup capital or that are
trivially copyable (generic dropshipping, generic online courses).

Focus on specific, niche opportunities that can be built with Claude Code, Cursor,
Vercel, Supabase, Canva, and similar accessible platforms.\
"""

_OPPORTUNITY_SCHEMA = """\
{
  "id": "<uuid v4 string>",
  "title": "<string>",
  "category": "<Tech | Beauty | Food & Health | Business Services | Education | Home & Living | Other>",
  "description": "<string, max 200 words>",
  "usp": "<string — what makes this hard to copy>",
  "capital_estimate_eur": {"min": <int>, "max": <int>},
  "scores": {
    "capital": <int 1-10>,
    "scalability": <int 1-10>,
    "uniqueness": <int 1-10>,
    "regulatory_complexity": <int 1-10>,
    "knowledge_barrier": <int 1-10>,
    "market_timing": <int 1-10>,
    "overall": <float — leave as 0, will be recomputed>
  },
  "knowledge_required": ["<skill>"],
  "regulatory_flags": ["<flag if any, else empty array>"],
  "actionable_first_steps": ["<step1>", "<step2>", "<step3>"],
  "sources": ["<url>"],
  "generated_at": "<ISO 8601 datetime>",
  "is_new_today": true
}\
"""


def _strip_fences(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        lines = text.splitlines()
        # drop first and last fence lines
        inner = lines[1:-1] if lines[-1].strip() == "```" else lines[1:]
        text = "\n".join(inner)
    return text.strip()


def analyze_signals(signals: list[RawSignal], date_str: str) -> list[dict]:
    """Returns a list of scored opportunity dicts derived from raw signals."""
    opportunities: list[dict] = []

    # Group by category
    by_category: dict[str, list[RawSignal]] = {}
    for sig in signals:
        by_category.setdefault(sig.category, []).append(sig)

    for category, cat_signals in by_category.items():
        if not cat_signals:
            continue

        signal_lines = "\n".join(
            f"- [{s.source}] {s.title}: {s.summary[:200]} (trend_score={s.trend_score:.0f})"
            for s in cat_signals[:20]
        )

        user_msg = (
            f"Analyze these Dutch market signals for the **{category}** sector and identify "
            f"1–3 concrete business opportunities.\n\n"
            f"Market signals:\n{signal_lines}\n\n"
            f"Today: {date_str}\n\n"
            f"Return a JSON **array** of opportunity objects matching this schema exactly:\n"
            f"{_OPPORTUNITY_SCHEMA}\n\n"
            f"Return ONLY the JSON array — no markdown, no explanation."
        )

        try:
            resp = _client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=4096,
                system=_SYSTEM_PROMPT,
                messages=[{"role": "user", "content": user_msg}],
            )
            raw = _strip_fences(resp.content[0].text)
            parsed: list[dict] = json.loads(raw)
            if isinstance(parsed, list):
                for opp in parsed:
                    opp["id"] = str(uuid.uuid4())
                    opp["generated_at"] = datetime.utcnow().isoformat() + "Z"
                    opp["is_new_today"] = True
                opportunities.extend(parsed)
        except Exception as exc:
            print(f"[analyzer] Category '{category}' error: {exc}")

    scored = score_opportunities(opportunities)
    print(f"[analyzer] Produced {len(scored)} opportunities")
    return scored


def generate_digest(opportunities: list[dict], date_str: str) -> dict:
    """Generates today's digest from the scored opportunity list."""
    top_3 = sorted(
        opportunities,
        key=lambda o: o.get("scores", {}).get("overall", 0),
        reverse=True,
    )[:3]

    if not top_3:
        return _fallback_digest(date_str, [])

    opp_summaries = "\n".join(
        f"- {o['title']} (score {o['scores']['overall']:.1f}): {o.get('description', '')[:120]}"
        for o in top_3
    )
    top_ids = json.dumps([o["id"] for o in top_3])

    user_msg = (
        f"Based on today's top Dutch market opportunities, generate a daily digest.\n\n"
        f"Top opportunities:\n{opp_summaries}\n\n"
        f"Return a JSON object:\n"
        f'{{\n'
        f'  "date": "{date_str}",\n'
        f'  "headline_insight": "<1-sentence summary of today\'s most important signal>",\n'
        f'  "top_opportunities": {top_ids},\n'
        f'  "market_mood": "<Rising | Stable | Cautious>",\n'
        f'  "dutch_context_note": "<1-2 sentences on Dutch-specific market conditions>",\n'
        f'  "weekly_prompt": {{\n'
        f'    "question": "<reflection or action prompt for the user>",\n'
        f'    "category": "<category string>"\n'
        f'  }}\n'
        f'}}\n\n'
        f"Return ONLY the JSON object — no markdown."
    )

    try:
        resp = _client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1024,
            system=_SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_msg}],
        )
        raw = _strip_fences(resp.content[0].text)
        return json.loads(raw)
    except Exception as exc:
        print(f"[analyzer] Digest generation error: {exc}")
        return _fallback_digest(date_str, top_3)


def _fallback_digest(date_str: str, top_3: list[dict]) -> dict:
    return {
        "date": date_str,
        "headline_insight": top_3[0]["title"] if top_3 else "Marktanalyse voltooid.",
        "top_opportunities": [o["id"] for o in top_3],
        "market_mood": "Stable",
        "dutch_context_note": "De Nederlandse markt toont gemengde signalen vandaag.",
        "weekly_prompt": {
            "question": "Welke kans sluit het beste aan bij jouw vaardigheden?",
            "category": "General",
        },
    }
