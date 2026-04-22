"""KansScout FastAPI application — entry point for Vercel serverless deployment."""

from __future__ import annotations

import os

from fastapi import FastAPI, HTTPException, Security
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader
from mangum import Mangum

from backend.api import categories, digest, opportunities

# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------

app = FastAPI(
    title="KansScout API",
    version="1.0.0",
    description="Dutch market opportunity intelligence — powered by Claude.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "OPTIONS"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# API-key auth dependency
# ---------------------------------------------------------------------------

_API_KEY = os.environ.get("KANSSCOUT_API_KEY", "")
_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def _verify_key(api_key: str | None = Security(_api_key_header)) -> str:
    if _API_KEY and api_key != _API_KEY:
        raise HTTPException(status_code=403, detail="Invalid or missing X-API-Key header")
    return api_key or ""


# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------

_deps = [Security(_verify_key)]
app.include_router(opportunities.router, prefix="/api", dependencies=_deps)
app.include_router(digest.router, prefix="/api", dependencies=_deps)
app.include_router(categories.router, prefix="/api", dependencies=_deps)


@app.get("/")
async def root():
    return {"status": "ok", "service": "KansScout API", "version": "1.0.0"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


# ---------------------------------------------------------------------------
# Vercel / AWS Lambda handler
# ---------------------------------------------------------------------------

handler = Mangum(app, lifespan="off")
