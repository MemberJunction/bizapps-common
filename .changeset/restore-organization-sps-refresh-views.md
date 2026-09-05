---
"@mj-biz-apps/common-entities": minor
---

Restore the Organization create/update/delete procedures to their current CodeGen definitions (V202609051800 had re-introduced cascade deletes from an older capture), refresh the views that select PhotoURL/LogoURL after the NVARCHAR(MAX) widening, and reference the core schema via ${mjSchema} (loom #12 WP1 follow-up).
