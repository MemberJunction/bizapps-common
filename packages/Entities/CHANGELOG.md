# Change Log - mj_generatedentities

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
