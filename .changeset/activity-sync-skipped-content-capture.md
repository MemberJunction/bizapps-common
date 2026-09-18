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

**KEY ROTATION DOES NOT REACH THIS COLUMN, and an auditor is the person who finds out.** MJ's
serialized ciphertext is `$ENC$keyId$algorithm$iv$ciphertext$authTag` — it records which KEY encrypted
a value but not which VERSION of it, confirmed against a blob this change produced: six parts,
key ID present, no version anywhere. `Decrypt` rebuilds the key configuration from the key row as it
stands at read time, so it always reaches for the current version's material.

`RotateEncryptionKeyAction` handles that by re-encrypting everything before bumping the version — but
it finds what to re-encrypt by enumerating `EntityField` rows matching
`EncryptionKeyID = '<key>' AND Encrypt = 1`. `CapturedContent` is not one: this app encrypts through
the engine by hand rather than declaring the field encrypted, which is the same decision that keeps
the crypto out of `common-activity-sync`. So a rotation re-encrypts every declared field and leaves
captured content behind, at a version nothing records.

Live operational data is re-encrypted as part of the rotation, which is why this has not bitten
anything before. An audit archive is the one kind of column where the read can come years after the
write. **Nothing here should change to fix that** — recording a version, or declaring the field
MJ-encrypted, are both platform decisions rather than this PR's. It is written down because this is
the change that tells an operator to switch long-lived retention on, and *"Ciphertext, always"* reads
like a promise that it stays readable.

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
pure-LF tree: 57 files, 0 CRLF, **80 anchors, 0 skips**.

**The three inherited truncations are off, and the two that were missed now actually are.** The
docblock this change added to `run.ErrorMessage` already argued the case: every free-text column here
is NVARCHAR(MAX) and none is 4000 wide, so the caps were habit rather than constraint. It then took
one of them off and left the others.

`.slice(0, 4000)` came off `healthErrorFromResults`, with a unit test pinning it — and
`stampConnectionHealth` sliced the same string back to 4000 on its way to `LastError`, so nothing an
operator reads had changed. Testing the pure function could not tell those two states apart, which is
why it did not. The check that replaces it drives a broadly failing run to what actually lands on the
row, and `M-ERR1` puts the cap back on the write site alone: it fells the new check and leaves the
pure-function one passing, which is the gap itself.

The third was three lines from the capture block: `ActivitySyncRunDetail.Reason` is also NVARCHAR(MAX)
and was sliced at 500. It matters most for exactly the rows this feature is about — a `Failed`
detail's Reason is the writer's issues joined, and it sits beside `CapturedContent` as the account of
why the message was not filed. `M-ERR3` puts it back.

**The capture path was run against a real key for the first time.** Every automated check stubs the
cipher, so "`CapturedContent` holds ciphertext an auditor can open" rested on MJ's engine behaving as
documented. Driven end to end against the real `SQLServerDataProvider` with a throwaway key: both
policies produce a real `$ENC$` blob, neither contains the plaintext, `Decrypt` returns the exact
subject and the exact subject-plus-body, and an unknown key throws rather than returning plaintext —
which is the fail-closed contract the engine depends on.

**`ActivityContentCipher` now takes a `contextUser`, and it is worth being exact about why.** A cipher
is asked to perform a privileged read, and the engine is the only code that knows whose run it is; a
host whose cipher reads its own key table, or calls a KMS as the caller, has no other way to find out.
The order-line edit veto in Orders is handed a user for the same reason. `M-CAP13` pins that the
engine forwards it.

What it does NOT do is fix a fault in MJ's engine, and two earlier revisions of this paragraph claimed
it did. `setupSQLServerClient` calls `StartupManager.Startup()`, which configures `EncryptionEngine`
with a system user — and that holds even when key validation fails, because `Loaded` means the metadata
loaded and the key-material check is separate. Measured in a fresh process against a host with no
usable key: with and without a user, `Encrypt` returns the identical error. The argument is the seam's
contract, not a workaround.

*(The first revision said nothing configures the engine at startup, which a `@RegisterForStartup`
decorator made invisible to the grep behind the claim. The second said the lazy path runs when startup
validation fails, which running it disproved. Both are recorded here rather than quietly rewritten,
because the same habit — asserting from source without executing it — is what this changeset keeps
finding in the code it describes.)*

`M-CAP8` needed re-anchoring as a consequence: threading the argument through made the `Encrypt` call
multi-line and its anchor was the single-line form, so it matched nothing and reported SKIP — on the
mutant this description singles out, for the second time. It now anchors on both statements and
reorders them, which is what the mutation always meant. **The FULL run caught it; running only the
mutant added alongside would have reported success while switching this one off.**

27 tests across the two packages and 17 registered mutants, all caught — including `M-CAP1`, the
literal revert to the previous behaviour, and `M-CAP8`, which sets the key before the ciphertext so a
throw leaves `CK_ActivitySyncRunDetail_ContentKey` violated. One coverage gap was found by a mutant
rather than by reading: nothing tested that an **included** message keeps its content out of the
audit column, so capturing on every decision survived until that test existed.

`M-BOOT3` covers the bootstrap registration itself. Without it the test making this seam different
from `ActivityFileSink` — that `LoadBizAppsCommonServer` actually calls it — was the one claim here with
nothing proving it could fail.
