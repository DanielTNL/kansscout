-- KansScout Supabase Schema
-- Run this in your Supabase SQL editor after creating your project.

-- ============================================================
-- Extensions
-- ============================================================
create extension if not exists "uuid-ossp";

-- ============================================================
-- Tables
-- ============================================================

create table if not exists opportunities (
  id                  uuid primary key default uuid_generate_v4(),
  title               text            not null,
  category            text            not null,
  description         text,
  usp                 text,
  capital_min         integer,
  capital_max         integer,
  score_capital       integer         check (score_capital between 1 and 10),
  score_scalability   integer         check (score_scalability between 1 and 10),
  score_uniqueness    integer         check (score_uniqueness between 1 and 10),
  score_regulatory    integer         check (score_regulatory between 1 and 10),
  score_knowledge     integer         check (score_knowledge between 1 and 10),
  score_market_timing integer         check (score_market_timing between 1 and 10),
  score_overall       float,
  knowledge_required  text[]          default '{}',
  regulatory_flags    text[]          default '{}',
  actionable_steps    text[]          default '{}',
  sources             text[]          default '{}',
  generated_at        timestamptz     default now(),
  is_new_today        boolean         default true,
  date                date            default current_date
);

create index if not exists idx_opportunities_category    on opportunities (category);
create index if not exists idx_opportunities_date        on opportunities (date desc);
create index if not exists idx_opportunities_score       on opportunities (score_overall desc);
create index if not exists idx_opportunities_is_new      on opportunities (is_new_today);

create table if not exists daily_digests (
  id                      uuid primary key default uuid_generate_v4(),
  date                    date unique     not null,
  headline_insight        text,
  top_opportunity_ids     uuid[]          default '{}',
  market_mood             text            check (market_mood in ('Rising', 'Stable', 'Cautious')),
  dutch_context_note      text,
  weekly_prompt_question  text,
  weekly_prompt_category  text,
  created_at              timestamptz     default now()
);

create index if not exists idx_digests_date on daily_digests (date desc);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table opportunities  enable row level security;
alter table daily_digests  enable row level security;

-- Anon users can read everything (iOS app uses anon key)
create policy "Public read opportunities"
  on opportunities for select
  using (true);

create policy "Public read digests"
  on daily_digests for select
  using (true);

-- Service role key bypasses RLS automatically in Supabase (no extra policy needed).
-- The daily job uses the service role key for writes.

-- ============================================================
-- Optional: reset is_new_today daily
-- (run via pg_cron or call from the daily job)
-- ============================================================

-- select cron.schedule(
--   'reset-is-new-today',
--   '55 4 * * *',   -- just before the job runs
--   $$update opportunities set is_new_today = false where is_new_today = true$$
-- );
