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

## Future note

If backend or persistence is added later, security/privacy requirements must be redesigned before production use.
