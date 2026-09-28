-- Hand-written PG twin of V202609270930__v5.46.x__People_Organization_Lookup_Search_Performance.sql.
-- Indexes + the user-search configuration from metadata/entities/.entities.json. The T-SQL twin
-- also recreates vwPeople / vwOrganizations to replace CAST(g.ID AS NVARCHAR(MAX)) in the
-- AddressLink join, a SQL Server-only sargability problem, so that part has no PG counterpart.
-- Named .pg.sql so the converter leaves the T-SQL source alone (see Business_Time_Zone.pg.sql).

CREATE INDEX IF NOT EXISTS "IX_Person_DisplayName" ON __mj_bizappscommon."Person" ("DisplayName");
CREATE INDEX IF NOT EXISTS "IX_Person_LastName" ON __mj_bizappscommon."Person" ("LastName");
CREATE INDEX IF NOT EXISTS "IX_Person_Title" ON __mj_bizappscommon."Person" ("Title");
CREATE INDEX IF NOT EXISTS "IX_Person_Email" ON __mj_bizappscommon."Person" ("Email");
CREATE INDEX IF NOT EXISTS "IX_Organization_Name" ON __mj_bizappscommon."Organization" ("Name");
CREATE INDEX IF NOT EXISTS "IX_Organization_LegalName" ON __mj_bizappscommon."Organization" ("LegalName");
CREATE INDEX IF NOT EXISTS "IX_Organization_TaxID" ON __mj_bizappscommon."Organization" ("TaxID");
CREATE INDEX IF NOT EXISTS "IX_Organization_Email" ON __mj_bizappscommon."Organization" ("Email");
CREATE INDEX IF NOT EXISTS "IX_Organization_Website" ON __mj_bizappscommon."Organization" ("Website");

UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = true, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: People';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'BeginsWith', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'DisplayName';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'FirstName';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'BeginsWith', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'LastName';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'PrimaryEmail';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'Exact', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'Email';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'MiddleName';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'PreferredName';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'BeginsWith', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'Title';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'Phone';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: People' AND f."Name" = 'ID';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = true, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Organizations';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'BeginsWith', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: Organizations' AND f."Name" = 'Name';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'BeginsWith', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: Organizations' AND f."Name" = 'LegalName';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'Exact', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: Organizations' AND f."Name" = 'TaxID';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'Exact', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: Organizations' AND f."Name" = 'Email';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = true, "UserSearchPredicateAPI" = 'BeginsWith', "AutoUpdateIncludeInUserSearchAPI" = false, "AutoUpdateUserSearchPredicate" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: Organizations' AND f."Name" = 'Website';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: Organizations' AND f."Name" = 'Phone';
UPDATE "__mj"."EntityField" f SET "IncludeInUserSearchAPI" = false, "AutoUpdateIncludeInUserSearchAPI" = false FROM "__mj"."Entity" e WHERE e."ID" = f."EntityID" AND e."Name" = 'MJ_BizApps_Common: Organizations' AND f."Name" = 'ID';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Addresses';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Address Links';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Activity Types';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Activity Files';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Activity Links';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Activity Sync Connections';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Activity Sync Rule Sets';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Activity Sync Rules';
UPDATE "__mj"."Entity" SET "AllowUserSearchAPI" = false, "AutoUpdateAllowUserSearchAPI" = false WHERE "Name" = 'MJ_BizApps_Common: Activity Sync Exclusions';
