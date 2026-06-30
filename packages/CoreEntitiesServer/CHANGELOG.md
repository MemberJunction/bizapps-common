# @mj-biz-apps/common-core-entities-server

## 5.31.2

### Patch Changes

- 969954b: fix(common): lowercase PostgreSQL app schema name in migrations to match physical schema
- Updated dependencies [969954b]
  - @mj-biz-apps/common-entities@5.31.2

## 5.31.1

### Patch Changes

- 6e0ea6c: Add system user guards to PersonEntityServer to prevent syncUserRecord and autoLinkUser from modifying the MJ system user record. Change method visibility from private to protected for downstream overridability.
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

### Minor Changes

- 49d5b9c: Add CoreEntitiesServer package with PersonEntityServer and LinkedUserID unique constraint

### Patch Changes

- Updated dependencies [49d5b9c]
  - @mj-biz-apps/common-entities@5.30.0
