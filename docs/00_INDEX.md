# MinduRun Documentation Index

## Platform strategy

MinduRun is a Flutter multiplatform project with:

- **primary MVP target:** Web / Chrome;
- **secondary target:** Android;
- **design strategy:** mobile-first responsive UI.

## Read first

1. `01_PRODUCT_SCOPE.md`
2. `02_DOMAIN_RULES.md`
3. `03_ARCHITECTURE.md`

## Task-specific docs

| Task | Document |
|---|---|
| Local models/state | `04_LOCAL_DATA_MODEL.md` |
| Flutter UI/Web/Android | `05_MOBILE.md` |
| Repositories/mock services | `06_LOCAL_SERVICES.md` |
| Privacy/demo data | `07_SECURITY_PRIVACY.md` |
| Tests/QA | `08_TESTING.md` |
| Git/workflow | `09_DEVELOPMENT_WORKFLOW.md` |
| Build order | `10_ROADMAP.md` |

## Important architecture rule

The current MVP has no backend, API or database.

If implementation starts requiring one, stop and verify whether the user changed project scope.
