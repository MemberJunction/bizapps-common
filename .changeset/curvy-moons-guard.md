---
"@mj-biz-apps/common-ng": patch
---

Security hardening: escape `@Input()`-sourced values interpolated into RunView ExtraFilters (address editor, org hierarchy tree, person job functions, relationship list), open contact-method links with `noopener,noreferrer` to prevent reverse tabnabbing.
