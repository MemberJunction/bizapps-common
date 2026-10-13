---
'@mj-biz-apps/common-ng': minor
---

Adds a Staff section to the Organization form: the organization's active Employee relationships as headline figures and a staff table. Adds `OrganizationStaffContributor`, a ClassFactory plug-in point other apps register against to add their own figures and per-person columns to that section; the highest-priority registration wins per key, and one failing contributor never hides the others.
