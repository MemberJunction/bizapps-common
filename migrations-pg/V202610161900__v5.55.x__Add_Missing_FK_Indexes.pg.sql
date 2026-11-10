-- =============================================================================================
-- PostgreSQL counterpart of V202610161900__v5.55.x__Add_Missing_FK_Indexes.sql
-- =============================================================================================

SET standard_conforming_strings = on;

CREATE SCHEMA IF NOT EXISTS __mj_bizappscommon;
SET search_path TO __mj_bizappscommon, public;

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ActivityFile_ActivityID" ON __mj_BizAppsCommon."ActivityFile" ("ActivityID");
CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ActivityFile_FileID" ON __mj_BizAppsCommon."ActivityFile" ("FileID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ActivityLink_ActivityID" ON __mj_BizAppsCommon."ActivityLink" ("ActivityID");
CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_ActivityLink_EntityID" ON __mj_BizAppsCommon."ActivityLink" ("EntityID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Person_SeniorityLevelID" ON __mj_BizAppsCommon."Person" ("SeniorityLevelID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_PersonJobFunction_JobFunctionID" ON __mj_BizAppsCommon."PersonJobFunction" ("JobFunctionID");
CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_PersonJobFunction_PersonID" ON __mj_BizAppsCommon."PersonJobFunction" ("PersonID");

CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_JobFunctionID" ON __mj_BizAppsCommon."Relationship" ("JobFunctionID");
CREATE INDEX IF NOT EXISTS "IDX_AUTO_MJ_FKEY_Relationship_SeniorityLevelID" ON __mj_BizAppsCommon."Relationship" ("SeniorityLevelID");
