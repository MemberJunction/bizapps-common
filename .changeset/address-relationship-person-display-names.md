---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-server": minor
"@mj-biz-apps/common-ng": minor
---

Readable record names for Addresses, Relationships, Address Links and People.

- **Addresses**: new stored, indexed `DisplayName` column, a one-line label in US order (`123 Main St, Springfield, IL 62701, United States`), with blank parts skipped. It replaces `Line1`, which can be empty, as the name field. `vwAddressLinks.Address` and `vwActivities.Address` now show this label.
- **Relationships**: `vwRelationships` becomes a layered view (`vwRelationshipsGenerated` plus a thin wrapper) that adds `DisplayName` = `From → To (Type)`, for example `Jane Smith → Acme (Employee)`. It replaces `Title` as the name field.
- **Address Links**: the name field is now `Address` (the linked address's label) instead of `AddressType`.
- **People**: `DisplayName` now skips blank name parts and includes `Suffix` (`John Smith Jr.`).
- **Geocoding**: Address's `Line1`, `City`, `StateProvince`, `PostalCode` and `Country` are now tagged `GeoAddress` / `GeoCity` / `GeoStateProvince` / `GeoPostalCode` / `GeoCountry`, so an Address saved without coordinates can be geocoded from its parts (the new `DisplayName` stays untagged). Activity's free-text `Location` is no longer tagged `GeoAddress`, so saving an Activity no longer calls the geocoder or writes a failed `RecordGeoCode` row; `vwActivities` drops the `vwRecordGeoCodes` join and Activities lose the `__mj_Latitude` / `__mj_Longitude` fields (`_mj__Latitude` / `_mj__Longitude` in GraphQL). Address Links are pinned as not geocoded.

Five migrations (`V202610131635`, `V202610131636`, `V202610131637`, `V202610131950`, `V202610132305`). The name-field settings and the Address geo tags reach hosts in the release metadata seed. PostgreSQL counterparts are left to the release build.
