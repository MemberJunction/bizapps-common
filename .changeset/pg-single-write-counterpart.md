---
"@mj-biz-apps/common-entities": minor
---

Add the PostgreSQL counterpart of the single-write `spUpdate*` / trigger-guard migration. It changes nothing on PostgreSQL, whose `__mj_UpdatedAt` triggers are already BEFORE UPDATE triggers that stamp the row in one write; it keeps the two migration sets paired for the release gate.
