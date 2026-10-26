# Security and Privacy for the Academic MVP

This MVP does not implement production security.

## Current limitations

There is:
- no server authentication;
- no persistent domain storage;
- no server authorization boundary;
- no cloud upload.

Do not present the app as production-ready.

## Demo data

Use fictional or consented data.

Avoid:
- real passwords;
- tokens;
- sensitive personal data;
- unnecessary real screenshots containing location/profile information.

## Evidence

For presentation reliability:
- prefer bundled sample screenshots;
- if the user selects an image, keep it only in memory;
- do not upload it;
- do not assume a persistent filesystem path on Web;
- references may disappear on restart.

## Permissions

Do not request:
- GPS/location;
- background location;
- microphone;
- contacts.

Only request/trigger image selection access if the chosen web/Android picker requires it.

## Synced mode (real test with Supabase)

The sections above describe demo mode. In synced mode (`12_SUPABASE.md`):

- **Consent:** before entering, each participant must check a notice that
  their name, runs and screenshots are visible to their rooms' participants,
  used only for this academic test and deleted afterwards
  (`privacyNotice` in `user_selection_page.dart`).
- **Data collected:** display name, rooms, competitions, activity numbers,
  screenshots (compressed), reports and votes. No e-mail, phone, password or
  location. Accounts are anonymous Supabase sign-ins tied to the device.
- **Access:** any signed-in participant can read all MinduRun rows; writes are
  limited to the caller's own rows, and moderation goes through server
  functions. Screenshots sit in a public bucket (anyone with the link).
- **Deletion:** after the test, empty the `evidence` bucket and run
  `supabase/cleanup.sql` (or delete the Supabase project).
- **Still not production:** no account recovery, no rate limiting beyond
  Supabase defaults, no audit log. Redesign before any real-world use.
