---
'@mj-biz-apps/common-server': patch
---

Make `COUNT(*)` cheap on `vwPeople` and `vwOrganizations`.

MJ's RunView computes `TotalRowCount` as an unfiltered `SELECT COUNT(*)` over the base view for
pagination. Both layered wrappers resolve the primary address and the primary email/phone with
`LEFT OUTER JOIN`s, and SQL Server cannot prove a `LEFT JOIN` is 1:1 — so it evaluates all of the
enrichment for every row purely to count rows.

Measured at production scale: Organizations (327,575 rows) counted in 36ms through the inner
generated view and 11,939ms through the wrapper; People (1,063,303 rows) 94ms versus 4,775ms.

The consequence is not a slow panel. The record page issues its related-entity panels as one
batched `RunViews` call, so a twelve-second count inside that batch pushes the request past the
30s timeout and fails the whole batch — **every tab on an Organization record returns 504**, not
just the one that needed the count. Nothing in the UI points at the count, so this presents as
unrelated panels breaking.

Each enrichment is now an `OUTER APPLY (SELECT TOP 1 ...)` — the construct this file already used
for `vwPeople`'s employer lookup, applied consistently to the rest. `TOP 1` is provably at most one
row, so the optimizer eliminates it for `COUNT(*)` while returning identical values for `SELECT`.

Value-identical, not merely equivalent: verified on 327,575 organizations and 1,063,303 people that
no row has a duplicate primary address, email or phone, and that row counts, non-null value
fingerprints and column sets are unchanged before and after. Where a duplicate primary ever did
exist the `LEFT JOIN` silently multiplied the row and inflated every count built on it, so this also
removes a latent correctness bug rather than trading correctness for speed.

Two smaller fixes ride along. `CAST(g.[ID] AS NVARCHAR(MAX))` matched the polymorphic `AddressLink`
whose `RecordID` is `nvarchar(700)`; comparing against an `NVARCHAR(MAX)` expression prevented a seek
on `IX_AddressLink_EntityRecord_Primary` and forced a scan. And `Organization.Name` had no index
behind the directory's sort, so every load sorted the full table — 11,500ms at 327k rows, 14ms with
`IX_Organization_Name`.

No column is added, removed or renamed, so no EntityField or CodeGen changes are required.
