# Testing Strategy

## Priority

Test domain behavior and presentation-critical flows.

Primary runtime validation target: Chrome/Web.

Secondary validation target: Android when available.

## Unit tests

Required for:
- score calculation;
- pace consistency/tolerance;
- competition state;
- ranking;
- tie-breaks;
- report eligibility;
- voting;
- moderation outcome.

## Repository tests

Test:
- create/list room;
- join room;
- create competition;
- submit activity;
- evidence references;
- report/vote storage;
- reset demo data.

## Widget tests

Cover:
- user selector;
- create/join room forms;
- activity form;
- asset/memory evidence preview;
- ranking;
- moderation badge;
- reporting/voting UI;
- responsive behavior of critical screens where practical.

Phase 4 tests cover distance with dot/comma, MM:SS and HH:MM:SS duration,
MM:SS pace, invalid values, authorization at publication (including after a
preview expires), screenshot decoding/cancellation/errors, repository ordering,
session sharing, preview, publication and evidence viewing at 375×800 and
1400×900. Widget tests inject screenshot bytes through the picker provider;
they do not prove that the native browser file chooser works.

For Chrome, separately verify the production file-selector adapter: open
Registrar atividade, select an existing PNG/JPEG/WebP screenshot from disk,
confirm the preview, enter 5,23 / 31:45 / 06:04, validate 523 points and publish.
Open Ver evidência and switch to Ana to confirm the activity remains visible.
Repeat with inconsistent values and with scheduled/finished competitions.

## Integration-style Flutter tests

If time allows:
1. select demo user;
2. enter room;
3. submit activity;
4. verify feed;
5. verify ranking;
6. report another activity;
7. vote;
8. verify score/ranking change.

## Manual presentation checks

Before presentation:
- run in Chrome;
- test a narrow phone-like viewport;
- test normal desktop browser width;
- confirm no overflow;
- confirm demo reset;
- verify app does not need internet for its core demo.

## Completion checks

Phase 7 tests reset twice after creating rooms, joining, creating competitions,
submitting an activity, storing memory evidence, reporting and voting. They
check the original seed/ranking, cleared votes/evidence, logout and refresh of
already-initialized providers. Local ID counters reset with their repositories.
UI tests cover confirmation/cancellation, rapid duplicate action callbacks,
empty rooms/competitions/activities/zero ranking, invalid IDs and session redirects
at 375x800 and 1400x900. All five evidence assets are loaded and decoded.

Image tests retain corrupt/oversize rejection and also verify PNG/JPEG/WebP
container signatures, rejecting other formats before decoding. This does not
verify the native Chrome picker. The official script and real picker checks
remain separate manual checks, as does the loaded-app offline presentation.

Phase 6 service/repository/controller tests cover eligibility (including room
members outside the participant snapshot), author and duplicate guards, one
open report, quorum at 4/3/2/1/0 eligible voters, immutable vote history,
majority/tie outcomes, review after competition end, and shared profile state.
They verify that review retains points and rejection removes their contribution
without deleting the original Activity or score. Widget tests at 375x800 and
1400x900 exercise evidence, the report form with long details, author read-only
review, votes across profiles, vote confirmation, resolution and ranking update.

For Chrome QA, Almir can report Ana's activity, vote INVALID, switch to Carlos
and vote INVALID, then switch to João and vote VALID. Ana's activity must remain
visible as rejected and her ranking must change from 710 to 0. Before the third
vote the score remains 710. The pre-existing Carlos review is also available.

Phase 5 tests cover stored-score aggregation, competition/room isolation,
snapshot participants, zero scores, moderation contribution and deterministic
ordinal positions. Provider tests publish through the activity controller and
mutate the repository directly to verify immediate updates without resetting
state. Widget tests cover the ranking in competition details at 375x800 and
1400x900, user highlighting, review indicators, changes in place, profile
switching, finished competitions and long names with zero scores.

For manual Chrome QA, open the seeded competition, verify Carlos still counts
while marked Em revisão, publish an activity and observe the changed order.
Switch profiles and confirm the same scores with Você on the selected profile.

- `dart format .`
- `flutter analyze`
- relevant `flutter test`
- manual Chrome run when UI/platform behavior changed.
