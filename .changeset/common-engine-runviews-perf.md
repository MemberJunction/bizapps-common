---
"@mj-biz-apps/common-entities": patch
"@mj-biz-apps/common-ng": patch
"@mj-biz-apps/common-activity-sync": patch
---

Add `CommonEngine` (`BaseEngine` / `BaseSingleton`) caching all bounded reference/taxonomy tables with O(1) lookup maps, multi-provider & impersonation safety, permission gating (`GetUserPermisions`), and incremental bounded `People`/`Organizations` ID batching with `BaseEntity` event invalidation. Collapse sequential and `Promise.all` `RunView` calls into batched `rv.RunViews([...])` calls with `RunView.FromMetadataProvider(...)`, narrow `Fields`, and RLS-safe two-step entity reads across `Entities`, `Angular`, and `ActivitySync`. Document the Canonical 5-Rule Performance Standard in `CLAUDE.md` and `AGENTS.md`.
