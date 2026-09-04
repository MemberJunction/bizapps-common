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
> attestation, no host has one, and the attestation cannot be satisfied by a flag — it requires
> naming the security group, who confirmed it, and when. Whoever deploys has to answer the question
> deliberately. They cannot skip it by accident.
>
> Two legitimate outcomes, both informed: accept the tenant-wide grant and record who accepted it, or
> scope the app to a group first. `scripts/` carries a check that reports which is in force, and
> prints the `New-ManagementScope` / `New-ManagementRoleAssignment` commands to create the
> restriction if the answer is "unscoped".

`AllowLiveFetch` was the FIRST constructor argument of `MSGraphActivitySyncProvider`, defaulting to
`false`. `MJGlobal.ClassFactory` builds plugins with NO arguments. So through `ActivitySyncEngine` —
the only path production uses — live fetch was permanently off, and the parameter could be set by
tests and the demo alone. Every test passed, because every test constructed the provider directly.

This is the same defect the transport factory had one layer down, and it gets the same fix: a host
registry. What it is emphatically NOT is a relaxation. Making a gate reachable must not make it open,
and most of the new tests exist to pin that: with nothing registered, an unconfigured host refuses
exactly as before, and the transport it refused is never called.

**The opt-in is an attestation, not a boolean.** A boolean records that somebody WANTED live fetch.
`LiveMailboxPolicyAttestation` records that somebody CHECKED — which mail-enabled security group the
Exchange Application Access Policy names, who confirmed it, and when. Those are the things an audit
asks for, and the things a person has to look up rather than guess. `Confirmed` is the literal `true`
rather than `boolean`, so a variable that happens to be false will not type-check and the attestation
cannot be satisfied by threading a flag through. An attestation with a blank group or no name is
rejected: accepting one would turn this straight back into a boolean with extra steps.

**Deliberately not driven by data.** `ActivitySyncConnection` is an ordinary editable entity. Had the
opt-in lived there, anyone who could edit a row could enable tenant-wide mail reading from a form —
app-only `Mail.Read` reads EVERY mailbox in the tenant, and a connection's `Mailbox` narrows what we
ask for, not what we are allowed to read. The package already refuses to let a database row swap the
transport; this applies the same rule to the more dangerous switch. `AllowLiveMailboxFetch` is a
bootstrap-time call, and the host reads it from deployment configuration.

**A partial configuration throws rather than quietly staying off.** `LoadLiveMailboxPolicyFromEnv`
requires all three of `ACTIVITY_SYNC_MAILBOX_POLICY_GROUP`, `..._CONFIRMED_BY` and `..._CONFIRMED_AT`,
or none. Silently ignoring a half-written opt-in is the exact trap this codebase keeps being written
against: an operator who set two of three would see the provider refuse, believe the Exchange policy
was wrong, and go hunting for a fault that is in their `.env`. Blank and whitespace-only values read
as absent, and an unparseable date is rejected by name.

**The refusal now names the way out.** `LIVE_GRAPH_REFUSAL` explained why live fetch was off but not
how to enable it, which left an operator who HAD verified the policy with no supported next step —
and the tempting unsupported one is to go editing rows.

25 tests across the two packages, each mutation-checked: reverting the default to `false`, allowing
everything, dropping either blank check, accepting whitespace as a group name, treating a partial
env as complete, skipping date validation, and misreporting the result are all caught.
