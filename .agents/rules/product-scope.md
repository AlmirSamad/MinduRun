# MinduRun product-scope rule

The current MinduRun is an academic Flutter MVP.

Target strategy:
- primary: Flutter Web / Chrome;
- secondary: Android;
- design: mobile-first.

Required:
- local in-memory state;
- seeded demo data;
- room/competition/activity/feed/ranking/report/vote flows;
- responsive mobile-first interface.

Forbidden unless scope changes:
- backend;
- API;
- database;
- cloud storage;
- production authentication;
- GPS;
- route tracking;
- OCR;
- external fitness integrations.

Web-specific:
- do not use `dart:io` in shared application code;
- evidence must work without relying on filesystem-only paths.
