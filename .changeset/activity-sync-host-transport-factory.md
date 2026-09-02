---
'@mj-biz-apps/common-activity-sync': minor
'@mj-biz-apps/common-server': minor
---

Activity Sync — the transport factory seam is finally reachable, and a host implements it.

`ActivityTransportFactory` was declared as "how a HOST supplies a transport", exported, documented,
and reachable **only as the third constructor argument**. `MJGlobal.ClassFactory` builds plugins with
no arguments, so through `ActivitySyncEngine` — the only path production uses — a factory could never
arrive. Every test that exercised one passed it to the constructor, which production never does. A
seam that is exported and unreachable is the same class of defect this package keeps being written
against, one layer up.

**A host registry replaces the unreachable parameter.** `RegisterActivityTransportFactory` is called
once at bootstrap and `Configure` consults it. A transport or factory passed to the CONSTRUCTOR still
wins, so tests and the demo keep supplying their own and a process-wide registration cannot reach in
and replace them.

**`ActivityTransportContext` gains `ContextUser`.** MJ's Credentials engine documents `contextUser` as
required server-side, so a factory that resolves a credential cannot work without it. It stays
optional because a factory serving recordings needs no user.

**`common-server` now implements the factory.** `GraphTransportFactory` turns a connection's
`CredentialsRef` into a `GraphCommunicationTransport`, resolving the credential through MJ's
Credentials engine and the provider through `ClassFactory` — including the base-class check copied
from `CommunicationEngine.GetProvider`, because `CreateInstance` returns a BASE instance when no
registration matches, so a missing provider otherwise comes back as a truthy object that answers no
call usefully. It lives in the host rather than in ActivitySync because ActivitySync takes both
engines as peers deliberately: a host syncing only fixtures should install neither.

**This enables nothing on its own.** `AllowLiveFetch` still defaults false, so a live read is still
refused until someone who has confirmed the Exchange Application Access Policy opts in. What ends is
the state where a correctly configured credential could not be resolved at all.
