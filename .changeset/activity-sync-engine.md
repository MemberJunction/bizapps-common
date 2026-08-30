---
'@mj-biz-apps/common-activity-sync': minor
'@mj-biz-apps/common-core-entities-server': minor
---

Activity Sync Engine P4/P5 — engine, writer, identity resolver, fixture and Graph providers.

Graph refuses live fetch until an Exchange Application Access Policy exists. Synced
activities are Visibility=Private. Unmatched addresses become unresolved ActivityLinks.
Dry runs never set WatermarkAfter. Exclusions run first and are absolute.
