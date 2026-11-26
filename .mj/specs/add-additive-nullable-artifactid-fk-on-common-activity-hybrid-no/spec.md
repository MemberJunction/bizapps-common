# Common.Activity Category B Hybrid Spine (`Activity.ArtifactID` -> `MJ: Artifacts`)

- **Slug:** `add-additive-nullable-artifactid-fk-on-common-activity-hybrid-no`
- **Repository:** `MemberJunction/bizapps-common`
- **Target Trunk Branch:** `next` (MJ `^6.3.0-edge.1`)
- **Approved FactoryPlan:** `7582BA01-1C50-4CBD-8233-F94B5CA21FF4` (v2)
- **CriteriaHash:** `21f028fe7161ef6ed1f7165341d0a39ac18e28299d83b02e8c5a2429a639dce1`

## Problem Statement

Operational users logging everyday interactions (Notes, Calls, Meetings, Emails) in `MJ_BizApps_Common: Activities` require sub-2-second quick capture without document bloat, while consultants, legal counsel, and account leads occasionally need to attach or expand an Activity into a versioned, collaborative **MJ Doc** (`MJ: Artifacts`). Prior to this change, `Common.Activity` had no first-class relational link to `[__mj].[Artifact]`, forcing either unstructured URLs inside `Description` or redundant artifact creation for lightweight notes.

## Architectural Solution (Category B Hybrid Spine)

1. **Strictly Additive Schema & Dual-Dialect PG Parity (`AC-1`, `AC-2`):**
   - `migrations/V202611261245__v6.3.x__Activity_ArtifactID.sql` adds nullable `[ArtifactID] UNIQUEIDENTIFIER NULL` with foreign key `FK_Activity_Artifact` -> `[__mj].[Artifact]([ID])`, filtered nonclustered index `IDX_AUTO_MJ_FKEY_Activity_ArtifactID` (`WHERE [ArtifactID] IS NOT NULL`), `MS_Description`, and verbatim CodeGen updates (`EntityField`, `vwActivities`, `spCreateActivity`, `spUpdateActivity`, `spDeleteActivity`). Zero columns are dropped, renamed, or narrowed (`PUBLISH_NO_BREAK_POLICY.md`).
   - `migrations-pg/V202611261245__v6.3.x__Activity_ArtifactID.pg.sql` provides deterministic PostgreSQL parity generated via `mj migrate convert --split --bake-codegen` + bounded `.needs-hand` + `mj migrate rebake --file ... --capture-only`, stamped on line 1 with `-- @mj-pg-provenance: split-bake v1 source=... source-sha256=... mode=needs-hand-rebaked`.
2. **Generated Entity, Zod, GraphQL & Form Layers (`AC-1`, `AC-3`):**
   - Regenerated `mjBizAppsCommonActivityEntity` (`@mj-biz-apps/common-entities`), Zod schema, GraphQL schema (`@mj-biz-apps/common-server`), and generated form component (`@mj-biz-apps/common-ng`) with zero `any`, zero lazy `unknown`, and zero `.Get()`/`.Set()`.
3. **Hybrid Activity UI & OpenApp v3 Readiness (`AC-5`):**
   - Preserves `<2s` quick capture in `<bizapps-activity-composer>` and `SaveQuickActivity` with `ArtifactID = null` by default (never auto-creating an `MJ: Artifacts` row).
   - Provides opt-in linking (`LinkExistingArtifactToActivity`), atomic expansion (`ExpandActivityToArtifact` using `TransactionGroup` / compensating rollback), safe unlinking (`UnlinkArtifactFromActivity` preserving `Description`/`Details` and the Artifact), batched timeline hydration (`LoadActivityArtifactsByIDs` using `RunViews`, `ResultType: 'simple'`, minimal `Fields`, `CacheLocal: false`, zero-call short-circuit), and `NavigationService` navigation (`OpenLinkedArtifact`).
   - Maintains Dual Form Registration Parity (`30/30` entities live-registered in `ClassFactory` via `LoadBizAppsCommonClient()`), Navigation/Resource Parity (`5/5` `DefaultNavItems` wrapped in `<mj-page-layout>` with `OnPush` and `queueMicrotask`-deferred `NotifyLoadStarted()`/`NotifyLoadComplete()`), semantic `--mj-*` tokens (zero raw `#hex`/`rgb`/`rgba`/`hsl`), `UserInfoEngine.Instance` preference persistence, and zero raw Markdown leaks.
4. **Dual-DBMS Real-World Integration & Governance (`AC-4`, `AC-6`):**
   - Multi-entity seed fixtures (`scripts/seed-activity-hybrid-world.mjs` and `packages/IntegrationTests/src/world/activity-hybrid-world.ts`, `>= 20` domain records across Organizations, People, Roles/Permissions, Note/Call/Meeting/Email Activities, ActivityLinks, and opt-in MJ Docs).
   - Live dual-DBMS cross-stack checks (`packages/IntegrationTests/checks/activity-hybrid-artifact.check.mjs`) verified in parallel on SQL Server 2022 and PostgreSQL via `sf-workspace-db-broker.mjs rehearse-dual-db`, plus GraphQL-wire check `activities.A7` and Vitest guard suite `packages/IntegrationTests/src/__tests__/ActivityPgParityAndGuards.test.ts`.
   - Documented the `'MJ Docs (MJ: Artifacts) vs. MJ: Comments vs. Quick Notes'` rubric in `CLAUDE.md` and `AGENTS.md`, synchronized package/root READMEs, registered the `v6.3.x` edge-only migration in `release-lines.json`, verified CI gates in `.github/workflows/ci.yml`, and added `.changeset/activity-artifact-hybrid-spine.md`.

## Critical User Journeys (CUJs)

1. **CUJ-1 — Frictionless Quick Capture (`ArtifactID = NULL`, Account Executive):**
   - Open `<bizapps-activity-composer>` on the Activities dashboard or an Organization/Person record.
   - Select `Call` or `Note`, enter concise notes in `Description`/`Details`, and save.
   - **Expected outcome:** Activity persists in `<2s` with `ArtifactID = NULL`, zero `MJ: Artifacts` records are created, and the timeline renders a clean plain-text excerpt with zero extra Artifact queries.
2. **CUJ-2 — Opt-In Linked MJ Doc, Expansion, Unlink & Graceful Degradation (Consultant / Counsel):**
   - Open an existing Meeting or Note Activity and opt in to **Link MJ Doc** (selecting an existing `MJ: Artifacts` record) or **Expand to MJ Doc** (creating a versioned Artifact and linking `ArtifactID` atomically).
   - Click the hydrated `<bizapps-activity-artifact-badge>` to open the document via `NavigationService`, or **Unlink** to reset `ArtifactID = NULL` while preserving `Description`, `Details`, and the Artifact itself.
   - If a viewer lacks read access to a linked Artifact (or the Artifact is unavailable), the badge degrades cleanly to `Linked MJ Doc (Unavailable)` with zero console errors.
3. **CUJ-3 — OpenApp Top-Level Navigation & Dual Form Parity (Explorer User):**
   - Navigate across all 5 `DefaultNavItems` (`CommonDirectoryResource`, `CommonPeopleResource`, `CommonOrganizationsResource`, `CommonRelationshipGraphResource`, `CommonActivitiesResource`) and open Activity/Person/Organization forms.
   - **Expected outcome:** Every top-level resource mounts cleanly inside `<mj-page-layout>`, fires `NotifyLoadComplete()`, renders loaded FontAwesome 6 icons with semantic `--mj-*` tokens, and completes with `0 pageErrors`, `0 consoleErrors`, `0` broken images, and `0` raw Markdown leaks.
4. **CUJ-4 — Dual-DBMS CI & Deployment Parity (Platform Engineer):**
   - Run `sf-workspace-db-broker.mjs rehearse-dual-db` applying T-SQL and `split-bake v1` PostgreSQL migrations + `mj sync push --dir metadata --ci` (zero deploy-time `mj codegen`) and executing `packages/IntegrationTests/checks/activity-hybrid-artifact.check.mjs` in parallel on SQL Server and PostgreSQL.
   - **Expected outcome:** Zero 6-category schema delta, valid SHA-256 provenance header, `>= 20` seeded domain records verified, dangling `ArtifactID` rejected by `FK_Activity_Artifact`, RLS/permission boundaries verified, and transactional rollback leaves `0` leaked rows.
