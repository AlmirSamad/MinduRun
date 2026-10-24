-- MinduRun: erase all participant data after the real test.
-- IRREVERSIBLE. Run in Supabase SQL Editor only when the test is over.
--
-- 1) Screenshots: the database blocks deleting storage files through SQL.
--    Dashboard -> Storage -> bucket "evidence" -> "..." -> Empty bucket.
-- 2) Then run this script: it deletes every MinduRun row and the anonymous
--    accounts. Tables, functions and policies stay, ready for a new test.
--    (Deleting the whole Supabase project also removes everything.)

begin;

-- activity_likes / activity_comments exist after migration 004.
do $$
begin
  truncate table public.activity_likes, public.activity_comments;
exception when undefined_table then null;
end $$;

truncate table
  public.votes,
  public.reports,
  public.activities,
  public.competitions,
  public.room_members,
  public.rooms,
  public.profiles
cascade;

-- Anonymous sign-ins only; any real account in the project is kept.
delete from auth.users where is_anonymous;

commit;

-- Check: every count must be 0.
select
  (select count(*) from public.profiles) as profiles,
  (select count(*) from public.rooms) as rooms,
  (select count(*) from public.activities) as activities,
  (select count(*) from auth.users where is_anonymous) as anonymous_users,
  (select count(*) from storage.objects where bucket_id = 'evidence') as evidence_files;
