# @mj-biz-apps/common-actions

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
