---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-server': minor
'@mj-biz-apps/common-ng': minor
---

Activity Sync — register the `ActivitySyncExclusion` virtual field on Activity Sync Run Details. V202608301900 shipped the view column and name map without the EntityField, so on a from-scratch install BaseEntity's positional save-capture saw 21 view columns against 20 fields and every Run Detail save failed silently. The migration inserts the field at sequence 19 (bumping the trailing virtuals descending, as V202608261015 did) and the generated entity class, GraphQL schema and form component carry the field.
