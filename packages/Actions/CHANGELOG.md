# @mj-biz-apps/common-actions

## 5.33.2

## 5.33.1

## 5.33.0

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

## 5.30.0

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.
