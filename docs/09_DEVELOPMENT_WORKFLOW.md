# Development Workflow

## Primary development target

Use Chrome for the MVP:

```bash
flutter run -d chrome
```

Use:

```bash
flutter devices
```

to confirm available targets.

Android setup/testing can be added later.

For a predictable presentation URL, run `flutter pub get`, then
`flutter run -d web-server --web-port 8787` and open it in Chrome. Do not start
another server on an occupied port. Stop the current instance with `q` before
restarting; retain 8787. With cached dependencies, `flutter pub get --offline`
can resolve packages when network access is unavailable.

Before each presentation, use the Home/selection overflow menu to Resetar
demonstração and confirm. This logs out, rebuilds the existing deterministic
seed and refreshes readers of the same repositories. Verify the reset again
after completing the official script in README, including real image selection.

## Branches

- `main`
- `feat/<feature>`
- `fix/<bug>`

## Commits

Examples:
- `feat(rooms): add in-memory room creation`
- `feat(activity): add web-compatible evidence handling`
- `feat(ranking): calculate local leaderboard`
- `fix(layout): prevent feed overflow on narrow screens`
- `test(scoring): cover pace tolerance`

## Agent workflow

Before:
- inspect code;
- read docs;
- identify affected feature/repository/service.

During:
- focused edits;
- no unrelated refactors;
- no infrastructure;
- avoid Web-incompatible shared code.

Before completion:
- format;
- analyze;
- test;
- run in Chrome if UI/platform behavior changed;
- inspect diff;
- update docs.

## Dependencies

Before adding a package ask:
- is it necessary for the academic presentation?
- does it support Flutter Web and Android if it touches platform behavior?
- can Flutter already do this?
- does it introduce unnecessary infrastructure?

Avoid packages for:
- HTTP;
- databases;
- cloud storage;
- auth providers;
- analytics.

## Demo preparation

Before presentation:
- reset demo state;
- verify seed data;
- test navigation;
- verify demo evidence assets;
- run on target presentation computer;
- test normal and phone-like Chrome viewport;
- confirm core demo works without network.
