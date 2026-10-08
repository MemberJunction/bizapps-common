---
"@mj-biz-apps/common-entities": minor
---

Field-level security is now on for `MJ_BizApps_Common: People`. It lets an app such as Collaboration give guest and participant roles People's name and email fields without phone, birth date, gender or address. The migration also gives every role that can read People a permission row on each field, computed from the host's own People permissions with MemberJunction's snapshot rule, so no role's access changes until an administrator tightens a field. If a role ever loses People fields after this release, save any People Entity Permission in the UI: MemberJunction then reconciles People's field permissions for all roles. Requires MemberJunction 6.1.5 or later (already the floor).
