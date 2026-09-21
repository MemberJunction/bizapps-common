# @mj-biz-apps/common-activity-sync

## 5.45.0

### Patch Changes

- Updated dependencies [868b125]
  - @mj-biz-apps/common-entities@5.45.0

## 5.44.0

### Minor Changes

- 701e505: Activity Sync — audit retention for skipped messages was migrated, documented and unreachable.

  A deployment could set `SkippedContentPolicy` to `SubjectEncrypted`, point it at an encryption key,
  watch every run complete successfully, and retain **nothing**. No error, no warning, no row. An
  auditor asking "what was in the message you declined to file?" would have been told the record
  existed, and it did not.

  Every piece of the feature was already here and none of it was reachable:

  | piece                                                  | state before                                                                  |
  | ------------------------------------------------------ | ----------------------------------------------------------------------------- |
  | `ActivitySyncProviderType.DefaultSkippedContentPolicy` | _"Overridable per connection"_ — no reader, so there was no chain to override |
  | `ActivitySyncProviderType.DefaultEncryptionKeyID`      | no reader                                                                     |
  | `ActivitySyncConnection.SkippedContentPolicy`          | loaded into a TypeScript interface, never read off the row                    |
  | `ActivitySyncConnection.EncryptionKeyID`               | not on the interface at all                                                   |
  | `ActivitySyncRunDetail.CapturedContent`                | _"Ciphertext, always"_ — never written by anything                            |
  | `ActivitySyncRunDetail.EncryptionKeyID`                | never written                                                                 |
  | `ResolveCapturePlan()`                                 | written, documented, unit-tested — **zero callers**                           |
  | `ResolvePolicy()`                                      | the fallback helper; its only mention was in a doc comment                    |

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
  encrypted _"through MJ's EncryptionEngine... this app never implements its own crypto"_, so
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
  the change that tells an operator to switch long-lived retention on, and _"Ciphertext, always"_ reads
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

  _(The first revision said nothing configures the engine at startup, which a `@RegisterForStartup`
  decorator made invisible to the grep behind the claim. The second said the lazy path runs when startup
  validation fails, which running it disproved. Both are recorded here rather than quietly rewritten,
  because the same habit — asserting from source without executing it — is what this changeset keeps
  finding in the code it describes.)_

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

### Patch Changes

- Updated dependencies [7056463]
  - @mj-biz-apps/common-entities@5.44.0

## 5.43.0

### Minor Changes

- 4ad78ac: Activity Sync — `IncludeAttachments` had no reader, so a rule that asked for attachments got none and said nothing.

  `ActivitySyncRule.IncludeAttachments` describes itself as _"1 = also pull attachments into ActivityFile
  rows"_. `MaxAttachmentBytes` sits beside it. The `ActivityFile` table, its `Kind` value list
  (Body / Attachment / Ics) and its base view are migrated and registered in metadata. **Nothing anywhere
  read a line of it.** Fifth instance in this package of schema and documentation written ahead of the
  wiring — and as with the others, every test passed because nothing exercised the unwired path.

  **The decision is made where it can be made.** Rules are evaluated _after_ the fetch, so "does this
  item want its attachments?" is unanswerable while fetching. `NormalizedItem` now carries a cheap
  `HasAttachments` flag straight from the provider payload, and the policy is resolved at write time
  from the rule that actually decided the item. Listing attachments costs a call **per message**, so
  that call is now paid only for items a rule both included and asked about.

  **No rule means no attachments.** An item can be included by the KnownParticipant stage or a
  provider-type default, and neither expresses an attachment choice. Defaulting to "fetch" there would
  pull every attachment in a mailbox on the strength of a decision nobody made.

  **Everything dropped is reported.** Silently omitting a signed contract because it exceeded a cap,
  while reporting a successful sync, is the failure this package keeps being written against. Oversize
  files are named individually; inline images are summarised by count so forty signature logos cannot
  bury the one line that matters. A file whose size cannot be read is skipped rather than allowed while
  a cap is in force — that gap would pass exactly the file the cap exists to stop. A cap of `0` reads as
  "unset", not "keep nothing", because that is overwhelmingly what a zero in that column means.

  **Inline attachments are dropped by default** — body furniture, already visible in the body, and
  `ActivityFile.Kind` has a separate `Body`. Keeping them would fill file storage with one copy of a
  corporate logo per email. Still reported, so a deployment that wants them can see what it is missing.

  **The bytes are not moved yet, and that is now said out loud.** `ActivityFile.FileID` is a foreign key
  into `__mj.File`, so storing an attachment needs MJ's `FileStorageEngine` and a configured
  `FileStorageAccount` — every MJ storage driver is a remote service, and a host may legitimately have
  none. `ActivityFileSink` is the seam a host fills, exactly as it fills the transport factory — and it is
  now fillable the same way, through `RegisterActivityFileSink()` at bootstrap. It was not: the only
  production construction is `new ActivitySyncEngine()` inside an Action, so the constructor parameter
  that took a sink was unreachable and `Store()` had no caller on any real path. A host could implement
  the interface exactly as documented and get nothing. A sink passed to the constructor still wins,
  because tests and the demo supply their own.

  BOTH ENDS REPORT. With no sink registered, an item whose rule asked for attachments produces an issue
  naming the item and both ways out, instead of an activity quietly filed without them. With a sink
  registered it reports too, because `Store()` is still not wired to the selection: rewarding a host for
  filling the seam correctly with the same quiet nothing would be the more misleading of the two, since
  everything on the host's side is right. It says the gap is in Activity Sync, not in the host.

  19 tests, each mutation-checked and now registered as `M-AT1`–`M-AT8`: fetching with no rule,
  ignoring the item's flag, reading a zero cap as "keep nothing", keeping inline images, allowing an
  unmeasurable file past a cap, an off-by-one at the cap boundary, ignoring `Fetch: false`, and
  suppressing the skip report are all caught — as is the mapper quietly ceasing to read Graph's own
  `hasAttachments` flag (`M-MAP1`), which would make the whole feature do nothing on every real message
  while reporting success. That list had been verified by hand and not kept, which left it describing
  evidence that no longer existed. Verified end to end against the database: with the rule switched on, exactly one of five demo
  items reported — the one whose payload says it has attachments.

- b1e8650: Activity Sync — the calendar surface had no transport, so every calendar fetch returned nothing.

  `MSGraphCalendarSyncProvider` declared a `GraphEventFetcher` seam that **nothing implemented**,
  reachable only as the second constructor argument — and `MJGlobal.ClassFactory` builds plugins with
  no arguments. Through the engine, every calendar fetch returned `Payloads: []` and logged "no
  transport is wired". Exported, documented, typechecked and unreachable: exactly the state the message
  surface was in before its transport landed, one surface over.

  **It rides the same seam as mail rather than a parallel one.** `ActivityMessageTransport` is really
  "fetch raw payloads for a mailbox", which is the calendar contract too, and the host factory now
  dispatches on `DriverClass` to serve both. One connection, one `CredentialsRef`, one credential —
  separate factories would let a connection read mail as one principal and calendar as another.

  **There was nothing to wrap until now.** MJ's `MSGraphProvider` had no calendar API at all, and the
  piece that would make one possible (`getGraphClient`, which owns token acquisition and the
  credential-keyed client cache) is private. Building a Graph client here would have forked precisely
  what `BaseActivitySyncProvider` says to wrap, so calendar retrieval was added to MJ first
  (`GetEvents`) and this wraps it — with the same compile-time assertion the message reader uses, so
  drift in MJ's signature breaks the BUILD rather than the first live call.

  **One attestation, not two.** The same Exchange Application Access Policy scopes `Mail.Read` and
  `Calendars.Read`, so the calendar provider reads the same `AllowLiveMailboxFetch` attestation. A
  second switch would let someone record half a decision and believe they had scoped both.

  **`IsLive` now follows the transport** instead of being hard-coded `true`. The engine refuses to write
  `Source: 'Integration'` rows from a non-live provider, and that guard was worthless while a replayed
  calendar run could claim to be live — the resulting rows would be indistinguishable from real ones.

  **Three things a calendar read can do quietly, now said out loud:**

  - _The window is a rolling lookback and never the watermark._ `/calendarView` refuses an unbounded
    request, so a bound is invented — and an invented bound nobody mentions reads as "we synced your
    calendar" when it means "we synced a month of it". It is said out loud on the first run, where
    somebody expects full history; the same bound applies on every later run.

    An earlier version of this branch passed the watermark as `StartDateTime`, which is a different
    quantity used as if it were the same one. `WatermarkBasisForKind('Calendar')` is `ObservationTime`
    — when we last LOOKED — and `StartDateTime` filters on the EVENT'S own time. So a meeting held
    last week but added to the calendar tomorrow starts before the watermark, falls outside the next
    run's window, and outside every later one, since each starts later still. Never read, on any run,
    no issue, `Success = true`. Retroactive additions and back-dated invitations are ordinary calendar
    behaviour. The same events are now re-read every run, which costs one de-duplication lookup each
    and writes nothing, while a missed event is unrecoverable.

  - _Recurrence may not have been expanded._ A series master and a single occurrence look alike, so
    without this a weekly meeting is filed once, at whatever date the series began, and every
    downstream check still passes.
  - _A capped read_ may have left events in the window.

  Cancelled events are fetched deliberately — `MapGraphEvent` already carries `Cancelled` through, and
  dropping them at the transport would make that field dead code. The window reaches forward as well as
  back, because `Activity.Status` includes `Scheduled`.

  The dead `GraphEventFetcher` interface is removed: nothing implemented it, and keeping an unreachable
  seam is the defect this change exists to end.

  32 tests across the two packages, each mutation-checked — dropping the end bound, silencing the
  lookback notice, discarding cancelled events, reading the normalized `Events` instead of `SourceData`,
  omitting the recurrence warning, turning a Graph failure into an empty batch, hard-coding `IsLive`,
  opening the gate, ignoring the attestation, and refusing to serve the calendar driver are all caught.
  All of them are now REGISTERED rather than verified once by hand — `M-CAL1`–`M-CAL8` for the
  transport and the provider's `IsLive`, `M-GTF1`–`M-GTF5` for the factory's surface dispatch, and
  `M-SD1`/`M-SD2` for `SurfaceDriverClass`. Restoring the watermark as the window start is caught too
  (`M-CW1`), which it was not when that bug was live: the harness did not open this file at all, so
  every mutation aimed at it reported all-clear by never reaching it. That is the reason the list is
  worth registering rather than writing down — an enumerated "all caught" over a file the harness never
  opens reads exactly like coverage.

- 3aeb4a1: Activity Sync — `InternalDomains` had no reader, so every participant rule silently inverted.

  `ActivitySyncRuleSet.InternalDomains` describes itself as "Required for any rule using
  ParticipantScope", `participants.ts` names it as where the list lives, and the migration that created
  it explains why it exists at all. `ActivitySyncEngine` passed a hard-coded `[]` into every
  qualification context and never read the column. Same shape as the `CredentialsRef` gap: written,
  documented, migrated, and consumed by nothing.

  **An empty list is not a disabled feature — it is an inverted one.** `ClassifyParticipants` counts an
  address as Internal only when its domain appears in the list, so with an empty list every participant
  is External:

  | scope                         | intended                      | what actually happened                            |
  | ----------------------------- | ----------------------------- | ------------------------------------------------- |
  | `HasExternal` / `AllExternal` | threads with an outside party | matched **everything**, internal chatter included |
  | `AllInternal` / `HasInternal` | internal-only traffic         | matched **nothing**                               |
  | `Mixed`                       | both present                  | could never match                                 |

  So a rule set written to keep internal mail out of the sync included all of it, while reading as a
  working filter. On a real mailbox that is the difference between filing a customer thread and filing
  everything the user has ever received.

  **Malformed fails the run rather than degrading to empty.** A typo in the column would otherwise
  become "sync everything", silently — the worst possible reading of a config error. "Internal" is a
  property of the deployment, so guessing it is worse than refusing.

  **A scoped rule with no domains now says so.** Absent `InternalDomains` is legitimate — plenty of
  rule sets never test participants — so it is a reported issue rather than a refusal, naming how many
  rules are affected and what to set. Silence there was what made the original defect invisible.

  Parsing and the warning are pure functions in `participants.ts` (`ParseInternalDomains`,
  `ParticipantScopeWarning`), testable without standing up a RunView. 21 tests, each mutation-checked:
  degrading a malformed list to empty, accepting a non-array, dropping the case/`@` normalisation that
  keeps the list comparable with the addresses it is matched against, losing de-duplication, silencing
  the warning, and treating `Any` as a participant test are all caught.

  **And the wiring itself, which those 21 did not reach.** Reverting the engine to the hard-coded `[]`
  — the literal original defect — passed every test in the package, because the only test driving `Run`
  stubbed each lookup to empty, so `[]` and the real rows were indistinguishable. The fix was real and
  the evidence for it was not, which is the same shape as the defect. `engine.internal-domains.test.ts`
  observes the rule set the engine actually hands the qualifier, and `M-ID1`/`M-ID2` fell both the
  revert and the swallowed parse failure. The seven parsing mutations named above are registered too
  (`M-PA1`–`M-PA7`): they had been run by hand when the work was done and nothing kept them, so the
  list described evidence that no longer existed.

- 7e6e87c: Activity Sync — the live-fetch gate was unreachable, so a scoped host could not turn it on.

  > **A DECISION IS REQUIRED BEFORE THIS IS TURNED ON, AND IT IS NOT A CODE DECISION.**
  >
  > `MSGraphProvider` authenticates app-only, so the `Mail.Read` **application** permission is granted
  > against the tenant, not against a mailbox: it can read **every mailbox in the organisation**. The
  > `Mailbox` column on a connection narrows what we _ask_ for, never what we are _allowed_ to read.
  > The only thing that narrows the grant is an Exchange RBAC-for-Applications assignment binding the
  > app registration to a mail-enabled security group.
  >
  > **We do not know whether that assignment exists**, and could not find out: it is visible only to an
  > Exchange administrator. The app in use (`BizApps Sales - Activity Ingest`) holds application
  > `Mail.Read` and nothing else — confirmed from the token's own `roles` claim.
  >
  > **Merging this changes nothing on its own.** Live fetch stays refused: the default is the host
  > attestation, no host has one, and the attestation cannot be satisfied by a flag. Whichever way the
  > question is answered it needs a person and a date, plus EITHER the security group an Exchange
  > assignment scopes the app to OR a written sentence accepting the tenant-wide grant. Whoever deploys
  > has to answer the question deliberately. They cannot skip it by accident.
  >
  > Two legitimate outcomes, both informed: accept the tenant-wide grant and record who accepted it, or
  > scope the app to a group first. Creating the restriction is an Exchange administrator's job
  > (`New-ManagementScope` and `New-ManagementRoleAssignment`), and it is not something this package
  > can do or check from inside the application.

  `AllowLiveFetch` was the FIRST constructor argument of `MSGraphActivitySyncProvider`, defaulting to
  `false`. `MJGlobal.ClassFactory` builds plugins with NO arguments. So through `ActivitySyncEngine` —
  the only path production uses — live fetch was permanently off, and the parameter could be set by
  tests and the demo alone. Every test passed, because every test constructed the provider directly.

  This is the same defect the transport factory had one layer down, and it gets the same fix: a host
  registry. What it is emphatically NOT is a relaxation. Making a gate reachable must not make it open,
  and most of the new tests exist to pin that: with nothing registered, an unconfigured host refuses
  exactly as before, and the transport it refused is never called.

  **Two decisions are modelled, because two decisions are what organisations make.** The attestation is
  a discriminated union:

  - `RestrictedToGroup` — an Exchange assignment binds the app to a named security group.
  - `TenantWideAccepted` — the tenant-wide grant was looked at and accepted, with `AcceptedRisk` saying
    what was accepted in the deciding person's own words.

  An earlier draft demanded a group name, which quietly assumed every deployment would create an
  Exchange RBAC assignment. Most will not: adding an API permission in Entra is one team's five-minute
  job, and RBAC for Applications is a different system that often nobody owns. A gate that accepts only
  "scoped" leaves everyone else choosing between inventing a group name and bypassing the gate — and
  both destroy the record it exists to keep. What stays impossible is the third state, _nobody looked_:
  neither variant can be satisfied without a name, a date, and either a group or a written reason.

  `AcceptedRisk` is free text and required rather than a flag, deliberately. A tick-box records that
  somebody clicked; a sentence records that somebody understood, and it is what an audit reads when the
  next person asks why this app can read every mailbox.

  **The opt-in is an attestation, not a boolean.** A boolean records that somebody WANTED live fetch.
  `LiveMailboxPolicyAttestation` records that somebody CHECKED — which mail-enabled security group the
  Exchange Application Access Policy names, who confirmed it, and when. Those are the things an audit
  asks for, and the things a person has to look up rather than guess. `Confirmed` is the literal `true`
  rather than `boolean`, so a variable that happens to be false will not type-check and the attestation
  cannot be satisfied by threading a flag through. The types are not the only guard, because a type is
  not a guard at all against an untyped caller: `AllowLiveMailboxFetch` CHECKS at runtime that
  `Confirmed` is literally `true`, that `ConfirmedBy` is not blank, and that `ConfirmedAt` is a real
  `Date` — each refusing by name. Whichever variant is used, a blank group or a blank accepted-risk
  sentence is rejected: accepting one would turn this straight back into a boolean with extra steps.

  Staleness is deliberately NOT enforced. `ConfirmedAt` is recorded and logged at bootstrap so an
  operator can SEE that an attestation is two years old; expiring it in code would take a working
  deployment off the air on a date nobody scheduled, which is a worse failure than a visible old date.

  **Deliberately not driven by data.** `ActivitySyncConnection` is an ordinary editable entity. Had the
  opt-in lived there, anyone who could edit a row could enable tenant-wide mail reading from a form —
  app-only `Mail.Read` reads EVERY mailbox in the tenant, and a connection's `Mailbox` narrows what we
  ask for, not what we are allowed to read. The package already refuses to let a database row swap the
  transport; this applies the same rule to the more dangerous switch. `AllowLiveMailboxFetch` is a
  bootstrap-time call, and the host reads it from deployment configuration.

  **A partial configuration throws rather than quietly staying off.** `LoadLiveMailboxPolicyFromEnv`
  wants `ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_BY` and `..._CONFIRMED_AT` whichever decision was made,
  and then EXACTLY ONE of `..._GROUP` or `..._ACCEPTED_RISK` — the two are mutually exclusive, because
  setting both claims the app is restricted and knowingly unrestricted at the same time. Setting none
  of the four is the ordinary un-opted-in case and is silent; setting some of them throws. Silently
  ignoring a half-written opt-in is the exact trap this codebase keeps being written against: an
  operator who set two of three would see the provider refuse, believe the Exchange policy was wrong,
  and go hunting for a fault that is in their `.env`. Blank and whitespace-only values read as absent,
  and an unparseable date is rejected by name.

  **The refusal now names the way out.** `LIVE_GRAPH_REFUSAL` explained why live fetch was off but not
  how to enable it, which left an operator who HAD verified the policy with no supported next step —
  and the tempting unsupported one is to go editing rows.

  343 tests in `common-activity-sync` and 47 in `common-server`, with a mutation driver in each:
  64 mutants in `packages/ActivitySync/test-harnesses/mutate-checks.mjs` and 15 in
  `packages/Server/test-harnesses/mutate-checks.mjs`, all 79 caught. Every source file this change
  touches carries at least one, bar the barrel and the types file. Between them they fell reverting
  the default to `false`, allowing everything, dropping any of the three runtime attestation checks,
  accepting whitespace as a group name, treating a partial env as complete, claiming both decisions at
  once, claiming neither, filing a tenant-wide acceptance as a group restriction, skipping date
  validation, and misreporting the result.

  Later commits on this branch fix defects of the same class found in the branch itself. The
  attestation was a compile-time shape with no runtime check. The `InternalDomains` fix had no test
  that could fail. The calendar window keyed on the watermark rather than on a lookback span, which
  silently skipped back-dated meetings, and the replay transport had the matching hole on its first
  run. Issues raised by a run that SUCCEEDED were never written anywhere, which discarded the delivery
  mechanism for every deliberate report this package makes. `ActivityFileSink` gained a host registry,
  because its only production construction passes no arguments and `Store()` therefore had no caller.

  Several of those were found by asking the suites to prove they could fail, rather than by reading.
  `common-server` had no mutation driver, and deleting either of the two guards that decide WHICH
  attestation was made left all 40 of its tests green — both rules are described above and neither had
  a reader. It also had no typecheck step over its tests, because its build config excludes them and
  vitest does not typecheck; adding one surfaced six type errors in test code, including assertions
  indexing an empty tuple, which could not have been reading what they claimed to.

  The last of them is the wiring itself. `LoadBizAppsCommonServer` is what MJAPI's
  `DynamicPackageLoader` calls at startup, and its two lines registering the transport factory and
  reading the attestation are the only thing that populates either registry on a real host. Commenting
  out either left every test green, because both loaders are unit-tested by calling them directly.
  Without the policy load a host that set all four variables correctly is refused, and the refusal
  tells it to set the variables it just set.

  **The refusal itself was part of the same problem.** It said to "call `AllowLiveMailboxFetch()` with
  the group the policy names" — naming one of the two decisions this release exists to model, and a
  function rather than the environment variables a deployment actually sets. Every test compared
  against the constant, so the text could have been trimmed to one sentence and stayed green. It now
  names both decisions and the configuration, and three tests pin that it keeps doing so.

### Patch Changes

- 192cc39: Activity Sync — the calendar transport needs the same credential handling the message transport just got.

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

- 9d5cb06: Activity Sync — a calendar fixture, and the engine bug it immediately found.

  `demo/graph-sample-events.json` is the calendar counterpart to the message fixture: six events
  hand-built to the shape of Microsoft's published `event` resource, chosen to exercise decisions rather
  than to look tidy — a recurring **occurrence** with a `seriesMasterId`, a cancellation, an
  internal-only meeting for the `ParticipantScope` path, one event carrying attachments, and one whose
  `timeZone` is a named non-UTC zone with no offset, which genuinely determines no instant. Fields the
  mapper never reads are kept deliberately, so the fixture agrees with Microsoft rather than with us.

  **Running it end to end found a real bug.** `RunConnections` drives a second calendar surface from the
  same connection and the same type row, and `Configure` received `typeRow.DriverClass` on both passes.
  So a host factory serving both surfaces was told `"Microsoft365"` for the calendar too: it built a
  **mail** transport, fed Graph message payloads to the event mapper, and every one was dropped for
  having no start time.

  The failure mode is why it survived. The run reported `Success` with an empty calendar, which is
  indistinguishable from a genuinely empty calendar — no error, no exception, nothing to investigate.
  It surfaced the moment five real events arrived as five "no usable start time" skips.
  `SurfaceDriverClass` now answers with the driver of the surface being run, from the `Kind` the plugin
  already declares.

  **Both fixtures are now covered by tests**, which they were not before: the message fixture was loaded
  only by a demo script, so nothing stood behind it but plausible-looking output. A fixture nobody
  asserts against drifts silently — a mapper quietly stops reading a field and the demo still prints a
  green wall with one column now empty. Among other things these pin that the timezone sample is
  _skipped_, so a later "fix" that guesses at a named zone fails here rather than filing meetings hours
  from when they happened.

  **How it was exercised.** `RunConnections` is the path the scheduled Action uses and the only one
  that reaches the calendar surface at all, so it was driven end to end against a real database through
  a local harness, with a recorded factory dispatching on `DriverClass` so each surface replays its own
  payloads. That harness is a local investigation script and is deliberately not part of this change:
  it constructs the provider with `AllowLiveFetch` directly, which is exactly the gate the rest of this
  work exists to install. The behaviour it exercised is pinned by `engine.fixture-run` and the fixture
  tests instead, which run in CI and do not need a database.

  Verified against the database: a fleet run writes 5 Email and 5 Meeting activities, with the sixth
  event correctly skipped by name.

- 9fc60ef: Activity Sync — a first run that filled its page silently lost every message older than it.

  `Capped` required `query.Since`, so it could never be true on a first sync. That left the run most
  likely to overflow a page as the only one with no protection:

  1. no date bound is sent, so Graph returns the newest `Limit` messages;
  2. `ResolveHighWatermark` takes the newest of those for a Message surface;
  3. the next run asks for everything **after** it;
  4. every message older than that first page is permanently below the watermark, unread.

  The run reported `Success`, wrote its activities, and raised no issue. A mailbox with more history
  than one page lost all of it, invisibly.

  The previous behaviour was deliberate — a test asserted it, on the reasoning that a first sync "has no
  watermark to strand mail behind". That does not survive contact with a real mailbox. There is no
  watermark _before_ the run; the run **creates** one, and that is what does the stranding. The test is
  reversed, with the reasoning recorded so nobody re-derives the original conclusion.

  `Capped` is now simply "the page came back full", which also withholds the watermark upstream — that
  is what actually prevents the loss. The issue text distinguishes a first run from an incremental one,
  because the remedy differs: raise the limit, or re-run until it drains.

  **The replay transport had the same hole, and it was found by auditing this branch against itself.**
  `RecordedMessageTransport` kept `capped && !!query.Since` after the live path dropped it, with a
  comment claiming parity with the live path and a test asserting the first-run case was safe "because
  there is no watermark to strand anything behind" — the reasoning this note had already rejected,
  still sitting two files away. Nothing enforces the order of a recording: a newest-first one truncated
  to `Limit` returns the newest N and withholds the oldest, and an uncapped run then computes a
  watermark from what it did return. It reaches past the fixture because that mark is durable and the
  transport behind it is swappable, so a host that replays a truncated recording and later points the
  same connection at live mail skips real messages on a fixture's say-so. Now `Capped: capped`, with
  the newest-first case reproduced in a test rather than argued about.

  What that does NOT fix is stated in the file rather than left to be rediscovered: `slice(0, Limit)`
  is positional and the window is applied downstream, so a truncated replay re-takes the same first N
  payloads on every run. A recording longer than `Limit` cannot be replayed in full in any order,
  capped or not — measured. The flag keeps that from becoming a false watermark in the database; giving
  the fixture transport real paging is a separate change, and the Issues already name the shortfall on
  every run.

  **Found by running the engine against a real mailbox.** Every recorded fixture is smaller than the
  limit, so no replayed test could ever produce a full page. This is the second defect today that only
  a live run could surface, after MJ's undeclared `accountEmail`.

  Also: `demo/graph-sample-messages.json` is now **validated against live payloads**. Twenty-five real
  messages were compared field-name by field-name — never by value — and three real fields were missing:
  `conversationIndex`, `flag`, and a populated `replyTo` (it had always been `[]`, so its nested shape
  had never appeared, and MJ's own `GetMessages` derives its normalized `To` from `replyTo[0]`). All
  three are added; the fixture and live payloads now agree exactly, 48 field paths to 48.

- Updated dependencies [23b6827]
- Updated dependencies [ec6fab7]
  - @mj-biz-apps/common-entities@5.43.0

## 5.42.0

### Patch Changes

- @mj-biz-apps/common-entities@5.42.0

## 5.41.0

### Patch Changes

- Updated dependencies [783936a]
- Updated dependencies [7d94d43]
  - @mj-biz-apps/common-entities@5.41.0

## 5.40.0

### Minor Changes

- de47552: Activity Sync — an exclusion could not be switched off, and one dated to lapse never lapsed.

  `ActivitySyncExclusion` carries `IsEnabled`, `EffectiveFrom` and `EffectiveTo`. The qualification
  cascade read none of the three. Same shape as the `CredentialsRef` and `InternalDomains` gaps:
  columns written, migrated, documented, and consumed by nothing.

  Two independent failures, both silent:

  | set by an operator            | intended                    | what actually happened                |
  | ----------------------------- | --------------------------- | ------------------------------------- |
  | `IsEnabled = 0`               | stop excluding this address | kept excluding, indefinitely          |
  | `EffectiveTo` in the past     | the exclusion lapses        | never lapsed                          |
  | `EffectiveFrom` in the future | starts excluding later      | excluded from the moment it was saved |

  None of it is visible from the outside. The run reports success, `ActivitySyncRunDetail` records the
  exclusion as matched, and the only symptom is mail that quietly never arrives — typically noticed
  months after whoever set the date stopped watching for it. Rules honoured their own `IsEnabled` from
  the first commit, so the two halves of one cascade disagreed about whether an off switch meant
  anything.

  **The window is matched against the item, not the wall clock.** `RuleRow.DateFrom`/`DateTo` are
  already compared against `item.StartedAt` one stage later in the same cascade. Had an exclusion's
  window meant "while this record is in force" instead, the same two dates would mean different things
  one stage apart — a trap for whoever writes the second rule set. Item time also keeps a re-run
  reproducible: `ActivitySyncRunDetail` exists to answer "which rule ate my message", and an answer
  that moves with the clock is a narrative rather than evidence.

  **Absence reads as enabled.** A row that does not carry `IsEnabled` still excludes. An exclusion
  exists to stop something being ingested, so the missing-flag case has to fail in the direction that
  keeps it stopped.

  **The check lives in memory, not in `ExclusionsExtraFilter`.** One place decides, matching how rules
  are handled — a SQL half and a TypeScript half would be two places to keep in agreement.

  `ExclusionAppliesTo` is a pure exported function, so the three ways an exclusion can fail to apply
  are testable without standing up a cascade. 16 tests, each mutation-checked (M-AC31–M-AC38): dropping
  either bound, dropping the enabled check, reading absence as off, making either boundary exclusive,
  abandoning the cascade instead of skipping one lapsed row, and judging by run time instead of item
  time are all caught.

- de47552: Activity Sync — deactivating a provider type did nothing, and no test file was ever typechecked.

  `ActivitySyncProviderType.IsActive` had no reader anywhere: not on `ProviderTypeRow`, not in
  `loadProviderType`'s `Fields` list, not in the run path. An administrator switching a connector type
  off changed nothing — every connection pointing at it kept fetching mail and kept reporting success.

  **It refuses rather than skipping quietly.** A connection that stops syncing while still showing
  green is the failure this subsystem exists to make impossible, so an inactive type produces an issue
  naming the type and lands in the connection's health stamp. It follows the shape already set by
  "Connection X is not in its Active window" directly above it. The refusal is taken before any
  provider is resolved and before any fetch, so it cannot be reached only through a driver lookup
  failure, and no mailbox is read on the way to it.

  **What an operator will see when they switch a type off.** Every connection using it reports the
  refusal on the next fleet tick, so each flips to `Status = 'Error'` with the reason in `LastError`.
  That is the existing behaviour for any failed run, not something new here, and it is self-healing:
  errored connections are still selected by the fleet query, so the next successful run after the type
  is reactivated clears `LastError` and returns them to `Active` with no manual step.

  **Absence keeps running.** The comparison is `=== false`, so a row loaded without the field still
  syncs. Absence means the query did not ask for the column, and turning one trimmed `Fields` list into
  a silent total halt of every sync is a worse failure than the one being guarded against. SQL `BIT`
  arrives through `RunView` as a real JS boolean — measured against the database rather than assumed —
  so the strict comparison is safe.

  **The trap that caused it is now a test.** A field declared on `ProviderTypeRow` but absent from the
  `Fields` list is `undefined` at runtime, so any check written against it silently never fires. That
  is exactly how `IsActive` came to be ignored. The existing `SELECT *` tripwire now pins the interface
  and the field list to each other and fails until a new column is added to both.

  **Separately: the test suite was never typechecked.** `tsconfig.json` excludes
  `src/**/__tests__/**` so test files never reach `dist` — correct for a published package — but
  nothing else checked them either, and vitest transpiles through esbuild without typechecking. Six
  errors were sitting in the suite, including a test constructing an `ExclusionRow` missing three
  required fields. A `noEmit` config now covers everything, and `pnpm test` runs it before vitest,
  which is the only hook available: CI runs `build`, `changes` and `publish`, and never the tests.

  11 mutants added to the package harness (M-AC31–M-AC41); all 27 pass.

### Patch Changes

- Updated dependencies [e21b2db]
- Updated dependencies [b4387e4]
- Updated dependencies [dc7693c]
- Updated dependencies [22f6624]
  - @mj-biz-apps/common-entities@5.40.0

## 5.39.0

### Minor Changes

- 8657091: Activity Sync — the MS Graph provider gets an actual transport, and credentials.

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

- b6b2b64: Activity Sync — the transport factory seam is finally reachable, and a host implements it.

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

### Patch Changes

- 7887d5d: License declarations now agree on BUSL-1.1 everywhere.

  `LICENSE`, `package.json`, `mj-app.json` and every workspace package already declared
  BUSL-1.1. Two statements still said ISC: the README badge, which is the first license
  statement a reader meets and so outranked all of them in practice, and the `mj-app.json`
  sample in `docs/open-app.md` — this repo is the reference Open App, so that snippet is
  copied into new repos and is how the wrong value spreads. The badge now links to `LICENSE`.

- Updated dependencies [7887d5d]
  - @mj-biz-apps/common-entities@5.39.0

## 5.38.0

### Patch Changes

- Updated dependencies [4c27078]
- Updated dependencies [4c27078]
  - @mj-biz-apps/common-entities@5.38.0

## 5.37.0

### Minor Changes

- d73a3af: Activity Sync Engine — provider plugin contracts and the provider-type/extension schema.

  Adds `@mj-biz-apps/common-activity-sync` with the `BaseActivitySyncProvider` plugin base class,
  the qualification cascade (deterministic stages first, inference last — enforced, not documented),
  and `BaseActivitySyncExtension`, the in-process contract a downstream app implements to add links
  to an Activity inside its own write transaction.

  Adds a migration turning two things that were code into data: `ActivitySyncProviderType` replaces
  `CK_ActivitySyncConnection_Provider`, so a new source is a plugin package plus a metadata row
  rather than a migration to Common; and `ActivitySyncExtension` registers enrichment plugins that
  consumer apps ship rows for.

  Design: `plans/activity-sync-engine.md`.

- d73a3af: Activity Sync Engine P4/P5 — engine, writer, identity resolver, fixture and Graph providers.

  Graph refuses live fetch until an Exchange Application Access Policy exists. Synced
  activities are Visibility=Private. Unmatched addresses become unresolved ActivityLinks.
  Dry runs never set WatermarkAfter. Exclusions run first and are absolute.

- d73a3af: Entity Action workflow adoption — the Common side (plans/mj-entity-action-workflow-adoption.md).

  `Common.LogActivity` is the declarative entry point to the unified timeline: a thin action over the
  new `ActivityWriter.WriteManual`, the second entry point on the ONE writer (manual defaults —
  Visibility Internal, no connection, no sync-extension dispatch; same transactional core, dedupe and
  link writing as the sync path). Takes only serializable params ('Entity Object Data', never
  'Entity Object'), with EventKey per-record idempotency and LinkFields declarative link routing.

  Ships the §5 bindings as metadata: People·AfterCreate → LogActivity, People·AfterUpdate (Status
  changed) → the Person Lifecycle Changed flow agent, Organizations·AfterUpdate scoped to an
  OrganizationType, Relationships·AfterCreate/ended scoped to the Employee RelationshipType — all
  RunMode Durable, all Status Active at every level. Two reusable ActionFilter rows (MJ ships no
  seeds — verified) and the SystemEvent activity type.

- d73a3af: Activity sync trigger, calendar companion as data, and per-connection health.

  Seeds Common.SyncActivities (Action, Limit, result codes, hourly job) as JSON.
  CalendarDriverClass on ActivitySyncProviderType drives the companion surface through
  ClassFactory. Connection health is stamped once from combined surfaces. A failed
  connection list load is ERROR, not NO_CONNECTIONS.

### Patch Changes

- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
  - @mj-biz-apps/common-entities@5.37.0
