---
'@mj-biz-apps/common-activity-sync': patch
---

Activity Sync — supply the `accountEmail` MJ requires but its own credential type does not declare.

`MSGraphProvider.resolveCredentials` validates FOUR fields — `tenantId`, `clientId`, `clientSecret`
and `accountEmail` — while MJ's `"Azure Service Principal"` credential type declares only the first
three as required. A credential created exactly as MJ documents it therefore fails the provider it
exists to feed:

```
Missing required credentials for Microsoft Graph: accountEmail.
```

**Found by the first live call, which is where a fixture structurally cannot help.** Every recorded
run stubs the communication provider, so nothing had ever exercised MJ's real credential validation —
the failure was waiting on the exact hop the recordings exist to avoid.

Supplied by the transport rather than stored on the credential, for two reasons. The provider only
uses `accountEmail` as the fallback mailbox when no `Identifier` is given, and both transports always
give one — so storing it would persist a value nothing reads. And it would duplicate
`ActivitySyncConnection.Mailbox`, leaving two places to keep in sync and no signal when they disagree.
The mailbox being read *is* the account for that call.

Applied to the calendar transport too: `GetEvents` resolves credentials through the same path and
would have hit the same wall on its first live call.

The better long-term fix is in MJ — not requiring `accountEmail` when `Identifier` is supplied, or
declaring it on the credential type so the two agree. Worth raising separately rather than widening
an open PR.
