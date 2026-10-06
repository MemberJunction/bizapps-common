---
"@mj-biz-apps/common-entities": minor
---

People and Organizations no longer carry the virtual `__mj_Latitude` / `__mj_Longitude` fields
(migration `V202610062130__v5.51.x__Drop_Person_Organization_Virtual_Geo_Fields`; #215). MJ CodeGen
joins `vwRecordGeoCodes` only for geo-source entities, so once a host ran CodeGen these four
EntityField rows named columns `vwPeople` / `vwOrganizations` no longer produce: reads selected missing
columns and every later CodeGen run failed on `UQ_EntityField_EntityID_Sequence`. The migration
recreates `vwPeopleGenerated` / `vwOrganizationsGenerated` in CodeGen's shape, refreshes the two
wrappers, and deletes the four rows. Coordinates for both come from the primary Address
(`PrimaryAddressLatitude` / `PrimaryAddressLongitude`).
