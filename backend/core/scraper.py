"""Collects raw market signals from Google Trends, NewsAPI, and SerpAPI for the Dutch market."""

from __future__ import annotations

import os
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta

CATEGORIES = [
    "Technology",
    "Beauty & Cosmetics",
    "Health & Food",
    "Business Services",
    "Education",
    "Home & Living",
]

# Google Trends category IDs
_TREND_CATEGORY_IDS: dict[str, int] = {
    "Technology": 5,
    "Beauty & Cosmetics": 44,
    "Health & Food": 71,
    "Business Services": 12,
    "Education": 958,
    "Home & Living": 11,
}

_SERP_QUERIES = [
    "beste business ideeën 2025 nederland",
    "groeiende markten nederland",
    "niche business starten nederland",
]

_NEWS_QUERIES: list[tuple[str, str]] = [
    ("startup nederland", "Business Services"),
    ("technologie trend nederland", "Technology"),
    ("gezondheid markt nederland", "Health & Food"),
    ("schoonheid beauty nederland", "Beauty & Cosmetics"),
    ("onderwijs online nederland", "Education"),
    ("wonen interieur trend nederland", "Home & Living"),
]


@dataclass
class RawSignal:
    source: str
    title: str
    summary: str
    url: str
    category: str
    trend_score: float
    collected_at: datetime

    def to_dict(self) -> dict:
        d = asdict(self)
        d["collected_at"] = self.collected_at.isoformat()
        return d


# ---------------------------------------------------------------------------
# Collectors
# ---------------------------------------------------------------------------

_TRENDS_KEYWORDS = [
    "online business nederland",
    "niche webshop starten",
    "freelance diensten nederland",
    "digitaal product verkopen",
    "saas nederland",
    "app idee nederland",
]


def _collect_google_trends() -> list[RawSignal]:
    signals: list[RawSignal] = []
    try:
        from pytrends.request import TrendReq

        pytrends = TrendReq(hl="nl-NL", tz=60, timeout=(10, 30), retries=2, backoff_factor=0.5)

        # Build payload for a set of keywords and fetch interest over time
        pytrends.build_payload(_TRENDS_KEYWORDS, cat=0, timeframe="now 7-d", geo="NL")
        interest = pytrends.interest_over_time()

        if interest is not None and not interest.empty:
            # Average score per keyword across the period
            for i, keyword in enumerate(_TRENDS_KEYWORDS):
                if keyword in interest.columns:
                    avg_score = float(interest[keyword].mean())
                    signals.append(
                        RawSignal(
                            source="google_trends",
                            title=keyword,
                            summary=f"Google Trends NL (7d gemiddelde): {avg_score:.0f}/100 — {keyword}",
                            url=f"https://trends.google.com/trends/explore?q={keyword}&geo=NL",
                            category="Business Services",
                            trend_score=avg_score,
                            collected_at=datetime.utcnow(),
                        )
                    )
        # Also try related queries for richer signals
        related = pytrends.related_queries()
        for keyword, data in related.items():
            rising = data.get("rising")
            if rising is not None and not rising.empty:
                for j, row in rising.head(5).iterrows():
                    query = str(row.get("query", ""))
                    value = float(row.get("value", 50))
                    if query:
                        signals.append(
                            RawSignal(
                                source="google_trends_rising",
                                title=query,
                                summary=f"Stijgende zoekopdracht gerelateerd aan '{keyword}': {query}",
                                url=f"https://trends.google.com/trends/explore?q={query}&geo=NL",
                                category="Business Services",
                                trend_score=min(100.0, value),
                                collected_at=datetime.utcnow(),
                            )
                        )
    except Exception as exc:
        print(f"[scraper] Google Trends error: {exc}")
    return signals


def _collect_news() -> list[RawSignal]:
    signals: list[RawSignal] = []
    api_key = os.environ.get("NEWSAPI_KEY")
    if not api_key:
        print("[scraper] NEWSAPI_KEY not set — skipping news collection")
        return signals

    try:
        from newsapi import NewsApiClient

        client = NewsApiClient(api_key=api_key)
        from_date = (datetime.utcnow() - timedelta(days=7)).strftime("%Y-%m-%d")

        for query, category in _NEWS_QUERIES:
            try:
                result = client.get_everything(
                    q=query,
                    language="nl",
                    from_param=from_date,
                    sort_by="relevancy",
                    page_size=10,
                )
                for i, article in enumerate(result.get("articles", [])):
                    signals.append(
                        RawSignal(
                            source="newsapi",
                            title=article.get("title") or "",
                            summary=(article.get("description") or article.get("content") or "")[:500],
                            url=article.get("url") or "",
                            category=category,
                            trend_score=max(0.0, 80.0 - i * 8),
                            collected_at=datetime.utcnow(),
                        )
                    )
            except Exception as exc:
                print(f"[scraper] NewsAPI query '{query}' error: {exc}")
    except ImportError:
        print("[scraper] newsapi-python not installed")
    return signals


def _collect_serp() -> list[RawSignal]:
    signals: list[RawSignal] = []
    api_key = os.environ.get("SERPAPI_KEY")
    if not api_key:
        print("[scraper] SERPAPI_KEY not set — skipping SERP collection")
        return signals

    try:
        import httpx

        for query in _SERP_QUERIES:
            try:
                resp = httpx.get(
                    "https://serpapi.com/search",
                    params={"q": query, "gl": "nl", "hl": "nl", "num": 10, "api_key": api_key},
                    timeout=30,
                )
                resp.raise_for_status()
                data = resp.json()
                for i, item in enumerate(data.get("organic_results", [])):
                    signals.append(
                        RawSignal(
                            source="serpapi",
                            title=item.get("title") or "",
                            summary=item.get("snippet") or "",
                            url=item.get("link") or "",
                            category="Business Services",
                            trend_score=max(0.0, 90.0 - i * 9),
                            collected_at=datetime.utcnow(),
                        )
                    )
            except Exception as exc:
                print(f"[scraper] SerpAPI query '{query}' error: {exc}")
    except ImportError:
        print("[scraper] httpx not installed")
    return signals


def collect_all_signals() -> list[RawSignal]:
    signals: list[RawSignal] = []
    signals.extend(_collect_google_trends())
    signals.extend(_collect_news())
    signals.extend(_collect_serp())
    print(f"[scraper] Collected {len(signals)} raw signals")
    return signals
