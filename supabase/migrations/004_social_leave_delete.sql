-- MinduRun migration 004: delete own activity, leave/remove room members,
-- likes and comments. Run in Supabase SQL Editor AFTER 003.
-- Safe to re-run; keeps data. Mirrors docs/02_DOMAIN_RULES.md.

-- 1) Delete own activity: author, PUBLISHED, never reported, competition
--    ACTIVE by server time (ActivitySubmissionService.canDelete).
create or replace function public.delete_activity(p_activity_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid text := auth.uid()::text;
  v_activity public.activities%rowtype;
  v_comp public.competitions%rowtype;
begin
  if v_uid is null then
    raise exception 'Sessão inválida.';
  end if;
  select * into v_activity from public.activities
    where id = p_activity_id for update;
  if not found then
    return; -- already gone: deleting twice is harmless
  end if;
  select * into v_comp from public.competitions where id = v_activity.competition_id;
  if v_activity.user_id <> v_uid
     or v_activity.moderation_status <> 'published'
     or exists (select 1 from public.reports where activity_id = p_activity_id)
     or v_comp.status = 'cancelled'
     or now() < v_comp.starts_at
     or now() >= v_comp.ends_at then
    raise exception 'Só é possível excluir a própria atividade, sem denúncias, enquanto a competição estiver ativa.';
  end if;
  delete from public.activities where id = p_activity_id;
end;
$$;

revoke all on function public.delete_activity(text) from public, anon;
grant execute on function public.delete_activity(text) to authenticated;

-- Screenshot of a deleted activity: the author removes it from their folder.
drop policy if exists "evidence delete own folder" on storage.objects;
create policy "evidence delete own folder" on storage.objects for delete to authenticated
  using (bucket_id = 'evidence' and (storage.foldername(name))[1] = auth.uid()::text);

-- 2) Leave a room (never the owner) or the owner removes another member.
drop policy if exists "leave or remove member" on public.room_members;
create policy "leave or remove member" on public.room_members for delete to authenticated
  using (
    exists (
      select 1 from public.rooms r
      where r.id = room_id
        and r.owner_id <> user_id
        and (user_id = auth.uid()::text or r.owner_id = auth.uid()::text)
    )
  );

-- 3) Likes and comments (participants of the activity's competition).
create table if not exists public.activity_likes (
  activity_id text not null references public.activities(id) on delete cascade,
  user_id text not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (activity_id, user_id)
);

create table if not exists public.activity_comments (
  id text primary key,
  activity_id text not null references public.activities(id) on delete cascade,
  user_id text not null references public.profiles(id),
  body text not null check (char_length(trim(body)) between 1 and 280),
  created_at timestamptz not null default now()
);

alter table public.activity_likes enable row level security;
alter table public.activity_comments enable row level security;

create or replace function public.is_participant_of_activity(p_activity_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.activities a
    join public.competitions c on c.id = a.competition_id
    where a.id = p_activity_id and auth.uid()::text = any (c.participant_ids)
  )
$$;

drop policy if exists "read likes" on public.activity_likes;
create policy "read likes" on public.activity_likes for select to authenticated using (true);
drop policy if exists "like as participant" on public.activity_likes;
create policy "like as participant" on public.activity_likes for insert to authenticated
  with check (
    user_id = auth.uid()::text
    and public.is_participant_of_activity(activity_id)
    and not exists (
      select 1 from public.activities a
      where a.id = activity_id and a.user_id = auth.uid()::text
    )
  );
drop policy if exists "unlike own" on public.activity_likes;
create policy "unlike own" on public.activity_likes for delete to authenticated
  using (user_id = auth.uid()::text);

drop policy if exists "read comments" on public.activity_comments;
create policy "read comments" on public.activity_comments for select to authenticated using (true);
drop policy if exists "comment as participant" on public.activity_comments;
create policy "comment as participant" on public.activity_comments for insert to authenticated
  with check (
    user_id = auth.uid()::text
    and public.is_participant_of_activity(activity_id)
  );

-- Realtime for the new tables (ignore "already member" on re-run).
do $$
begin
  alter publication supabase_realtime add table public.activity_likes;
exception when duplicate_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.activity_comments;
exception when duplicate_object then null;
end $$;
