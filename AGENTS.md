# BizApps Common — Agent Development Guide

This repository (`MemberJunction/bizapps-common`) is the shared foundational entity library for MemberJunction Open Apps (People, Organizations, Addresses, Contact Methods, Relationships, Activities, Activity Sync).

Full repository rules, release-line workflow, migration rules, and nested MJ guidance live in [`CLAUDE.md`](CLAUDE.md) and `.claude/rules/`. Both `CLAUDE.md` and `AGENTS.md` apply to every coding agent working in this repository.

---

## Critical Non-Negotiable Rules

1. **Zero `any` or lazy `unknown`** — No `: any`, `as any`, `<any>`, and no `unknown` as a lazy substitute (enforced by `ci: static-gates`).
2. **Zero `.Get()` / `.Set()` on generated entities** — Always use strongly-typed generated entity properties (`@mj-biz-apps/common-entities`) and derive union types via indexed access (`Entity['Field']`).
3. **Use `BaseSingleton<T>` for all singletons** — Never a manual `static _instance` field. Engines extend `BaseEngine<T>` (which extends `BaseSingleton<T>`).
4. **No cross-package re-exports** — Import types, classes, and helpers directly from the package that defines them.
5. **UUID comparisons use `UUIDsEqual` / `NormalizeUUID`** — Never `===`/`!==` on record IDs or raw row-ID Map/Set keys (enforced by `scripts/check-uuid-comparisons.mjs`).
6. **Persist user preferences via `UserInfoEngine`** — Never `localStorage` or `sessionStorage`.
7. **Modern Angular conventions** — Standalone leaf components, explicit `standalone: false` in NgModules, `@if`/`@for`/`@switch`, `inject()`, semantic `--mj-*` tokens, `<mj-loading>` for wait states.
8. **Git & CI safety** — Never push directly to `next`/`main`, never squash-merge PRs (use standard merge commits `--merge`), never edit shipped migrations or `ci/` protected files without approval, never commit local host artifacts.
9. **Consumer blindness** — `bizapps-common` must never name, import, or depend on consumer apps (Orders, Sales, Accounting, Committees, etc.).

---

## Canonical 5-Rule Performance Standard

All code in `packages/Entities`, `packages/Angular`, `packages/ActivitySync`, `packages/CoreEntitiesServer`, and `packages/Server` must adhere to these five rules:

1. **`BaseEngine` (`BaseSingleton`) for bounded reference/taxonomy metadata.**
   - Cache bounded reference/taxonomy tables (`Activity Types`, `Address Types`, `Consent Purposes`, `Contact Types`, `Job Functions`, `Organization Types`, `Relationship Types`, `Seniority Levels`, `Activity Sync Provider Types`) in `CommonEngine` (`packages/Entities/src/common-engine.ts`) using `BaseEnginePropertyConfig` with `AutoRefresh: true`.
   - Maintain O(1) lookup maps (`Map` keyed by `NormalizeUUID(id)` or normalized code/name) and rebuild them on every reload in `AdditionalLoading`.
   - Always read taxonomy lists and lookups from `CommonEngine.Instance` instead of firing repeated per-component `RunView`s.

2. **Multi-Provider & Impersonation Safety.**
   - Active `ProviderToUse` must follow the provider passed to `Config()` (or ambient `Metadata.Provider` when unpinned).
   - Detect provider switches and `userId` changes (impersonation / persona switches) and auto-evict per-user caches while refreshing permission-gated configs.
   - Set `CacheLocal: false` on any RLS-filtered entity (and on all `CommonEngine` configs and party lookups) so local cache storage never leaks cross-user rows.
   - Gate optional entity queries on `EntityInfo.GetUserPermisions(user)?.CanRead`.

3. **Mandatory `rv.RunViews([...])` single-request batching.**
   - Instantiate views via `RunView.FromMetadataProvider(provider)`.
   - Use `ResultType: 'simple'` and narrow `Fields` whenever entity mutation is not needed.
   - Collapse independent queries into a single `rv.RunViews([...])` batch call — **never** `Promise.all([new RunView().RunView(...), ...])`, **never** `RunView` inside a loop, and **never** multi-hop `ParentID` loops when `RootParentID` is available.

4. **`ConversationEngine`-style bounded container caching.**
   - Cache only bounded per-container windows/subtrees or bounded ID-keyed caches (e.g., `CommonEngine.Instance.GetPeopleByIDs` / `GetOrganizationsByIDs` with bounded LRU/size eviction).
   - Every bounded cache must implement `BaseEntity` save/delete event invalidation, explicit `Invalidate*()` methods, and automatic eviction on persona/provider switch.
   - **NEVER** globally cache unbounded transactional tables (`People`, `Organizations`, `Activities`, `Relationships`, `Addresses`) or arbitrary `ExtraFilter` list queries.

5. **RLS-safe two-step entity reads.**
   - Never embed raw SQL subqueries against RLS-filtered `vw*` views inside `ExtraFilter` (raw subqueries bypass entity-level RLS filters).
   - Query the RLS-filtered entity first via `RunView`, then pass the resolved IDs (`ID IN (...)`) into the dependent query.

---

## Verification Checklist

Before opening or updating a PR, run from the repository root:

```bash
pnpm run build:packages
pnpm run test
pnpm run test:mutants:anchors
node scripts/check-uuid-comparisons.mjs
node --test scripts/*.spec.mjs
node --test 'packages/*/test-harnesses/*.spec.mjs' 'test-harnesses/*.spec.mjs'
node ./.github/scripts/check-dependency-model.mjs
```

See [`CLAUDE.md`](CLAUDE.md) for the complete branching model, release-line rules, migration authoring rules, and `.claude/rules/` index.
