---
'@mj-biz-apps/common-activity-sync': minor
---

Activity Sync — the MS Graph provider gets an actual transport, and credentials.

`MSGraphActivitySyncProvider` had none. Both of its `FetchRaw` returns handed back `Payloads: []`,
one behind an opt-in flag and one behind a "not supported in this build" log — written, typechecked
and refused. The consequence was not only that live sync did not work: nothing ever exercised the
path that needs a credential, so the fact that no credential was configured anywhere went unnoticed
until someone asked for a live demo. A fixture provider that bypasses the Graph path entirely was
the only thing producing data, and it was green throughout.

**The transport is now a seam.** `ActivityMessageTransport` isolates the one call that reaches the
network. `GraphCommunicationTransport` wraps MJ's Communication MS Graph provider and resolves an
"Azure Service Principal" credential from MJ's Credentials engine per fetch — never held on the
object, never logged, never interpolated into an issue string, and incomplete credentials are
refused by FIELD NAME before any call is made. `RecordedMessageTransport` replays captured Graph
payloads through the same mapper, so a run against recordings exercises everything except the
network hop rather than standing in for the engine wholesale.

**`IsLive` now follows the transport** instead of being hard-coded true. The engine refuses to write
`Source: 'Integration'` rows from a non-live provider, and that guard was worthless while a replayed
run could claim to be live. `AllowLiveFetch` still defaults false and still refuses live Graph reads
for the unchanged reason: app-only `Mail.Read` reads every mailbox in the tenant until an Exchange
Application Access Policy scopes the app registration. A recorded transport is exempt because it
reaches no mailbox.

**A message could go missing, and did so silently.** `Normalize` unwrapped a one-element `Payloads`
array and handed `MapGraphMessages` a bare message object, which matches neither shape it accepts —
so a mailbox with exactly one new message normalized to nothing and reported a clean, empty,
successful sync. One message is the most likely size of a real incremental pass. The response
envelope is now detected by shape rather than inferred from array length.

**A mutant had been skipping.** `M-AC18`'s anchor carried 12 spaces of indentation against
`writer.ts`'s 8 — the code was re-indented and the mutant never updated — so "stores a cancelled
meeting as Cancelled, not Logged" had no proof it could fail. Re-anchored, and `M-AC23`–`M-AC28`
added for the new behaviour.

**`CredentialsRef` is finally read.** The column describes itself as an "MJ Credentials engine key.
NEVER a secret value at rest" — and no code anywhere consumed it, so a connection could name the
credential it wanted and be silently ignored. Worse than an absent column: the configuration looked
complete while the provider refused for what appeared to be an unrelated reason. `BaseActivitySyncProvider`
gains a `Configure` hook (a no-op by default, so every existing provider is untouched), the engine calls
it with the connection's `CredentialsRef`, `Mailbox` and driver before fetching, and the Graph provider
resolves a transport from it through a host-supplied factory. Each way of failing now says something
different — no CredentialsRef, no factory registered, or a factory that served nothing — because each
has a different fix. A transport passed to the constructor still wins and is never replaced.

**No date bound is sent yet, deliberately.** The published Communication API has no first-class date
filter, and the only alternative was `ContextData.Filter`, which silently discarded any other clause.
MemberJunction/MJ#4123 adds `ReceivedAfter` and fixes that overwrite; until it publishes, the window
is applied downstream in `Normalize` as before, and a capped read that may have left mail behind now
reports an issue instead of passing quietly.

`@memberjunction/communication-types` and `@memberjunction/credentials` are added as peer
dependencies for their types. Neither is a runtime dependency: both collaborators are injected, so a
host that syncs only fixtures need install neither.
