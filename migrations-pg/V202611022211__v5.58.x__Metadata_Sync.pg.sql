-- =============================================================================================
-- PostgreSQL counterpart of V202611022211__v5.58.x__Metadata_Sync.sql -- BizApps Common v5.58.x Metadata_Sync
-- =============================================================================================
-- Same record, same value as the T-SQL file; see its header for what ships, why it is written by
-- hand, and what is held back. Written by hand to match: one UPDATE by pinned ID, a no-op on any
-- database that ran V202611021520__v5.58.x__Company_Sender_Identity.pg.sql.
-- Core table uses ${mjSchema}.
-- =============================================================================================
UPDATE ${mjSchema}."Entity"
   SET "DisplayName" = 'Company Sender Identities'
 WHERE "ID" = '64c02581-1ae6-4e8d-a4f2-0d9bed1a9b13'
   AND "DisplayName" IS DISTINCT FROM 'Company Sender Identities';
