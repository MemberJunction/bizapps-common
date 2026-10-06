---
"@mj-biz-apps/common-entities": patch
---

Build, test and generate against MemberJunction's 6.1 LTS line, the version AIDP Next runs
(MemberJunction/bc-aidp-next-golive#298). Every `@memberjunction/*` range moves from
`^6.1.0-edge.6` to `~6.1.5`, `mj-app.json` declares `>=6.1.5 <7.0.0`, and the generated code is
regenerated on 6.1.5 from a database built from migrations. Nullable `__mj_` columns such as Address
`__mj_Latitude` / `__mj_Longitude` are now declared nullable in the GraphQL types
(MemberJunction/MJ#4603), so a record with no geocode loads.
