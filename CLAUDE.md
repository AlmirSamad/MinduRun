# MinduRun — Claude Code Instructions

@AGENTS.md
@docs/00_INDEX.md
@docs/01_PRODUCT_SCOPE.md
@docs/02_DOMAIN_RULES.md
@docs/03_ARCHITECTURE.md

Use `AGENTS.md` as the primary repository rule set.

This project is an academic Flutter MVP.

## Target strategy

- Primary target: Flutter Web / Chrome
- Secondary target: Android
- UI: mobile-first and responsive

Do not build a separate desktop UI for the web presentation.

Since 2026-10-23 the only backend is Supabase, used in the build-time
"synced mode" for the real multi-phone test (see `AGENTS.md` and
`docs/12_SUPABASE.md`). Do not introduce any other:
- backend;
- API;
- database;
- cloud authentication;
- cloud storage;
- persistence infrastructure.

Demo mode keeps in-memory repositories and seeded demo data.

Because Web is the primary target:
- avoid `dart:io` in shared application code;
- do not assume evidence images are available through filesystem paths;
- use bundled assets or in-memory bytes/references.

Before each task:
1. inspect existing code;
2. read relevant documentation;
3. keep changes focused;
4. preserve domain behavior;
5. validate the feature in Chrome where relevant;
6. run Flutter checks;
7. update docs if behavior changed.

If a design choice would normally require backend infrastructure, implement a local/mock equivalent instead.
