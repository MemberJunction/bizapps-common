---
"@mj-biz-apps/common-actions": patch
"@mj-biz-apps/common-activity-sync": patch
"@mj-biz-apps/common-core-entities-server": patch
"@mj-biz-apps/common-entities": patch
"@mj-biz-apps/common-ng": patch
"@mj-biz-apps/common-server": patch
---

MemberJunction packages are peer dependencies with caret ranges (`^6.1.5`, no `~`, nothing in
`dependencies`), so a 6.2 host keeps one copy of MemberJunction instead of installing a second 6.1
tree. devDependencies and the root `pnpm.overrides` use the same `^6.1.5` floor. Adds
`check-dependency-model` to CI.
