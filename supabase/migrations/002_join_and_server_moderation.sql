-- MinduRun migration 002: late competition join + server-side moderation.
-- Run in Supabase SQL Editor AFTER schema.sql. Safe to re-run; keeps data.
--
-- Mirrors the Dart domain rules (docs/02_DOMAIN_RULES.md):
-- * a room member may join a SCHEDULED/ACTIVE competition;
-- * reports/votes follow ModerationService (min(3, eligible) votes, strict
--   INVALID majority rejects, ties keep the activity valid);
-- * activities are accepted only from participants while ACTIVE (server time).
-- Clients can no longer change moderation status directly.

-- Direct writes replaced by the functions below.
drop policy if exists "moderation status update" on public.activities;
drop policy if exists "report status update" on public.reports;
drop policy if exists "own report insert" on public.reports;
drop policy if exists "own vote on open report" on public.votes;

-- Activities: participant of an ACTIVE competition (server clock), as self.
-- Enum-like columns are checked so a bad row cannot break other phones.
drop policy if exists "own activity insert" on public.activities;
create policy "own activity insert" on public.activities for insert to authenticated
  with check (
    user_id = auth.uid()::text
    and moderation_status = 'published'
    and evidence_kind = 'remote'
    and evidence_id like auth.uid()::text || '/%'
    and exists (
      select 1 from public.competitions c
      where c.id = competition_id
        and auth.uid()::text = any (c.participant_ids)
        and c.status <> 'cancelled'
        and now() >= c.starts_at
        and now() < c.ends_at
    )
  );

drop policy if exists "owner creates competition" on public.competitions;
create policy "owner creates competition" on public.competitions for insert to authenticated
  with check (
    status in ('scheduled', 'active', 'finished', 'cancelled')
    and exists (
      select 1 from public.rooms r
      where r.id = room_id and r.owner_id = auth.uid()::text
    )
  );

-- Join a competition after its creation (room members only).
create or replace function public.join_competition(p_competition_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid text := auth.uid()::text;
  v_comp public.competitions%rowtype;
begin
  if v_uid is null then
    raise exception 'Sessão inválida.';
  end if;
  select * into v_comp from public.competitions
    where id = p_competition_id for update;
  if not found then
    raise exception 'Competição não encontrada.';
  end if;
  if not exists (
    select 1 from public.room_members
    where room_id = v_comp.room_id and user_id = v_uid
  ) then
    raise exception 'Somente membros da sala podem participar.';
  end if;
  if v_comp.status = 'cancelled' or now() >= v_comp.ends_at then
    raise exception 'Esta competição não aceita novos participantes.';
  end if;
  if v_uid = any (v_comp.participant_ids) then
    return;
  end if;
  update public.competitions
    set participant_ids = array_append(participant_ids, v_uid)
    where id = p_competition_id;
end;
$$;

-- Report an activity: validates and puts it UNDER_REVIEW atomically.
create or replace function public.create_report(
  p_id text,
  p_activity_id text,
  p_reason text,
  p_details text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid text := auth.uid()::text;
  v_activity public.activities%rowtype;
  v_participants text[];
  v_details text := nullif(trim(coalesce(p_details, '')), '');
begin
  if v_uid is null then
    raise exception 'Sessão inválida.';
  end if;
  if p_reason not in (
    'distanceMismatch', 'durationMismatch', 'paceMismatch', 'invalidEvidence',
    'duplicateActivity', 'suspectedOtherPersonActivity', 'other'
  ) then
    raise exception 'Motivo inválido.';
  end if;
  select * into v_activity from public.activities
    where id = p_activity_id for update;
  if not found then
    raise exception 'Atividade não encontrada.';
  end if;
  select participant_ids into v_participants from public.competitions
    where id = v_activity.competition_id;
  if v_activity.user_id = v_uid then
    raise exception 'Você não pode denunciar sua própria atividade.';
  end if;
  if not (v_uid = any (v_participants)) then
    raise exception 'Somente participantes podem denunciar.';
  end if;
  if v_activity.moderation_status <> 'published' then
    raise exception 'Esta atividade já está em revisão ou foi rejeitada.';
  end if;
  if exists (
    select 1 from public.reports
    where activity_id = p_activity_id
      and (status = 'open' or reporter_id = v_uid)
  ) then
    raise exception 'Esta atividade já possui denúncia aberta ou sua denúncia já foi registrada.';
  end if;
  if char_length(coalesce(v_details, '')) > 500 then
    raise exception 'Use até 500 caracteres nos detalhes.';
  end if;
  insert into public.reports (id, activity_id, reporter_id, reason, details, status, created_at)
    values (p_id, p_activity_id, v_uid, p_reason, v_details, 'open', now());
  update public.activities set moderation_status = 'underReview'
    where id = p_activity_id;
end;
$$;

-- Vote on an open report and resolve it when the minimum is reached.
-- Returns 'pending', 'upheld' or 'dismissed'.
create or replace function public.cast_vote(
  p_id text,
  p_report_id text,
  p_vote text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid text := auth.uid()::text;
  v_report public.reports%rowtype;
  v_activity public.activities%rowtype;
  v_eligible int;
  v_minimum int;
  v_total int;
  v_invalid int;
begin
  if v_uid is null then
    raise exception 'Sessão inválida.';
  end if;
  if p_vote not in ('valid', 'invalid') then
    raise exception 'Voto inválido.';
  end if;
  -- Row lock serializes simultaneous votes on the same report.
  select * into v_report from public.reports
    where id = p_report_id for update;
  if not found then
    raise exception 'Denúncia não encontrada.';
  end if;
  if v_report.status <> 'open' then
    raise exception 'Esta denúncia não está aberta.';
  end if;
  select * into v_activity from public.activities
    where id = v_report.activity_id for update;
  if v_activity.moderation_status <> 'underReview' then
    raise exception 'Esta atividade não está em revisão.';
  end if;
  select count(distinct p) into v_eligible
    from public.competitions c, unnest(c.participant_ids) as p
    where c.id = v_activity.competition_id and p <> v_activity.user_id;
  if v_uid = v_activity.user_id or not exists (
    select 1 from public.competitions c
    where c.id = v_activity.competition_id and v_uid = any (c.participant_ids)
  ) then
    raise exception 'Voto não permitido: somente outros participantes votam.';
  end if;
  if exists (
    select 1 from public.votes where report_id = p_report_id and voter_id = v_uid
  ) then
    raise exception 'Você já votou nesta denúncia.';
  end if;
  insert into public.votes (id, report_id, voter_id, vote, created_at)
    values (p_id, p_report_id, v_uid, p_vote, now());

  v_minimum := least(3, v_eligible);
  select count(*), count(*) filter (where vote = 'invalid')
    into v_total, v_invalid
    from public.votes where report_id = p_report_id;
  if v_eligible <= 0 or v_total < v_minimum then
    return 'pending';
  end if;
  if v_invalid > v_total - v_invalid then
    update public.reports set status = 'upheld' where id = p_report_id;
    update public.activities set moderation_status = 'rejected'
      where id = v_activity.id;
    return 'upheld';
  end if;
  update public.reports set status = 'dismissed' where id = p_report_id;
  update public.activities set moderation_status = 'published'
    where id = v_activity.id;
  return 'dismissed';
end;
$$;

-- Evidence retries overwrite the same object (upload with upsert).
drop policy if exists "evidence read own folder" on storage.objects;
create policy "evidence read own folder" on storage.objects for select to authenticated
  using (bucket_id = 'evidence' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "evidence update own folder" on storage.objects;
create policy "evidence update own folder" on storage.objects for update to authenticated
  using (bucket_id = 'evidence' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'evidence' and (storage.foldername(name))[1] = auth.uid()::text);

revoke all on function public.join_competition(text) from public, anon;
revoke all on function public.create_report(text, text, text, text) from public, anon;
revoke all on function public.cast_vote(text, text, text) from public, anon;
grant execute on function public.join_competition(text) to authenticated;
grant execute on function public.create_report(text, text, text, text) to authenticated;
grant execute on function public.cast_vote(text, text, text) to authenticated;
