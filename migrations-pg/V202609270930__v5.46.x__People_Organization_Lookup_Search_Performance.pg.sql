-- Hand-written PG twin of V202609270930__v5.46.x__People_Organization_Lookup_Search_Performance.sql.
-- Indexes only. The T-SQL twin also recreates vwPeople / vwOrganizations to replace
-- CAST(g.ID AS NVARCHAR(MAX)) in the AddressLink join, a SQL Server-only sargability problem.
-- Search configuration is metadata and ships through the release Metadata_Sync.
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
