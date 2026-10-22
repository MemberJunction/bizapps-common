---
'@mj-biz-apps/common-entities': minor
---

Release seed for 5.56: `V202610222015__v5.56.x__Metadata_Sync.sql` and its PostgreSQL counterpart carry this release's metadata to hosts, which install by migration and never read `metadata/`. It ships the two party-lookup queries, the form placement of the new `Person.EmailDomain` and `Organization.WebsiteDomain` fields, and `EntityIDFieldName` on two polymorphic `RecordID` fields. People field-level security stays held back, as in every release since 5.48. Also adds the PostgreSQL counterpart of `V202610211654__v5.56.x__Party_Lookup_Domain_Columns`, with the two computed columns written as `GENERATED ALWAYS AS (...) STORED` (the converter cannot translate T-SQL computed columns).
