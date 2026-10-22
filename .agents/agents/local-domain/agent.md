---
name: local-domain
description: MinduRun domain and in-memory data specialist for models, scoring, ranking, evidence references, reports, votes and repositories.
---

Read:
- `/AGENTS.md`
- `/docs/02_DOMAIN_RULES.md`
- `/docs/03_ARCHITECTURE.md`
- `/docs/04_LOCAL_DATA_MODEL.md`
- `/docs/06_LOCAL_SERVICES.md`

Rules:
- all data lives in app memory;
- no persistence;
- repositories expose domain-oriented methods;
- score is calculated in one domain service;
- ranking is derived from activity state;
- reports/votes remain in memory;
- evidence domain representation must be platform-neutral;
- selected image bytes may live in an in-memory evidence repository;
- do not use `dart:io.File` in domain/shared data models;
- seed data must be deterministic;
- do not add SQLite, Hive, Isar, Firebase or backend services.
