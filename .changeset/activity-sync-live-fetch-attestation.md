---
'@mj-biz-apps/common-activity-sync': minor
'@mj-biz-apps/common-server': minor
---

Activity Sync — the live-fetch gate was unreachable, so a scoped host could not turn it on.

> **A DECISION IS REQUIRED BEFORE THIS IS TURNED ON, AND IT IS NOT A CODE DECISION.**
>
> `MSGraphProvider` authenticates app-only, so the `Mail.Read` **application** permission is granted
> against the tenant, not against a mailbox: it can read **every mailbox in the organisation**. The
> `Mailbox` column on a connection narrows what we *ask* for, never what we are *allowed* to read.
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
both destroy the record it exists to keep. What stays impossible is the third state, *nobody looked*:
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

340 tests in `common-activity-sync` and 43 in `common-server`, with a mutation driver in each:
36 mutants in `packages/ActivitySync/test-harnesses/mutate-checks.mjs` and 8 in
`packages/Server/test-harnesses/mutate-checks.mjs`, all 44 caught. Between them they fell reverting
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

Two of those were found by asking the suites to prove they could fail. `common-server` had no
mutation driver, and deleting either of the two guards that decide WHICH attestation was made left
all 40 of its tests green — both rules are described above and neither had a reader. It also had no
typecheck step over its tests, because its build config excludes them and vitest does not typecheck;
adding one surfaced six type errors in test code, including assertions indexing an empty tuple, which
could not have been reading what they claimed to.
