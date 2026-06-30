-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
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


-- ===================== Stored Procedures (sp*) =====================

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateAddressType"
--     @ID UUID = NULL,
--     @Name VARCHAR(100),
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @IconCl...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateAddressType"
--     @ID UUID,
--     @Name VARCHAR(100) = NULL,
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @IconCl...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteAddressType"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."AddressType"
--     WHERE
--         "ID" = @...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateAddressLink"
--     @ID UUID = NULL,
--     @AddressID UUID,
--     @EntityID UUID,
--     @RecordID VARCHAR(700),
--     @AddressT...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateAddressLink"
--     @ID UUID,
--     @AddressID UUID = NULL,
--     @EntityID UUID = NULL,
--     @RecordID VARCHAR(700) = NULL,...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteAddressLink"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."AddressLink"
--     WHERE
--         "ID" = @...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateContactMethod"
--     @ID UUID = NULL,
--     @PersonID_Clear bit = 0,
--     @PersonID UUID = NULL,
--     @OrganizationID_Clear bit = 0,
--   ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateContactMethod"
--     @ID UUID,
--     @PersonID_Clear bit = 0,
--     @PersonID UUID = NULL,
--     @OrganizationID_Clear bit = 0,
--     @Orga...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteContactMethod"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."ContactMethod"
--     WHERE
--         "ID"...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateAddress"
--     @ID UUID = NULL,
--     @Line1 VARCHAR(255),
--     @Line2_Clear bit = 0,
--     @Line2 VARCHAR(255) = NULL,
--     @Line3_Clear bit = 0,
-- ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateAddress"
--     @ID UUID,
--     @Line1 VARCHAR(255) = NULL,
--     @Line2_Clear bit = 0,
--     @Line2 VARCHAR(255) = NULL,
--     @Line3_Clear bit = 0,
-- ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteAddress"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."Address"
--     WHERE
--         "ID" = @ID
-- 
-- 
--    ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateContactType"
--     @ID UUID = NULL,
--     @Name VARCHAR(100),
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @IconCl...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateContactType"
--     @ID UUID,
--     @Name VARCHAR(100) = NULL,
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @IconCl...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteContactType"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."ContactType"
--     WHERE
--         "ID" = @...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateOrganization"
--     @ID UUID = NULL,
--     @Name VARCHAR(255),
--     @LegalName_Clear bit = 0,
--     @LegalName VARCHAR(255) = NULL,
--     @Organizat...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateOrganization"
--     @ID UUID,
--     @Name VARCHAR(255) = NULL,
--     @LegalName_Clear bit = 0,
--     @LegalName VARCHAR(255) = NULL,
--     @Organizat...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateRelationship"
--     @ID UUID = NULL,
--     @RelationshipTypeID UUID,
--     @FromPersonID_Clear bit = 0,
--     @FromPersonID uniqueidentif...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateRelationship"
--     @ID UUID,
--     @RelationshipTypeID UUID = NULL,
--     @FromPersonID_Clear bit = 0,
--     @FromPersonID uniqueidentif...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteRelationship"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."Relationship"
--     WHERE
--         "ID" =...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreatePerson"
--     @ID UUID = NULL,
--     @FirstName VARCHAR(100),
--     @LastName VARCHAR(100),
--     @MiddleName_Clear bit = 0,
--     @MiddleName nvarch...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdatePerson"
--     @ID UUID,
--     @FirstName VARCHAR(100) = NULL,
--     @LastName VARCHAR(100) = NULL,
--     @MiddleName_Clear bit = 0,
--     @MiddleName...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeletePerson"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."Person"
--     WHERE
--         "ID" = @ID
-- 
-- 
--     -...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateOrganizationType"
--     @ID UUID = NULL,
--     @Name VARCHAR(100),
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @I...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateOrganizationType"
--     @ID UUID,
--     @Name VARCHAR(100) = NULL,
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @I...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteOrganizationType"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."OrganizationType"
--     WHERE
--       ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spCreateRelationshipType"
--     @ID UUID = NULL,
--     @Name VARCHAR(100),
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @C...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spUpdateRelationshipType"
--     @ID UUID,
--     @Name VARCHAR(100) = NULL,
--     @Description_Clear bit = 0,
--     @Description TEXT = NULL,
--     @C...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteRelationshipType"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
-- 
--     DELETE FROM
--         __mj_bizappscommon."RelationshipType"
--     WHERE
--       ...

-- SKIPPED: procedure (auto-conversion not supported)
-- CREATE PROCEDURE __mj_bizappscommon."spDeleteOrganization"
--     @ID UUID
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     -- Cascade update on ContactMethod using cursor to call spUpdateContactMethod
--    ...


-- ===================== Triggers =====================

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateAddressType
-- ON __mj_bizappscommon."AddressType"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."AddressType"
--     SET
 

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateAddressLink
-- ON __mj_bizappscommon."AddressLink"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."AddressLink"
--     SET
 

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateContactMethod
-- ON __mj_bizappscommon."ContactMethod"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."ContactMethod"
   

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateAddress
-- ON __mj_bizappscommon."Address"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."Address"
--     SET
--         __mj_

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateContactType
-- ON __mj_bizappscommon."ContactType"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."ContactType"
--     SET
 

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateOrganization
-- ON __mj_bizappscommon."Organization"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."Organization"
--     SE

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateRelationship
-- ON __mj_bizappscommon."Relationship"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."Relationship"
--     SE

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdatePerson
-- ON __mj_bizappscommon."Person"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."Person"
--     SET
--         __mj_Upd

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER __mj_bizappscommon.trgUpdateOrganizationType
-- ON __mj_bizappscommon."OrganizationType"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."Organization

-- SKIPPED: trigger (auto-conversion not supported)
-- CREATE TRIGGER [__mj_bizappscommon".trgUpdateRelationshipType
-- ON __mj_bizappscommon."RelationshipType"
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE
--         __mj_bizappscommon."Relationship


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

UPDATE __mj."Entity"
SET    "CascadeDeletes" = TRUE
WHERE  "Name" = 'MJ_BizApps_Common: Organizations';

-- Sanity check: ensure exactly one row was updated. If zero, the entity
-- was missing (Metadata_Sync hasn't run, or entity was renamed). If
-- multiple, something is very wrong.


-- ===================== Grants =====================

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Address Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Types
-- Item: spUpdateAddressType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Address Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Types
-- Item: spDeleteAddressType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Address Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spCreateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spUpdateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddressLink" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Address Links
-- Item: spDeleteAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressLink
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Address Links */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddressLink" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spCreateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethod
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Methods */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spUpdateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethod
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactMethod" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spDeleteContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethod
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactMethod" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Methods */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactMethod" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: spCreateAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Address
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Addresses */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: spUpdateAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Address
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateAddress" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Addresses */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Addresses
-- Item: spDeleteAddress
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Address
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddress" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Addresses */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteAddress" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spCreateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Contact Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spUpdateContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateContactType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Contact Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Types
-- Item: spDeleteContactType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Contact Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteContactType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spCreateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Organization
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Organizations */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spUpdateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Organization
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganization" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spCreateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Relationship
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Relationships */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spUpdateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Relationship
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationship" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spDeleteRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Relationship
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationship" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Relationships */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationship" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spCreatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Person
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: People */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spUpdatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Person
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdatePerson" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: People
-- Item: spDeletePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Person
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeletePerson" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: People */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeletePerson" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organization Types
-- Item: spCreateOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR OrganizationType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Organization Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organization Types
-- Item: spUpdateOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR OrganizationType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateOrganizationType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Organization Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organization Types
-- Item: spDeleteOrganizationType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR OrganizationType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganizationType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Organization Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganizationType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate SQL for MJ_BizApps_Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationship Types
-- Item: spCreateRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR RelationshipType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spCreate Permissions for MJ_BizApps_Common: Relationship Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spCreateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spUpdate SQL for MJ_BizApps_Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationship Types
-- Item: spUpdateRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR RelationshipType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spUpdateRelationshipType" TO "cdp_Developer", "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Relationship Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationship Types
-- Item: spDeleteRelationshipType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR RelationshipType
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationshipType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Relationship Types */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteRelationshipType" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spDeleteOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Organization
------------------------------------------------------------;

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganization" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* spDelete Permissions for MJ_BizApps_Common: Organizations */

DO $$ BEGIN GRANT EXECUTE ON FUNCTION __mj_bizappscommon."spDeleteOrganization" TO "cdp_Integration"; EXCEPTION WHEN others THEN NULL; END $$;
/* SQL text to delete unneeded entity fields */


-- ===================== Other =====================

-- =====================================================================
-- v5.33 Tolerant SP Regeneration + Enable CascadeDeletes for Organizations
-- =====================================================================
--
-- Purpose:
--   1. Flip [CascadeDeletes" = 1 on the "MJ_BizApps_Common: Organizations"
--      entity in "__mj"."Entity" so CodeGen emits cascade cleanup logic
--      in spDeleteOrganization.
--   2. Install regenerated tolerant CRUD stored procedures for every
--      BAC entity (introduced in MJ v5.31+). These accept NULL for any
--      non-primary-key parameter and apply database defaults via
--      COALESCE(...) in the body, so historical EXEC calls remain valid
--      after additive schema changes. Nullable columns with database
--      defaults get an accompanying `<Field>_Clear bit = 0` companion
--      parameter that lets callers explicitly set the column to NULL.
--
-- Per-FK cascade direction is determined automatically by MJ CodeGen:
--   - Non-nullable FKs to Organization -> cascade DELETE child rows
--   - Nullable FKs to Organization     -> cascade UPDATE child rows
--                                         setting FK to NULL (via
--                                         tolerant SP `_Clear` param)
--
-- This migration mirrors the pattern established in BCSaaS's
-- V202605131038__v1.2.x_Enable_CascadeDeletes_For_Organizations.sql:
-- STEP 1 is a hand-authored flag flip with a strict @@ROWCOUNT guard;
-- STEP 2 is the appended output of a forceRegeneration CodeGen run.
--
-- =====================================================================


-- =====================================================================
-- STEP 1: Flip the metadata flag on Organizations
-- =====================================================================

-- NOTE: unrecognized batch type (UNKNOWN) — passed through as-is
-- IF @@ROWCOUNT <> 1
-- BEGIN
--     DECLARE @err VARCHAR(400) = CONCAT(
--         N'Expected exactly 1 row updated for "MJ_BizApps_Common: Organizations" in "__mj"."Entity"; got ',
--         CAST(@@ROWCOUNT AS VARCHAR(10)),
--         N'. Aborting migration.'
--     );
--     THROW 50000, @err, 1;
-- END;

-- =====================================================================
-- STEP 2: Regenerated tolerant CRUD stored procedures (CodeGen output)
-- =====================================================================
--
-- Generated by running `mj codegen` with mj.config.cjs flags:
--
--     forceRegeneration: {
--         enabled: true,
--         spCreate: true,
--         spUpdate: true,
--         spDelete: true,
--         allStoredProcedures: false,
--         baseViews: false,
--         indexes: false,
--         fullTextSearch: false,
--     }
--
-- against a BAC DB where STEP 1 (CascadeDeletes = 1 on
-- MJ_BizApps_Common: Organizations) was previously applied. The
-- regenerated spDeleteOrganization body therefore contains cascade
-- cursors for every dependent FK; the other 29 sprocs (spCreate,
-- spUpdate, and the remaining 9 spDeletes) are the v5.33 tolerant
-- signatures.
--
-- =====================================================================

/* SQL text to update existing entities from schema */

/* spUpdate Permissions for MJ_BizApps_Common: Address Types */

/* spUpdate Permissions for MJ_BizApps_Common: Address Links */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Methods */

/* spUpdate Permissions for MJ_BizApps_Common: Addresses */

/* spUpdate Permissions for MJ_BizApps_Common: Contact Types */

/* spUpdate Permissions for MJ_BizApps_Common: Organizations */

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */

/* spUpdate Permissions for MJ_BizApps_Common: People */

/* spUpdate Permissions for MJ_BizApps_Common: Organization Types */

/* spUpdate Permissions for MJ_BizApps_Common: Relationship Types */
