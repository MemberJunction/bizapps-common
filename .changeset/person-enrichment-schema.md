---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-server": minor
"@mj-biz-apps/common-ng": minor
---

Person enrichment schema (plan Phase 2). New entities `Enrichment Providers`, `Enrichment Provider
Rates`, `Person Educations` and `Person External Identities`, and `Source` / `SourceSystem`
provenance columns on `Relationships` (existing rows become `Manual`; `spCreateRelationship` and
`spUpdateRelationship` take them as optional parameters, so existing callers are unaffected). The
nine CHECK-constraint validators for the new constraints ship in the migration and are pinned in
`metadata/generated-codes/`. The Person form gains Person Educations and Person External Identities
sections.
