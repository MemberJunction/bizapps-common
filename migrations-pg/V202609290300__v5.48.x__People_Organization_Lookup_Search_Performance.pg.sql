-- Hand-written PG twin of V202609290300__v5.48.x__People_Organization_Lookup_Search_Performance.sql.
-- Indexes only. The T-SQL twin also recreates vwPeople / vwOrganizations to replace
-- CAST(g.ID AS NVARCHAR(MAX)) in the AddressLink join, a SQL Server-only sargability problem.
-- Search configuration is metadata and ships through the release Metadata_Sync.
-- Named .pg.sql so the converter leaves the T-SQL source alone (see Business_Time_Zone.pg.sql).
--
-- BeginsWith reaches PostgreSQL as a plain `col LIKE 'x%'` (PostgreSQLDataProvider
-- buildPerFieldSearchPredicate). A default btree serves a LIKE prefix only under the C collation,
-- and MJ installs get the image/RDS default (en_US.utf8), so the prefix columns use the pattern
-- operator classes: varchar_pattern_ops for VARCHAR, text_pattern_ops for DisplayName (a TEXT
-- generated column). The Exact columns (Email, TaxID) are compared with `=`, which a default btree
-- serves under any collation. Website is not searched (see .entities.json), so it has no index.

CREATE INDEX IF NOT EXISTS "IX_Person_DisplayName" ON __mj_bizappscommon."Person" ("DisplayName" text_pattern_ops);
CREATE INDEX IF NOT EXISTS "IX_Person_LastName" ON __mj_bizappscommon."Person" ("LastName" varchar_pattern_ops);
CREATE INDEX IF NOT EXISTS "IX_Person_Title" ON __mj_bizappscommon."Person" ("Title" varchar_pattern_ops);
CREATE INDEX IF NOT EXISTS "IX_Person_Email" ON __mj_bizappscommon."Person" ("Email");
CREATE INDEX IF NOT EXISTS "IX_Organization_Name" ON __mj_bizappscommon."Organization" ("Name" varchar_pattern_ops);
CREATE INDEX IF NOT EXISTS "IX_Organization_LegalName" ON __mj_bizappscommon."Organization" ("LegalName" varchar_pattern_ops);
CREATE INDEX IF NOT EXISTS "IX_Organization_TaxID" ON __mj_bizappscommon."Organization" ("TaxID");
CREATE INDEX IF NOT EXISTS "IX_Organization_Email" ON __mj_bizappscommon."Organization" ("Email");
