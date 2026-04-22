"""Deterministic weighted scorer that normalises Claude's 1-10 sub-scores into an overall score."""

from __future__ import annotations

_WEIGHTS: dict[str, float] = {
    "capital": 0.25,
    "scalability": 0.25,
    "uniqueness": 0.20,
    "market_timing": 0.15,
    "knowledge_barrier": 0.10,   # inverted — lower barrier → higher contribution
    "regulatory_complexity": 0.05,  # inverted — lower complexity → higher contribution
}


def _clamp(value: float, lo: float = 1.0, hi: float = 10.0) -> float:
    return max(lo, min(hi, value))


def normalize_scores(opportunity: dict) -> dict:
    scores: dict = opportunity.get("scores", {})

    capital = _clamp(float(scores.get("capital", 5)))
    scalability = _clamp(float(scores.get("scalability", 5)))
    uniqueness = _clamp(float(scores.get("uniqueness", 5)))
    market_timing = _clamp(float(scores.get("market_timing", 5)))
    # Invert barrier / complexity: score of 1 (easiest) → contribution 10
    knowledge_contribution = 11.0 - _clamp(float(scores.get("knowledge_barrier", 5)))
    regulatory_contribution = 11.0 - _clamp(float(scores.get("regulatory_complexity", 5)))

    overall = (
        capital * _WEIGHTS["capital"]
        + scalability * _WEIGHTS["scalability"]
        + uniqueness * _WEIGHTS["uniqueness"]
        + market_timing * _WEIGHTS["market_timing"]
        + knowledge_contribution * _WEIGHTS["knowledge_barrier"]
        + regulatory_contribution * _WEIGHTS["regulatory_complexity"]
    )

    scores["overall"] = round(overall, 2)
    opportunity["scores"] = scores
    return opportunity


def score_opportunities(opportunities: list[dict]) -> list[dict]:
    return [normalize_scores(opp) for opp in opportunities]
