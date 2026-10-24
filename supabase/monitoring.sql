-- MinduRun: read-only queries to follow the real test.
-- Supabase Dashboard -> SQL Editor: paste ONE query at a time and Run.
-- Times are shown in Brasília time.

-- 1) Overview: how many of each.
select
  (select count(*) from public.profiles) as participants,
  (select count(*) from public.rooms) as rooms,
  (select count(*) from public.competitions) as competitions,
  (select count(*) from public.activities) as activities,
  (select count(*) from public.reports where status = 'open') as open_reports;

-- 2) Who joined (newest first) and which rooms they are in.
select p.display_name,
       p.created_at at time zone 'America/Sao_Paulo' as joined_at,
       coalesce(string_agg(r.name, ', ' order by r.name), '(sem sala)') as rooms
from public.profiles p
left join public.room_members m on m.user_id = p.id
left join public.rooms r on r.id = m.room_id
group by p.id, p.display_name, p.created_at
order by p.created_at desc;

-- 3) Rooms: invite code, owner and member count.
select r.name, r.invite_code, o.display_name as owner,
       count(m.user_id) as members
from public.rooms r
join public.profiles o on o.id = r.owner_id
left join public.room_members m on m.room_id = r.id
group by r.id, r.name, r.invite_code, o.display_name
order by r.created_at;

-- 4) Competitions: period (server time), status and participant counts.
--    "members_out" = room members who still need to tap "Participar".
select c.name, r.name as room,
       c.starts_at at time zone 'America/Sao_Paulo' as starts,
       c.ends_at at time zone 'America/Sao_Paulo' as ends,
       case
         when c.status = 'cancelled' then 'cancelled'
         when now() < c.starts_at then 'scheduled'
         when now() < c.ends_at then 'active'
         else 'finished'
       end as status_now,
       cardinality(c.participant_ids) as participants,
       (select count(*) from public.room_members m
         where m.room_id = c.room_id
           and not (m.user_id = any (c.participant_ids))) as members_out
from public.competitions c
join public.rooms r on r.id = c.room_id
order by c.starts_at;

-- 5) Live ranking per competition (same rule as the app: rejected = 0,
--    sum of stored scores, tie-break by accepted distance).
select c.name as competition, p.display_name,
       coalesce(sum(a.score) filter (where a.moderation_status <> 'rejected'), 0) as points,
       coalesce(sum(a.distance_km) filter (where a.moderation_status <> 'rejected'), 0) as km,
       count(a.id) as activities,
       count(a.id) filter (where a.moderation_status = 'underReview') as under_review
from public.competitions c
cross join lateral unnest(c.participant_ids) as part(user_id)
join public.profiles p on p.id = part.user_id
left join public.activities a
  on a.competition_id = c.id and a.user_id = part.user_id
group by c.id, c.name, p.id, p.display_name
order by c.name, points desc, km desc;

-- 6) Latest activities, with a flag when the screenshot file is missing.
select a.submitted_at at time zone 'America/Sao_Paulo' as submitted,
       p.display_name, c.name as competition,
       a.distance_km, a.duration_seconds, a.pace_seconds_per_km,
       a.score, a.moderation_status,
       exists (select 1 from storage.objects o
                where o.bucket_id = 'evidence' and o.name = a.evidence_id) as has_screenshot
from public.activities a
join public.profiles p on p.id = a.user_id
join public.competitions c on c.id = a.competition_id
order by a.submitted_at desc
limit 50;

-- 7) Reports and voting progress (minimum = min(3, eligible voters)).
select rep.created_at at time zone 'America/Sao_Paulo' as reported,
       author.display_name as author, reporter.display_name as reporter,
       rep.reason, rep.status, a.moderation_status,
       count(v.id) as votes,
       least(3, (select count(distinct x) from unnest(c.participant_ids) x
                  where x <> a.user_id)) as votes_needed,
       count(v.id) filter (where v.vote = 'invalid') as invalid_votes
from public.reports rep
join public.activities a on a.id = rep.activity_id
join public.competitions c on c.id = a.competition_id
join public.profiles author on author.id = a.user_id
join public.profiles reporter on reporter.id = rep.reporter_id
left join public.votes v on v.report_id = rep.id
group by rep.id, rep.created_at, author.display_name, reporter.display_name,
         rep.reason, rep.status, a.moderation_status, a.user_id, c.participant_ids
order by rep.created_at desc;
