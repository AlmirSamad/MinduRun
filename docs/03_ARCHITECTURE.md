# Architecture

## Architecture style

Flutter-only local MVP.

No backend, no API, no database.

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

Current implementations are in-memory only.

## Evidence architecture

Web is the primary target, so do not make `dart:io.File` or raw filesystem paths part of the domain model.

Use a platform-neutral evidence reference.

Recommended conceptual model:

```text
EvidenceRef
- id
- kind: asset | memory
```

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

No real authentication.

Use simulated local session:
- predefined demo users;
- simple user selector;
- selected `currentUser`.

## Data reset

App startup may reinitialize seed data.

Provide a presentation-friendly action such as:

`Resetar dados de demonstração`

## Time

Device time is acceptable for the academic demo.

## Future-proofing

Repository/domain boundaries should allow a future backend without rewriting the main UI.

Do not overengineer future migration now.
