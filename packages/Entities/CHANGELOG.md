# Change Log - mj_generatedentities

## 5.33.2

### Patch Changes

- c2974b6: Migrate the workspace from npm to pnpm, and release the peer-range fix from #51.

  No published package's code, types, metadata or migrations change — this is a
  build-tooling change plus a dependency-range correction, which is why it is a patch.

  **pnpm migration.** `packageManager` moves to `pnpm@10.33.0`, `package-lock.json` is
  replaced by `pnpm-lock.yaml`, the npm `overrides` block moves to `pnpm.overrides`, and
  CI installs with `pnpm install --frozen-lockfile`. Two workspace settings are
  load-bearing and mirror MJ core: `linkWorkspacePackages: true` (pnpm 10 defaults it
  false, which resolves this repo's exact-pinned internal packages from the registry
  instead of linking them locally) and an `onlyBuiltDependencies` allowlist (pnpm 10 runs
  no dependency build scripts without one).

  pnpm's non-hoisted layout also surfaced one latent defect: `apps/MJAPI` runs `vitest run`
  but never declared `vitest` anywhere in the repo, so it had been resolving from a hoisted
  transitive copy. It is now declared. That app is private and unpublished, so this does
  not affect consumers.

  **Why this ships #51.** The peer-range fix merged to `next` without a changeset, so it
  had no path to npm. This release carries it: every `@memberjunction/*` peer across the
  five published packages moves from an exact `6.1.0-edge.0` pin to `^6.1.0-edge.0`.

  That matters for consumers. An exact peer pin says "this build and no other", so a
  consumer on `6.1.0-edge.1` — which is the rest of the estate — had a mismatch. Under npm
  with `legacy-peer-deps` the mismatch was silently ignored; under pnpm it is satisfied by
  installing a **second copy** of ~100 MemberJunction packages. Two `@memberjunction/global`
  instances means two `MJGlobal` singletons and a split `ClassFactory` registry: it compiles
  cleanly and fails at runtime. A caret on a prerelease matches other prereleases sharing
  the same major.minor.patch, so `^6.1.0-edge.0` is satisfied by an existing edge.1 copy and
  the duplicate disappears.

  Consumers on a MemberJunction 6.x line should take this release and will need no
  `overrides` workaround to deduplicate MJ.

## 5.33.1

### Patch Changes

- 6eae25b: Upgrade to MemberJunction 6.1.0-edge.0. All `@memberjunction/*` dependencies and peer ranges now require the 6.x line, and the Open App manifest's `mjVersionRange` is `>=6.1.0 <7.0.0` — consumers must be on a MemberJunction 6.x environment. No source changes were required: the MJ 6.x breaking-change surface (integration connectors, ActionExecutionLog.Params, AIEngine similarity APIs, system-catalog SQL, HS256 JWTs, negation-form RLS filters) does not touch this codebase.

## 5.33.0

### Minor Changes

- 1ffb2a5: Deprecate Person LinkedUserID

## 5.32.0

### Minor Changes

- b5f34d2: PG fixes for CanonicalSchema and CodeGen

## 5.31.3

### Patch Changes

- 5346c70: Upgraded BAC to MJ 5.44; PostgreSQL install verified, seeds fixed.

## 5.31.2

### Patch Changes

- 969954b: fix(common): lowercase PostgreSQL app schema name in migrations to match physical schema

## 5.31.1

## 5.31.0

### Minor Changes

- 64200c7: Added PG support and MJ upgrade to 5.40.2

## 5.30.1

### Patch Changes

- a46ab44: Fix publish CI/CD to sync mj-app.json version and mjVersionRange automatically during release

## 5.30.0

### Patch Changes

- 49d5b9c: Add CoreEntitiesServer package with PersonEntityServer and LinkedUserID unique constraint

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.

This log was last generated on Sun, 14 Apr 2024 15:50:05 GMT and should not be manually modified.

<!-- Start content -->

## 1.0.3

Sun, 14 Apr 2024 15:50:05 GMT

### Patches

- Bump @memberjunction/core to v1.0.9
- Bump @memberjunction/global to v1.0.9

## 1.0.2

Sat, 13 Apr 2024 02:32:44 GMT

### Patches

- Update build and publish automation (craig.adam@bluecypress.io)
- Bump @memberjunction/core to v1.0.8
- Bump @memberjunction/global to v1.0.8
