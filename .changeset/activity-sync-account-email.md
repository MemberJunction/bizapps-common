---
'@mj-biz-apps/common-activity-sync': patch
---

Activity Sync — the calendar transport needs the same credential handling the message transport just got.

`#115` fixed this for `GetMessages`: `MSGraphProvider.resolveCredentials` validates four fields —
`tenantId`, `clientId`, `clientSecret` and `accountEmail` — while MJ's `"Azure Service Principal"`
credential type declares only the first three, so a credential created exactly as MJ documents it
fails the provider it exists to feed. It also passes `disableEnvironmentFallback`, so a gap in the
credential can never be filled from the host's `AZURE_*` variables — the difference between failing
on a missing field and reading a mailbox nobody asked for.

`GetEvents` resolves credentials through the identical path and would have hit both walls on its
first live call. Same two arguments, same reasons, applied to the calendar transport.

Found the same way #115 was: the first live call. Every recorded run stubs the communication provider,
so nothing had exercised MJ's real credential validation on either surface.
