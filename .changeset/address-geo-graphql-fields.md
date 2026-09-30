---
"@mj-biz-apps/common-server": patch
"@mj-biz-apps/common-entities": patch
---

Addresses open again. Every Address single-record load failed with `Cannot query field
"_mj__Latitude" on type "mjBizAppsCommonAddress_"` (MemberJunction/bc-aidp-next-golive#295).
`vwAddresses` exposes the native coordinates as MJ's geo virtual fields `__mj_Latitude` and
`__mj_Longitude`, and migration V202609101800 registers both as EntityFields. The client asks for
every EntityField, but the Address GraphQL type was not regenerated after that migration, so it
lacked both. It now declares them as nullable floats, as Activities, Organizations and People
already do. The Address entity class also gains the matching read-only `__mj_Latitude` and
`__mj_Longitude` getters.
