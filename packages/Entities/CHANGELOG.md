# Change Log - mj_generatedentities

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
