---
'@mj-biz-apps/common-activity-sync': minor
'@mj-biz-apps/common-server': minor
---

Activity Sync — audit retention for skipped messages was migrated, documented and unreachable.

A deployment could set `SkippedContentPolicy` to `SubjectEncrypted`, point it at an encryption key,
watch every run complete successfully, and retain **nothing**. No error, no warning, no row. An
auditor asking "what was in the message you declined to file?" would have been told the record
existed, and it did not.

Every piece of the feature was already here and none of it was reachable:

| piece | state before |
|---|---|
| `ActivitySyncProviderType.DefaultSkippedContentPolicy` | *"Overridable per connection"* — no reader, so there was no chain to override |
| `ActivitySyncProviderType.DefaultEncryptionKeyID` | no reader |
| `ActivitySyncConnection.SkippedContentPolicy` | loaded into a TypeScript interface, never read off the row |
| `ActivitySyncConnection.EncryptionKeyID` | not on the interface at all |
| `ActivitySyncRunDetail.CapturedContent` | *"Ciphertext, always"* — never written by anything |
| `ActivitySyncRunDetail.EncryptionKeyID` | never written |
| `ResolveCapturePlan()` | written, documented, unit-tested — **zero callers** |
| `ResolvePolicy()` | the fallback helper; its only mention was in a doc comment |

Two CHECK constraints — `CK_ActivitySyncProviderType_KeyRequired` and
`CK_ActivitySyncRunDetail_ContentKey` — were enforcing invariants for a feature no code participated
in. This is the same shape as the six defects `#116` was opened for, in the same subsystem, and it is
why that PR's audit went looking: a column that documents its own purpose and has no reader.

**The misconfiguration it exists to refuse never fired either.** `ResolveCapturePlan` rejects a policy
above `None` with no key — retaining content from a message deliberately not ingested is only
permissible encrypted. Nothing called it, so that refusal was unreachable too.

**Resolved before anything is read, not at persist time.** Refusing after a mailbox has been fetched
costs the read and leaves the run holding content it has just been told it may not keep. A
misconfigured connection now stops before it touches anyone's mail, and the run fails rather than
reporting success over an audit trail that does not exist.

**Only on a real skip.** `Included` already has an Activity carrying the content, so capturing it
again would put an encrypted duplicate of ordinary mail in a column meant for messages that were not
filed. A DRY RUN captures nothing: `WouldExclude` is a rehearsal, and a preview must not put real
content behind a retention policy on the strength of one. `Failed` **is** captured — a message that
could not be written is exactly the one an auditor asks about, and the case where nothing else holds
a copy.

**The cipher is a seam, and it ships with its implementation.** `CapturedContent` is documented as
encrypted *"through MJ's EncryptionEngine... this app never implements its own crypto"*, so
`common-activity-sync` takes no runtime dependency on the Encryption engine and asks a host for an
`ActivityContentCipher` — one method, encrypt only, because the sync engine never needs to read
captured content back and an engine that cannot decrypt cannot leak.

The difference from `ActivityFileSink`, whose `Store()` still has no caller on any real path:
`common-server` **fills** this seam at bootstrap, beside the transport factory and the mailbox
policy. A seam nothing implements is the defect this subsystem keeps being cleaned of, so the
interface does not ship alone. A host that asked for retention and registered no cipher is refused by
name rather than quietly retaining nothing.

Encryption failing for one message reports and still saves the decision: losing a whole run record
because one message could not be encrypted is a worse trade than an audit gap that says so.

**Setting a policy above `None` also requires the host's encryption key to be usable** — for the
default `Base Encryption Key`, that means `MJ_BASE_ENCRYPTION_KEY` set to a base64 32-byte value. The
pre-flight refuses a host with no cipher REGISTERED, but it cannot tell whether the key behind it has
material without attempting an encrypt. On a host missing that variable the run still records every
decision, and every message adds an issue saying its content could not be encrypted. Nothing is lost
and nothing is silent, but the audit trail is empty, so set the variable before setting the policy.

**A correction to an earlier claim in this changeset.** It read "74 of 74, driver exits 0", and that
was true only on the machine that measured it. Three anchors were written with CRLF; this repo commits
LF and carries no `.gitattributes`, so on a clean checkout `M-CAP8` and `M-AC41` matched nothing and
the driver exited 1. `M-CAP8` had therefore never run anywhere, and `M-AC41` **worked on `next` until
this branch re-anchored it** — it guards `ProviderTypeRow` staying in sync with the `Fields` list, and
this change adds two fields to both, so the mutant that would catch a mismatch was off in the change
that most needed it.

The driver now normalises to LF before matching and writes back in the file's own ending, so every
anchor is portable rather than two being fixed and the trap moved. Verified against a purpose-built
pure-LF tree: 57 files, 0 CRLF, **76 anchors, 0 skips**.

24 tests across the two packages and 13 registered mutants, all caught — including `M-CAP1`, the
literal revert to the previous behaviour, and `M-CAP8`, which sets the key before the ciphertext so a
throw leaves `CK_ActivitySyncRunDetail_ContentKey` violated. One coverage gap was found by a mutant
rather than by reading: nothing tested that an **included** message keeps its content out of the
audit column, so capturing on every decision survived until that test existed.

`M-BOOT3` covers the bootstrap registration itself. Without it the test making this seam different
from `ActivityFileSink` — that `LoadBizAppsCommonServer` actually calls it — was the one claim here with
nothing proving it could fail.
