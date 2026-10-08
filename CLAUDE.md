# GENERAL RULE
Don't say "You're absolutely right" each time I correct you. Mix it up, that's so boring!

# BizApps Common Development Guide

This is a **shared library repository** built on top of the [MemberJunction](https://github.com/MemberJunction/MJ) platform. It provides common business entities (Person, Organization, Address, ContactMethod, Relationship) that can be consumed by other MemberJunction applications.

## Repository Structure

```
bizapps-common/
  mj-app.json          - MJ Open App manifest
  apps/
    MJAPI/             - GraphQL API server (port 4101)
    MJExplorer/        - Angular UI application (port 4301)
  packages/
    Entities/          - @mj-biz-apps/common-entities (CodeGen-generated entity subclasses)
    Actions/           - @mj-biz-apps/common-actions (CodeGen-generated action subclasses)
    Server/            - @mj-biz-apps/common-server (server bootstrap + GraphQL resolvers)
    Angular/           - @mj-biz-apps/common-ng (Angular bootstrap + form components)
```

---

## CRITICAL RULES - VIOLATIONS ARE UNACCEPTABLE

### 1. NO COMMITS WITHOUT EXPLICIT APPROVAL
- **NEVER run `git commit` without the user explicitly asking you to**
- **Each commit requires ONE-TIME explicit approval** - don't assume ongoing permission
- **NEVER ask to commit** - wait for the user to request it
- **ONLY commit what is staged** - never modify or add to staged changes
- **NEVER commit work-in-progress** that isn't staged by the user

### 2. NO `any` TYPES - EVER
- **NEVER use `any` types in TypeScript code**
- **ALWAYS ask the user** if you think you need to use `any`
- This includes: No `as any`, No `: any`, No `<any>`, No `unknown` as a lazy alternative
- **Why**: MemberJunction has strong typing throughout - there's always a proper type available

### 3. NO MODIFICATIONS TO MERGED PRs
- **NEVER update title/description of merged PRs** without explicit approval each time

### 4. ANGULAR COMPONENT & MODULE STRATEGY
MemberJunction supports both standalone and NgModule-declared components. Choose the right approach for each situation:

#### When to Use Standalone Components (Preferred for New Components)
- **New leaf components** (dialogs, panels, small widgets) that don't need to share a module
- **Lazy-loaded route components** - standalone enables direct `loadComponent()` without wrapper modules
- **Simple, self-contained components** with clear dependency lists

#### When to Use NgModules
- **Feature modules** grouping many related components
- **Shared modules** providing common functionality to multiple consumers
- **Existing module-declared components** - don't migrate just for the sake of it

#### Rules for Both Approaches
- **Standalone components**: declare all dependencies in the component's `imports` array
- **NgModule components**: must use `standalone: false` explicitly (Angular 21 defaults to standalone)
- **Never mix within a single component** - a component is either standalone or module-declared
- When adding to an existing package, **follow the pattern already used in that package**

#### Modern Template Syntax (Required for New Code)
- **Use `@if`/`@for`/`@switch`** block syntax instead of `*ngIf`/`*ngFor`/`*ngSwitch`
- **Use `inject()` function** instead of constructor injection for new components

### 5. NO RE-EXPORTS BETWEEN PACKAGES
- **NEVER re-export types, classes, or interfaces from other packages**
- **ALWAYS** import directly from the source package that defines them

### 6. USE BaseSingleton FOR ALL SINGLETONS
- **NEVER use manual `static _instance` singleton patterns** - always extend `BaseSingleton<T>` from `@memberjunction/global`
- See MJ documentation for the pattern

---

## IMPORTANT
- Before starting a new line of work always check the local branch we're on. Feature branches should be cut from `next` (the integration branch), not from `main` (the release branch). If we aren't already in an appropriately-named, empty feature branch tracking `origin/<same-name>`, ask before creating a new one. See "Branching Model" below for the full release flow.

**VERY IMPORTANT** We want you to be a high performance agent. Therefore whenever you need to spin up tasks - if they do not require interaction with the user and if they are not interdependent in any way, ALWAYS spin up multiple parallel tasks to work together for faster responses. **NEVER** process tasks sequentially if they are candidates for parallelization

## Git Branch Tracking Rules

### Feature Branches MUST Track Same-Named Remote Branches
When creating or working with feature branches, **ALWAYS** ensure the local branch tracks a remote branch **with the same name**. Never track `main` or other permanent branches.

```bash
# CORRECT
git checkout -b my-feature-branch
git push -u origin my-feature-branch

# WRONG - Branch created from main will track origin/main by default!
git checkout main
git checkout -b my-feature-branch
# Now my-feature-branch tracks origin/main - DANGEROUS!
```

### Before Every Push
1. Run `git branch -vv` to verify tracking
2. Ensure your branch tracks `origin/<same-branch-name>`
3. If tracking is wrong, fix it before pushing

### Branching Model: `next` → `main` Release Flow
BAC uses a two-tier branching model (matching BCSaaS and MJ):

- **`next`** — integration branch. All feature work merges here.
- **`main`** — release branch. Only updated by the release PR from `release/vX.Y.Z` (cut from `next`). A merge to `main` triggers the publish workflow.

**Feature work flow:**
1. Cut feature branch from `next` (not from `main`): `git checkout next && git pull && git checkout -b <feature-name>`
2. Make changes, commit, push, open PR → `next`
3. `changes.yml` + `build.yml` run validation on the PR
4. Merge to `next`

**Release flow: one dispatch and one merge** (runbook: [`docs/release.md`](docs/release.md)):
1. Dispatch **Prepare a release** (`release-prep.yml`). It cuts `release/vX.Y.Z` from `next`, runs `pnpm run version`, and opens the "Release vX.Y.Z" PR into `main`.
2. Review and merge that PR with a merge commit. The merge triggers `publish.yml`, which builds, runs the release-readiness gates, publishes to npm, tags `vX.Y.Z`, and opens the `chore/backmerge-vX.Y.Z-<main sha>` → `next` PR (any later merge into `main` gets a back-merge PR of its own).
3. `publish.yml` merges the back-merge PR once its checks pass. It leaves it open (and says why in the run summary) on conflicts, a red or slow check, or commits added to the branch; then merge it yourself. Until it lands, **Prepare a release** refuses to cut the next release.

`pnpm run release:plan` answers "is a release due?" read-only: version, pending changesets, gates, and every blocker.

**Rules:**
- **Nothing pushes to `main` or `next`**, whether a human or a workflow. Every change reaches them through a PR. The release workflows push only `release/*`, `chore/backmerge-*` and the `vX.Y.Z` tag. The GitHub App pushes `release/*`, opens both PRs (a `GITHUB_TOKEN`-authored PR starts no CI) and merges the back-merge PR; the back-merge branch and the tag are pushed with `GITHUB_TOKEN`, because `publish.yml`'s checkout persists that credential and it outranks the App token in the remote URL. `pnpm run lint:release-pushes` fails any workflow or script that pushes to either branch.
- **`Metadata_Sync` is release work, not PR work.** A feature PR carries only declarative JSON under `metadata/`: no `sync` block and no `*__Metadata_Sync.sql`. The build engineer generates one consolidated seed per release from a clean database: [`migrations/README.md`](migrations/README.md). `check:release-seed` and `check:seed-cadence` gate the release, not feature PRs. The model: [Release Metadata Migrations Guide](https://github.com/MemberJunction/MJ/blob/next/guides/RELEASE_METADATA_MIGRATIONS_GUIDE.md). This repo's recipe: [`migrations/README.md`](migrations/README.md), "Regenerating the metadata seed".
- **`mj-app.json` is checked on every PR, into `next` or `main`** (`build.yml`'s `release-tooling` job, which runs on every event, runs the `sync-app-version` spec). A PR that changes the `@memberjunction/core` pin in `packages/Entities` must run `node scripts/sync-app-version.mjs` and commit `mj-app.json` — **not** `pnpm run version`, which would consume the pending changesets.
- **`changes.yml` guards both directions.** A PR into `main` fails unless its branch contains `main`'s tip (merging it would otherwise revert `main`, a published version bump included). A PR into `next` fails while a back-merge is outstanding, until the `chore/backmerge-*` PR lands. Neither is a required check, so read them before merging.
- **A back-merge PR left open is merged with a merge commit**, never squash or rebase: either leaves `main`'s tip outside `next`'s history and **Prepare a release** keeps refusing. If it happened, open a fresh `main → next` PR and merge it with a merge commit.
- **Hotfixes that genuinely must bypass `next`** still go through a PR to `main`, and that PR must carry its own bump (`pnpm run version`), because `publish.yml` refuses to publish while changesets remain. Afterwards `main` holds a commit `next` lacks: merge the `chore/backmerge-v*` PR that `publish.yml` opens (or open one from `main`'s tip by hand) before the next release, which is blocked until you do.

---

## Build Commands
- Build all packages: `npm run build` (from repo root, uses Turborepo)
- Build generated packages: `npm run build:generated`
- Build API only: `npm run build:api`
- Build Explorer only: `npm run build:explorer`
- Start API server: `npm run start:api` (port 4101)
- Start Explorer UI: `npm run start:explorer` (port 4301)
- Build specific package: `cd packages/PackageName && npm run build`
- **IMPORTANT**: When building individual packages for testing/compilation, always use `npm run build` in the specific package directory

### Build Pipeline
- MJExplorer uses the Angular `application` builder powered by ESBuild and Vite
- Dev server uses Vite with HMR for fast iteration
- Source maps are configured for full debugging support including local packages

### NPM Workspace Management
- This is an NPM workspace monorepo
- **IMPORTANT**: To add dependencies to a specific package:
  - Define dependencies in the individual package's package.json
  - Run `npm install` at the repository root (NOT within the package directory)
  - Never run `npm install` inside individual package directories

## MemberJunction versions — the LTS line AIDP Next runs

AIDP Next runs MemberJunction's 6.1 LTS line, pinned exactly in `aidp-next/package.json`. This repo builds, tests and runs CodeGen against that same version, so what passes here is what runs there (bc-aidp-next-golive#298).

- **Declared ranges.** In a published package, `@memberjunction/*` (and any other app's `@mj-biz-apps/*`) is a **peer** with a caret range, `^6.1.N`, and never appears in `dependencies`: the host installs one copy, and a `~6.1.N` or exact peer makes every 6.2 host install a second 6.1 tree, which splits the ClassFactory. Each peer has an **exact** `6.1.N` entry in the same package's `devDependencies`, where 6.1.N is the version AIDP Next runs; that anchor is what installs locally, so builds, tests and CodeGen still run against it. Never an edge or prerelease range (`6.1.0-edge.x` sorts *before* 6.1.0 and has none of the LTS fixes). `.github/scripts/check-dependency-model.mjs` enforces this in CI. Packages MJ versions separately (`@memberjunction/connector-*`, `@memberjunction/skyway-*`) keep their own ranges.
- **`pnpm.overrides`.** `@memberjunction/core` and `@memberjunction/global` are pinned **exactly** to AIDP Next's version (for example `"6.1.5"`), not to a range. A range override can still leave two copies of `core`, and two copies split the ClassFactory: registrations land in one factory while the resolver reads the other, and nothing errors. Overrides are workspace-local and never published. Do not exact-pin sibling `@mj-biz-apps/*` packages here; how the apps declare each other is bc-aidp-next-golive#265.
- **One copy of each.** After any install, `pnpm why @memberjunction/core` must show a single version. A sibling app package that exact-pins an old MJ build brings a second copy in (for example `@mj-biz-apps/common-ng@5.37.0` pinned edge.3 packages); fix it by raising that package's floor, not with more overrides.
- **Bumping to a new 6.1.N**, when AIDP Next moves: update every `^6.1.N` peer floor, every exact `6.1.N` devDependencies anchor and both overrides; `pnpm install`; confirm one copy; run `node scripts/sync-app-version.mjs` and commit `mj-app.json` (CI's `sync-app-version` spec checks it on every PR); rebuild the database from migrations on MJ core `v6.1.N` and regenerate (below); run the full test suite; add a `patch` changeset; commit the lockfile. If CI then fails on the lockfile although a clean local install works, GitHub is testing the merge with `next`: merge `next` in, run `pnpm install --no-frozen-lockfile`, and commit the lockfile.
- **Never patch MemberJunction.** No `pnpm patch`, `patchedDependencies`, patch-package or `sed` against `@memberjunction/*` `dist/`. That is AIDP Next's hard rule (`.github/workflows/MJ_PATCH_REGISTER.md` in aidp-next). Fix MJ on its `next` branch and bring the fix to the line with the `backport lts/6.1` label, or with a hand-port PR against `lts/6.1` when the fix can't be isolated; then wait for the patch release.

### CodeGen output must be reproducible from this repo

Generated files are committed, and AIDP Next ships them as they are: it excludes every `__mj_BizApps*` schema from its own CodeGen and installs the published packages. So the committed output has to be what this repo's toolchain produces from its migrations.

- Run CodeGen only with this repo's pinned MJ version, against a database built from migrations (MJ core `v6.1.N`, then the apps this one depends on, then this repo), after `mj sync push` of `metadata/`.
- Set an AI key in your gitignored `.env`: `AI_VENDOR_API_KEY__GeminiLLM` (every CodeGen prompt ranks Gemini first), or `AI_VENDOR_API_KEY__OpenRouterLLM`. Without one, CodeGen silently drops AI-written output: check-constraint `Validate*()` methods, display names, descriptions and form layouts.
- Never hand-edit generated files, and never paste in generated output from another toolchain or another database. That is how OrderLine lost `OrderHeader`'s `@Field` (bc-aidp-next-golive#295).
- Review what AI wrote. Validators, names and descriptions are not deterministic between runs.
- If CodeGen has to create metadata in the database that the generated code depends on (fields, value lists, relationships, validator code), ship it in a migration in the same PR. Otherwise every host installed from migrations drifts from the code.

## Development Workflow
- **CRITICAL**: After making code changes, always compile the affected package by running `npm run build` in that package's directory to check for TypeScript errors
- Fix all compilation errors before proceeding with additional changes
- **Tasks**: whenever you need to spin up tasks - if they do not require interaction with the user and if they are not interdependent in any way, ALWAYS spin up multiple parallel tasks to work together for faster responses

## Ports
- MJAPI GraphQL server: **4101** (configured via `GRAPHQL_PORT` in `.env`)
- MJExplorer Angular app: **4301** (configured in MJExplorer start script)
- These avoid conflicts with other MJ dev environments (MJ uses 4001/4201)

## Environment Configuration
- The repo root `.env` file contains all configuration (DB, auth, AI keys, etc.)
- `apps/MJAPI/.env` is a **symlink** to `../../.env` - do not create a separate file there
- Angular environment files are in `apps/MJExplorer/src/environments/`

---

## Code Style Guide
- Use TypeScript strict mode and explicit typing
- Always use MemberJunction generated `BaseEntity` sub-classes for all data work for strong typing
- No explicit `any` types - see CRITICAL RULES section above
- Prefer union types over enums for better package exports
- Prefer object shorthand syntax
- Follow existing naming conventions:
  - PascalCase for classes and interfaces
  - **PascalCase for public class members** (properties, methods, `@Input()`, `@Output()`)
  - **camelCase for private/protected class members**
  - camelCase for local variables and function parameters
  - Use descriptive names and avoid abbreviations
- Imports: group imports by type (external, internal, relative)
- Error handling: use try/catch blocks and provide meaningful error messages
- Keep functions focused and concise
- **NEVER use dynamic require() or import() statements** - always use static imports at the top of files unless explicitly requested

### Functional Decomposition Is Mandatory
- **NEVER** write long, monolithic functions that do multiple things
- **ALWAYS** decompose complex operations into smaller, well-named helper functions
- **MAXIMUM** function length should be ~30-40 lines (excluding comments)
- If a function is getting long, STOP and refactor it immediately

---

## MemberJunction Entity and Data Access Patterns

### Entity Object Creation
**Never directly instantiate BaseEntity subclasses** - always use the Metadata system:

```typescript
// WRONG - bypasses MJ class system
const entity = new PersonEntity();

// CORRECT - uses MJ metadata system
const md = new Metadata();
const entity = await md.GetEntityObject<PersonEntity>('Person');
```

### BaseEntity Spread Operator Limitation
**CRITICAL**: Never use the spread operator (`...`) directly on BaseEntity-derived classes. Use `GetAll()` instead:

```typescript
// WRONG
const data = { ...myEntity, extraField: 'value' };

// CORRECT
const data = { ...myEntity.GetAll(), extraField: 'value' };
```

### Server-Side Context User Requirements
When working on server-side code, **ALWAYS** pass `contextUser` to `GetEntityObject` and `RunView` methods:

```typescript
// WRONG - missing contextUser on server
const entity = await md.GetEntityObject<SomeEntity>('Entity Name');

// CORRECT - includes contextUser for server-side operations
const entity = await md.GetEntityObject<SomeEntity>('Entity Name', contextUser);
```

### Loading Records with RunView
```typescript
const rv = new RunView();
const results = await rv.RunView<PersonEntity>({
    EntityName: 'Person',
    ExtraFilter: `LastName='Smith'`,
    OrderBy: 'FirstName ASC',
    ResultType: 'entity_object'  // Returns actual entity objects
});
```

### RunView Error Handling
**Important**: RunView does NOT throw exceptions. Check `Success` property:

```typescript
const result = await rv.RunView<SomeEntity>({...});
if (result.Success) {
    const items = result.Results || [];
} else {
    console.error('Failed:', result.ErrorMessage);
}
```

### ResultType: entity_object vs simple
- Use `entity_object` when you need to **mutate and save** records
- Use `simple` with `Fields` parameter when you only need to **read/display** data
- **DO NOT** use `Fields` parameter with `entity_object` - it is automatically ignored

### Batch Queries with RunViews
Use `RunViews` (plural) for multiple independent queries:

```typescript
const rv = new RunView();
const [people, orgs] = await rv.RunViews([
    { EntityName: 'Person', ExtraFilter: '', ResultType: 'entity_object' },
    { EntityName: 'Organization', ExtraFilter: '', ResultType: 'entity_object' }
]);
```

---

## Angular Development Best Practices

### Change Detection
- Add `ChangeDetectorRef` and use `cdr.detectChanges()` after programmatic changes
- Replace `setTimeout` with `Promise.resolve().then()` for microtask timing

### Input Properties - Use Getter/Setters
```typescript
// GOOD - Precise control with getter/setter
private _myInput: string | null = null;

@Input()
set myInput(value: string | null) {
    const prev = this._myInput;
    this._myInput = value;
    if (value && value !== prev) this.onMyInputChanged(value);
}
get myInput(): string | null { return this._myInput; }
```

### Loading Indicators
- **ALWAYS** use the `<mj-loading>` component from `@memberjunction/ng-shared-generic`
- **NEVER** create custom spinners

### Dialog Button Placement
- **Confirm/Submit buttons go on the LEFT**, Cancel buttons on the RIGHT

### Icon Libraries
- **Primary**: Font Awesome (already included)

---

## CodeGen

This repo uses MemberJunction's CodeGen system to generate entity and action subclasses. The generated code lives in:
- `packages/Entities/` - Entity TypeScript classes with Zod schemas
- `packages/Actions/` - Action TypeScript classes
- `packages/Server/src/generated/` - GraphQL resolvers and class registrations
- `packages/Angular/src/lib/generated/` - Angular form components and module

**Key rules:**
- Never manually edit files in generated directories - CodeGen will overwrite them
- Always run CodeGen after database schema changes
- Run `npm run mj:codegen` from repo root to regenerate

## Database Migrations
- Run `npm run mj:migrate` from repo root
- See MJ documentation for migration file format and conventions
- Never include `__mj_CreatedAt`/`__mj_UpdatedAt` columns in CREATE TABLE - CodeGen handles them
- Never create indexes for foreign key columns - CodeGen creates them automatically

---

## Debugging

### VSCode Launch Configurations
- **MJAPI**: Node.js debugger with source maps for local packages
- **MJExplorer**: Chrome debugger (port 4301) with source maps
- **MJExplorer (attach)**: Attach to existing Chrome on port 9222
- **Full Stack**: Compound configuration running both MJAPI + MJExplorer

### Source Map Scoping
Source maps are scoped to local packages only (`apps/MJAPI/**`, `packages/Entities/**`, `packages/Actions/**`, `packages/Server/**`, `packages/Angular/**`). Third-party packages and node_modules are excluded to avoid noise.

---

## Performance Best Practices

### Batch Database Operations
- Use `RunViews` (plural) instead of multiple `RunView` calls
- Group related queries together in a single batch operation

### Avoid Per-Item Queries in Loops
- **NEVER** make RunView calls inside loops
- Load all data once, then process client-side

### Use View Fields Instead of Lookups
- Most MJ views include denormalized fields from related entities
- Use the denormalized field directly instead of a separate lookup query

---

## GitHub Repository
- Repository: https://github.com/MemberJunction/bizapps-common
- Default branch: `next` (the integration branch, where feature PRs land)
- Release branch: `main` (a merge to it publishes)
- Feature PRs target `next`. Release PRs target `main`.
- See "Branching Model" section above for the full flow.

## Purpose

**Consumer blindness.** Common must not name, refresh, cascade into, or heal consumer apps (Orders, Accounting, Tasks, …). FKs and package deps point **up** only. Shipped entities have `CascadeDeletes = false`. CodeGen cascade SQL is intra-schema unless a host sets `allowCrossSchemaCascadeDeletes` (do not turn that on here).

This repository provides foundational business entities that can be consumed by other MemberJunction applications. Applications can:

1. Reference the BizApps entities directly in their own migrations/schemas
2. Link their application-specific entities to Person, Organization, etc.
3. Extend the core entities with additional fields or relationships

**Example**: The Committees application links Committee Members to BizApps Person records.

## Angular pinning model

**Angular pinning model** (family-wide, 2026-08-07, with MemberJunction/MJ#3580): `@angular/*` peers in `packages/*` are **caret ranges at the platform pin** (`^21.1.3`) — compatibility claims, never exact. Each package that consumes Angular **anchors** the concrete version with exact `21.1.3` entries in its own `devDependencies`; the anchor is what actually installs. In the shared pnpm dev workspace `auto-install-peers=true` turns unanchored peer ranges into install instructions, which is how two copies of `@angular/core` ended up installed family-wide. Rev anchors with the era platform pin, never with MJ pins.
