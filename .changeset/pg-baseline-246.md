---
'@mj-biz-apps/common-entities': minor
---

PostgreSQL baseline covering every migration through v5.63.x, so the app installs on a PostgreSQL host. Fresh installs start from it and skip the released v5.54–v5.61 PostgreSQL files, which never applied on PostgreSQL; the baseline carries corrected versions of them. Existing installs are unaffected.
