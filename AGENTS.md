# MinduRun — Agent Instructions

## Purpose

This is the primary repository instruction file for AI coding agents working on the MinduRun academic MVP.

The current goal is **not** to build production infrastructure. The goal is to build a functional, presentable Flutter prototype for a college project.

MinduRun is a **multiplatform Flutter project with a mobile-first interface**.

### Current target priority

1. **Primary MVP target: Flutter Web running in Chrome**
2. **Secondary target: Android**
3. iOS is outside the immediate academic presentation scope, but the shared code should avoid unnecessary platform lock-in.

The application must look and behave like a mobile app even when presented in a desktop browser.

## Source-of-truth order

When instructions conflict:

1. User's latest explicit instruction.
2. `AGENTS.md`.
3. `docs/02_DOMAIN_RULES.md`.
4. `docs/03_ARCHITECTURE.md`.
5. Task-specific docs.
6. Existing code conventions.

Never silently override a higher-priority source.

## Mandatory reading before implementation

Always read:

- `docs/00_INDEX.md`
- `docs/01_PRODUCT_SCOPE.md`
- `docs/02_DOMAIN_RULES.md`
- `docs/03_ARCHITECTURE.md`

Then:

- UI/mobile/web task → `docs/05_MOBILE.md`
- State/data task → `docs/04_LOCAL_DATA_MODEL.md`
- Mock service/repository task → `docs/06_LOCAL_SERVICES.md`
- Security/privacy task → `docs/07_SECURITY_PRIVACY.md`
- Tests/QA task → `docs/08_TESTING.md`
- Workflow/repository task → `docs/09_DEVELOPMENT_WORKFLOW.md`
- Scope/priorities → `docs/10_ROADMAP.md`

## Current technical baseline

Do not add backend infrastructure unless the user explicitly changes scope.

- Framework: Flutter + Dart
- Primary runtime target: Web / Chrome
- Secondary runtime target: Android
- UI strategy: mobile-first and responsive
- State management: Riverpod
- Navigation: GoRouter
- Persistence: none
- Database: none
- API: none
- Backend: none
- Authentication: simulated/local only
- Data source: in-memory repositories
- Demo data: seeded mock data
- Tests: Flutter test
- CI: optional for academic MVP

## MVP invariants

- No backend.
- No REST API.
- No database.
- No Firebase.
- No Supabase.
- No PostgreSQL.
- No SQLite/Hive/Isar/shared_preferences for domain persistence.
- No cloud storage.
- No production authentication.
- No GPS.
- No route tracking.
- No background location.
- No Strava/Garmin/Apple Health/Health Connect integration.
- No OCR.
- No microservices.

All domain data exists only while the app is running.

If the app is restarted, it is acceptable and expected for data/state to reset.

## Web-first constraints

Because Chrome/Web is the primary target:

- shared application code must not depend on `dart:io`;
- do not model evidence using filesystem-only paths as the sole representation;
- bundled demo evidence should use Flutter assets;
- user-selected evidence should be stored as in-memory bytes/reference during the session;
- do not introduce browser-specific code unless isolated behind a small adapter;
- layouts must remain usable at common phone widths and when centered in a desktop browser.

## Product behavior

The app must demonstrate:

- user/profile selection or simulated login;
- room creation;
- joining a room;
- competition creation;
- participants;
- activity submission;
- evidence screenshot selection/demo evidence;
- distance, time and pace input;
- score calculation;
- feed;
- ranking;
- reporting;
- community validation/voting;
- score removal after invalidation;
- final competition result.

## Architecture principle

Use interfaces/repositories so the app can later replace memory repositories with a real backend without rewriting the UI/domain layer.

The MVP should behave as if it had a data layer, but that layer is local and in-memory.

## UI principle

The application is mobile-first.

For the web presentation:

- prefer a centered mobile content shell on wide screens;
- keep primary flows comfortable around typical phone widths;
- avoid building a separate desktop application;
- allow modest responsive expansion where it improves presentation;
- do not duplicate mobile and web screens.

## Change protocol

Before implementing a significant feature:

1. Read required docs.
2. Identify impacted feature/state/repository files.
3. Make the smallest coherent plan.
4. Implement.
5. Run format/analyze/tests.
6. Test in Chrome.
7. Update docs if behavior changed.
8. Review for unnecessary infrastructure or platform-specific coupling.

## Dependency rules

Do not add packages for infrastructure the MVP does not need.

Do not add:
- HTTP clients;
- database drivers;
- cloud SDKs;
- authentication SDKs;
- storage SDKs.

A small web-compatible image picker package is allowed only if/when the activity submission feature needs real image selection.

## Definition of done

A task is complete when:

- behavior works locally;
- state updates correctly;
- the demo remains usable without internet after dependencies/assets are available;
- Chrome/Web behavior was considered;
- tests for relevant business logic pass;
- `dart format` and `flutter analyze` pass;
- no backend/database/API dependency was introduced;
- documentation remains aligned.
