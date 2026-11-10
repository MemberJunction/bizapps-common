-- =============================================================================================
-- PostgreSQL counterpart of V202611100515__v5.64.x__Relationships_Durable_LogActivity_Bindings.sql
-- =============================================================================================

SET standard_conforming_strings = on;
SET search_path TO __mj_bizappscommon, public;

-- 1) Remove the two superseded 'Entity Object Data' RecordData EntityActionParam rows.
DELETE FROM ${mjSchema}."EntityActionParam"
 WHERE "ID" IN (
     '01F9747B-6F07-4671-A44E-953113442878',
     '42AF8F1E-0B3E-4879-A72C-9D728D9DFAAB'
 );

-- 2) Switch both Relationships Common.LogActivity bindings to RunMode = 'Durable'.
UPDATE ${mjSchema}."EntityAction"
   SET "RunMode" = 'Durable',
       "__mj_UpdatedAt" = NOW()
 WHERE "ID" IN (
     'ABF0B899-C4D8-4BF8-9AE8-4EAE7DD32346',
     '32D1707C-D9BE-48F7-BB46-701F8DB09110'
 );

-- 3) Set LogValue = TRUE on both Relationships LinkFields EntityActionParam rows.
UPDATE ${mjSchema}."EntityActionParam"
   SET "LogValue" = TRUE,
       "__mj_UpdatedAt" = NOW()
 WHERE "ID" IN (
     '0002071D-7D2B-4777-A211-9F4CCD3626E9',
     'C3209787-8595-49A9-A026-3C45237AB2EC'
 );

-- 4) Seed the two Script RecordData EntityActionParam rows for hosts upgrading via migration.
INSERT INTO ${mjSchema}."EntityActionParam" ("ID", "EntityActionID", "ActionParamID", "ValueType", "Value", "LogValue", "Comments")
SELECT v."ID", v."EntityActionID", v."ActionParamID", v."ValueType", v."Value", v."LogValue", v."Comments"
  FROM (
      VALUES
          (
              CAST('01F9747B-6F07-4671-A44E-953113442879' AS UUID),
              CAST('ABF0B899-C4D8-4BF8-9AE8-4EAE7DD32346' AS UUID),
              CAST('D067FFE0-70B2-4A28-9C31-066BB536E637' AS UUID),
              'Script',
              'return { ID: EntityActionContext.entityObject.ID, FromPersonID: EntityActionContext.entityObject.FromPersonID, ToPersonID: EntityActionContext.entityObject.ToPersonID, FromOrganizationID: EntityActionContext.entityObject.FromOrganizationID, ToOrganizationID: EntityActionContext.entityObject.ToOrganizationID };',
              TRUE,
              'RecordData — projects only the five party/record IDs needed for LinkFields so RedactParams keeps it in the durable task payload.'
          ),
          (
              CAST('42AF8F1E-0B3E-4879-A72C-9D728D9DFAAC' AS UUID),
              CAST('32D1707C-D9BE-48F7-BB46-701F8DB09110' AS UUID),
              CAST('D067FFE0-70B2-4A28-9C31-066BB536E637' AS UUID),
              'Script',
              'return { ID: EntityActionContext.entityObject.ID, FromPersonID: EntityActionContext.entityObject.FromPersonID, ToPersonID: EntityActionContext.entityObject.ToPersonID, FromOrganizationID: EntityActionContext.entityObject.FromOrganizationID, ToOrganizationID: EntityActionContext.entityObject.ToOrganizationID };',
              TRUE,
              'RecordData — projects only the five party/record IDs needed for LinkFields so RedactParams keeps it in the durable task payload. No EventKey: a relationship can end, restart and end again; each transition is its own entry.'
          )
  ) AS v("ID", "EntityActionID", "ActionParamID", "ValueType", "Value", "LogValue", "Comments")
 INNER JOIN ${mjSchema}."EntityAction" ea
    ON ea."ID" = v."EntityActionID"
 INNER JOIN ${mjSchema}."ActionParam" ap
    ON ap."ID" = v."ActionParamID"
  LEFT JOIN ${mjSchema}."EntityActionParam" existing
    ON existing."ID" = v."ID"
 WHERE existing."ID" IS NULL;
