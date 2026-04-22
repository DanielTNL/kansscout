#!/usr/bin/env python3
"""Daily KansScout analysis job.

Run by GitHub Actions at 06:00 CET daily.
Loads .env automatically when run locally.
"""

from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path

# Allow running from repo root: python jobs/daily_scan.py
sys.path.insert(0, str(Path(__file__).parent.parent))

from dotenv import load_dotenv

load_dotenv()

from backend.core.analyzer import analyze_signals, generate_digest  # noqa: E402
from backend.core.db import insert_digest, upsert_opportunities  # noqa: E402
from backend.core.scraper import collect_all_signals  # noqa: E402


def main() -> None:
    date_str = datetime.now(tz=timezone.utc).strftime("%Y-%m-%d")
    print(f"\n=== KansScout daily scan — {date_str} ===\n")

    # 1. Collect raw signals
    signals = collect_all_signals()
    if not signals:
        print("[job] No signals collected — aborting.")
        sys.exit(1)

    # 2. Analyse with Claude → scored opportunities
    opportunities = analyze_signals(signals, date_str)

    # 3. Persist opportunities
    if opportunities:
        upsert_opportunities(opportunities)
    else:
        print("[job] No opportunities generated today.")

    # 4. Generate and persist daily digest
    digest = generate_digest(opportunities, date_str)
    insert_digest(digest)

    print(f"\n=== Done. {len(opportunities)} opportunities | mood: {digest.get('market_mood')} ===\n")


if __name__ == "__main__":
    main()
