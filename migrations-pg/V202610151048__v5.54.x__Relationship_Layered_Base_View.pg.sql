-- =============================================================================================
-- PostgreSQL counterpart of V202610151048__v5.54.x__Relationship_Layered_Base_View.sql
-- =============================================================================================
-- `mj sql-convert --from tsql --to postgres` (MJ CLI 6.1.5) output, finished by hand:
--   * Tables, columns, constraints, indexes, views, data and grants are the converter's.
--   * CodeGen's CRUD procedures (spCreate/spUpdate/spDelete), its __mj_UpdatedAt triggers and any
--     hierarchy functions are NOT here: the converter cannot translate T-SQL procedures, triggers
--     or table-valued functions. A PostgreSQL host runs `mj codegen` after installing, which
--     generates them natively. The converter's notes for them remain, fully commented out.
--   * vwRelationships: written by hand in PL/pgSQL from this migration's T-SQL.
--   * 1 view-rebuild block(s): the target schema lowercased, so the dependent-view rebuild
--     finds the view when its column list changes.
-- Schema names are written unquoted, as the converter emits them, so they fold to the lowercase
-- schema a PostgreSQL install uses.
-- =============================================================================================

SET standard_conforming_strings = on;

-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
--
-- The schema name is emitted UNQUOTED, so PostgreSQL folds it to lowercase. That is deliberate and
-- self-consistent: everything downstream in a converted migration refers to it unquoted too, so
-- both definition and lookup land on the same folded name.
--
-- DOWNSTREAM NOTE for the build engineer: a PostgreSQL database that was populated by an EARLIER
-- converter — one that emitted a quoted, case-preserved name — already holds that mixed-case
-- schema: for a target named MySchema_Name, the quoted "MySchema_Name". Re-converting against
-- that database creates a SECOND, empty schema myschema_name rather than reusing the existing
-- one, because IF NOT EXISTS compares the folded name and finds no match. The repo's own committed
-- migrations-pg files are unaffected (the only quoted CREATE SCHEMAs there are the four pg_dump
-- baselines, which this path does not produce), so this is an open-app / downstream concern, not
-- one for this repo's Flyway history.
CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;
SET search_path TO __mj_bizappscommon, public;

-- Ensure backslashes in string literals are treated literally (not as escape sequences)
SET standard_conforming_strings = on;

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== Other =====================

-- =============================================================================
-- Layered base view for Relationships — PART 2 of 2 (the wrapper)
-- =============================================================================
--
-- Pairs with V202610151047, which flips Relationships to a layered base view and carries
-- the CodeGen output that CREATES vwRelationshipsGenerated. Run that first; timestamp
-- ordering guarantees it.
--
-- This wrapper owns only what CodeGen cannot produce: DisplayName, the entity's name
-- field. Everything else — base columns and every FK display column — comes from g.*, so
-- the wrapper exposes a SUPERSET of the generated view. A SELECT g.* view fixes its column
-- list when it is created; columns added to vwRelationshipsGenerated later reach this view
-- through the guarded sp_refreshview CodeGen emits after each regeneration.
--
-- DisplayName = "<From> → <To> (<Type>)", e.g. "Jane Smith → Acme (Employee)".
--   * From/To: the person's DisplayName or the organization's Name (CK_Relationship_
--     FromOwner / ToOwner guarantee exactly one is set on each side).
--   * Type: the RelationshipType Name already on the generated view. Not ForwardLabel:
--     a sentence ("Jane Smith is employee of Acme") depends on every label's grammar and
--     fixes English word order. The arrow and parentheses carry no language, so a host
--     localizes the label by renaming its RelationshipTypes. Names lead, so pickers sort
--     and search by party.
--   * The arrow is NCHAR(8594) so the view does not depend on how the file is decoded.
--   * Every part is NULLIF(TRIM(x), N''): CONCAT_WS skips a blank party, and a blank
--     type drops the whole " (...)" suffix (N' (' + NULL is NULL, which CONCAT skips).
--
-- CREATE OR ALTER (not DROP + CREATE) keeps the grants already on vwRelationships.
--
-- NO CODEGEN SECTION HERE. The EntityField row for DisplayName ships in PART 1's
-- CodeGen output.
-- =============================================================================

-- vwRelationships: everything vwRelationshipsGenerated has, plus DisplayName
-- "<From> -> <To> (<Type>)". Written by hand: the converter passes the T-SQL view through untranslated.
-- CONCAT_WS skips a blank party and a blank type drops the " (...)" suffix, as in T-SQL. Replaced in
-- place when it can be. When its column list changes, every view that depends on it and every function
-- whose signature uses one of those views' row types (CodeGen's CRUD functions return SETOF the view)
-- is captured with its grants, dropped, and recreated after the view: no CASCADE, so nothing is lost.
DO $do$
DECLARE
  v_target_schema CONSTANT TEXT := '__mj_bizappscommon';
  v_target_name CONSTANT TEXT := 'vwRelationships';
  vsql CONSTANT TEXT := $vsql$CREATE OR REPLACE VIEW __mj_bizappscommon."vwRelationships"
AS SELECT
    g.*,
    CAST(
        CONCAT(
            CONCAT_WS(' ' || chr(8594) || ' ',
                NULLIF(TRIM(COALESCE(g."FromPerson", g."FromOrganization")), ''),
                NULLIF(TRIM(COALESCE(g."ToPerson", g."ToOrganization")), '')),
            ' (' || NULLIF(TRIM(g."RelationshipType"), '') || ')')
        AS VARCHAR(1000)) AS "DisplayName"
FROM
    __mj_bizappscommon."vwRelationshipsGenerated" AS g$vsql$;
  v_target_oid OID;
  v_target_acl TEXT;
  v_views JSONB[] := ARRAY[]::JSONB[];
  v_fns JSONB[] := ARRAY[]::JSONB[];
  v_dep RECORD;
  v_g RECORD;
  v_n INTEGER;
BEGIN
  EXECUTE vsql;
EXCEPTION WHEN invalid_table_definition THEN
  SELECT c.oid, c.relacl::text INTO v_target_oid, v_target_acl
  FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = v_target_schema AND c.relname = v_target_name AND c.relkind = 'v';
  FOR v_dep IN
    WITH RECURSIVE deps AS (
      SELECT c.oid, 1 AS depth
      FROM pg_depend d JOIN pg_rewrite r ON r.oid = d.objid JOIN pg_class c ON c.oid = r.ev_class
      WHERE d.refobjid = v_target_oid AND c.relkind = 'v' AND c.oid <> v_target_oid
      UNION
      SELECT c.oid, p.depth + 1
      FROM deps p JOIN pg_depend d ON d.refobjid = p.oid JOIN pg_rewrite r ON r.oid = d.objid
      JOIN pg_class c ON c.oid = r.ev_class
      WHERE c.relkind = 'v' AND c.oid <> p.oid
    )
    SELECT c.oid, n.nspname AS schema, c.relname AS name, MAX(deps.depth) AS depth,
           pg_catalog.pg_get_viewdef(c.oid, true) AS def, c.relacl::text AS acl
    FROM deps JOIN pg_class c ON c.oid = deps.oid JOIN pg_namespace n ON n.oid = c.relnamespace
    GROUP BY c.oid, n.nspname, c.relname, c.relacl ORDER BY MAX(deps.depth) ASC
  LOOP
    v_views := v_views || jsonb_build_object('oid', v_dep.oid, 'schema', v_dep.schema, 'name', v_dep.name,
                                             'def', v_dep.def, 'acl', v_dep.acl);
  END LOOP;
  FOR v_dep IN
    SELECT DISTINCT pr.oid, pg_catalog.pg_get_functiondef(pr.oid) AS def, pr.proacl::text AS acl,
           pr.oid::regprocedure::text AS sig
    FROM pg_depend d JOIN pg_proc pr ON pr.oid = d.objid AND d.classid = 'pg_proc'::regclass
    JOIN pg_class c ON c.reltype = d.refobjid
    WHERE c.oid = v_target_oid OR c.oid IN (SELECT (x->>'oid')::oid FROM unnest(v_views) x)
  LOOP
    v_fns := v_fns || jsonb_build_object('def', v_dep.def, 'acl', v_dep.acl, 'sig', v_dep.sig);
  END LOOP;
  IF array_length(v_fns, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_fns, 1) LOOP EXECUTE 'DROP FUNCTION ' || (v_fns[v_n]->>'sig'); END LOOP;
  END IF;
  IF array_length(v_views, 1) > 0 THEN
    FOR v_n IN REVERSE array_length(v_views, 1)..1 LOOP
      EXECUTE format('DROP VIEW %I.%I', v_views[v_n]->>'schema', v_views[v_n]->>'name');
    END LOOP;
  END IF;
  EXECUTE format('DROP VIEW %I.%I', v_target_schema, v_target_name);
  EXECUTE vsql;
  IF v_target_acl IS NOT NULL THEN
    FOR v_g IN SELECT a.privilege_type, CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
               FROM aclexplode(v_target_acl::aclitem[]) a WHERE a.grantee <> a.grantor
    LOOP EXECUTE format('GRANT %s ON %I.%I TO %s', v_g.privilege_type, v_target_schema, v_target_name, v_g.grantee); END LOOP;
  END IF;
  IF array_length(v_views, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_views, 1) LOOP
      EXECUTE format('CREATE VIEW %I.%I AS %s', v_views[v_n]->>'schema', v_views[v_n]->>'name', v_views[v_n]->>'def');
      IF v_views[v_n]->>'acl' IS NOT NULL THEN
        FOR v_g IN SELECT a.privilege_type, CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
                   FROM aclexplode((v_views[v_n]->>'acl')::aclitem[]) a WHERE a.grantee <> a.grantor
        LOOP EXECUTE format('GRANT %s ON %I.%I TO %s', v_g.privilege_type, v_views[v_n]->>'schema', v_views[v_n]->>'name', v_g.grantee); END LOOP;
      END IF;
    END LOOP;
  END IF;
  IF array_length(v_fns, 1) > 0 THEN
    FOR v_n IN 1..array_length(v_fns, 1) LOOP
      EXECUTE v_fns[v_n]->>'def';
      IF v_fns[v_n]->>'acl' IS NOT NULL THEN
        FOR v_g IN SELECT a.privilege_type, CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(a.grantee)) END AS grantee
                   FROM aclexplode((v_fns[v_n]->>'acl')::aclitem[]) a WHERE a.grantee <> a.grantor
        LOOP EXECUTE format('GRANT %s ON FUNCTION %s TO %s', v_g.privilege_type, v_fns[v_n]->>'sig', v_g.grantee); END LOOP;
      END IF;
    END LOOP;
  END IF;
END;
$do$;
DO $$ BEGIN GRANT SELECT ON __mj_bizappscommon."vwRelationships" TO "cdp_UI", "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;

