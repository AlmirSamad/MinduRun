# Architecture

## Architecture style

Flutter MVP with two build-time modes:

- **Demo mode:** local only. No backend, no API, no database.
- **Synced mode:** Supabase (anonymous auth, Postgres, realtime, storage) for
  the real multi-phone test. See "Synced mode" below and `12_SUPABASE.md`.

## Platform strategy

```text
                 Shared Flutter code
                         |
              +----------+----------+
              |                     |
              v                     v
       Web / Chrome              Android
       PRIMARY MVP             SECONDARY
              |
              v
      College presentation
```

The application is mobile-first.

The Web target exists so development and presentation can happen comfortably on a computer without maintaining a second JavaScript/web codebase.

## Target repository

```text
mindurun/
├─ AGENTS.md
├─ CLAUDE.md
├─ lib/
│  ├─ app/
│  ├─ core/
│  └─ features/
├─ test/
├─ assets/
│  └─ demo/
├─ web/
├─ android/
├─ docs/
└─ .agents/
```

## Main layers

```text
Presentation
    ↓
Application / State
    ↓
Domain services
    ↓
Repository interfaces
    ↓
In-memory repository implementations
```

## Presentation

Contains:
- screens;
- widgets;
- forms;
- navigation;
- responsive layout;
- UI state rendering.

Must not contain core scoring, ranking or moderation logic.

### Responsive approach

Build one mobile-first interface.

On narrow screens:
- use the available phone width naturally.

On wide browser screens:
- center the main app content;
- apply a sensible maximum content width;
- allow dialogs/secondary panels to adapt only when useful.

Do not create duplicate web and mobile screen trees.

## Application / State

Use Riverpod providers/notifiers to coordinate:
- current demo user;
- rooms;
- competitions;
- activities;
- reports;
- votes;
- ranking updates.

## Domain

Contains pure/testable logic:
- scoring;
- pace consistency;
- competition state;
- ranking;
- moderation.

## Data layer

Repository interfaces hide storage details.

Examples:
- `UserRepository`
- `RoomRepository`
- `CompetitionRepository`
- `ActivityRepository`
- `ModerationRepository`
- optional `EvidenceRepository`

Demo mode uses the in-memory implementations directly.

### Synced mode

`lib/core/remote/`:

```text
Synced*Repository  --reads/validation-->  InMemory*Repository (local cache)
        |                                         ^
        | queued writes (in order)                | full snapshot refresh
        v                                         |
     SyncEngine  ---------- RemoteStore ----------+
                     (SupabaseRemoteStore)
```

- Writes hit the cache first, so controllers and widgets stay synchronous.
- The engine pushes writes one at a time and rebuilds the cache from a full
  snapshot on realtime events, every 20 s and on app resume — never while a
  write is pending.
- New entities use random ids (`newRemoteId`) and 6-character invite codes so
  phones never collide.
- `syncRevisionProvider` is bumped after each rebuild so room, competition and
  user readers re-query; activities and moderation use repository `changes`.
- `SyncedStartup` signs in anonymously, downloads the snapshot and overrides
  the repository providers before showing the app.

## Evidence architecture

Web is the primary target, so do not make `dart:io.File` or raw filesystem paths part of the domain model.

Use a platform-neutral evidence reference.

Recommended conceptual model:

```text
EvidenceRef
- id
- kind: asset | memory | remote
```

`remote` evidence (synced mode) is an object path in the Supabase `evidence`
bucket (`<userId>/evidence-<id>.jpg`), uploaded before the activity row and
shown with its public URL.

Demo evidence:
- bundled under `assets/demo/`;
- referenced by asset path.

User-selected evidence:
- read through a web-compatible Flutter picker;
- keep bytes in memory for the current session;
- reference those bytes by an in-memory evidence ID.

A simple `InMemoryEvidenceRepository` may map:

```text
evidenceId -> Uint8List
```

Domain models should keep only the evidence reference, not platform file objects.

## Authentication

Demo mode has no real authentication. It uses a simulated local session:
- predefined demo users;
- simple user selector;
- selected `currentUser`.

Synced mode uses one Supabase anonymous account per phone plus a typed
display name (`profiles` table). Profile switching and demo reset are hidden.

## Data reset

App startup may reinitialize seed data.

Provide a presentation-friendly action such as:

`Resetar dados de demonstração`

## Time

Device time is acceptable for the academic demo.

## Future-proofing

Repository/domain boundaries should allow a future backend without rewriting the main UI.

Do not overengineer future migration now.
