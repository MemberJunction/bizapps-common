# Company Sender Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every MJ Company a database register of approved sender addresses, a pure "is this sender allowed" resolver, and a panel on the Company record to manage it, shipped from bizapps-common with no vertical and no MJ change.

**Architecture:** One new table `CompanySenderIdentity` in `__mj_BizAppsCommon` with a FK to MJ core `Company`; CodeGen produces the entity. A pure module in `@mj-biz-apps/common-entities` holds the matching and normalisation rules; a thin shared entity subclass applies them on every save, in browser and server. A standalone Angular widget plus a `BaseFormPanel` contribution render the register on MJ's generated Company form through its `after-related` slot.

**Tech Stack:** T-SQL migration (Skyway), MemberJunction CodeGen, TypeScript (vitest), Angular 21 (`@memberjunction/ng-base-forms`), pnpm workspace built from the parent folder.

**Spec:** `docs/superpowers/specs/2026-11-02-company-sender-identity-design.md`

## Global Constraints

- **No agent commits.** CLAUDE.md: never run `git commit`; Soham commits and writes the `minor` changeset. Every task ends with files saved and tests green, nothing staged.
- No `any`, no `unknown`, no `.Get()`/`.Set()`; field types derive from the generated entity. No re-exports between packages. New Angular code uses `@if`/`@for` and `inject()`.
- Migration: plain T-SQL, no existence guards, `MS_Description` on the table and every column, no `__mj_*` columns, no FK index by hand, stamp `V202611021520` (Central Time, sorts after `V202610282028`), 50 blank lines then the appended CodeGen output with no literal `Sequence` on `EntityField` inserts.
- Entity name `MJ_BizApps_Common: Company Sender Identities`; generated class `mjBizAppsCommonCompanySenderIdentityEntity`; display name `Company Sender Identities`.
- Address rules from the spec: trimmed and lower-cased; `Mailbox` has exactly one `@` and a dotted domain after it; `Domain` has no `@` and is a dotted name; `DisplayName` null on Domain rows; domain match is exact equality on the part after the last `@`; zero rows means not allowed and no default.
- Angular: `<mj-loading>` for waits; confirm button left, cancel right; Font Awesome icons; `--mj-*` tokens only; `cdr.detectChanges()` after programmatic changes; `Promise.resolve().then()` not `setTimeout`.
- Server/wire code passes `contextUser`; never `RunView` in a loop.
- Build from the package directory (`pnpm run build`) after each code change and fix every TypeScript error. Definition of done: unit tests pass, integration checks pass, counts reported.
- One database per agent for `mj migrate` / `mj codegen` (see CLAUDE.md "Fresh database").

## Review Focus

1. Address with surrounding whitespace or mixed case (`"  HR@Acme.com "`) must be stored as `hr@acme.com` and match `HR@acme.com` at resolve time. Pinned in Task 1 and Task 4.
2. A Domain row set as default must never yield a From address; `DefaultSenderForCompany` returns null. Pinned in Task 1.
3. Two rows for the same company and address differing only in case must be refused by the unique index after normalisation. Pinned in Task 6.
4. "Set default" when another row is already default must not trip the filtered unique index: demote first, then promote, and a failure of either save is reported with the address. Pinned in Task 5.
5. Rows of another company present in the array passed to the resolver must be ignored. Pinned in Task 1.

---

### Task 1: Pure resolver and normaliser (`sender-identity.ts`)

**Files:**
- Create: `packages/Entities/src/sender-identity.ts`
- Modify: `packages/Entities/src/index.ts` (add `export * from './sender-identity.js';`)
- Test: `packages/Entities/src/__tests__/sender-identity.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces:
  ```ts
  export type SenderIdentityKind = 'Mailbox' | 'Domain';
  export interface CompanySenderIdentityRow {
      readonly CompanyID: string;
      readonly Kind: SenderIdentityKind;
      readonly Address: string;
      readonly DisplayName: string | null;
      readonly IsDefault: boolean;
  }
  export interface SenderFrom { readonly from: string; readonly fromName: string | null; }
  export function SenderDomain(address: string): string | null;
  export function IsSenderAllowedForCompany(companyId: string, address: string, identities: readonly CompanySenderIdentityRow[]): boolean;
  export function DefaultSenderForCompany(companyId: string, identities: readonly CompanySenderIdentityRow[]): SenderFrom | null;
  /** Trim + lower-case the address and check its shape for the kind. `errors` is empty when the value is acceptable. */
  export interface NormalizedSenderIdentity { readonly address: string; readonly displayName: string | null; readonly errors: readonly string[]; }
  export function NormalizeSenderIdentity(kind: SenderIdentityKind, address: string, displayName: string | null): NormalizedSenderIdentity;
  ```

- [ ] **Step 1: Write the failing tests**

```ts
import { describe, it, expect } from 'vitest';
import { DefaultSenderForCompany, IsSenderAllowedForCompany, NormalizeSenderIdentity, SenderDomain, type CompanySenderIdentityRow } from '../sender-identity.js';

const ACME = 'A0000000-0000-4000-8000-00000000000A';
const BOLT = 'B0000000-0000-4000-8000-00000000000B';
const rows: CompanySenderIdentityRow[] = [
    { CompanyID: ACME, Kind: 'Mailbox', Address: 'hr@acme.com', DisplayName: 'Acme HR', IsDefault: true },
    { CompanyID: ACME, Kind: 'Domain', Address: 'acme-jobs.com', DisplayName: null, IsDefault: false },
    { CompanyID: BOLT, Kind: 'Mailbox', Address: 'jobs@bolt.io', DisplayName: null, IsDefault: true },
];

describe('SenderDomain', () => {
    it('returns the lower-cased part after the last @', () => expect(SenderDomain('A@B@Acme.COM')).toBe('acme.com'));
    it('returns null when there is no @', () => expect(SenderDomain('acme.com')).toBeNull());
});

describe('IsSenderAllowedForCompany', () => {
    it('matches a Mailbox row case- and space-insensitively', () => expect(IsSenderAllowedForCompany(ACME, '  HR@Acme.com ', rows)).toBe(true));
    it('matches a Domain row by exact domain', () => expect(IsSenderAllowedForCompany(ACME, 'anyone@acme-jobs.com', rows)).toBe(true));
    it('does not match a subdomain of a Domain row', () => expect(IsSenderAllowedForCompany(ACME, 'x@mail.acme-jobs.com', rows)).toBe(false));
    it("ignores another company's rows", () => expect(IsSenderAllowedForCompany(ACME, 'jobs@bolt.io', rows)).toBe(false));
    it('is false with no rows', () => expect(IsSenderAllowedForCompany(ACME, 'hr@acme.com', [])).toBe(false));
    it('is false for a bare domain even when a Mailbox row shares it', () => expect(IsSenderAllowedForCompany(ACME, 'acme.com', rows)).toBe(false));
});

describe('DefaultSenderForCompany', () => {
    it('returns the default Mailbox as a From pair', () => expect(DefaultSenderForCompany(ACME, rows)).toEqual({ from: 'hr@acme.com', fromName: 'Acme HR' }));
    it('returns null with no rows', () => expect(DefaultSenderForCompany(ACME, [])).toBeNull());
    it('returns null when the default is a Domain row', () => {
        const only = [{ CompanyID: ACME, Kind: 'Domain', Address: 'acme.com', DisplayName: null, IsDefault: true }] as const;
        expect(DefaultSenderForCompany(ACME, only)).toBeNull();
    });
});

describe('NormalizeSenderIdentity', () => {
    it('trims and lower-cases a Mailbox', () => expect(NormalizeSenderIdentity('Mailbox', '  HR@Acme.com ', 'Acme HR')).toEqual({ address: 'hr@acme.com', displayName: 'Acme HR', errors: [] }));
    it('rejects a Mailbox without @ or without a dotted domain', () => {
        expect(NormalizeSenderIdentity('Mailbox', 'acme.com', null).errors).toHaveLength(1);
        expect(NormalizeSenderIdentity('Mailbox', 'hr@acme', null).errors).toHaveLength(1);
        expect(NormalizeSenderIdentity('Mailbox', 'a@b@acme.com', null).errors).toHaveLength(1);
    });
    it('rejects a Domain with @ or without a dot', () => {
        expect(NormalizeSenderIdentity('Domain', 'hr@acme.com', null).errors).toHaveLength(1);
        expect(NormalizeSenderIdentity('Domain', 'localhost', null).errors).toHaveLength(1);
    });
    it('rejects a DisplayName on a Domain row', () => expect(NormalizeSenderIdentity('Domain', 'acme.com', 'Acme').errors).toHaveLength(1));
    it('rejects an empty address', () => expect(NormalizeSenderIdentity('Mailbox', '   ', null).errors).toHaveLength(1));
    it('every error names the value', () => expect(NormalizeSenderIdentity('Domain', 'hr@acme.com', null).errors[0]).toContain('hr@acme.com'));
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd packages/Entities && pnpm exec vitest run src/__tests__/sender-identity.test.ts`
Expected: FAIL, module `../sender-identity.js` not found.

- [ ] **Step 3: Implement `sender-identity.ts`** with the signatures above. Module docstring explains the deliberate difference from Caliber's `SenderDomain` (null, not the whole string, when there is no `@`). One private `normalizeAddress(raw: string): string` shared by all four exports. Dotted-domain rule: at least one `.` with non-empty labels on both sides, no whitespace.

- [ ] **Step 4: Export from `index.ts` and run the tests**

Run: `cd packages/Entities && pnpm test`
Expected: all green, including the new file's 17 tests.

---

### Task 2: Migration `V202611021520__v5.58.x__Company_Sender_Identity.sql`

**Files:**
- Create: `migrations/V202611021520__v5.58.x__Company_Sender_Identity.sql`
- Modify: `metadata/entities/.display-names.json` (add a record locking `DisplayName: "Company Sender Identities"`, same shape as its neighbours)

**Interfaces:**
- Produces: table `[${flyway:defaultSchema}].[CompanySenderIdentity]` with the columns in spec §5.

- [ ] **Step 1: Write the migration** following `V202608171935__v5.35.x__Activities.sql` for layout:

```sql
CREATE TABLE [${flyway:defaultSchema}].[CompanySenderIdentity] (
    ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    CompanyID UNIQUEIDENTIFIER NOT NULL,
    Kind NVARCHAR(20) NOT NULL,
    Address NVARCHAR(320) NOT NULL,
    DisplayName NVARCHAR(200) NULL,
    IsDefault BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_CompanySenderIdentity PRIMARY KEY (ID),
    CONSTRAINT FK_CompanySenderIdentity_Company FOREIGN KEY (CompanyID) REFERENCES [${mjSchema}].[Company](ID),
    CONSTRAINT UQ_CompanySenderIdentity_CompanyAddress UNIQUE (CompanyID, Address),
    CONSTRAINT CK_CompanySenderIdentity_Kind CHECK (Kind IN (N'Mailbox', N'Domain'))
);
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_CompanySenderIdentity_Default
    ON [${flyway:defaultSchema}].[CompanySenderIdentity] (CompanyID)
    WHERE IsDefault = 1;
GO
```

Then `sp_addextendedproperty` `MS_Description` for the table and each of the six columns (syntax as in the Activities migration). The `Address` description states "stored trimmed and lower-cased by the entity; a full mailbox when Kind = Mailbox, a bare domain when Kind = Domain". The `IsDefault` description states "at most one per company (UQ_CompanySenderIdentity_Default); only a Mailbox row is a usable default". Then 50 blank lines (CodeGen output is appended in Task 3).

- [ ] **Step 2: Verify the stamp sorts last and the file has no guards**

Run: `ls migrations | sort | tail -1` → `V202611021520__v5.58.x__Company_Sender_Identity.sql`
Run: `grep -nE "IF (NOT )?EXISTS|OBJECT_ID|COL_LENGTH" migrations/V202611021520*.sql` → no output.

---

### Task 3: Apply the migration and run CodeGen

**Files:**
- Modify: `migrations/V202611021520__v5.58.x__Company_Sender_Identity.sql` (append the `CodeGen_Run_*.sql` output after the 50 blank lines)
- Generated (never hand-edited): `packages/Entities/src/generated/**`, `packages/Actions/src/generated/**`, `packages/Server/src/generated/**`, `packages/Angular/src/lib/generated/**`
- Possibly: `metadata/generated-codes/.validators.json` (only if CodeGen logs a `Check Constraint Parser` call for `CK_CompanySenderIdentity_Kind`; a pure `IN (...)` CHECK usually becomes a value list and needs no row)

**Interfaces:**
- Produces: `mjBizAppsCommonCompanySenderIdentityEntity` (and its `…EntityType`) exported from `@mj-biz-apps/common-entities`, with fields `ID`, `CompanyID`, `Kind`, `Address`, `DisplayName`, `IsDefault`, plus the view `vwCompanySenderIdentities` and CRUD SPs.

- [ ] **Step 1: Confirm a private database** (CLAUDE.md "Fresh database"): `DB_DATABASE` in `.env` is yours alone, `AI_VENDOR_API_KEY__GeminiLLM` or `…OpenRouterLLM` is set.

- [ ] **Step 2: Migrate** — Run: `pnpm run mj:migrate`. Expected: the new migration applied, no errors.

- [ ] **Step 3: CodeGen** in the four-step order from CLAUDE.md: `pnpm exec mj codegen --skipfiles`, `pnpm exec mj sync push --dir=metadata --ci`, `pnpm exec mj codegen --skipdb`. Expected log: entity `MJ_BizApps_Common: Company Sender Identities` created; no `CodeGen: Check Constraint Parser` line (if there is one, pin the validator row per CLAUDE.md).

- [ ] **Step 4: Append the `CodeGen_Run_*.sql`** produced in step 3 to the migration after the 50 blank lines; remove any literal `Sequence` on `EntityField` inserts. Restore any `sync` block CodeGen wrote back under `metadata/`.

- [ ] **Step 5: Verify the generated class and build**

Run: `grep -n "class mjBizAppsCommonCompanySenderIdentityEntity" packages/Entities/src/generated/entities/__mj_BizAppsCommon.ts` → one line.
Run: `cd packages/Entities && pnpm run build && cd ../Angular && pnpm run build` → both clean.
Run: `git status --short` → only generated files, the migration, `.display-names.json` and (maybe) `.validators.json` changed. Read the diff of the generated Angular form; it must contain only the new entity.

---

### Task 4: Shared entity subclass `CompanySenderIdentityEntity`

**Files:**
- Create: `packages/Entities/src/CompanySenderIdentityEntity.ts`
- Modify: `packages/Entities/src/index.ts` (add `export * from './CompanySenderIdentityEntity.js';`)
- Test: `packages/Entities/src/__tests__/company-sender-identity-entity.test.ts`

**Interfaces:**
- Consumes: `NormalizeSenderIdentity` (Task 1), `mjBizAppsCommonCompanySenderIdentityEntity` (Task 3).
- Produces:
  ```ts
  @RegisterClass(BaseEntity, 'MJ_BizApps_Common: Company Sender Identities')
  export class CompanySenderIdentityEntity extends mjBizAppsCommonCompanySenderIdentityEntity {
      public override Validate(): ValidationResult;   // adds one ValidationErrorInfo per NormalizeSenderIdentity error, on field Address (or DisplayName)
      public override async Save(options?: EntitySaveOptions): Promise<boolean>; // writes the normalised Address/DisplayName, then super.Save()
  }
  ```
  Pattern: `bizapps-contracts/packages/Entities/src/ContractTypeEntity.ts` (shared subclass, `@RegisterClass` on the generated class). The server already imports `@mj-biz-apps/common-entities` (`packages/Server/src/index.ts:10`), and `LoadGeneratedEntities()` is what keeps the package in browser bundles; the subclass file is reachable through `index.ts`, so no bootstrap change is needed. The builder confirms by grepping the built `dist/index.js` for the class.

- [ ] **Step 1: Write the failing test.** Construct the subclass without a provider is not possible, so test the two pure seams it exposes: `Validate()` through a minimal stub and the normalisation through `Save()` interception. Follow `person-user-link.test.ts` for the `vi.mock('@memberjunction/core')` shape: mock `BaseEntity` so `Get`/`Set` back a plain record, `super.Validate()` returns `{ Success: true, Errors: [] }`, and `super.Save()` records the fields it was called with.

```ts
describe('CompanySenderIdentityEntity', () => {
    it('Validate reports a malformed Mailbox on the Address field', () => { /* Kind Mailbox, Address 'acme.com' → Errors[0].Source === 'Address', Success false */ });
    it('Validate reports a DisplayName on a Domain row on the DisplayName field', () => { /* Errors[0].Source === 'DisplayName' */ });
    it('Save writes the trimmed lower-cased Address before calling the base save', async () => { /* Address '  HR@Acme.com ' → base save sees 'hr@acme.com' */ });
    it('Save refuses and does not call the base save when Validate fails', async () => { /* result false, base save not called, LatestResult message contains the bad value */ });
});
```

- [ ] **Step 2: Run to verify failure** — `cd packages/Entities && pnpm exec vitest run src/__tests__/company-sender-identity-entity.test.ts` → FAIL (module missing).

- [ ] **Step 3: Implement the subclass.** `Validate()` calls `super.Validate()`, then `NormalizeSenderIdentity(this.Kind, this.Address, this.DisplayName)` and pushes a `ValidationErrorInfo` (from `@memberjunction/global`, `Source` = field name) per error (field `Address`, or `DisplayName` for the display-name error), setting `Success = false`. `Save()` runs the normaliser, assigns `this.Address` / `this.DisplayName`, runs `Validate()`, and returns false with the errors in the result message (naming the address) rather than calling `super.Save()` when it fails. No swallowed errors.

- [ ] **Step 4: Export, build, test** — `cd packages/Entities && pnpm run build && pnpm test` → green; `grep -c "CompanySenderIdentityEntity" dist/index.js` ≥ 1.

---

### Task 5: Angular widget and Company form panel

**Files:**
- Create: `packages/Angular/src/lib/components/company-sender-identities/company-sender-identities.component.ts` (+ `.html`, `.css`)
- Create: `packages/Angular/src/lib/custom/panels/company-sender-identities.panel.ts` (+ `.html`)
- Modify: `packages/Angular/src/lib/custom/custom-forms.module.ts` (add the panel to `PANELS`, import and export the standalone widget)
- Modify: `packages/Angular/src/public-api.ts` (export both classes next to `PersonJobFunctionsPanel`)
- Test: `packages/Angular/src/lib/components/company-sender-identities/__tests__/company-sender-identities.component.test.ts`, `packages/Angular/src/lib/custom/panels/__tests__/company-sender-identities.panel.test.ts`

**Interfaces:**
- Consumes: `CompanySenderIdentityEntity`, `NormalizeSenderIdentity` (Tasks 1 and 4); `BizAppsFormPanel` (`custom/panels/bizapps-form-panel.ts`); `BaseFormPanel` registration shape from `person-job-functions.panel.ts`; set-primary precedent `contact-method-list.component.ts:561`.
- Produces:
  ```ts
  @Component({ standalone: true, selector: 'bizapps-company-sender-identities', … })
  export class CompanySenderIdentitiesComponent {
      @Input() CompanyID: string | null;
      @Input() EditMode = true;
      @Input() Provider?: IMetadataProvider;
      @Output() DataChanged = new EventEmitter<void>();
      public Rows: CompanySenderIdentityEntity[]; public Loading: boolean; public Saving: boolean; public Error: string | null;
      public async loadAll(): Promise<void>;                       // one RunView on 'MJ_BizApps_Common: Company Sender Identities' filtered by CompanyID, ordered Address
      public async addRow(kind: SenderIdentityKind, address: string, displayName: string | null): Promise<boolean>;
      public async setDefault(row: CompanySenderIdentityEntity): Promise<boolean>;  // demote current default (Save), then promote `row` (Save); hidden for Domain rows
      public async removeRow(row: CompanySenderIdentityEntity): Promise<boolean>;   // after a confirm dialog
  }
  @RegisterClassEx(BaseFormPanel, { key: 'form-panel:Companies:sender-identities', metadata: { entity: 'MJ: Companies', slot: 'after-related', sortKey: 20, contributionKey: 'company-sender-identities' } })
  export class CompanySenderIdentitiesPanel extends BizAppsFormPanel<MJCompanyEntity> {}
  ```
  `MJCompanyEntity` is `@memberjunction/core-entities`' Company class. No `replacesSectionKey`: the panel is additive (spec §8).

- [ ] **Step 1: Write the failing component tests** (vitest, `vi.mock('@memberjunction/core')` as in `selling-company-field.component.test.ts`):

```ts
it('loadAll runs one RunView filtered by CompanyID and exposes the rows', …);        // runView called once with ExtraFilter containing the id
it('addRow refuses a malformed address before any save and shows the error', …);    // NormalizeSenderIdentity errors → Error set, GetEntityObject not called
it('setDefault demotes the current default before promoting the chosen row', …);    // saves recorded in order: old row IsDefault false, then new row true
it('setDefault reports a failed demote with the address and stops', …);             // first Save returns false → Error contains old address, second Save not called
it('removeRow deletes and emits DataChanged', …);
```

- [ ] **Step 2: Write the failing panel test** (shape of `activity-header.panel.test.ts`): the panel is registered on `BaseFormPanel` under key `form-panel:Companies:sender-identities` with `entity 'MJ: Companies'` and slot `after-related`, found through `MJGlobal.Instance.ClassFactory`.

- [ ] **Step 3: Run both** — `cd packages/Angular && pnpm exec vitest run company-sender-identities` → FAIL (modules missing).

- [ ] **Step 4: Implement the widget.** Template: `<mj-loading>` while `Loading`; a list with kind icon (`fa-solid fa-envelope` / `fa-solid fa-globe`), address, display name, a **Default** badge; per row **Set default** (Mailbox only, hidden when already default) and **Remove**; an inline add form with a Mailbox/Domain toggle, address, display name (Mailbox only), **Add** on the left and **Cancel** on the right; after a successful add, the one-line reminder from spec §8 ("Make sure this sender is verified in your mail provider before using it."). Errors render in a `--mj-*`-toned alert, never only in the console. `cdr.detectChanges()` after each state change.

- [ ] **Step 5: Implement the panel** (`.ts` as in Interfaces; `.html` copies `person-job-functions.panel.html` with `SectionKey="companySenderIdentities"`, `SectionName="Email senders"`, `Icon="fa-solid fa-paper-plane"`, and the widget bound to `[CompanyID]="Record.ID"`). Register in `custom-forms.module.ts` and `public-api.ts`.

- [ ] **Step 6: Build and test** — `cd packages/Angular && pnpm run build && pnpm test` → green, counts reported.

---

### Task 6: Integration check (live database, GraphQL wire)

**Files:**
- Create: `packages/IntegrationTests/src/checks/sender-identities.checks.ts`
- Modify: `packages/IntegrationTests/src/entity-names.ts` (add `CompanySenderIdentity: 'MJ_BizApps_Common: Company Sender Identities'` and `Company: 'MJ: Companies'`), `packages/IntegrationTests/src/index.ts` (export the bundle, add a line to the BUNDLES comment: `sender-identities  SI1–SI3`)

**Interfaces:**
- Consumes: `FindRows`, `Quote`, `RequireSave` from `wire.ts`; `CompanySenderIdentityEntity`; `MJCompanyEntity` from `@memberjunction/core-entities`.
- Produces: checks `sender-identities.SI1`..`SI3`, all `RequiresMutation: true`.

- [ ] **Step 1: Write the checks.** Each creates a throwaway `MJ: Companies` row named `COM-WORLD Sender Co <random>` and deletes it and every register row it made in `finally`, whatever happened; never touches an existing company.
  - **SI1**: add a Mailbox `  HR@<random>.test ` → re-read over RunView → `Address === 'hr@<random>.test'`, `IsDefault` false.
  - **SI2**: add `hr@<random>.test` then `HR@<random>.test` → second `Save()` returns false (unique index after normalisation); message names the address.
  - **SI3**: add two Mailbox rows, set the first default, then set the second default by demote-then-promote → exactly one row with `IsDefault = 1`; promoting the second without demoting first → `Save()` returns false.

- [ ] **Step 2: Run** — `pnpm run test:integration` against your private database with MJAPI running. Expected: SI1–SI3 pass; report pass/fail/skip counts. If the integration user cannot create `MJ: Companies`, the check logs that reason, skips, and the PR says so (spec §10).

---

### Task 7: Whole-repo verification

- [ ] **Step 1:** From the workspace parent: `pnpm --filter "@mj-biz-apps/common-*" run build` → clean.
- [ ] **Step 2:** `pnpm test` in this repo → all packages green; `pnpm run lint:entityfield-drift` → clean.
- [ ] **Step 3:** `pnpm run test:integration` → counts reported.
- [ ] **Step 4:** `git status --short` lists only: the migration, the generated files, `.display-names.json` (and `.validators.json` if pinned), the five source files from Tasks 1, 4, 5, the three tests, `custom-forms.module.ts`, `public-api.ts`, `entity-names.ts`, `index.ts` files. Nothing under `apps/`. Stop and hand to Soham: no commit, no changeset.
