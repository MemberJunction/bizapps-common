-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
CREATE SCHEMA IF NOT EXISTS __mj_BizAppsCommon;
SET search_path TO __mj_BizAppsCommon, public;

-- Ensure backslashes in string literals are treated literally (not as escape sequences)
SET standard_conforming_strings = on;

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== DDL: Tables, PKs, Indexes =====================

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Person_LinkedUserID" ON __mj_BizAppsCommon."Person" ("LinkedUserID") WHERE "LinkedUserID" IS NOT NULL;


-- ===================== Other =====================

-- ============================================================================
-- Add filtered unique index on Person."LinkedUserID"
--
-- Enforces 1:1 relationship between Person and User records.
-- Filtered to WHERE LinkedUserID IS NOT NULL so multiple unlinked persons
-- are allowed. Prevents two Person records from linking to the same User.
-- ============================================================================

-- Verify no duplicates exist before adding the constraint

-- ============================================================================
-- CodeGen output below — paste regenerated views/SPs after running CodeGen
-- ============================================================================
