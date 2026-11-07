# Company Sender Identity: design (common part)

Date: 2026-11-02
Issue: [MemberJunction/bizapps-common#391](https://github.com/MemberJunction/bizapps-common/issues/391)
Follow-ups (not this design): bizapps-caliber#671, bizapps-ats#227
Status: draft, awaiting Soham's approval

## 1. Intent

Every BizApps vertical that sends email has to answer one question before it writes a
`From:` header: **may this company send as this address?** Today Caliber answers it with a
process-wide environment variable (`CALIBER_COMMS_ALLOWED_FROM_DOMAINS` /
`CALIBER_COMMS_DEFAULT_FROM`), checks it at one of its two send doors and not the other, and
Forms keeps a third copy in `FORMS_EMAIL_FROM`. The CDP host has said it will not set these
variables on any deployment, because one variable cannot say "company A sends as `a.com`,
company B as `b.com`".

This design gives every company its own **register of approved sender addresses**, stored in
the database, keyed to MJ core's `Company` row that every BizApps table already uses as its
tenant anchor. Verticals ask the register instead of the environment.

Analogy: a reception desk keeps a register of approved letterheads per department. The post
office (SendGrid) decides whether a letterhead is genuine; the desk only records which
department may use which letterhead. In this first release the desk does **not** phone the post
office. An operator verifies the address in SendGrid's own dashboard, then adds it to the
register.

## 2. Decisions already made (with Soham, 2026-11-02)

| Decision | Choice | Why |
|---|---|---|
| Which repo | `bizapps-common` | ATS and Forms already import `@mj-biz-apps/common-entities`; Caliber's app manifest already declares a dependency on common. Caliber (the mail engine) would force Forms and Marketing to import the whole engine to pick a sender. MJ core would make the fix wait for a platform release. |
| MJ core changes | **None** | `BaseCommunicationProvider` in MJ has no "list verified senders" method. Adding one is a later, optional phase; it must not block removing the env vars. |
| Verification status | **Not stored** | The issue proposed `Status` / `VerifiedAt` / `Revoked` and a 15-minute sync job. That is a cache of what SendGrid knows, and a cache needs a job, a state machine and a writer rule. The first release stores intent only. SendGrid still rejects an unverified sender at send time, exactly as today, but now per company. |
| Admin UI | A **form panel** on MJ's `MJ: Companies` record, in `@mj-biz-apps/common-ng` | MJ's generated Company form exposes an `after-related` slot, and common already contributes panels this way (`custom/panels/person-job-functions.panel.ts`). Cheaper than a page, friendlier than a raw grid. |
| Domain match | **Exact** on the part after the last `@` | Subdomain (suffix) matching is a later change when a client needs it. Marked as my call. |
| Who may add rows | MJ's normal entity permissions, no custom role | First release. Marked as my call. |
| Vertical behaviour | **Unchanged** by this PR | Caliber and ATS consume the register in their own repos (follow-ups above). |

## 3. Goals, non-goals, anti-goals

**Goals**

- One table, one pure resolver, one admin panel, shipped from common with CodeGen output committed.
- A company with no rows is **refused**, never defaulted to a deployment-wide address.
- Both Caliber doors and the ATS pickers can call the **same** resolver function, so they can never disagree again.

**Non-goals (this release)**

- Asking SendGrid whether an address is verified.
- A scheduled sync job, a `Status` column, a "Revoked" health check.
- Changing Caliber, ATS, Forms or Marketing.
- Subdomain matching, multiple mail providers per company.

**Anti-goals (would make this a failure even if it works)**

- A second place to configure senders next to the env vars, so an operator has to keep two in agreement. The register must be sufficient on its own.
- Any code path that silently sends from a deployment-wide address when the company has no register row.
- Common naming or importing Caliber, ATS or any other vertical (consumer blindness).

## 4. Constraints (from CLAUDE.md and the repo)

- Plain T-SQL migration, no existence guards, `MS_Description` on every column, no `__mj_*` audit columns and no FK indexes by hand (CodeGen adds them), 50 blank lines then the appended CodeGen output.
- Stamp `V<YYYYMMDDHHMM>` in Central Time, sorting after `V202610282028`. The migration needs a user-written `minor` changeset.
- CHECK constraints spelled for people (CodeGen turns them into value lists); each CHECK gets a pinned validator row in `metadata/generated-codes/.validators.json`, byte-identical to `sys.check_constraints.definition`.
- No `any`, no `unknown`; derive field types from the generated entity. No re-exports between packages. `BaseSingleton` for singletons.
- Angular: panel is module-declared (`standalone: false`) like its siblings; `@if`/`@for`; `inject()`; `<mj-loading>` for waits; confirm left, cancel right; `--mj-*` tokens only.
- Server code passes `contextUser`; never `RunView` in a loop.
- No commits by the agent; the user commits and writes the changeset.

## 5. The table

Schema `__mj_BizAppsCommon`, table `CompanySenderIdentity`, entity
`MJ_BizApps_Common: Company Sender Identities`.

| Column | Type | Rule |
|---|---|---|
| `ID` | `UNIQUEIDENTIFIER` PK, default `NEWSEQUENTIALID()` | |
| `CompanyID` | `UNIQUEIDENTIFIER` NOT NULL, FK → `[${mjSchema}].Company(ID)` | the tenant |
| `Kind` | `NVARCHAR(20)` NOT NULL, CHECK IN (`'Mailbox'`, `'Domain'`) | |
| `Address` | `NVARCHAR(320)` NOT NULL | lower-cased, trimmed. Full mailbox when `Kind = Mailbox`; bare domain when `Kind = Domain`. UNIQUE `(CompanyID, Address)`. |
| `DisplayName` | `NVARCHAR(200)` NULL | the From display name. Mailbox rows only. |
| `IsDefault` | `BIT` NOT NULL default 0 | at most one per company: filtered unique index `WHERE IsDefault = 1` on `CompanyID`. |

`MS_Description` on the table and every column (they become the generated docstrings). No
`Status`, `VerifiedAt`, `Provider`, `ProviderRef`, `Notes`. If any of those is wanted later it is
an additive migration.

## 6. The entity subclass (`packages/Entities/src/custom/CompanySenderIdentityEntity.ts`, hand-written)

Lives in `packages/Entities` (client **and** server), not in `packages/CoreEntitiesServer`.
*My call.* Common has only one hand-written subclass today, `PersonEntityServer.ts`, and it is
server-only. Sibling apps (contracts, accounting, orders) put theirs in `packages/Entities` so the
browser runs the same class. That is what §1 needs: the panel, the Explorer form and the API all
normalise and reject the same way, before a round trip. This is the first such subclass in common,
so the builder follows a sibling app's registration (`@RegisterClass(BaseEntity, '<entity name>')`
plus the package's load-entities export so tree-shaking keeps it) and adds the registration to the
Angular package's bootstrap the way the sibling apps do.

On `Save()` (before the base save):

- Trim and lower-case `Address`. Done here, not in the UI, so every writer normalises.
- `Kind = Mailbox` requires exactly one `@` with a dotted domain after it; `Kind = Domain`
  requires no `@` and a dotted name. Reject with a message that names the field and the value.
- `DisplayName` must be null when `Kind = Domain`.
- A company's **first** row may be saved with `IsDefault = 1`; otherwise `IsDefault` is a plain
  flag and the filtered unique index enforces "one per company". The subclass does not demote
  the previous default itself (see §10).

Never swallow a failed save: return the failure result with the company and address in the
message.

## 7. The resolver (`packages/Entities/src/sender-identity.ts`, pure, no I/O)

```ts
/** The fields the resolver reads. Callers pass rows from a RunView on the entity, or test literals. */
export interface CompanySenderIdentityRow {
    readonly CompanyID: string;
    readonly Kind: 'Mailbox' | 'Domain';
    readonly Address: string;
    readonly DisplayName: string | null;
    readonly IsDefault: boolean;
}

/** True when `address` equals a Mailbox row of the company, or its domain equals a Domain row. */
export function IsSenderAllowedForCompany(
    companyId: string,
    address: string,
    identities: readonly CompanySenderIdentityRow[],
): boolean;

/** The company's IsDefault row as a From pair, else null (never a guess). */
export function DefaultSenderForCompany(
    companyId: string,
    identities: readonly CompanySenderIdentityRow[],
): { from: string; fromName: string | null } | null;

/** The part after the last `@`, lower-cased, or null when there is no `@`. Caliber's SenderDomain returns the whole string when there is no `@`; this one returns null on purpose, so a bare domain never passes as a mailbox. */
export function SenderDomain(address: string): string | null;
```

Rules:

- Both sides lower-cased and trimmed before comparison.
- A Domain row matches by **equality** with `SenderDomain(address)`. `mail.acme.com` does not match a `acme.com` row.
- Rows of other companies are ignored even if present in the array.
- Zero rows for the company: `false` / `null`.
- A Domain row that is `IsDefault` cannot produce a From address, so `DefaultSenderForCompany` returns null for it (a Domain default is a data mistake; the panel does not offer "set default" on a Domain row).

Exported from the package `index.ts`. Unit tests in `packages/Entities/src/__tests__/` cover:
Mailbox match, Domain match, case and whitespace, Pending-style non-match is not applicable
(no status), other-company rows ignored, no rows, Domain default returns null, subdomain does
not match.

## 8. The admin panel (`packages/Angular/src/lib/custom/panels/company-sender-identities.panel.ts`)

Registered with `RegisterClassEx(BaseFormPanel, …)` against entity `MJ: Companies`, slot
`after-related`, like the existing `person-job-functions.panel.ts`. Declared in the same NgModule
as its siblings. It is **additive**, with no `replacesSectionKey`: MJ core generates the Company form
and excludes BizApps schemas, so there is no generated section for this entity to replace.
bizapps-accounting already registers panels against `MJ: Companies` the same way.

Shows:

- A list of the company's rows: kind, address, display name, a **Default** badge.
- **Add mailbox** / **Add domain**: a small inline form (address, display name for mailbox). On
  save, a one-line reminder: "Make sure this sender is verified in your mail provider before
  using it." No provider call.
- **Set default** on a Mailbox row (hidden on Domain rows). Flips the chosen row on and the
  previous default off, in that order the database allows (off first, then on, see §10).
- **Remove** with a confirmation dialog.

Does not show: any verified / pending state, a "Check now" button.

## 9. Metadata and CodeGen

- Migration adds the table; CodeGen (from a database built from migrations, with an AI key set)
  generates the entity, view, SPs, Angular form and the `CodeGen_Run_*.sql` appended to the
  migration.
- A pure `IN (...)` CHECK becomes a value list, not a `Validate*()` method, so the `Kind` CHECK
  may need no validator row. Pin a row only if the CodeGen run logs a `Check Constraint Parser`
  call for it.
- Display name locked in `metadata/entities/.display-names.json`.
- No `sync` blocks, no `Metadata_Sync` migration in the PR.
- No scheduled job, no action, no application setting.

## 10. Left to the builder

- Exact file placement of the subclass and how it registers (follow the nearest hand-written
  subclass in `packages/Entities/src`).
- How "set default" sequences the two saves so the filtered unique index is never violated
  (demote old, then promote new, inside the panel; or a tiny server-side helper if the panel
  cannot order the two saves reliably). Either is fine; the panel must report a failure of
  either save with context.
- Panel markup and styling, following the sibling panels.
- Whether `Address` gets its own non-unique index for the resolver's by-company read (the
  unique `(CompanyID, Address)` index already covers the by-company read; probably not).
- Integration test shape in `packages/IntegrationTests`. The harness runs over GraphQL against a
  live MJAPI with no transaction; checks clean up with explicit `Delete()` calls. The check creates
  a throwaway `MJ: Companies` row as a fixture and deletes it and its register rows in `finally`.
  *My call:* never use an existing company, because a failed run would leave sender rows on a real
  company's register, which §3's anti-goals forbid. If the integration user cannot create or delete
  `MJ: Companies`, drop the integration check and rely on the unit tests plus the migration replay
  in CI; say so in the PR.

## 11. Acceptance

- [ ] `CompanySenderIdentity` exists via one common migration; CodeGen output committed; FK to `[${mjSchema}].Company`; unique `(CompanyID, Address)`; one default per company enforced in the database.
- [ ] Entity subclass normalises `Address` and rejects a malformed Mailbox or Domain with a clear message.
- [ ] `IsSenderAllowedForCompany`, `DefaultSenderForCompany`, `SenderDomain` exported from `@mj-biz-apps/common-entities`, pure, unit-tested as in §7.
- [ ] Company record in Explorer shows the panel; an admin can add a mailbox, add a domain, set a default, remove a row.
- [ ] No vertical behaviour changes; no env var is read or written by common.
- [ ] `pnpm run build`, `pnpm test` and `pnpm run test:integration` pass; counts reported.

## 12. What comes after (not this design)

- **Caliber** (bizapps-caliber#671): both doors call `IsSenderAllowedForCompany` with the engagement's company rows; `DefaultSenderForCompany` replaces the deployment rung; env vars become an optional single-tenant convenience; the readiness report (`sender-readiness.ts`) reads the same resolver.
- **ATS** (bizapps-ats#227): letter and round sender fields become pickers over the company's rows, default preselected.
- **Forms**: `install-sender.js` reads `DefaultSenderForCompany` with `FORMS_EMAIL_FROM` as fallback.
- **Phase 2, optional**: an MJ provider method "list verified senders" and a verified badge in the panel.
