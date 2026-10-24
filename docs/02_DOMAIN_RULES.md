# Domain Rules

## Rooms

- A user may participate in multiple rooms during the session.
- A room has an owner.
- A room contains members.
- Join flow can use a simple generated/mock code.
- No server authorization exists in this MVP; access rules are enforced locally.

## Competitions

States:
- `SCHEDULED`
- `ACTIVE`
- `FINISHED`
- `CANCELLED`

Rules:
- a competition belongs to one room;
- dates are represented consistently;
- current device time may be used for the demo;
- activity submission is allowed only while the competition is considered active;
- competition participants remain associated with the competition in memory.

Participants start as a snapshot of the room members at creation. A room
member who is not yet a participant may join later ("Participar da
competição") while the competition is `SCHEDULED` or `ACTIVE`; joining is not
possible once it is `FINISHED` or `CANCELLED`. Joining appends to the
participant list (it never removes anyone) and immediately makes the member
eligible to submit, report and vote. In synced mode the server enforces the
same rule (`join_competition`) and uses server time for the submission window.

## Activity submission

Required:
- competition;
- participant;
- evidence image reference;
- distance;
- duration;
- average pace.

Recommended representation:
- distance: `double` kilometers;
- duration: integer seconds;
- average pace: integer seconds per kilometer.

## Consistency validation

Expected pace:

`durationSeconds / distanceKm`

Initial tolerance:

`± 8 seconds/km`

Reject:
- distance <= 0;
- duration <= 0;
- pace <= 0;
- malformed values.

## Scoring

MVP formula:

`score = round(distanceKm * 100)`

Examples:
- 3.00 km → 300
- 5.23 km → 523
- 10.00 km → 1000

The scoring rule must live in one domain service, not in widgets.

## Moderation

Activity states:
- `PUBLISHED`
- `UNDER_REVIEW`
- `REJECTED`

Rules:
- new valid activity starts `PUBLISHED`;
- reports can move it to `UNDER_REVIEW`;
- one report alone does not remove points;
- rejected activity contributes zero points;
- state remains visible for demonstration.

## Report reasons

- `DISTANCE_MISMATCH`
- `DURATION_MISMATCH`
- `PACE_MISMATCH`
- `INVALID_EVIDENCE`
- `DUPLICATE_ACTIVITY`
- `SUSPECTED_OTHER_PERSON_ACTIVITY`
- `OTHER`

Rules:
- author cannot report own activity;
- duplicate report by same user/activity should be blocked in memory.

Phase 6 permits at most one open report per activity. An activity already
UNDER_REVIEW or REJECTED cannot receive a new report. A dismissed report stays
in history; another eligible participant may later report the published
activity, but the same reporter/activity pair remains blocked. Optional details
are trimmed and limited to 500 characters.

## Voting

Starter policy:
- eligible voters = other competition participants;
- one vote per user/report;
- vote values = `VALID` or `INVALID`;
- minimum votes = `min(3, eligibleVoterCount)`;
- after minimum, strict majority decides;
- tie keeps activity valid.

Eligibility uses the competition participant list (creation snapshot plus
late joins), never current room membership. The minimum is computed when each
vote is cast. The reporter may vote normally; the author may only observe.
Votes cannot be edited or replaced. At the minimum count, resolve immediately:
INVALID > VALID upholds the report and rejects the activity; all other outcomes
(including ties) dismiss the report and republish the activity. Resolved reports
accept no more votes. Reports and votes remain in memory as history.

Moderation has no period restriction: eligible participants may report and
complete reviews after the competition ends. Only activity submission requires
ACTIVE. The UI shows total votes collected and the current user's own vote,
without exposing a partial VALID/INVALID tally.

In synced mode, reports and votes go through server functions
(`create_report`, `cast_vote` in `supabase/migrations/002_*.sql`) that mirror
`ModerationService` and resolve each report atomically; clients cannot change
moderation status directly. The app still validates first for immediate
feedback, and the server result replaces the local one on the next refresh.

## Ranking

Ranking is derived from activities.

- `PUBLISHED` contributes score.
- `UNDER_REVIEW` still contributes score but is visibly marked.
- `REJECTED` contributes zero.

Tie-break:
1. higher score;
2. greater accepted distance;
3. stable participant ordering if still tied.

Positions remain sequential ordinal places (`1, 2, 3, ...`), matching the
original RankingService. Equal scores are ordered by accepted distance;
if both are equal, the competition's participant snapshot order provides
visual stability, not an additional sporting advantage. Shared positions
are not used. Participants without activities remain listed with zero.

Only activities belonging to the requested competition and its participant
snapshot contribute. Sum each activity's stored score; do not recompute
historical scores from distance. Rejected activities stay visible in the
feed with zero contribution and their original score identified separately.

No persisted ranking table is needed.
