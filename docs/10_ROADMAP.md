# Academic MVP Roadmap

## Platform strategy for all phases

Primary target:
- Flutter Web / Chrome.

Secondary target:
- Android.

UI:
- mobile-first responsive.

## Phase 0 — Foundation

- Flutter project with Web and Android platform folders;
- theme;
- GoRouter;
- Riverpod;
- responsive mobile app shell;
- models;
- repository interfaces;
- in-memory repositories;
- evidence abstraction compatible with Web;
- demo seed data;
- first Chrome run.

## Phase 1 — Local session

- demo user selector;
- current user state;
- profile display.

## Phase 2 — Rooms

- list rooms;
- create room;
- join via code;
- members.

## Phase 3 — Competitions

- create competition;
- participant list;
- status;
- competition detail.

## Phase 4 — Activity submission

- bundled demo evidence;
- optional web/Android-compatible image selection;
- distance;
- duration;
- pace;
- consistency validation;
- score;
- feed.

## Phase 5 — Ranking

- aggregation;
- ranking UI;
- tie-breaks;
- under-review indicator.

## Phase 6 — Reports and voting

- report reasons;
- under-review state;
- voting;
- rejection;
- score/ranking recalculation.

## Phase 7 — Presentation polish

Implementation includes confirmed reset/logout, deterministic seed restoration,
reader refresh, duplicate-submit guards, success feedback, empty/error-state
checks, image format validation and responsive regression tests. Existing
mobile shell, domain rules and seed ranking are preserved. Chrome desktop/mobile,
real file selection and the loaded-app offline script must be verified on the
presentation machine; automated widget tests do not mark these checks complete.

- demo reset button;
- seeded scenarios;
- responsive UI polish;
- phone-like browser presentation check;
- desktop Chrome check;
- empty/error states;
- tests;
- offline/core-demo verification.

## Deferred beyond academic MVP

- backend;
- API;
- database;
- persistent login;
- cloud image storage;
- notifications;
- OCR;
- external running APIs;
- GPS;
- wearable/health integrations.
