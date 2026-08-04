# Tracking: move the enriched views to MJ layered base views

**Blocked on:** [MemberJunction/MJ#3419](https://github.com/MemberJunction/MJ/pull/3419) — *CodeGen: layered base views*
**Affects:** `vwPeopleExtended`, `vwOrganizationsExtended` (`migrations/V202602271454__v1.0.x_Enriched_Views.sql`)

## What we do today

Both entities are `BaseViewGenerated = 0` with a hand-written enriched view. Each one restates the
CodeGen-generated shape — the FK denormalisation joins — and then adds the interesting part
(`DisplayName`, primary address, primary contacts, employer).

The enriched columns are the point and are worth having. The restated half is pure liability:

- **A new foreign key on `Person` or `Organization` silently loses its display field.** Nothing
  regenerates the join, so the column is *absent* rather than wrong — nothing errors, and no test
  notices until somebody asks why a name is blank.
- **These views are frozen at whatever CodeGen produced when they were written.** Geo columns and
  recursive root-ID columns both arrived afterwards; neither view has them.
- `vwOrganizationsExtended` already depends on the generated `fnOrganizationParentID_GetRootID`, so
  the coupling to generated output exists — it just has to be maintained by hand.

## What changes once MJ ships #3419

`Entity.GeneratedBaseViewName` lets CodeGen keep generating the whole view under an inner name while
this app owns a thin wrapper:

```sql
CREATE VIEW [__mj_BizAppsCommon].[vwPeopleExtended] AS
SELECT g.*,
       TRIM(...) AS [DisplayName],
       addr.Line1 AS [PrimaryAddressLine1],
       ...
FROM   [__mj_BizAppsCommon].[vwPeopleGenerated] g
LEFT JOIN ...;
```

The FK denormalisation block disappears from our file entirely and starts regenerating. A future
foreign key appears on its own.

## Plan

1. Upgrade to the MJ release carrying #3419.
2. Set `BaseViewGenerated = 0` (already) and `GeneratedBaseViewName` on `MJ.BizApps.Common: People`
   and `MJ.BizApps.Common: Organizations`.
3. Rewrite `V202602271454__v1.0.x_Enriched_Views.sql` to select from the generated inner views and
   drop the hand-restated FK joins.
4. Rebuild → CodeGen → verify the enriched columns still register as virtual `EntityField` rows.
5. Confirm the ordering note at the top of that migration still holds: it must run **after** CodeGen,
   because it now depends on the generated inner views as well as the root-ID function.

## Worth checking during the move

The generated inner view will bring columns the current hand-written one lacks (geo, root-ID). That is
the point, but it is also a change in shape for anything doing `SELECT *` against these views —
`vwPeopleExtended` is consumed by **bizapps-orders**, whose `vwOrderHeaders` joins to it for
`BillToPerson`/`ShipToPerson` display fields. Worth a check that nothing depends on the current column
list positionally.
