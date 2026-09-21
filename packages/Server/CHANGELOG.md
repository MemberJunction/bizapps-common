# @mj-biz-apps/common-server

## 5.45.0

### Minor Changes

- 868b125: Party Signals: a shared answer to "which organizations and people are our customers", plus a
  selling-company field that defaults and confirms.

  Common owns Organizations and People but cannot see the orders, contracts or sales schemas, and
  neither party carries a customer flag or a last-activity date. So nothing that renders a party —
  a foreign-key picker above all — has ever been able to tell a customer from any other row in a
  directory that can run to hundreds of thousands. It offers the first twenty rows that contain the
  typed letters, in no particular order.

  **The contract.** An app declares its own customers by shipping ONE query in the new `Party Signals`
  query category, returning `PartyKind` (`'organization'` | `'person'`), `PartyID`, `Count` and
  `LastActivityAt`, and carrying a `[signal: noun|nouns]` marker in its own `Description` so a caller
  can label "4 orders" without knowing what an order is. The category is the registry: Common never
  imports an app, and an app joins the answer by shipping metadata, with no code change here.

  `@mj-biz-apps/common-entities` exports the contract and the pure union — `PARTY_SIGNALS_CATEGORY`,
  the row and roster types, `MergePartySignalRows`, `ParseSignalNouns`, `ChipText`. Party IDs are
  matched case-insensitively, because GUIDs arrive in whichever case the provider produced and two
  spellings of one organization would otherwise read as two customers.

  **Two readers, one definition.** `PartySignalStore` (common-ng) discovers the category through
  metadata and runs each query once per session, for Explorer. `Common.GetPartySignals`
  (common-server) does the same union server-side for everything that is not Angular — agents, MCP,
  reports, scripts. Both run every query as the calling user, so the roster is permission-filtered; a
  query the caller cannot read contributes nothing and is named in warnings rather than failing the
  call, so a missing signal weakens ranking instead of breaking the field.

  **`bizapps-selling-company-field`.** The company on an order or a contract decides which legal
  entity books the revenue, and the picker behind it lists every company row the instance has. Apps
  have defaulted it by whichever company sorted first alphabetically, or by the first product on the
  order — rules nobody wrote down. This field defaults to the current user's own company when they
  have one and it is a company the instance knows, otherwise to the new Common `DefaultSellingCompanyID`
  setting, otherwise to nothing. Anything else is held, named back to the user against the default,
  and written only on confirm; an unanswered question reverts, because it must not decide where
  revenue lands. It wraps `mj-form-field`, so the dropdown, keyboard behaviour and link rendering
  stay the platform's.

  **Metadata.** `AllowMultipleSubtypes` is now set on Organizations and People, because both are
  extended as IsA children and the disjoint default mis-chains silently. `AllowRecordMerge` is not:
  `CK_Entity_AllowRecordMerge` requires `AllowDeleteAPI = 1` and `DeleteType = 'Soft'`, and both
  parties are hard-delete, so enabling merge is a schema change rather than a flag and belongs in its
  own release. `Organizations.Website` and
  `People.Title` join user search, with `BeginsWith` predicates and `AutoUpdate` pins so CodeGen
  cannot flip them back; the other identifying fields were already flagged.

  The party lookup strategy that consumes all of this is a separate release: it needs the platform
  foreign-key lookup-strategy seam, which nothing here waits on.

### Patch Changes

- Updated dependencies [868b125]
  - @mj-biz-apps/common-entities@5.45.0
  - @mj-biz-apps/common-activity-sync@5.45.0
  - @mj-biz-apps/common-core-entities-server@5.45.0
  - @mj-biz-apps/common-actions@5.45.0

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

- Updated dependencies [701e505]
- Updated dependencies [7056463]
  - @mj-biz-apps/common-activity-sync@5.44.0
  - @mj-biz-apps/common-entities@5.44.0
  - @mj-biz-apps/common-core-entities-server@5.44.0
  - @mj-biz-apps/common-actions@5.44.0

## 5.43.0

### Minor Changes

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

- Updated dependencies [23b6827]
- Updated dependencies [192cc39]
- Updated dependencies [4ad78ac]
- Updated dependencies [9d5cb06]
- Updated dependencies [b1e8650]
- Updated dependencies [9fc60ef]
- Updated dependencies [3aeb4a1]
- Updated dependencies [7e6e87c]
- Updated dependencies [ec6fab7]
- Updated dependencies [b2a310b]
  - @mj-biz-apps/common-entities@5.43.0
  - @mj-biz-apps/common-activity-sync@5.43.0
  - @mj-biz-apps/common-actions@5.43.0
  - @mj-biz-apps/common-core-entities-server@5.43.0

## 5.42.0

### Patch Changes

- @mj-biz-apps/common-actions@5.42.0
- @mj-biz-apps/common-activity-sync@5.42.0
- @mj-biz-apps/common-core-entities-server@5.42.0
- @mj-biz-apps/common-entities@5.42.0

## 5.41.0

### Patch Changes

- Updated dependencies [783936a]
- Updated dependencies [7d94d43]
  - @mj-biz-apps/common-entities@5.41.0
  - @mj-biz-apps/common-activity-sync@5.41.0
  - @mj-biz-apps/common-core-entities-server@5.41.0
  - @mj-biz-apps/common-actions@5.41.0

## 5.40.0

### Patch Changes

- Updated dependencies [de47552]
- Updated dependencies [de47552]
- Updated dependencies [e21b2db]
- Updated dependencies [b4387e4]
- Updated dependencies [dc7693c]
- Updated dependencies [22f6624]
  - @mj-biz-apps/common-activity-sync@5.40.0
  - @mj-biz-apps/common-entities@5.40.0
  - @mj-biz-apps/common-core-entities-server@5.40.0
  - @mj-biz-apps/common-actions@5.40.0

## 5.39.0

### Minor Changes

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

- Updated dependencies [8657091]
- Updated dependencies [b6b2b64]
- Updated dependencies [7887d5d]
  - @mj-biz-apps/common-activity-sync@5.39.0
  - @mj-biz-apps/common-actions@5.39.0
  - @mj-biz-apps/common-core-entities-server@5.39.0
  - @mj-biz-apps/common-entities@5.39.0

## 5.38.0

### Patch Changes

- Updated dependencies [4c27078]
- Updated dependencies [4c27078]
  - @mj-biz-apps/common-entities@5.38.0
  - @mj-biz-apps/common-activity-sync@5.38.0
  - @mj-biz-apps/common-core-entities-server@5.38.0
  - @mj-biz-apps/common-actions@5.38.0

## 5.37.0

### Minor Changes

- d73a3af: Fold CodeGen output for ActivitySyncProviderType.CalendarDriverClass into V202608301900.

  Hand DDL is the ALTER TABLE only. Microsoft365's CalendarDriverClass value stays in
  metadata JSON. CodeGen SQL (EntityField, view, spCreate/spUpdate/spDelete, trigger)
  is appended after the standard banner.

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
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
  - @mj-biz-apps/common-entities@5.37.0
  - @mj-biz-apps/common-activity-sync@5.37.0
  - @mj-biz-apps/common-core-entities-server@5.37.0
  - @mj-biz-apps/common-actions@5.37.0

## 5.36.0

### Minor Changes

- 60804ac: Ship CodeGen entity metadata, base views, and CRUD procedures for the six Activity tables introduced in V202608171935. A clean migrate previously left those tables without \_\_mj.Entity rows, so metadata sync of activity-types failed.
- 6fe1f09: Register the Activity related-name virtual EntityFields on Activity Links and Activity Files so save-capture ResultTables match the base views. Also covers the consumer-blind CodeGen V (no Orders in Common), Organizations CascadeDeletes off, and Activity Types hierarchy virtuals.

### Patch Changes

- Updated dependencies [60804ac]
- Updated dependencies [6fe1f09]
  - @mj-biz-apps/common-entities@5.36.0
  - @mj-biz-apps/common-core-entities-server@5.36.0
  - @mj-biz-apps/common-actions@5.36.0

## 5.35.1

### Patch Changes

- eac151e: Declare BUSL-1.1 in mj-app.json. The LICENSE file and every package already
  state BUSL-1.1; the manifest still said ISC, so anything reading it saw the
  wrong license.
- Updated dependencies [eac151e]
  - @mj-biz-apps/common-actions@5.35.1
  - @mj-biz-apps/common-core-entities-server@5.35.1
  - @mj-biz-apps/common-entities@5.35.1

## 5.35.0

### Patch Changes

- cbd0e27: Add RelatedRecordCollection metadata configuration for People and Organizations (Contact Methods, Relationships, Child Organizations) and synchronize CodeGen output.
- Updated dependencies [1f07f2a]
- Updated dependencies [026b83e]
- Updated dependencies [4b4bcaa]
- Updated dependencies [cbd0e27]
  - @mj-biz-apps/common-entities@5.35.0
  - @mj-biz-apps/common-core-entities-server@5.35.0
  - @mj-biz-apps/common-actions@5.35.0

## 5.34.0

### Patch Changes

- Updated dependencies [2c8c1bc]
- Updated dependencies [ab9f88e]
- Updated dependencies [2f8dd2b]
- Updated dependencies [e69c364]
  - @mj-biz-apps/common-entities@5.34.0
  - @mj-biz-apps/common-core-entities-server@5.34.0
  - @mj-biz-apps/common-actions@5.34.0

## 5.33.2

### Patch Changes

- Updated dependencies [c2974b6]
  - @mj-biz-apps/common-entities@5.33.2
  - @mj-biz-apps/common-core-entities-server@5.33.2
  - @mj-biz-apps/common-actions@5.33.2

## 5.33.1

### Patch Changes

- Updated dependencies [6eae25b]
  - @mj-biz-apps/common-entities@5.33.1
  - @mj-biz-apps/common-core-entities-server@5.33.1
  - @mj-biz-apps/common-actions@5.33.1

## 5.33.0

### Patch Changes

- Updated dependencies [1ffb2a5]
- Updated dependencies [2c33643]
  - @mj-biz-apps/common-entities@5.33.0
  - @mj-biz-apps/common-core-entities-server@5.33.0
  - @mj-biz-apps/common-actions@5.33.0

## 5.32.0

### Minor Changes

- b5f34d2: PG fixes for CanonicalSchema and CodeGen

### Patch Changes

- Updated dependencies [b5f34d2]
  - @mj-biz-apps/common-core-entities-server@5.32.0
  - @mj-biz-apps/common-entities@5.32.0
  - @mj-biz-apps/common-actions@5.32.0

## 5.31.3

### Patch Changes

- 5346c70: Upgraded BAC to MJ 5.44; PostgreSQL install verified, seeds fixed.
- Updated dependencies [5346c70]
  - @mj-biz-apps/common-core-entities-server@5.31.3
  - @mj-biz-apps/common-entities@5.31.3
  - @mj-biz-apps/common-actions@5.31.3

## 5.31.2

### Patch Changes

- 969954b: fix(common): lowercase PostgreSQL app schema name in migrations to match physical schema
- Updated dependencies [969954b]
  - @mj-biz-apps/common-actions@5.31.2
  - @mj-biz-apps/common-core-entities-server@5.31.2
  - @mj-biz-apps/common-entities@5.31.2

## 5.31.1

### Patch Changes

- Updated dependencies [6e0ea6c]
  - @mj-biz-apps/common-core-entities-server@5.31.1
  - @mj-biz-apps/common-actions@5.31.1
  - @mj-biz-apps/common-entities@5.31.1

## 5.31.0

### Minor Changes

- 64200c7: Added PG support and MJ upgrade to 5.40.2

### Patch Changes

- Updated dependencies [64200c7]
  - @mj-biz-apps/common-core-entities-server@5.31.0
  - @mj-biz-apps/common-entities@5.31.0
  - @mj-biz-apps/common-actions@5.31.0

## 5.30.1

### Patch Changes

- Updated dependencies [a46ab44]
  - @mj-biz-apps/common-entities@5.30.1
  - @mj-biz-apps/common-core-entities-server@5.30.1
  - @mj-biz-apps/common-actions@5.30.1

## 5.30.0

### Patch Changes

- 49d5b9c: Add CoreEntitiesServer package with PersonEntityServer and LinkedUserID unique constraint
- Updated dependencies [49d5b9c]
  - @mj-biz-apps/common-core-entities-server@5.30.0
  - @mj-biz-apps/common-entities@5.30.0
  - @mj-biz-apps/common-actions@5.30.0

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

### Patch Changes

- Updated dependencies [b0b2d13]
  - @mj-biz-apps/common-entities@5.29.0
  - @mj-biz-apps/common-actions@5.29.0

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

### Patch Changes

- Updated dependencies [b61bb46]
  - @mj-biz-apps/common-entities@5.28.0
  - @mj-biz-apps/common-actions@5.28.0

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.
- Updated dependencies [fa421da]
  - @mj-biz-apps/common-entities@5.27.1
  - @mj-biz-apps/common-actions@5.27.1
