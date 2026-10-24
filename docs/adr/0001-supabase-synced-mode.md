# ADR-0001 — Supabase synced mode for the real multi-phone test

## Status
Accepted (2026-10-23)

## Context
The MVP kept all data in memory on one device. The real field test on
2026-10-30 needs every participant to use the app on their own Android phone
and share rooms, competitions, activities and votes. That is impossible
without a shared backend, and the project rules forbade any backend.

## Decision
Add Supabase as the **only** backend, in a build-time **synced mode**
(`--dart-define-from-file=config/supabase.json`): anonymous auth + typed name,
Postgres with RLS, realtime and an `evidence` storage bucket. The in-memory
repositories stay as the local cache behind `Synced*` repositories; a
`SyncEngine` pushes writes in order and rebuilds the cache from full
snapshots. Moderation, participation, deletion and social rules are mirrored
in SQL functions/policies. Demo mode (no configuration) is unchanged and is
what tests use.

## Consequences
- Easier: real multi-phone use, persistence, server-enforced rules, server
  clock, UI and domain code untouched by storage details.
- Harder: rules live in two places (Dart and SQL) and must change together;
  schema changes need migrations run by hand in the Supabase dashboard;
  pending writes are lost if the app is killed (persistent queue deferred).

## Alternatives considered
- Firebase: Cloud Storage for new projects requires the paid plan.
- Custom backend/API: too much infrastructure for a one-week academic test.
- Running the test on a single shared phone: does not meet the test goal.
