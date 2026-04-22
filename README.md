# KansScout 🇳🇱

AI-powered Dutch market opportunity intelligence platform. Runs a daily analysis pipeline and surfaces low-capital, solo-scalable business opportunities in a SwiftUI iOS app.

## Architecture

```
GitHub Actions (06:00 CET)
    └─ jobs/daily_scan.py
          ├─ scraper.py   → Google Trends, NewsAPI, SerpAPI
          ├─ analyzer.py  → Claude claude-sonnet-4-20250514
          ├─ scorer.py    → Weighted normalisation
          └─ db.py        → Supabase (PostgreSQL)

FastAPI on Vercel
    └─ /api/opportunities, /api/digest, /api/categories

SwiftUI iOS app (iOS 17+)
    └─ HomeView → OpportunityDetailView → DigestHistoryView → CategoryView
```

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/kansscout.git
cd kansscout
```

### 2. Configure environment variables

```bash
cp .env.example .env
# Fill in all keys in .env
```

Required keys:

| Key | Where to get it |
|-----|----------------|
| `ANTHROPIC_API_KEY` | https://console.anthropic.com |
| `NEWSAPI_KEY` | https://newsapi.org |
| `SERPAPI_KEY` | https://serpapi.com |
| `SUPABASE_URL` | Supabase project settings |
| `SUPABASE_ANON_KEY` | Supabase project settings |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase project settings → API |
| `KANSSCOUT_API_KEY` | Generate: `openssl rand -hex 32` |

### 3. Set up Supabase

1. Create a new project at https://supabase.com
2. Open the SQL editor and run `supabase/schema.sql`
3. Copy your project URL and keys into `.env`

### 4. Deploy backend to Vercel

```bash
npm i -g vercel
cd kansscout   # repo root
vercel deploy
```

Add all secrets to Vercel:
```bash
vercel env add ANTHROPIC_API_KEY
vercel env add NEWSAPI_KEY
vercel env add SERPAPI_KEY
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add KANSSCOUT_API_KEY
```

### 5. Add GitHub Actions secrets

In your GitHub repo → Settings → Secrets and variables → Actions, add all the same keys listed above.

### 6. Test the daily job locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt
python jobs/daily_scan.py
```

### 7. Open the iOS project in Xcode

1. Create `ios/KansScout/Resources/Config.plist` from `Config.plist.example`
2. Fill in `API_BASE_URL` (your Vercel deployment URL) and `API_KEY`
3. Open `ios/KansScout.xcodeproj` in Xcode 15+
4. Select your Development Team (free personal team works for device testing)
5. Build & run on your iPhone

### 8. Trigger first data population

Go to your GitHub repo → Actions → "Daily KansScout Analysis" → Run workflow.
After it completes, open the app and pull to refresh.

---

## Project structure

```
kansscout/
├── backend/
│   ├── api/           FastAPI routers
│   ├── core/          Scraper, analyzer, scorer, DB client
│   ├── main.py        App entrypoint (Vercel handler)
│   ├── requirements.txt
│   └── vercel.json
├── jobs/
│   └── daily_scan.py  Daily GitHub Actions job
├── supabase/
│   └── schema.sql     PostgreSQL schema + RLS policies
├── ios/
│   └── KansScout/
│       ├── App/       KansScoutApp.swift, AppViewModel.swift
│       ├── Models/    SwiftData models
│       ├── Views/     All SwiftUI views
│       ├── Services/  APIService, NotificationService
│       └── Resources/ Config.plist (git-ignored)
└── .github/workflows/
    └── daily_analysis.yml
```

---

## Category colour system

| Category | Colour |
|----------|--------|
| Tech | `#4F6EF7` blue |
| Beauty | `#E86BAF` pink |
| Food & Health | `#52C47D` green |
| Business Services | `#F5A623` amber |
| Education | `#9B6BF7` purple |
| Home & Living | `#4BBFD4` teal |

---

## API reference

All endpoints require header `X-API-Key: <your key>`.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/opportunities` | List opportunities. Supports `?category=`, `?sort=score`, `?new_today=true`, `?page=`, `?page_size=` |
| GET | `/api/opportunities/{id}` | Single opportunity |
| GET | `/api/digest/latest` | Today's digest |
| GET | `/api/digest/history?days=7` | Past N digests |
| GET | `/api/categories` | Category summary with counts and avg scores |

---

## Xcode project setup checklist

After cloning, before building:

- [ ] Create `Config.plist` from `Config.plist.example`
- [ ] Set API_BASE_URL to your Vercel deployment URL
- [ ] Set API_KEY to your KANSSCOUT_API_KEY value
- [ ] Add `Config.plist` to the Xcode target (Build Phases → Copy Bundle Resources)
- [ ] Set your Development Team in Signing & Capabilities
- [ ] Enable push notifications capability (optional, for local notifications)
