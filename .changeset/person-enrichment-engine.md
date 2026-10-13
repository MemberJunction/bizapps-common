---
"@mj-biz-apps/common-enrichment": minor
"@mj-biz-apps/common-server": minor
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-actions": minor
"@mj-biz-apps/common-core-entities-server": minor
"@mj-biz-apps/common-activity-sync": minor
"@mj-biz-apps/common-ng": minor
---

Person enrichment engine (plan Phase 3). New package `@mj-biz-apps/common-enrichment`: the
`BaseEnrichmentProvider` contract, the engine on MemberJunction's record-set processor, the write
rules for education, employment, LinkedIn and vendor identity rows, the cost estimator, and a fixture
provider. `Common.EnrichPeople` (metadata action, ships with the release seed) runs it; Preview mode
counts and prices a run without calling a vendor. No vendor provider yet: Apollo and PDL arrive with
Phase 4.

Raises every package's MemberJunction floor from `^6.1.5` to `^6.2.0-edge.3` (`mj-app.json`
`mjVersionRange >=6.2.0-edge.3 <7.0.0`): `ProcessBatch` first shipped in the published
`6.2.0-edge.0`.
