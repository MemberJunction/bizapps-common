# @mj-biz-apps/common-core-entities-server

## 5.39.0

### Patch Changes

- 7887d5d: License declarations now agree on BUSL-1.1 everywhere.

  `LICENSE`, `package.json`, `mj-app.json` and every workspace package already declared
  BUSL-1.1. Two statements still said ISC: the README badge, which is the first license
  statement a reader meets and so outranked all of them in practice, and the `mj-app.json`
  sample in `docs/open-app.md` — this repo is the reference Open App, so that snippet is
  copied into new repos and is how the wrong value spreads. The badge now links to `LICENSE`.

- Updated dependencies [8657091]
- Updated dependencies [b6b2b64]
- Updated dependencies [7887d5d]
  - @mj-biz-apps/common-activity-sync@5.39.0
  - @mj-biz-apps/common-entities@5.39.0

## 5.38.0

### Patch Changes

- Updated dependencies [4c27078]
- Updated dependencies [4c27078]
  - @mj-biz-apps/common-entities@5.38.0
  - @mj-biz-apps/common-activity-sync@5.38.0

## 5.37.0

### Minor Changes

- d73a3af: Activity Sync Engine P4/P5 — engine, writer, identity resolver, fixture and Graph providers.

  Graph refuses live fetch until an Exchange Application Access Policy exists. Synced
  activities are Visibility=Private. Unmatched addresses become unresolved ActivityLinks.
  Dry runs never set WatermarkAfter. Exclusions run first and are absolute.

### Patch Changes

- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
- Updated dependencies [d73a3af]
  - @mj-biz-apps/common-entities@5.37.0
  - @mj-biz-apps/common-activity-sync@5.37.0

## 5.36.0

### Patch Changes

- Updated dependencies [60804ac]
- Updated dependencies [6fe1f09]
  - @mj-biz-apps/common-entities@5.36.0

## 5.35.1

### Patch Changes

- eac151e: Declare BUSL-1.1 in mj-app.json. The LICENSE file and every package already
  state BUSL-1.1; the manifest still said ISC, so anything reading it saw the
  wrong license.
- Updated dependencies [eac151e]
  - @mj-biz-apps/common-entities@5.35.1

## 5.35.0

### Patch Changes

- Updated dependencies [1f07f2a]
- Updated dependencies [026b83e]
- Updated dependencies [4b4bcaa]
- Updated dependencies [cbd0e27]
  - @mj-biz-apps/common-entities@5.35.0

## 5.34.0

### Patch Changes

- e69c364: Import UserCache from @memberjunction/generic-database-provider — MJ #3734 moved it out of @memberjunction/sqlserver-dataprovider with no re-export, so this package failed to compile against MJ next. Peer dependency swapped accordingly (PersonEntityServer was the only sqlserver-dataprovider usage). Requires the first MJ edge release that carries #3734.
- Updated dependencies [2c8c1bc]
- Updated dependencies [ab9f88e]
- Updated dependencies [2f8dd2b]
  - @mj-biz-apps/common-entities@5.34.0

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
