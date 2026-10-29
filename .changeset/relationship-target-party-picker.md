---
'@mj-biz-apps/common-ng': patch
---

The relationship list's Add form searches the target person or organization with the fast party picker (nothing listed until two characters, prefix search on indexed columns) instead of the stock lookup. The party picker labels a field by its related name field ("Person"), as read mode does, instead of the key ("Person ID"). Picking a party now also writes the related name field (`ToPerson`, `ToOrganization`), as the stock field does, so a relationship just added shows its target's name instead of "Unknown". New `ClearSearch()` drops a pending search and its hint; the relationship list calls it when the type changes.
