---
"@mj-biz-apps/common-entities": minor
---

`spCreatePerson` and `spUpdatePerson` take `@PhotoURL` as `NVARCHAR(MAX)` again. The v5.45 migration re-emitted both procedures with `NVARCHAR(1000)` while the column stayed `NVARCHAR(MAX)`, so every save of a photo longer than 1,000 characters (inline avatars, through Explorer, GraphQL or `mj sync push`) was silently truncated. Photos already stored truncated are not repaired; hosts that seeded inline photos should re-push them. The clean-room gate gains a `NARROW` assertion that fails the build when any `spCreate*`/`spUpdate*` parameter is narrower than its column.
