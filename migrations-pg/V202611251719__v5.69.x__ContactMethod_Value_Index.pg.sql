-- =============================================================================
-- PostgreSQL counterpart of V202611251719__v5.69.x__ContactMethod_Value_Index.sql
-- =============================================================================
-- Index ContactMethod.Value, so Activity Sync's address lookup
-- (Value IN (...), packages/ActivitySync/src/identity.ts) seeks instead of
-- scanning the table. A plain btree serves that equality test. PostgreSQL
-- compares text case-sensitively, so it matches only values stored in lower
-- case; that predates this index (see the comment in identity.ts).
-- =============================================================================

CREATE INDEX IF NOT EXISTS "IX_ContactMethod_Value"
    ON __mj_bizappscommon."ContactMethod" ("Value");
