-- =============================================================================
-- Migration: V202610211654__v5.56.x__Party_Lookup_Domain_Columns.sql
-- Description: Add two PERSISTED, indexed computed columns for the party lookup
--              (bizapps-party-field): Person.EmailDomain and Organization.WebsiteDomain.
--
-- WHY. Pickers on Deal, Order and Contract forms must find a person by email domain
-- ("aqha.com") and an organization by website ("acme.com") in under a second. Matching
-- the raw columns needs a leading wildcard (Email LIKE '%@aqha.com', Website LIKE
-- '%acme.com%'), which scans: 1.9 s and 28 s on Stage (1.29M people, 448K organizations).
-- A stored, indexed domain turns both into a prefix seek.
--
-- Person.EmailDomain: the lower-cased text after the first '@' of Email. NULL when Email
-- is NULL, has no '@', or has nothing after it ("bob@").
--
-- Organization.WebsiteDomain: Website trimmed and lower-cased, then
--   1. the scheme (http:// or https://) and a leading "www." are skipped: Start is the
--      position after them;
--   2. the host runs from Start to the first '/' after it (or the end).
-- "HTTPS://WWW.Acme.com/about" -> "acme.com". A port stays ("acme.com:8080"); a query
-- string with no path stays too. NULL when Website is NULL or nothing is left.
-- The picker normalizes a typed URL the same way (party-lookup-term.ts websiteDomainOf).
--
-- Both are CAST to NVARCHAR(255) (510 bytes) so they fit an index key. Every function used
-- is deterministic, which PERSISTED and the index require.
--
-- POSTGRESQL. Release work. Both expressions use only IMMUTABLE functions (lower, btrim,
-- position/strpos, substr), so GENERATED ALWAYS AS (...) STORED works there.
-- =============================================================================
IF COL_LENGTH('[${flyway:defaultSchema}].[Person]', 'EmailDomain') IS NULL
    ALTER TABLE [${flyway:defaultSchema}].[Person]
        ADD [EmailDomain] AS (
            CAST(
                CASE WHEN CHARINDEX(N'@', [Email]) > 0
                     THEN NULLIF(LOWER(TRIM(SUBSTRING([Email], CHARINDEX(N'@', [Email]) + 1, 255))), N'')
                END
                AS NVARCHAR(255))
        ) PERSISTED;
GO
IF COL_LENGTH('[${flyway:defaultSchema}].[Organization]', 'WebsiteDomain') IS NULL
    ALTER TABLE [${flyway:defaultSchema}].[Organization]
        ADD [WebsiteDomain] AS (
            -- LEFT(Host, CHARINDEX('/', Host + '/') - 1), where Host = SUBSTRING(x, Start, 1000):
            -- Host is written out twice because a computed column cannot name a sub-expression.
            CAST(
                NULLIF(
                    LEFT(
                        SUBSTRING(LOWER(TRIM([Website])),
                            CASE WHEN LOWER(TRIM([Website])) LIKE N'https://www.%' THEN 13
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://www.%'  THEN 12
                                 WHEN LOWER(TRIM([Website])) LIKE N'https://%'     THEN 9
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://%'      THEN 8
                                 WHEN LOWER(TRIM([Website])) LIKE N'www.%'         THEN 5
                                 ELSE 1 END, 1000),
                        CHARINDEX(N'/', SUBSTRING(LOWER(TRIM([Website])),
                            CASE WHEN LOWER(TRIM([Website])) LIKE N'https://www.%' THEN 13
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://www.%'  THEN 12
                                 WHEN LOWER(TRIM([Website])) LIKE N'https://%'     THEN 9
                                 WHEN LOWER(TRIM([Website])) LIKE N'http://%'      THEN 8
                                 WHEN LOWER(TRIM([Website])) LIKE N'www.%'         THEN 5
                                 ELSE 1 END, 1000) + N'/') - 1),
                    N'')
                AS NVARCHAR(255))
        ) PERSISTED;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Person_EmailDomain'
      AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]')
)
    CREATE INDEX [IX_Person_EmailDomain]
        ON [${flyway:defaultSchema}].[Person] ([EmailDomain]);
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Organization_WebsiteDomain'
      AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]')
)
    CREATE INDEX [IX_Organization_WebsiteDomain]
        ON [${flyway:defaultSchema}].[Organization] ([WebsiteDomain]);
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description',
        N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'Person', N'COLUMN', N'EmailDomain')
)
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Lower-cased domain of Email: the text after the first @. NULL when Email is empty, has no @, or has nothing after it. Computed and stored, indexed for prefix search by domain.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Person', @level2type = N'COLUMN', @level2name = N'EmailDomain';
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.fn_listextendedproperty(N'MS_Description',
        N'SCHEMA', N'${flyway:defaultSchema}', N'TABLE', N'Organization', N'COLUMN', N'WebsiteDomain')
)
    EXEC sp_addextendedproperty @name = N'MS_Description', @value = N'Lower-cased host of Website, without the http(s):// scheme, a leading www. or any path. NULL when Website is empty. Computed and stored, indexed for prefix search by domain.',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}', @level1type = N'TABLE', @level1name = N'Organization', @level2type = N'COLUMN', @level2name = N'WebsiteDomain';
GO
