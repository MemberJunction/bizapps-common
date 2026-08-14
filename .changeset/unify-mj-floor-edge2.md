---
'@mj-biz-apps/common-entities': patch
---

Unify every `@memberjunction` range at the estate-wide floor `^6.1.0-edge.2` — replacing the
mix of `^6.1.0-edge.0` (the original 6.x upgrade), `^6.1.0-edge.1` (the UserCache peer from
#54), and three exact `6.1.0-edge.0` pins. Pure range change; no code, migrations, or
metadata.
