# GENERAL RULE
Don't say "You're absolutely right" each time I correct you. Mix it up, that's so boring!

# BizApps Common Development Guide

This is a **shared library repository** built on the [MemberJunction](https://github.com/MemberJunction/MJ) platform. It provides the common business entities (Person, Organization, Address, ContactMethod, Relationship, Activity) that other MemberJunction Open Apps consume.

Everything in this file is either repo-specific, unrecoverable if violated, or true on every task. Detailed MemberJunction guidance loads on demand from `.claude/rules/`, `.claude/skills/` and the MJ mirror in `.claude/mj/`. See [Where the rest of the guidance lives](#where-the-rest-of-the-guidance-lives).

## Repository Structure

```
bizapps-common/
  mj-app.json           MJ Open App manifest (version and mjVersionRange are derived; see below)
  metadata/             Declarative seed JSON pushed by `mj sync push` (no `sync` blocks in PRs)
  migrations/           T-SQL migrations, one chain; README.md is the release-seed runbook
  packages/
    Entities/           @mj-biz-apps/common-entities (CodeGen-generated entity subclasses + hand-written helpers)
    Actions/            @mj-biz-apps/common-actions (CodeGen-generated action subclasses)
    ActivitySync/       @mj-biz-apps/common-activity-sync (provider plugin contracts, engine)
    CoreEntitiesServer/ @mj-biz-apps/common-core-entities-server (server-side entity subclasses)
    Server/             @mj-biz-apps/common-server (bootstrap, resolvers, custom actions)
    Angular/            @mj-biz-apps/common-ng (Angular bootstrap, forms, pages, widgets)
    IntegrationTests/   live-database checks (vitest, rolled back)
  plans/                Implementation plans (a plan PR adds one file and no code)
  scripts/              Repo guards and release helpers, each with a .spec.mjs
  apps/                 Build artifacts only. This repo ships no MJAPI or MJExplorer of its own.
```

---

## CRITICAL RULES - VIOLATIONS ARE UNACCEPTABLE

### 1. NO COMMITS WITHOUT EXPLICIT APPROVAL
- **NEVER run `git commit` without the user explicitly asking you to**
- **Each commit requires ONE-TIME explicit approval** - don't assume ongoing permission
- **NEVER ask to commit** - wait for the user to request it
- **ONLY commit what is staged** - never modify or add to staged changes
- **NEVER commit work-in-progress** that isn't staged by the user

### 2. NO DESTRUCTIVE GIT OPERATIONS WITHOUT EXPLICIT APPROVAL
- **NEVER run `git checkout -- <file>`, `git restore <file>` or `git reset --hard`** without the user approving it, even in auto-approve mode. They destroy uncommitted work and cannot be undone.
- To undo your own change, find it with `git diff` and reverse only that with targeted edits.
- **NEVER update the title or description of a merged PR** without explicit approval each time.

### 3. NO `any` TYPES - EVER
- No `: any`, `as any`, `<any>`, and no `unknown` as a lazy substitute. **Ask the user** if you think you need one. MemberJunction has a proper type for everything. Full rule: [`.claude/rules/typescript-style.md`](.claude/rules/typescript-style.md).

### 4. NO RE-EXPORTS BETWEEN PACKAGES
- Never re-export types, classes or interfaces from another package. Import from the package that defines them. The `core-entities-server-no-reexport` changeset records the last time this bit.

### 5. USE BaseSingleton FOR ALL SINGLETONS
- Never a manual `static _instance`. Extend `BaseSingleton<T>` from `@memberjunction/global`.

### 6. ANGULAR COMPONENT & MODULE STRATEGY
- New leaf components, lazy routes and self-contained widgets are **standalone**; feature and shared modules stay **NgModule**, and a module-declared component sets `standalone: false` explicitly (Angular 21 defaults to standalone). Never mix the two in one component. When adding to an existing package, follow the pattern already there.
- New code uses `@if`/`@for`/`@switch` and `inject()`.

---

## Branches

Before starting a new line of work, check the local branch. Feature branches are cut from `next` (the integration branch), never from `main` (the release branch). If we aren't already on an appropriately named, empty feature branch tracking `origin/<same-name>`, **ask before creating one**. `/new-branch` does it correctly.

**VERY IMPORTANT** We want you to be a high performance agent. Whenever you need to spin up tasks that don't need the user and aren't interdependent, ALWAYS run them in parallel. **NEVER** process tasks sequentially if they are candidates for parallelization.

### Feature branches MUST track same-named remote branches

```bash
# CORRECT
git checkout -b my-feature-branch
git push -u origin my-feature-branch

# WRONG - a branch created from main or next tracks that branch, and `git push` lands on it
git checkout next
git checkout -b my-feature-branch
```

Before every push: `git branch -vv`, confirm `origin/<same-branch-name>`, fix with `git branch --set-upstream-to` if not.

### Branching model: `next` → `main` release flow
BAC uses a two-tier branching model (matching BCSaaS and MJ):

- **`next`** — integration branch. All feature work merges here.
- **`main`** — release branch. Only updated by the **Version Packages** PR (`changeset-release/main` → `main`) that `version.yml` maintains. A merge to `main` triggers the publish workflow.

**Feature work flow:**
1. Cut a feature branch from `next`: `git checkout next && git pull && git checkout -b <feature-name>`
2. Make changes, commit, push, open a PR → `next` (`/create-pr` targets `next`)
3. `changes.yml` + `build.yml` run validation on the PR
4. Merge to `next`

**Release flow: merge the Version Packages PR.**
1. Every push to `next` runs `version.yml` (changesets/action, GitHub App token). While changesets are pending it opens or updates ONE **Version Packages** PR (`changeset-release/main` → `main`), built by `pnpm run version:prepare` (`changeset version`, then `ci/sync-mj-app-version.mjs` syncs `mj-app.json`, then the lockfile).
2. That PR is the release. PRs into `main` run `release-readiness.yml` (the `rr:` checks: changesets, minor bump, metadata shipped, pg counterparts, release base current, migration immutability, packages on npm) and `build.yml`. Merge it.
3. The push to `main` runs `publish.yml`: it publishes over npm OIDC, tags `vX.Y.Z` only if something shipped, then the App opens and merges a `release-back-merge/vX.Y.Z` → `next` PR.

There is no hand-opened `next` → `main` PR and no dispatch-driven publish.

**Rules:**
- **Nothing pushes to `main` or `next`**, whether a human or a workflow. Every change reaches them through a PR; the release workflows push only `changeset-release/main`, `release-back-merge/*` and the `vX.Y.Z` tag.
- **`Metadata_Sync` is release work, not PR work.** A feature PR carries only declarative JSON under `metadata/`: no `sync` block and no `*__Metadata_Sync.sql`. The build engineer generates one consolidated seed per release from a clean database: [`migrations/README.md`](migrations/README.md). `rr: metadata shipped` checks it on the release PR. The model: [Release Metadata Migrations Guide](https://github.com/MemberJunction/MJ/blob/next/guides/RELEASE_METADATA_MIGRATIONS_GUIDE.md).
- **`mj-app.json` is checked on every PR** (`repo: guards` runs `scripts/sync-app-version.spec.mjs`): a PR that changes the `@memberjunction/core` pin must run `node scripts/sync-app-version.mjs` and commit `mj-app.json`. At release, `version:prepare` also syncs its `version` and range.
- **Migrations need a changeset with at least a `minor` bump** (`changes.yml`'s `migration changeset` check), and a migration that has shipped is immutable. Changesets are written by the user, not by you.
- **Hotfixes** still go through a PR — into `next`, with a changeset — and ship through the Version Packages PR like any other change.

---

## The dev workspace: this repo develops against MemberJunction `next`

This clone is a member of an **`mj dev workspace`**: the parent folder (one level up) holds sibling clones of MJ and the Open App repos, and a generated pnpm workspace links every `@memberjunction/*` and `@mj-biz-apps/*` package to its source checkout. `@memberjunction/core` here resolves to `../MJ/packages/MJCore`. An edit in any repo is live in every other repo after a package build. Guide: [`../MJ/guides/DEV_WORKSPACE_QUICKSTART.md`](../MJ/guides/DEV_WORKSPACE_QUICKSTART.md).

- **The MJ checkout stays on `next`.** New work here uses what MJ `next` has today. Do not design around the LTS line: no `backport lts/6.1` labels, no fallbacks for features that `next` already ships. A fix this repo needs in MJ goes to MJ `next` as a normal PR; it reaches this repo through the workspace link immediately and reaches CI and hosts in the next edge release.
- **Never install inside a member.** `pnpm install` runs at the **parent** only. A `node_modules` created inside this repo or inside `../MJ` gives MJ a second package store and splits every singleton (`ClassFactory`, `type-graphql`). Never `pnpm link`, never symlink a package by hand, never copy another checkout's `dist/`. If something looks wrongly linked: `node ../MJ/packages/MJCLI/bin/run.js dev workspace status`, then `... dev workspace --force --clean-members` to recover.
- **Build from the parent or from here.** `pnpm --filter @mj-biz-apps/common-entities run build` from the parent, or `pnpm run build` in a package directory here. Consumers see the new `dist/` at once. MJ packages you changed need their own build before this repo sees the change.
- **Local host files never commit.** MJ's `mj.config.cjs`, `.env` and generated host folders are local artifacts of the MJ checkout. That is where this app is registered as an Open App for running MJAPI and MJExplorer (below).

## MemberJunction version policy

The pins are a **floor**, not a target. `^6.1.5` means "at least 6.1.5"; development happens on `next` through the workspace link above.

- **Declared ranges.** In a published package, `@memberjunction/*` (and any other app's `@mj-biz-apps/*`) is a **peer** with a caret range and never appears in `dependencies`: the host installs one copy, and a `~6.1.N` or exact peer makes every later host install a second tree, which splits the ClassFactory. Each peer also has a `devDependencies` entry with the same caret floor. `.github/scripts/check-dependency-model.mjs` enforces this in CI; it accepts a prerelease caret such as `^6.2.0-edge.3`. Packages MJ versions separately (`@memberjunction/connector-*`, `@memberjunction/skyway-*`) keep their own ranges.
- **`pnpm.overrides`.** `@memberjunction/core` and `@memberjunction/global` carry the same caret floor as every other MJ range, so every request in the graph resolves to one copy. Two copies of `core` split the ClassFactory: registrations land in one factory while the resolver reads the other, and nothing errors. Overrides are workspace-local and never published. Do not exact-pin sibling `@mj-biz-apps/*` packages here.
- **One copy of each.** After any install at the parent, `pnpm why @memberjunction/core` must show a single version. A sibling app package that exact-pins an old MJ build brings a second copy in; fix it by raising that package's floor, not with more overrides.
- **Raising the floor.** Do it when this repo's code or migrations start to need something newer than the current floor, and raise it to the first **published** MJ build that carries it: CI's `clean-room-gate.yml` installs MJ core at the floor of `mj-app.json`'s `mjVersionRange` and replays this repo's migrations on it, so a floor below what the code needs fails there, not on your machine. Raise every `^` floor in peers, devDependencies and both overrides; `pnpm install` at the parent; confirm one copy; run `node scripts/sync-app-version.mjs` and commit `mj-app.json`; rebuild the database from migrations and regenerate; run the full test suite; the user adds a `patch` changeset; commit the lockfile. If CI then fails on the lockfile although a clean local install works, GitHub is testing the merge with `next`: merge `next` in, run `pnpm install --no-frozen-lockfile`, and commit the lockfile.
- **Never patch MemberJunction.** No `pnpm patch`, `patchedDependencies`, patch-package or `sed` against `@memberjunction/*` `dist/`. Fix it on MJ `next`.

### CodeGen output must be reproducible from this repo

Generated files are committed, and hosts ship them as they are: a host excludes every `__mj_BizApps*` schema from its own CodeGen and installs the published packages. So the committed output has to be what this repo's toolchain produces from its migrations.

- Run CodeGen from the workspace (MJ `next` source) against a database built from migrations: MJ core from `../MJ`, then the apps this one depends on, then this repo, then `mj sync push` of `metadata/`. See [Fresh database](#fresh-database).
- Set an AI key in your gitignored `.env`: `AI_VENDOR_API_KEY__GeminiLLM` (every CodeGen prompt ranks Gemini first), or `AI_VENDOR_API_KEY__OpenRouterLLM`. Without one, CodeGen silently drops AI-written output: check-constraint `Validate*()` methods, display names, descriptions and form layouts.
- Never hand-edit generated files, and never paste in generated output from another toolchain or another database. That is how OrderLine lost `OrderHeader`'s `@Field` (bc-aidp-next-golive#295).
- Review what AI wrote. Validators, names and descriptions are not deterministic between runs.
- If CodeGen has to create metadata in the database that the generated code depends on (fields, value lists, relationships, validator code), ship it in a migration in the same PR. Otherwise every host installed from migrations drifts from the code.

### Fresh database

**One database per agent.** A git worktree isolates the filesystem, not the database. Before `mj migrate`, `mj codegen` or `mj sync push`, confirm no other session is using your `DB_DATABASE`. Build your own with the `bootstrap-clean-db` skill, with this repo's twists:

1. **Migrations are the whole install.** Both MJ core's and this repo's migrations carry their metadata (every release ships one consolidated `Metadata_Sync` seed) and replay every `CodeGen_Run_*.sql`. So a fresh database needs **only `mj migrate`**, core first and then this repo. Do not follow the skill's CodeGen and sync-push steps on a database with no new work in it: CodeGen without schema DDL has nothing to generate and only churns committed files, and a sync push with no new `metadata/` edits pushes nothing.
2. **MJ core comes from the MJ checkout.** Create the empty database as `sa` (the `mj-sqlserver` container's `MSSQL_SA_PASSWORD`; the app logins can't `CREATE DATABASE`), write `.env.clean` copies in `../MJ` and here pointing at it, and run `DOTENV_CONFIG_PATH=.env.clean pnpm run mj:migrate` in `../MJ`, then here. The CLI reads env through `dotenv/config`, so that variable selects the copy without touching the shared `.env`.
3. **CodeGen and sync push only when the branch adds them.** New DDL: the four-step order in the skill (`mj migrate`, `mj codegen --skipfiles`, `mj sync push --dir=metadata --ci`, `mj codegen --skipdb`), then append the `CodeGen_Run_*.sql` to the migration, read the regenerated diff, and restore any `sync` block write-back in `metadata/`. New `metadata/` JSON only: `mj sync push`, then `mj codegen --skipdb` if it adds Remote Operations. Invoke the CLI as `pnpm exec mj …`: `pnpm run mj:codegen -- --flag` forwards the literal `--` and the CLI rejects it.

The `mj` binary is `node_modules/.bin/mj`, linked to `../MJ/packages/MJCLI`, so after moving the MJ checkout rebuild its chain first: `pnpm --filter "@memberjunction/cli..." --filter "!./MJ-next/**" run build` from the parent.

---

## Build and test

This is a **pnpm** workspace (`packageManager` in `package.json`; the lockfile is `pnpm-lock.yaml`). Never `npm install`.

```bash
pnpm run build                    # every @mj-biz-apps/* package, Turborepo
pnpm run build:generated          # Entities + Actions only
cd packages/PackageName && pnpm run build   # one package: use this to check your change compiles
pnpm test                         # unit tests, every package
pnpm run test:integration         # live-database checks (packages/IntegrationTests), rolled back
pnpm run mj:migrate               # this repo's migrations, schema __mj_BizAppsCommon
pnpm run mj:codegen               # CodeGen scoped to this schema
pnpm run lint:entityfield-drift   # generated EntityField metadata vs. the views
```

- **After any code change, build the affected package** and fix every TypeScript error before moving on.
- **Definition of done:** the package's unit tests pass, and the integration checks pass when the change touches entities, migrations or metadata. Report pass, fail and skip counts.
- Adding a dependency: declare it in the package's `package.json`, then `pnpm install` at the **workspace parent**. pnpm resolves only declared imports.
- Running an app: this repo has none. Run MJAPI (port 4000, or `GRAPHQL_PORT`) and MJExplorer (4201) from `../MJ` with this app registered in MJ's local `mj.config.cjs` `dynamicPackages`; that file is never committed to MJ. `.vscode/tasks.json` keeps one task here, `build-all`.
- The repo root `.env` holds the database connection and AI keys for the `mj` CLI. It is gitignored.

---

## CodeGen

CodeGen output lives in `packages/Entities/src/generated`, `packages/Actions/src/generated`, `packages/Server/src/generated` and `packages/Angular/src/lib/generated`. Never edit it by hand; run `pnpm run mj:codegen` after every schema change. Entity names carry the `MJ_BizApps_Common: ` prefix from `mj.config.cjs` `newEntityDefaults`; display names are locked in `metadata/entities/.display-names.json`. How CodeGen works: [`.claude/mj/packages/CodeGenLib/CLAUDE.md`](.claude/mj/packages/CodeGenLib/CLAUDE.md).

## Database migrations

- Placeholders: `[${flyway:defaultSchema}]` for this schema, `[${mjSchema}]` for core. Guarded DDL (`IF OBJECT_ID(...) IS NULL`), `MS_Description` on every column, no `__mj_CreatedAt`/`__mj_UpdatedAt` columns and no foreign-key indexes (CodeGen adds both), then 50 blank lines, then the appended CodeGen output with no literal `Sequence` on `EntityField` inserts.
- The stamp (`V<YYYYMMDDHHMM>`, Central Time) must sort after every migration on `next` at merge time; `changes.yml` rejects one that doesn't. A shipped migration is immutable.
- T-SQL only in a feature PR. The PostgreSQL twin is release work (`docs/postgresql.md`).
- Full rules: [`.claude/mj/migrations/CLAUDE.md`](.claude/mj/migrations/CLAUDE.md); the release-seed runbook: [`migrations/README.md`](migrations/README.md).

## Metadata

Declarative JSON under `metadata/`, pushed by `mj sync push`. Primary keys come from `uuidgen`; references use `@lookup:`, `@parent:` and `@file:`; JSON-typed fields are native objects. No `sync` blocks in a PR. New directories go into `metadata/.mj-sync.json` `directoryOrder` after what they look up. Full rules: [`.claude/mj/metadata/CLAUDE.md`](.claude/mj/metadata/CLAUDE.md).

---

## Repo-specific conventions

- **Server code always passes `contextUser`** to `GetEntityObject`, `RunView` and `RunViews`, and uses the request's provider rather than `new Metadata()`.
- **Never `RunView` in a loop.** One `RunViews` per batch; use the denormalized fields on `vwPeople`, `vwRelationships` and friends instead of lookups.
- **Angular:** `<mj-loading>` from `@memberjunction/ng-shared-generic` for every wait, never a custom spinner; confirm buttons on the **left**, cancel on the right; Font Awesome icons; getter/setter `@Input()`s; `cdr.detectChanges()` after programmatic changes and `Promise.resolve().then()` instead of `setTimeout`; semantic `--mj-*` tokens only.
- **Functions stay short**, about 30 to 40 lines; decompose anything longer.
- Everything else about data access, typing, naming and styling: the rules below.

## Purpose

**Consumer blindness.** Common must not name, refresh, cascade into, or heal consumer apps (Orders, Accounting, Tasks, …). FKs and package deps point **up** only. Shipped entities have `CascadeDeletes = false`. CodeGen cascade SQL is intra-schema unless a host sets `allowCrossSchemaCascadeDeletes` (do not turn that on here).

This repository provides foundational business entities that other MemberJunction applications consume. Applications can reference the BizApps entities in their own migrations, link their entities to Person, Organization and so on, and extend the core entities with additional fields or relationships. The Committees application, for example, links Committee Members to BizApps Person records.

## Angular pinning model

**Angular pinning model** (family-wide, 2026-08-07, with MemberJunction/MJ#3580): `@angular/*` peers in `packages/*` are **caret ranges at the platform pin** (`^21.1.3`) — compatibility claims, never exact. Each package that consumes Angular **anchors** the concrete version with exact `21.1.3` entries in its own `devDependencies`; the anchor is what actually installs. In the shared pnpm dev workspace `auto-install-peers=true` turns unanchored peer ranges into install instructions, which is how two copies of `@angular/core` ended up installed family-wide. Rev anchors with the era platform pin, never with MJ pins.

## GitHub repository
- Repository: https://github.com/MemberJunction/bizapps-common
- Default branch: `next` (feature PRs land here). Release branch: `main` (a merge to it publishes).

## Filing issues (pilot of the BizApps issue system)
- **Never work around a bug in this repo or in MJ silently.** File it with the `/report-issue` skill
  (`.claude/skills/report-issue/`), which picks the repo where the fix lives, captures the
  environment, searches for duplicates, and writes the same headings as the web form
  (`.github/ISSUE_TEMPLATE/bug.yml`). If the bug already exists, it posts an occurrence comment on
  the original instead of a new issue.
- Filing from the web: **New issue → Bug report**. Every bug lands as `needs-triage`; a second
  person reproduces it before it is `confirmed`. Confidence is a field, not a gate — say what you
  actually did.
- Not filed during the pilot: nits (cosmetic, no user impact) go in a local `BUGS.md`, not GitHub.
  An agent files only with a minimal repro or after seeing the same failure twice, at most five
  per session, and never closes, relabels, transfers or assigns anything.
- MJ-core bugs go to `MemberJunction/MJ` (always pass `--repo`); mjdev-tool bugs to
  `MemberJunction/MJDev`. Say which repo you chose and why under "Duplicate search".

---

## Where the rest of the guidance lives

MemberJunction's own Claude guidance is copied into this repo by `scripts/sync-mj-claude-docs.sh` (re-run it after pulling MJ; `.claude/mj/SOURCE.json` records the MJ commit). Copies are verbatim, so a relative link inside one (`../../guides/...`) resolves in the `../MJ` checkout, not here.

### Path-scoped rules (`.claude/rules/`), from MJ, load when you open a matching file

| Rule | Loads for | Covers |
|---|---|---|
| [`data-access.md`](.claude/rules/data-access.md) | `**/*.ts` | `RunView`/`RunViews`, `ResultType`/`Fields`, Save/Delete error handling, `EntityByName`, primary keys, per-provider `Metadata`, `EscapeSQLString`, entity graphs, keyset paging, `UserInfoEngine` |
| [`typescript-style.md`](.claude/rules/typescript-style.md) | `**/*.ts` | No `any`, no `.Get()`/`.Set()`, derive field types from the entity, no re-exports, `BaseSingleton`, no dynamic `import()`, naming, functional decomposition |
| [`design-tokens.md`](.claude/rules/design-tokens.md) | `**/*.scss`, `**/*.css` | Semantic `--mj-*` tokens only, hex to token mappings, `color-mix()` |
| [`testing.md`](.claude/rules/testing.md) | `**/*.test.ts`, `**/__tests__/**` | Vitest conventions, structure, fixing test drift |

MJ's `changesets.md` rule is deliberately not copied: here changesets are user-authored and `changes.yml` enforces `minor` for migrations.

### Skills (`.claude/skills/`), load only when invoked

- **`report-issue`** (this repo's): file a bug on the right repo.
- From MJ: **`bootstrap-clean-db`** (a database from migrations alone, see [Fresh database](#fresh-database)), **`debug-build-failures`** (a package won't build, Turbo, cycles), **`playwright-cli`** (browser automation against MJ's dev servers), **`scaffold-mj-dashboard`** (a new Explorer dashboard; the L3 pattern applies to `packages/Angular` pages here too).

### MJ's nested `CLAUDE.md` files, mirrored under `.claude/mj/` at MJ's own paths

| Read | When you are |
|---|---|
| [`CLAUDE.md`](.claude/mj/CLAUDE.md) | Starting anything that touches MJ itself: its always-true facts and routing table |
| [`migrations/CLAUDE.md`](.claude/mj/migrations/CLAUDE.md) | Writing a migration |
| [`metadata/CLAUDE.md`](.claude/mj/metadata/CLAUDE.md) | Adding or editing `metadata/` JSON, prompts, applications, scheduled jobs |
| [`packages/CodeGenLib/CLAUDE.md`](.claude/mj/packages/CodeGenLib/CLAUDE.md) | Running CodeGen, reading its output, class-registration manifests |
| [`packages/MJCoreEntities/CLAUDE.md`](.claude/mj/packages/MJCoreEntities/CLAUDE.md) | Reading generated entity classes as the schema's source of truth |
| [`packages/Actions/CLAUDE.md`](.claude/mj/packages/Actions/CLAUDE.md) | Writing an action in `packages/Server/src/custom`: actions are boundaries, not internal APIs |
| [`packages/Angular/CLAUDE.md`](.claude/mj/packages/Angular/CLAUDE.md) | Any work in `packages/Angular`: `@Input() Provider`, routing, query-param round-trip, dialogs, buttons |
| [`packages/Angular/Generic/CLAUDE.md`](.claude/mj/packages/Angular/Generic/CLAUDE.md), [`Explorer/CLAUDE.md`](.claude/mj/packages/Angular/Explorer/CLAUDE.md), [`Explorer/dashboards/CLAUDE.md`](.claude/mj/packages/Angular/Explorer/dashboards/CLAUDE.md) | Widgets (no Router), Explorer resources (`NavigationService`, `BaseResourceComponent`), page chrome and agent context |
| [`packages/MJAPI/CLAUDE.md`](.claude/mj/packages/MJAPI/CLAUDE.md) | Running MJAPI from `../MJ`: `dynamicPackages`, startup mode, pooling |
| [`docker/CLAUDE.md`](.claude/mj/docker/CLAUDE.md), [`stats/CLAUDE.md`](.claude/mj/stats/CLAUDE.md), [`packages/DBAutoDoc/CLAUDE.md`](.claude/mj/packages/DBAutoDoc/CLAUDE.md), [`metadata/components/CLAUDE.md`](.claude/mj/metadata/components/CLAUDE.md), [`packages/Angular/Bootstrap*/CLAUDE.md`](.claude/mj/packages/Angular/Bootstrap/CLAUDE.md) | Rarely needed here; kept so the mirror is complete |

### MJ guides, in the checkout: [`../MJ/guides/README.md`](../MJ/guides/README.md)

Read the index before building in an unfamiliar area. Most relevant here: UI Layering, Remote Operations, Integration Testing Quickstart, Caching & Pub/Sub, Unified Permissions, Release Metadata Migrations, Dev Workspace Quickstart.

### This repo's own docs

[`docs/`](docs/) (architecture, entity model, development, release, PostgreSQL), [`migrations/README.md`](migrations/README.md), [`plans/`](plans/).
