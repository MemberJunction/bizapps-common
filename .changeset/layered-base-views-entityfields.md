---
'@mj-biz-apps/common-entities': minor
---

Re-register the layered `EntityField` rows after the wrapper views exist, so the Person and
Organization "Primary Address" panels actually populate on a host.

`V202608132239` inserts the 29 EntityField rows for the layered columns and then, 3,000 lines
later, runs `spDeleteUnneededEntityFields` — which compares that metadata against the columns
visible in each entity's `BaseView`. At that point `BaseView` is the application-owned wrapper
(`vwPeople` / `vwOrganizations`), which does not exist yet: it is created by `V202608132240`,
and it has to come second because a view cannot be created over the inner view that the same
migration creates. The columns are invisible, the procedure correctly deletes the rows, and the
panels stay empty.

Verified on a clean database — MJ core plus every bizapps-common migration in order, no CodeGen:
0 of the layered fields registered before this migration, 11 on People and 9 on Organizations
after it.
