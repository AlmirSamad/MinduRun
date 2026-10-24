# Flutter UI Architecture

## Platform strategy

MinduRun uses one Flutter codebase.

Priority:
1. Web / Chrome for development and presentation.
2. Android for secondary validation.

The design remains mobile-first.

## Stack

- Flutter
- Dart
- Riverpod
- GoRouter

No HTTP client is required.

## Suggested structure

```text
lib/
├─ app/
│  ├─ router/
│  ├─ theme/
│  └─ bootstrap/
├─ core/
│  ├─ models/
│  ├─ repositories/
│  ├─ services/
│  └─ widgets/
└─ features/
   ├─ session/
   ├─ rooms/
   ├─ competitions/
   ├─ activities/
   ├─ ranking/
   └─ moderation/
```

## Mobile-first responsive rules

- Design screens first for phone-sized widths.
- On desktop Chrome, center the app instead of stretching every element edge to edge.
- Use a reasonable max content width for the primary app shell.
- Avoid hardcoding one device's exact size.
- Use `LayoutBuilder`, constraints and responsive composition when necessary.
- Do not create separate web/mobile business flows.
- Navigation should remain understandable on both narrow and wide layouts.

## Presentation recommendation

For the college presentation:
- run with `flutter run -d chrome`;
- present in a normal browser or browser device emulation;
- keep the content visually similar to a phone app;
- ensure primary flows remain usable with mouse input.

## Visual identity

Dark theme only (`AppTheme.dark()` in `lib/app/theme/app_theme.dart`).
All colors and fonts come from `AppColors` / `AppFonts`; screens never use
raw hex values.

- Background `#0C0D0F`, cards `#17181B` with a 1 px `#2C2E31` border.
- Primary actions: electric lime `#C5F658`. Energy actions (register
  activity, create room/competition, publish) and points: ice blue `#8FD3E9`.
- Status: published `#5ED8A9`, under review `#F8C655`, rejected/cancelled
  `#FD7273`; competitions scheduled = ice blue, active = lime, finished = grey.
- Hero cards: graphite gradient `#1D1F23 → #2A2E34` with faint diagonal
  stripes (`HeroCard`).
- Text font Archivo; points, positions and the brand use Barlow Condensed
  ExtraBold Italic (`AppFonts.numbers`). The font files are not bundled yet,
  so the platform font is used as a fallback.
- Logo: lime bolt + ice-blue speed stroke (`MinduSymbol`, `MinduLogo`), drawn
  in code from the same geometry as the SVGs in `assets/brand/`.

## MVP screens

- demo user selection/local login;
- home/rooms;
- create room;
- join room;
- room details;
- create competition;
- competition feed;
- ranking;
- participants;
- submit activity;
- activity details/evidence;
- report activity;
- report voting/review.

## Activity submission UX

Inputs:
- evidence image;
- distance;
- duration;
- average pace.

Requirements:
- clear units;
- form validation;
- evidence preview;
- disable duplicate submission;
- show consistency error clearly;
- update feed/ranking immediately.

## Evidence on Web and Android

Preferred order for academic reliability:

1. bundled screenshots in `assets/demo/`;
2. optional user-selected image.

When user selection is implemented:
- use a Flutter package that supports Web and Android;
- read selected image data into memory;
- avoid `dart:io.File` in shared code;
- keep the evidence only for the current session.

## State

Features should handle:
- initial;
- empty;
- populated;
- validation/error;
- transition/update state.

## Demo reliability

Prioritize:
- predictable navigation;
- visible state changes;
- readable ranking;
- easy reset;
- no network dependency;
- Chrome compatibility.
