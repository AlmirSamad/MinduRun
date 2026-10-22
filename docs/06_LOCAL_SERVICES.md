# Local Services and Repositories

## Purpose

This layer simulates what a future backend/data source would provide.

Everything remains local and in memory.

## Suggested repository interfaces

### UserRepository
- list users
- get user by id

### RoomRepository
- list rooms for user
- create room
- join room
- get members

Phase 2 uses the existing `listRoomsForUser`, `getRoom`, `createRoom`,
`findByInviteCode`, `joinRoom` and `getMemberIds` methods. It adds:
- `createLocalRoom`: trims/validates the name (3–40 characters), generates a
  collision-checked incremental local ID and readable invite code, and stores
  the creator as owner and first member;
- `joinRoomByCode`: trims and uppercases the code, then joins without duplicate
  membership; returns null if no room matches.

`RoomsController` requires the current session for mutations and publishes
repository snapshots after changes. Room list/detail/member providers rebuild
from these updates and the selected user. Details require membership; users
are resolved from `memberIds` through `UserRepository`. Switching profiles
does not clear rooms. No domain data is persisted.

### CompetitionRepository
- list room competitions
- create competition
- get competition

Phase 3 preserves the seed insertion/update methods and adds `listCompetitions`,
`getParticipantIds` and `createLocalCompetition`. User-facing creation checks
the room owner, validates a trimmed 3–50 character name and requires end > start.
It generates a collision-checked local ID and copies current room member IDs
into an unmodifiable participant snapshot. Past periods are allowed.

`CompetitionsController` resolves the actual room and selected session user
before creation, then publishes a repository snapshot. Room competition lists,
details and participants react to those updates and session/room changes.
Reading a competition requires membership of its room; joining the room later
allows reading but does not change the competition's participants.

Lists use ascending start time with ID as a deterministic tie-break.
`CompetitionStateService` calculates effective status from the clock on each
status badge build, preserving cancellation as an override. No timer or
cancellation UI is introduced. Stored status is only the initial status.

### ActivityRepository
- list competition activities
- create activity
- update moderation status
- get activity

Phase 4 preserves seed insertion and adds `listActivities` plus
`createLocalActivity` (collision-checked local ID, PUBLISHED status). Lists are
ordered by submittedAt descending, then ID for deterministic ties.

`ActivitiesController` owns preview/publication and image registration. Each
publication checks the selected user, participant snapshot and effective ACTIVE
status again through `ActivitySubmissionService`/`CompetitionStateService`.
`ActivityInput` parses manual fields, `PaceValidationService` checks the existing
±8 s/km tolerance, and `ScoringService` computes the score. A stale preview does
not authorize publication. State snapshots refresh the competition feed and the
existing demo/ranking providers; no new leaderboard is introduced.

### ModerationRepository
- create report
- list activity reports
- add/update vote
- resolve report

### EvidenceRepository
- register bundled demo evidence reference
- store selected evidence bytes
- get evidence bytes/reference
- clear memory evidence on reset

Selected evidence is decoded before acceptance and stored as an immutable copy
of its bytes. The picker is injected at bootstrap via `evidencePickerProvider`;
the production adapter uses Flutter's `file_selector` package and `readAsBytes`.
Filters allow PNG/JPEG/WebP; a 10 MB file limit bounds session memory per image.
Cancelled selection preserves the draft, and read/decoding errors are shown in
the form. No filesystem path is stored in domain models and no image is uploaded.
Bundled seed evidence remains asset-based.

## In-memory implementation

Use lists/maps.

Conceptually:

```text
Map<String, User>
Map<String, Room>
Map<String, Competition>
Map<String, Activity>
Map<String, ActivityReport>
Map<String, ReportVote>
Map<String, Uint8List> selectedEvidenceBytes
```

The evidence byte map belongs to the data layer, not the domain model.

## Domain services

Keep separate:
- `ScoringService`
- `PaceValidationService`
- `RankingService`
- `ModerationService`
- `CompetitionStateService`

## Seed service

Provide `DemoSeedService` or equivalent.

Responsibilities:
- deterministic users;
- sample room;
- active competition;
- activities;
- asset-based evidence references;
- optional report/vote scenario.

## Reset

Provide a reset method that returns repositories to demo state.

## Future migration

If a backend is later added:
- keep repository interfaces;
- add remote implementations;
- preserve domain services where possible.

Do not build the remote layer now.

## Phase 5: reactive derived ranking

ActivityRepository exposes a changes stream. Its memory implementation emits
after creation, moderation-status updates and clear, and releases the stream
when its provider is disposed. ActivitiesController listens to these changes;
feed and ranking providers therefore observe the same repository mutations.

rankingForCompetitionProvider derives RankingEntry values through the existing
RankingService from the competition participant snapshot and current activities.
No ranking collection, duplicate activity store or persistence is introduced.

## Phase 6: reports, voting and moderation

Existing ActivityReport, ReportVote and enums are unchanged. ModerationRepository
now lists all reports and emits change notifications; addVote replaces the old
upsert operation and rejects duplicate votes and votes on resolved reports.
The in-memory implementation preserves reports/votes and prevents simultaneous
open reports for the same activity. Providers dispose its notification stream.

ModerationController coordinates the current session, accessible activity,
competition snapshot, ModerationService and repositories. The service owns
report/vote eligibility, minimum votes and outcomes. The controller generates
collision-checked local report IDs and user/report vote IDs. Reports move the
Activity to UNDER_REVIEW. At quorum it resolves to upheld/REJECTED or
dismissed/PUBLISHED through ActivityRepository.updateModerationStatus.

Reactive report/activity/competition and vote providers derive from repository
data; controller state is only a revision counter. ActivityRepository events
refresh the existing feed and ranking. RankingService itself is unchanged.
