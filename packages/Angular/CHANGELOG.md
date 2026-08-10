# @mj-biz-apps/common-ng

## 5.33.2

### Patch Changes

- Updated dependencies [c2974b6]
  - @mj-biz-apps/common-entities@5.33.2

## 5.33.1

### Patch Changes

- Updated dependencies [6eae25b]
  - @mj-biz-apps/common-entities@5.33.1

## 5.33.0

### Minor Changes

- 2c33643: Decouple Person from MJ User (fixes #36): saving a Person no longer provisions, links, syncs, or deactivates MJ User accounts. `PersonEntityServer` is reduced to a deprecated compatibility shell (protected helpers retained for downstream subclasses); the `LinkedUserID` EntityField is marked Status='Deprecated' via migration; the People entity is declared an overlapping IS-A parent (`AllowMultipleSubtypes=1`) so platform layers (e.g., BCSaaS 'BC: People') can own the person-to-user binding as an IS-A subtype. The LinkedUserID column remains physically in place; data disposition is owned by the platform layer's migration. The custom Person form no longer renders LinkedUserID.

### Patch Changes

- Updated dependencies [1ffb2a5]
  - @mj-biz-apps/common-entities@5.33.0

## 5.32.0

### Minor Changes

- b5f34d2: PG fixes for CanonicalSchema and CodeGen

### Patch Changes

- Updated dependencies [b5f34d2]
  - @mj-biz-apps/common-entities@5.32.0

## 5.31.3

### Patch Changes

- 5346c70: Upgraded BAC to MJ 5.44; PostgreSQL install verified, seeds fixed.
- Updated dependencies [5346c70]
  - @mj-biz-apps/common-entities@5.31.3

## 5.31.2

### Patch Changes

- 969954b: fix(common): lowercase PostgreSQL app schema name in migrations to match physical schema
- Updated dependencies [969954b]
  - @mj-biz-apps/common-entities@5.31.2

## 5.31.1

### Patch Changes

- @mj-biz-apps/common-entities@5.31.1

## 5.31.0

### Minor Changes

- 64200c7: Added PG support and MJ upgrade to 5.40.2

### Patch Changes

- Updated dependencies [64200c7]
  - @mj-biz-apps/common-entities@5.31.0

## 5.30.1

### Patch Changes

- Updated dependencies [a46ab44]
  - @mj-biz-apps/common-entities@5.30.1

## 5.30.0

### Patch Changes

- Updated dependencies [49d5b9c]
  - @mj-biz-apps/common-entities@5.30.0

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

### Patch Changes

- Updated dependencies [b0b2d13]
  - @mj-biz-apps/common-entities@5.29.0

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

### Patch Changes

- Updated dependencies [b61bb46]
  - @mj-biz-apps/common-entities@5.28.0

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.
- Updated dependencies [fa421da]
  - @mj-biz-apps/common-entities@5.27.1
