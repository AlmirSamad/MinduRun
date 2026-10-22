# Local Data Model

These are in-memory Dart models, not database tables.

## User
- `id`
- `displayName`
- `avatarAssetPath` nullable

## Room
- `id`
- `name`
- `ownerUserId`
- `inviteCode`
- `memberIds`
- `createdAt`

## Competition
- `id`
- `roomId`
- `name`
- `startsAt`
- `endsAt`
- `status`
- `participantIds`

On creation, `participantIds` is an immutable copy of the room's member IDs.
Later room membership changes do not alter existing competition participants.
The model keeps its existing fields; effective status is derived by
`CompetitionStateService` from the current time and period, with cancellation
as an override, rather than relying on the initially stored status.

## EvidenceRef
Platform-neutral evidence reference.

Fields:
- `id`
- `kind`

Suggested kinds:
- `asset`
- `memory`

Rules:
- `asset` points to bundled demo evidence managed by Flutter assets;
- `memory` identifies bytes held by an in-memory evidence repository;
- domain models must not depend on `dart:io.File`.

## Activity
- `id`
- `competitionId`
- `userId`
- `distanceKm`
- `durationSeconds`
- `averagePaceSecondsPerKm`
- `evidenceRef`
- `score`
- `moderationStatus`
- `submittedAt`

Phase 4 keeps this model unchanged. New submissions reference the current user
and competition, start PUBLISHED, use the calculated score and record publication
time through the app clock. They do not record the time the run was performed.
Duration and pace are stored as integer seconds; distance remains a double in km.

## ActivityReport
- `id`
- `activityId`
- `reporterUserId`
- `reason`
- `details` nullable
- `status`
- `createdAt`

## ReportVote
- `id`
- `reportId`
- `voterUserId`
- `vote`
- `createdAt`

## ID generation

Use a simple local strategy:
- incremental IDs;
- UUID;
- deterministic demo IDs.

## Seed data

Provide deterministic demo fixtures:
- 4–6 demo users;
- 1 sample room;
- 1 active competition;
- 3–5 sample activities;
- bundled evidence images;
- optional one reported activity.

Seed data should make the presentation immediately useful.
