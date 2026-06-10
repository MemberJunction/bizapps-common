# @mj-biz-apps/common-server

## 5.31.0

### Minor Changes

- 64200c7: Added PG support and MJ upgrade to 5.40.2

### Patch Changes

- Updated dependencies [64200c7]
  - @mj-biz-apps/common-core-entities-server@5.31.0
  - @mj-biz-apps/common-entities@5.31.0
  - @mj-biz-apps/common-actions@5.31.0

## 5.30.1

### Patch Changes

- Updated dependencies [a46ab44]
  - @mj-biz-apps/common-entities@5.30.1
  - @mj-biz-apps/common-core-entities-server@5.30.1
  - @mj-biz-apps/common-actions@5.30.1

## 5.30.0

### Patch Changes

- 49d5b9c: Add CoreEntitiesServer package with PersonEntityServer and LinkedUserID unique constraint
- Updated dependencies [49d5b9c]
  - @mj-biz-apps/common-core-entities-server@5.30.0
  - @mj-biz-apps/common-entities@5.30.0
  - @mj-biz-apps/common-actions@5.30.0

## 5.29.0

### Minor Changes

- b0b2d13: Adds BAC's first Metadata_Sync migration plus a Person.DisplayName computed column so consumers get correct seed data and friendly entity display names

### Patch Changes

- Updated dependencies [b0b2d13]
  - @mj-biz-apps/common-entities@5.29.0
  - @mj-biz-apps/common-actions@5.29.0

## 5.28.0

### Minor Changes

- b61bb46: Upgrade MJ to 5.33.0, regenerate BAC's CRUD sprocs with v5.33 tolerant signatures, and enable cascade deletes on Organizations.

### Patch Changes

- Updated dependencies [b61bb46]
  - @mj-biz-apps/common-entities@5.28.0
  - @mj-biz-apps/common-actions@5.28.0

## 5.27.1

### Patch Changes

- fa421da: Move `@memberjunction/*` and `@angular/*` deps to peerDependencies so consuming MJ apps resolve a single instance and avoid duplicate singletons.
- Updated dependencies [fa421da]
  - @mj-biz-apps/common-entities@5.27.1
  - @mj-biz-apps/common-actions@5.27.1
