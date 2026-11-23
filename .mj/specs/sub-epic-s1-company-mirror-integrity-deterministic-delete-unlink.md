# Sub-Epic S1: Company Mirror Integrity, Deterministic Delete Unlink & Backport Alignment

- **Slug:** `sub-epic-s1-company-mirror-integrity-deterministic-delete-unlink`
- **Repository:** `MemberJunction/bizapps-common`
- **Target Trunk Branch:** `next` (MJ 6.3 Edge)
- **Approved FactoryPlan:** `740F8A0E-87E0-460E-8132-2B283140D6A9` (v2)

## Summary

Hardens `MJ: Companies` → `MJ_BizApps_Common: Organizations` (`Organization.LinkedCompanyID`) mirror synchronization in `@mj-biz-apps/common-entities` and `@mj-biz-apps/common-core-entities-server`:

1. **Pre-create Organization Deduplication (`AC-1`):** Queries `MJ_BizApps_Common: Organizations` via `RunView` (`ResultType: 'simple'`, `BuildOrganizationMirrorLookupFilter`, `MAX_LOOKUP_CANDIDATES = 25`) using dual-dialect ANSI SQL predicates over `LinkedCompanyID` and unlinked normalized `Name`, `LegalName`, and `WebsiteDomain` before creating any new Organization row. Disambiguates deterministically and rejects ties with `AMBIGUOUS_ORGANIZATION_MATCH`.
2. **Structured Mirror Error Contract (`AC-2`):** Eliminates silent log-only catch blocks by surfacing `CompanyMirrorError`, `CompanyMirrorErrorDetails`, `CompanyMirrorResult`, and `CompanyUnlinkResult` with zero `any`, zero `as unknown` casts, and zero `BaseEntity.Get()/Set()`. `CompanyOrganizationMirrorEntityServer` records structured failures on `LastMirrorError` and `BaseEntity.LatestResult` and returns `false` on mirror/unlink failure.
3. **Deterministic Company Delete Unlink/Archive (`AC-3`):** `CompanyOrganizationMirrorEntityServer.Delete()` queries linked Organizations via `RunView` (`ResultType: 'simple'`), clears `LinkedCompanyID = null`, applies the safe archive transition (`'Active'` → `'Inactive'`, preserving `'Dissolved'`/`'Inactive'` without deleting shared internal Organizations), coordinates writes inside `EntityTransactionScope` / `TransactionGroup`, and aborts `super.Delete()` if unlinking fails.
4. **Trademark Cleanup, BUSL-1.1 & Release-Line Alignment (`AC-4`):** Removes third-party trademark copy from mirror sources/tests/docs and prototype mockups, preserves `Copyright (c) MemberJunction.com` / `SPDX-License-Identifier: BUSL-1.1` headers, verifies `release-lines.json` and `mj-app.json` (`>=6.3.0-edge.1 <7.0.0`) for `next`, and adds `.changeset/company-mirror-integrity.md`.
5. **CI Workflow & Full Verification (`AC-5`):** Ensures `.github/workflows/ci.yml` executes static gates, workspace build, and unit/server tests on PRs targeting `next` and `main`.

## Critical User Journeys & Verification Telemetry

1. **Company Mirror Create / Update / Deduplicate / Delete Lifecycle (Admin / Platform Operator):**
   - Verified via Vitest unit & server entity lifecycle suites (`packages/Entities/src/__tests__/organization-mirror-dedup.test.ts`, `mirror-error-contract.test.ts`, `company-delete-unlink.test.ts`, `mirror-hygiene.test.ts` and `packages/Server/src/__tests__/company-mirror-sync.test.ts`, `company-organization-mirror.test.ts`, `company-delete-unlink.test.ts`).
2. **MJ 6.3 Edge Release-Line & CI Gate Verification (Release Maintainer):**
   - Verified via `pnpm run build:packages`, `pnpm run test`, `pnpm run check:uuid`, `node .github/scripts/release-lines.mjs validate --file release-lines.json --base origin/next`, `node .github/scripts/check-dependency-model.mjs`, `pnpm run test:mutants:anchors`, `node --test scripts/*.spec.mjs`, and `node --test .github/scripts/__tests__/*.spec.mjs`.
