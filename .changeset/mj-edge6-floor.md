---
"@mj-biz-apps/common-actions": minor
"@mj-biz-apps/common-ng": minor
"@mj-biz-apps/common-core-entities-server": minor
---

Require the MemberJunction release this branch actually needs, in every package that asks for it.

The calendar transport compiles against `GetEvents`, which `6.1.0-edge.5` does not carry, so the
declared range moved to `^6.1.0-edge.6` across the workspace. Three published packages took that
bump without a changeset naming them — `common-actions`, `common-ng` and
`common-core-entities-server` — so they would never have versioned, and the raised floor would
never have reached npm. A consumer installing them would resolve a MemberJunction that cannot
satisfy their own dependency range.

`mj-app.json`'s `mjVersionRange` moves with them, from `>=6.1.0-edge.5` to `>=6.1.0-edge.6`. It is
the manifest `mj app install` checks, and leaving it behind meant a host sitting on exactly edge.5
satisfied the manifest and then failed to install.
