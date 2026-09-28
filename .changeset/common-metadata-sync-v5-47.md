---
'@mj-biz-apps/common-entities': minor
---

`Metadata_Sync` for 5.47: the metadata added or edited since the 5.38 seed now reaches hosts.

`V202609282100` creates the records no migration named until now (job functions, seniority levels,
the sentiment tags, the activity-history query, user views, prompts, record processes, the
`DefaultSellingCompanyID` setting, and six action rows) and carries the edits to records that
already ship: the search-API curation, the Address geo pin, the Image extended types, and the
LogActivity binding changes from #195 and #197.

It also applies the Activity Sync Run Details permissions: the 5.38 seed's update matched no row
on any host, and the Integration row was never seeded. The UI role loses read on that entity and Integration drops to create only, as `metadata/`
declares. The six sentiment tags gain the `DisplayName` MJ core requires.
