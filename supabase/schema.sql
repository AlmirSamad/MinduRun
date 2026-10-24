-- MinduRun: schema for the real multi-phone test.
-- Run once in Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to re-run: drops and recreates MinduRun tables (ALL DATA IS LOST).

drop table if exists public.votes cascade;
drop table if exists public.reports cascade;
drop table if exists public.activities cascade;
drop table if exists public.competitions cascade;
drop table if exists public.room_members cascade;
drop table if exists public.rooms cascade;
drop table if exists public.profiles cascade;

-- User ids are auth.uid() stored as text (the app models ids as strings).

create table public.profiles (
  id text primary key,
  display_name text not null check (char_length(trim(display_name)) between 2 and 30),
  created_at timestamptz not null default now()
);

create table public.rooms (
  id text primary key,
  name text not null,
  owner_id text not null references public.profiles(id),
  invite_code text not null unique,
  created_at timestamptz not null
);

create table public.room_members (
  room_id text not null references public.rooms(id) on delete cascade,
  user_id text not null references public.profiles(id),
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table public.competitions (
  id text primary key,
  room_id text not null references public.rooms(id) on delete cascade,
  name text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null,
  participant_ids text[] not null,
  created_at timestamptz not null default now()
);

create table public.activities (
  id text primary key,
  competition_id text not null references public.competitions(id) on delete cascade,
  user_id text not null references public.profiles(id),
  distance_km double precision not null check (distance_km > 0),
  duration_seconds integer not null check (duration_seconds > 0),
  pace_seconds_per_km integer not null check (pace_seconds_per_km > 0),
  evidence_kind text not null,
  evidence_id text not null,
  score integer not null,
  moderation_status text not null,
  submitted_at timestamptz not null
);

create table public.reports (
  id text primary key,
  activity_id text not null references public.activities(id) on delete cascade,
  reporter_id text not null references public.profiles(id),
  reason text not null,
  details text check (details is null or char_length(details) <= 500),
  status text not null,
  created_at timestamptz not null,
  unique (activity_id, reporter_id)
);

create table public.votes (
  id text primary key,
  report_id text not null references public.reports(id) on delete cascade,
  voter_id text not null references public.profiles(id),
  vote text not null,
  created_at timestamptz not null,
  unique (report_id, voter_id)
);

-- Row Level Security: any signed-in (anonymous) participant reads everything;
-- writes are tied to the caller's own id. Domain rules stay in the app.
alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.competitions enable row level security;
alter table public.activities enable row level security;
alter table public.reports enable row level security;
alter table public.votes enable row level security;

create policy "read profiles" on public.profiles for select to authenticated using (true);
create policy "own profile insert" on public.profiles for insert to authenticated
  with check (id = auth.uid()::text);
create policy "own profile update" on public.profiles for update to authenticated
  using (id = auth.uid()::text) with check (id = auth.uid()::text);

create policy "read rooms" on public.rooms for select to authenticated using (true);
create policy "own room insert" on public.rooms for insert to authenticated
  with check (owner_id = auth.uid()::text);

create policy "read members" on public.room_members for select to authenticated using (true);
create policy "join as self" on public.room_members for insert to authenticated
  with check (user_id = auth.uid()::text);

create policy "read competitions" on public.competitions for select to authenticated using (true);
create policy "owner creates competition" on public.competitions for insert to authenticated
  with check (exists (
    select 1 from public.rooms r
    where r.id = room_id and r.owner_id = auth.uid()::text
  ));

create policy "read activities" on public.activities for select to authenticated using (true);
create policy "own activity insert" on public.activities for insert to authenticated
  with check (user_id = auth.uid()::text);
-- Moderation outcomes are applied by the participant whose vote resolves the report.
create policy "moderation status update" on public.activities for update to authenticated
  using (true) with check (true);

create policy "read reports" on public.reports for select to authenticated using (true);
create policy "own report insert" on public.reports for insert to authenticated
  with check (reporter_id = auth.uid()::text);
create policy "report status update" on public.reports for update to authenticated
  using (true) with check (true);

create policy "read votes" on public.votes for select to authenticated using (true);
create policy "own vote on open report" on public.votes for insert to authenticated
  with check (
    voter_id = auth.uid()::text
    and exists (select 1 from public.reports r where r.id = report_id and r.status = 'open')
  );

-- Realtime: phones refresh when any of these tables change.
alter publication supabase_realtime add table
  public.profiles, public.rooms, public.room_members, public.competitions,
  public.activities, public.reports, public.votes;

-- Evidence screenshots (public read so every participant can view them).
insert into storage.buckets (id, name, public)
values ('evidence', 'evidence', true)
on conflict (id) do update set public = true;

drop policy if exists "evidence upload own folder" on storage.objects;
create policy "evidence upload own folder" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
