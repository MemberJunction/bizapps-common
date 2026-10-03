---
"@mj-biz-apps/common-ng": patch
---

The directory dashboard's "people added" bars count and name business days
(MemberJunction/bc-aidp-next-golive#168). The summary query bucketed `__mj_CreatedAt` by UTC day and
the labels named UTC weekdays, so on a Thursday evening in Chicago the current bar read "Fri" and
held that evening's signups. The query (`Common: Directory Dashboard Summary`, under `metadata/`)
now buckets with `fnBusinessDayOf` against `fnBusinessToday()`, and the labels come from
`BusinessTimeZoneEngine.Today()`. The query change reaches hosts through this release's
`Metadata_Sync`. The unused local-day helpers `CountByDay` and `LocalDayKey` are removed (not part of
the package's public API).
