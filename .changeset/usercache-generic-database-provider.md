---
"@mj-biz-apps/common-core-entities-server": minor
---

Import UserCache from @memberjunction/generic-database-provider — MJ #3734 moved it out of @memberjunction/sqlserver-dataprovider with no re-export, so this package failed to compile against MJ next. PersonEntityServer was the only sqlserver-dataprovider usage, so the peer dependency swaps over entirely.

Minor rather than patch: consumers must change which MJ package they install as a peer.

**Requires an MJ edge release that carries #3734.** No published MJ version has UserCache in generic-database-provider yet — 6.1.0-edge.1 was cut 2026-08-08, before the refactor merged — so the peer floor is left at `^6.1.0-edge.0` to match the sibling peers rather than implying edge.1 is a working minimum. Bump the floor to the first edge release that ships #3734 once it exists.
