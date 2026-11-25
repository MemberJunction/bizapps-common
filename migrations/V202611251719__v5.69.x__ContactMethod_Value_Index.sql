-- =============================================================================
-- Migration: V202611251719__v5.69.x__ContactMethod_Value_Index.sql
-- Description: Index ContactMethod.Value, so a lookup by address seeks instead
--              of reading the whole table.
--
-- Why: Activity Sync resolves every participant address of a batch with one
-- query (packages/ActivitySync/src/identity.ts, IdentityResolver.lookup):
--
--     SELECT ... FROM vwContactMethods WHERE Value IN ('a@x.test', ...)
--
-- The filter is sargable on purpose (the literals are lowercased in code, the
-- column is not wrapped in LOWER()), but no index starts with Value. The base
-- schema indexes ContactMethod only by PersonID / OrganizationID (Value is an
-- INCLUDE column there), so every lookup scans the table.
--
-- Measured on the AIDP test server (3,519,298 ContactMethod rows), one hourly
-- sync of one mailbox: the two lookups took 2.0 s (8 addresses) and 6.4 s
-- (38 addresses), about half of the 16-17 s run. Connections sync one after
-- another, so the cost adds up per mailbox. The resolver runs again for each
-- logged item, which repeats the scan.
--
-- Measured on a local SQL Server 2022 copy of the same row count: 69-74 ms
-- (8 addresses) and 262-271 ms (38 addresses) without the index, 1-2 ms with
-- it. The index built in about 1 s and takes about 322 MB at that size.
--
-- Index build: ONLINE builds are Enterprise-only, so none is requested; the
-- build holds a lock on ContactMethod while it runs (seconds at this size).
-- PostgreSQL: the .pg.sql twin is release work. PostgreSQL compares text
-- case-sensitively, so a plain btree there matches only lowercased values
-- (see the comment in identity.ts).
-- =============================================================================

CREATE NONCLUSTERED INDEX [IX_ContactMethod_Value]
    ON [${flyway:defaultSchema}].[ContactMethod] ([Value]);
GO
