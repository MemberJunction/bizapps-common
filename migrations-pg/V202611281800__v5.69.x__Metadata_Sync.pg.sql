-- =============================================================================================
-- PostgreSQL counterpart of V202611281800__v5.69.x__Metadata_Sync.sql
-- =============================================================================================
-- Same row, same values, same guard as the T-SQL file; see its header for what ships and why.
-- =============================================================================================

SET search_path TO __mj_bizappscommon, public;

UPDATE ${mjSchema}."EntityField"
SET "IncludeInUserSearchAPI" = TRUE,
    "UserSearchPredicateAPI" = 'BeginsWith',
    "AutoUpdateIncludeInUserSearchAPI" = FALSE,
    "AutoUpdateUserSearchPredicate" = FALSE
WHERE "EntityID" = 'C70448F9-9792-41D7-A82C-784B66429D54' -- MJ_BizApps_Common: Organizations
  AND "Name" = 'WebsiteDomain'
  AND "AutoUpdateIncludeInUserSearchAPI" = TRUE;
