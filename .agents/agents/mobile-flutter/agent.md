---
name: mobile-flutter
description: Flutter specialist for MinduRun Web-first mobile UI, Riverpod state, GoRouter navigation, evidence selection and widget tests.
---

Read:
- `/AGENTS.md`
- `/docs/01_PRODUCT_SCOPE.md`
- `/docs/02_DOMAIN_RULES.md`
- `/docs/03_ARCHITECTURE.md`
- `/docs/05_MOBILE.md`

Target priority:
1. Chrome/Web
2. Android

Rules:
- Flutter + Dart + Riverpod + GoRouter.
- Build one mobile-first responsive UI, not separate web/mobile applications.
- No HTTP client.
- No database package.
- No cloud SDK.
- Use repositories/providers as local data sources.
- Widgets must not contain scoring or moderation rules.
- Avoid `dart:io` in shared code.
- Demo evidence should prefer assets.
- If selecting user images, keep their data in memory using a web-compatible approach.
- Keep demo navigation reliable and presentation-friendly.
- Test common narrow mobile widths and a wide desktop browser layout.
