-- MinduRun migration 003: duplicate screenshot block + server clock.
-- Run in Supabase SQL Editor AFTER 002. Safe to re-run; keeps data.

-- SHA-256 of the evidence image, sent by the app. The same screenshot can
-- back only one activity per competition (docs/02_DOMAIN_RULES.md).
alter table public.activities add column if not exists evidence_hash text;
create unique index if not exists activities_competition_evidence_hash_key
  on public.activities (competition_id, evidence_hash)
  where evidence_hash is not null;

-- Server clock: the app corrects wrong phone clocks with it.
create or replace function public.server_now()
returns timestamptz
language sql
stable
as $$ select now() $$;

revoke all on function public.server_now() from public, anon;
grant execute on function public.server_now() to authenticated;
