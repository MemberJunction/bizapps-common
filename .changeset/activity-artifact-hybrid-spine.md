---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-server": minor
"@mj-biz-apps/common-ng": minor
---

Add additive, nullable `Activity.ArtifactID` foreign key referencing `[__mj].[Artifact]([ID])` with filtered nonclustered index `IDX_AUTO_MJ_FKEY_Activity_ArtifactID` (`WHERE [ArtifactID] IS NOT NULL`) and deterministic PostgreSQL `.pg.sql` parity (`split-bake v1`), establishing `Common.Activity` as a Category B Hybrid Spine. Preserves `<2s` frictionless quick capture (`ArtifactID = NULL`, zero auto-created Artifacts) while adding opt-in linked MJ Doc hydration, badges, picker/expand/unlink UI components (`<bizapps-activity-composer>`, `<bizapps-activity-artifact-badge>`, `<bizapps-activity-artifact-section>`), OpenApp v3 `<mj-page-layout>` resource parity, dual-DBMS cross-stack integration tests, and the MJ Docs vs. MJ: Comments vs. Quick Notes rubric.
