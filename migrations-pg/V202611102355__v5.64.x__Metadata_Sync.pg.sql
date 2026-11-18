-- =============================================================================================
-- PostgreSQL counterpart of V202611102355__v5.64.x__Metadata_Sync.sql
-- =============================================================================================
-- Same records, same values as the T-SQL file; see its header for what ships and why.
--
-- HOW IT WAS MADE: `mj sql-convert --from tsql --to postgres` (MJ CLI 6.2.1) on each block of the
-- push log, one block per run (the converter merges a multi-block log into one). Each block's
-- guard is then widened to match the T-SQL file (ID, or the natural key) and its update branch
-- removed, so every record is create-only, except the first block: the summary query's SQL update,
-- applied by ID as in the T-SQL file. The last block sets the new query's approved fingerprint only
-- while it has none. Core references use ${mjSchema}. String values the converter rewrote are
-- restored verbatim from the T-SQL file.
-- =============================================================================================

-- Save MJ: Queries (core SP call only)
DO $mj$
DECLARE
  p_SQL_3cdaeed9e9cd TEXT;
  p_TechnicalDescription_3cdaeed9e9cd TEXT;
  p_ExtractedSQLHash_3cdaeed9e9cd VARCHAR(64);
  p_ExtractionStatus_3cdaeed9e9cd VARCHAR(20);
  p_ID_3cdaeed9e9cd UUID;
BEGIN
  p_SQL_3cdaeed9e9cd := '-- Directory dashboard headline figures as ONE row of scalars.
--
-- The Angular tiles used to COUNT arrays from LoadDirectorySnapshot (RunView MaxRows 1000).
-- Cheese has ~3000 people, so every tile was a truncated sample. This query is COUNT(*)
-- over the Common base views — no row cap, no client aggregation.
--
-- Email = COALESCE(PrimaryEmail, Email), matching PersonEmail() in directory-stats.ts.
-- People added per business day is a separate query, Common: Directory People Per Day. Its
-- fnBusinessDayOf is a scalar function that SQL Server cannot inline (it converts time zones),
-- and one such call anywhere in a statement makes the whole plan single-threaded: in this query
-- that took the counts from about 9 seconds to over 20 on 1.3M people.
-- Org type mix is JSON so a variable number of types does not explode the column list.
--
-- The "worth a look" person and organization are each one TOP (1) row in its own derived table,
-- joined ON 1 = 1 so an empty result still returns the counts: one pass each instead of three
-- scalar subqueries, and the three fields always come from the same row.
--
-- People without an organization are counted with NOT EXISTS over active Employee relationships,
-- not from vwPeople.CurrentOrganizationID. The view finds that column with a TOP (1) OUTER APPLY
-- per person, which over 1.3M people took about 17 seconds; the NOT EXISTS count takes about 2.
-- It counts the same people as long as an active Employee relationship always names an
-- organization (vwPeople takes the latest one, and would show no organization if that one did not).
--
-- Single SELECT (no DECLARE / temp tables) so RunQuery can wrap it.
SELECT
    p.TotalPeople,
    p.ActivePeople,
    p.PeopleMissingEmail,
    po.PeopleMissingOrganization,
    pe.AttentionEmailPersonID,
    pe.AttentionEmailName,
    pe.AttentionEmailOrg,
    o.TotalOrganizations,
    o.ActiveOrganizations,
    o.OrganizationsMissingType,
    o.OrganizationsMissingWebsite,
    ot.AttentionTypeOrgID,
    ot.AttentionTypeOrgName,
    ot.AttentionTypeWebsite,
    o.OrgTypeMixJson,
    r.RelationshipCount
FROM
(
    SELECT
        COUNT(*) AS TotalPeople,
        ISNULL(SUM(CASE WHEN Status = N''Active'' THEN 1 ELSE 0 END), 0) AS ActivePeople,
        ISNULL(SUM(CASE WHEN Status = N''Active''
                  AND NULLIF(LTRIM(RTRIM(COALESCE(PrimaryEmail, Email))), N'''') IS NULL
                 THEN 1 ELSE 0 END), 0) AS PeopleMissingEmail
    FROM [${flyway:defaultSchema}].[vwPeople]
) p
CROSS JOIN
(
    SELECT COUNT(*) AS PeopleMissingOrganization
    FROM [${flyway:defaultSchema}].[vwPeople] p3
    WHERE p3.Status = N''Active''
      AND NOT EXISTS (
          SELECT 1
          FROM [${flyway:defaultSchema}].[Relationship] r
          INNER JOIN [${flyway:defaultSchema}].[RelationshipType] rt ON rt.[ID] = r.[RelationshipTypeID]
          WHERE rt.[Name] = N''Employee''
            AND r.[Status] = N''Active''
            AND r.[ToOrganizationID] IS NOT NULL
            AND r.[FromPersonID] = p3.[ID]
      )
) po
CROSS JOIN
(
    SELECT
        COUNT(*) AS TotalOrganizations,
        ISNULL(SUM(CASE WHEN Status = N''Active'' THEN 1 ELSE 0 END), 0) AS ActiveOrganizations,
        ISNULL(SUM(CASE WHEN Status = N''Active'' AND OrganizationTypeID IS NULL THEN 1 ELSE 0 END), 0) AS OrganizationsMissingType,
        ISNULL(SUM(CASE WHEN Status = N''Active'' AND NULLIF(LTRIM(RTRIM(Website)), N'''') IS NULL THEN 1 ELSE 0 END), 0) AS OrganizationsMissingWebsite,
        (
            SELECT TOP (100)
                ISNULL(NULLIF(LTRIM(RTRIM(o3.OrganizationType)), N''''), N''Unspecified'') AS Label,
                COUNT(*) AS Value
            FROM [${flyway:defaultSchema}].[vwOrganizations] o3
            GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(o3.OrganizationType)), N''''), N''Unspecified'')
            ORDER BY COUNT(*) DESC
            FOR JSON PATH
        ) AS OrgTypeMixJson
    FROM [${flyway:defaultSchema}].[vwOrganizations]
) o
CROSS JOIN
(
    SELECT COUNT(*) AS RelationshipCount
    FROM [${flyway:defaultSchema}].[vwRelationships]
) r
LEFT JOIN
(
    SELECT TOP (1)
        p2.ID AS AttentionEmailPersonID,
        p2.DisplayName AS AttentionEmailName,
        p2.CurrentOrganizationName AS AttentionEmailOrg
    FROM [${flyway:defaultSchema}].[vwPeople] p2
    WHERE p2.Status = N''Active''
      AND NULLIF(LTRIM(RTRIM(COALESCE(p2.PrimaryEmail, p2.Email))), N'''') IS NULL
    ORDER BY p2.__mj_CreatedAt DESC
) pe ON 1 = 1
LEFT JOIN
(
    SELECT TOP (1)
        o2.ID AS AttentionTypeOrgID,
        o2.Name AS AttentionTypeOrgName,
        o2.Website AS AttentionTypeWebsite
    FROM [${flyway:defaultSchema}].[vwOrganizations] o2
    WHERE o2.Status = N''Active'' AND o2.OrganizationTypeID IS NULL
    ORDER BY o2.__mj_CreatedAt DESC
) ot ON 1 = 1
;
';
  p_TechnicalDescription_3cdaeed9e9cd := 'Grain: one row. COUNT(*) / SUM(CASE) over vwPeople, vwOrganizations, vwRelationships. Email gap matches PersonEmail() (COALESCE PrimaryEmail, Email). People without an organization: NOT EXISTS over active Employee relationships, not vwPeople.CurrentOrganizationID (a per-row OUTER APPLY). People-per-day is the separate query Common: Directory People Per Day. Org type mix is FOR JSON PATH. No template parameters — pushing twice must not collide on QueryParameter.';
  p_ExtractedSQLHash_3cdaeed9e9cd := 'dfbad0cdc270d3e3c997e5454c363359741c0ad8e7dd36f83f286d16bdf76683';
  p_ExtractionStatus_3cdaeed9e9cd := 'OK';
  p_ID_3cdaeed9e9cd := '6C0A1000-0001-4000-A000-00000000000E';
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateQuery'
       AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
  ) THEN
    PERFORM "${mjSchema}"."spUpdateQuery"(p_data := jsonb_build_object(
    'SQL', p_SQL_3cdaeed9e9cd,
    'TechnicalDescription', p_TechnicalDescription_3cdaeed9e9cd,
    'ExtractedSQLHash', p_ExtractedSQLHash_3cdaeed9e9cd,
    'ExtractionStatus', p_ExtractionStatus_3cdaeed9e9cd,
    'ID', p_ID_3cdaeed9e9cd
  ));
  ELSE
    PERFORM "${mjSchema}"."spUpdateQuery"(p_SQL := p_SQL_3cdaeed9e9cd, p_TechnicalDescription := p_TechnicalDescription_3cdaeed9e9cd, p_ExtractedSQLHash := p_ExtractedSQLHash_3cdaeed9e9cd, p_ExtractionStatus := p_ExtractionStatus_3cdaeed9e9cd, p_ID := p_ID_3cdaeed9e9cd);
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cbfbdff120ec UUID;
  p_QueryID_cbfbdff120ec UUID;
  p_Name_cbfbdff120ec VARCHAR(255);
  p_Description_cbfbdff120ec TEXT;
  p_Sequence_cbfbdff120ec INTEGER;
  p_SQLBaseType_cbfbdff120ec VARCHAR(50);
  p_SQLFullType_cbfbdff120ec VARCHAR(100);
  p_SourceEntityID_cbfbdff120ec UUID;
  p_SourceFieldName_cbfbdff120ec VARCHAR(255);
  p_IsComputed_cbfbdff120ec BOOLEAN;
  p_ComputationDescription_cbfbdff120ec TEXT;
  p_IsSummary_cbfbdff120ec BOOLEAN;
  p_SummaryDescription_cbfbdff120ec TEXT;
  p_DetectionMethod_cbfbdff120ec VARCHAR(50);
  p_AutoDetectConfidenceScore_cbfbdff120ec NUMERIC(3,2);
  p_SourceEntityFieldID_cbfbdff120ec UUID;
  p_IsNullable_cbfbdff120ec BOOLEAN;
  p_SourceObjectName_cbfbdff120ec VARCHAR(500);
BEGIN
  p_ID_cbfbdff120ec := '9fb160d9-9d75-4a2e-a7a0-ba0c469720ff';
  p_QueryID_cbfbdff120ec := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_cbfbdff120ec := 'TotalPeople';
  p_Sequence_cbfbdff120ec := 1;
  p_SQLBaseType_cbfbdff120ec := 'int';
  p_SQLFullType_cbfbdff120ec := 'int';
  p_IsComputed_cbfbdff120ec := TRUE;
  p_IsSummary_cbfbdff120ec := FALSE;
  p_DetectionMethod_cbfbdff120ec := 'Database';
  p_IsNullable_cbfbdff120ec := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_cbfbdff120ec
                    OR ("QueryID" = p_QueryID_cbfbdff120ec AND "Name" = p_Name_cbfbdff120ec)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_cbfbdff120ec,
    'QueryID', p_QueryID_cbfbdff120ec,
    'Name', p_Name_cbfbdff120ec,
    'Description', p_Description_cbfbdff120ec,
    'Sequence', p_Sequence_cbfbdff120ec,
    'SQLBaseType', p_SQLBaseType_cbfbdff120ec,
    'SQLFullType', p_SQLFullType_cbfbdff120ec,
    'SourceEntityID', p_SourceEntityID_cbfbdff120ec,
    'SourceFieldName', p_SourceFieldName_cbfbdff120ec,
    'IsComputed', p_IsComputed_cbfbdff120ec,
    'ComputationDescription', p_ComputationDescription_cbfbdff120ec,
    'IsSummary', p_IsSummary_cbfbdff120ec,
    'SummaryDescription', p_SummaryDescription_cbfbdff120ec,
    'DetectionMethod', p_DetectionMethod_cbfbdff120ec,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_cbfbdff120ec,
    'SourceEntityFieldID', p_SourceEntityFieldID_cbfbdff120ec,
    'IsNullable', p_IsNullable_cbfbdff120ec,
    'SourceObjectName', p_SourceObjectName_cbfbdff120ec
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_cbfbdff120ec, p_QueryID := p_QueryID_cbfbdff120ec, p_Name := p_Name_cbfbdff120ec, p_Description := p_Description_cbfbdff120ec, p_Description_Clear := TRUE, p_Sequence := p_Sequence_cbfbdff120ec, p_SQLBaseType := p_SQLBaseType_cbfbdff120ec, p_SQLFullType := p_SQLFullType_cbfbdff120ec, p_SourceEntityID := p_SourceEntityID_cbfbdff120ec, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_cbfbdff120ec, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_cbfbdff120ec, p_ComputationDescription := p_ComputationDescription_cbfbdff120ec, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_cbfbdff120ec, p_SummaryDescription := p_SummaryDescription_cbfbdff120ec, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_cbfbdff120ec, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_cbfbdff120ec, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_cbfbdff120ec, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_cbfbdff120ec, p_SourceObjectName := p_SourceObjectName_cbfbdff120ec, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5b4c8f5877a8 UUID;
  p_QueryID_5b4c8f5877a8 UUID;
  p_Name_5b4c8f5877a8 VARCHAR(255);
  p_Description_5b4c8f5877a8 TEXT;
  p_Sequence_5b4c8f5877a8 INTEGER;
  p_SQLBaseType_5b4c8f5877a8 VARCHAR(50);
  p_SQLFullType_5b4c8f5877a8 VARCHAR(100);
  p_SourceEntityID_5b4c8f5877a8 UUID;
  p_SourceFieldName_5b4c8f5877a8 VARCHAR(255);
  p_IsComputed_5b4c8f5877a8 BOOLEAN;
  p_ComputationDescription_5b4c8f5877a8 TEXT;
  p_IsSummary_5b4c8f5877a8 BOOLEAN;
  p_SummaryDescription_5b4c8f5877a8 TEXT;
  p_DetectionMethod_5b4c8f5877a8 VARCHAR(50);
  p_AutoDetectConfidenceScore_5b4c8f5877a8 NUMERIC(3,2);
  p_SourceEntityFieldID_5b4c8f5877a8 UUID;
  p_IsNullable_5b4c8f5877a8 BOOLEAN;
  p_SourceObjectName_5b4c8f5877a8 VARCHAR(500);
BEGIN
  p_ID_5b4c8f5877a8 := '863e433a-8f1a-42f3-a472-1a0c8c2596bb';
  p_QueryID_5b4c8f5877a8 := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_5b4c8f5877a8 := 'ActivePeople';
  p_Sequence_5b4c8f5877a8 := 2;
  p_SQLBaseType_5b4c8f5877a8 := 'int';
  p_SQLFullType_5b4c8f5877a8 := 'int';
  p_IsComputed_5b4c8f5877a8 := TRUE;
  p_IsSummary_5b4c8f5877a8 := FALSE;
  p_DetectionMethod_5b4c8f5877a8 := 'Database';
  p_IsNullable_5b4c8f5877a8 := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_5b4c8f5877a8
                    OR ("QueryID" = p_QueryID_5b4c8f5877a8 AND "Name" = p_Name_5b4c8f5877a8)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_5b4c8f5877a8,
    'QueryID', p_QueryID_5b4c8f5877a8,
    'Name', p_Name_5b4c8f5877a8,
    'Description', p_Description_5b4c8f5877a8,
    'Sequence', p_Sequence_5b4c8f5877a8,
    'SQLBaseType', p_SQLBaseType_5b4c8f5877a8,
    'SQLFullType', p_SQLFullType_5b4c8f5877a8,
    'SourceEntityID', p_SourceEntityID_5b4c8f5877a8,
    'SourceFieldName', p_SourceFieldName_5b4c8f5877a8,
    'IsComputed', p_IsComputed_5b4c8f5877a8,
    'ComputationDescription', p_ComputationDescription_5b4c8f5877a8,
    'IsSummary', p_IsSummary_5b4c8f5877a8,
    'SummaryDescription', p_SummaryDescription_5b4c8f5877a8,
    'DetectionMethod', p_DetectionMethod_5b4c8f5877a8,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_5b4c8f5877a8,
    'SourceEntityFieldID', p_SourceEntityFieldID_5b4c8f5877a8,
    'IsNullable', p_IsNullable_5b4c8f5877a8,
    'SourceObjectName', p_SourceObjectName_5b4c8f5877a8
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_5b4c8f5877a8, p_QueryID := p_QueryID_5b4c8f5877a8, p_Name := p_Name_5b4c8f5877a8, p_Description := p_Description_5b4c8f5877a8, p_Description_Clear := TRUE, p_Sequence := p_Sequence_5b4c8f5877a8, p_SQLBaseType := p_SQLBaseType_5b4c8f5877a8, p_SQLFullType := p_SQLFullType_5b4c8f5877a8, p_SourceEntityID := p_SourceEntityID_5b4c8f5877a8, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_5b4c8f5877a8, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_5b4c8f5877a8, p_ComputationDescription := p_ComputationDescription_5b4c8f5877a8, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_5b4c8f5877a8, p_SummaryDescription := p_SummaryDescription_5b4c8f5877a8, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_5b4c8f5877a8, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_5b4c8f5877a8, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_5b4c8f5877a8, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_5b4c8f5877a8, p_SourceObjectName := p_SourceObjectName_5b4c8f5877a8, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_2acf9019c7ae UUID;
  p_QueryID_2acf9019c7ae UUID;
  p_Name_2acf9019c7ae VARCHAR(255);
  p_Description_2acf9019c7ae TEXT;
  p_Sequence_2acf9019c7ae INTEGER;
  p_SQLBaseType_2acf9019c7ae VARCHAR(50);
  p_SQLFullType_2acf9019c7ae VARCHAR(100);
  p_SourceEntityID_2acf9019c7ae UUID;
  p_SourceFieldName_2acf9019c7ae VARCHAR(255);
  p_IsComputed_2acf9019c7ae BOOLEAN;
  p_ComputationDescription_2acf9019c7ae TEXT;
  p_IsSummary_2acf9019c7ae BOOLEAN;
  p_SummaryDescription_2acf9019c7ae TEXT;
  p_DetectionMethod_2acf9019c7ae VARCHAR(50);
  p_AutoDetectConfidenceScore_2acf9019c7ae NUMERIC(3,2);
  p_SourceEntityFieldID_2acf9019c7ae UUID;
  p_IsNullable_2acf9019c7ae BOOLEAN;
  p_SourceObjectName_2acf9019c7ae VARCHAR(500);
BEGIN
  p_ID_2acf9019c7ae := '8e623c7f-e5ab-4096-87e4-9ba7d346b174';
  p_QueryID_2acf9019c7ae := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_2acf9019c7ae := 'PeopleMissingEmail';
  p_Sequence_2acf9019c7ae := 3;
  p_SQLBaseType_2acf9019c7ae := 'int';
  p_SQLFullType_2acf9019c7ae := 'int';
  p_IsComputed_2acf9019c7ae := TRUE;
  p_IsSummary_2acf9019c7ae := FALSE;
  p_DetectionMethod_2acf9019c7ae := 'Database';
  p_IsNullable_2acf9019c7ae := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_2acf9019c7ae
                    OR ("QueryID" = p_QueryID_2acf9019c7ae AND "Name" = p_Name_2acf9019c7ae)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_2acf9019c7ae,
    'QueryID', p_QueryID_2acf9019c7ae,
    'Name', p_Name_2acf9019c7ae,
    'Description', p_Description_2acf9019c7ae,
    'Sequence', p_Sequence_2acf9019c7ae,
    'SQLBaseType', p_SQLBaseType_2acf9019c7ae,
    'SQLFullType', p_SQLFullType_2acf9019c7ae,
    'SourceEntityID', p_SourceEntityID_2acf9019c7ae,
    'SourceFieldName', p_SourceFieldName_2acf9019c7ae,
    'IsComputed', p_IsComputed_2acf9019c7ae,
    'ComputationDescription', p_ComputationDescription_2acf9019c7ae,
    'IsSummary', p_IsSummary_2acf9019c7ae,
    'SummaryDescription', p_SummaryDescription_2acf9019c7ae,
    'DetectionMethod', p_DetectionMethod_2acf9019c7ae,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_2acf9019c7ae,
    'SourceEntityFieldID', p_SourceEntityFieldID_2acf9019c7ae,
    'IsNullable', p_IsNullable_2acf9019c7ae,
    'SourceObjectName', p_SourceObjectName_2acf9019c7ae
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_2acf9019c7ae, p_QueryID := p_QueryID_2acf9019c7ae, p_Name := p_Name_2acf9019c7ae, p_Description := p_Description_2acf9019c7ae, p_Description_Clear := TRUE, p_Sequence := p_Sequence_2acf9019c7ae, p_SQLBaseType := p_SQLBaseType_2acf9019c7ae, p_SQLFullType := p_SQLFullType_2acf9019c7ae, p_SourceEntityID := p_SourceEntityID_2acf9019c7ae, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_2acf9019c7ae, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_2acf9019c7ae, p_ComputationDescription := p_ComputationDescription_2acf9019c7ae, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_2acf9019c7ae, p_SummaryDescription := p_SummaryDescription_2acf9019c7ae, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_2acf9019c7ae, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_2acf9019c7ae, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_2acf9019c7ae, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_2acf9019c7ae, p_SourceObjectName := p_SourceObjectName_2acf9019c7ae, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a7db28e0cea6 UUID;
  p_QueryID_a7db28e0cea6 UUID;
  p_Name_a7db28e0cea6 VARCHAR(255);
  p_Description_a7db28e0cea6 TEXT;
  p_Sequence_a7db28e0cea6 INTEGER;
  p_SQLBaseType_a7db28e0cea6 VARCHAR(50);
  p_SQLFullType_a7db28e0cea6 VARCHAR(100);
  p_SourceEntityID_a7db28e0cea6 UUID;
  p_SourceFieldName_a7db28e0cea6 VARCHAR(255);
  p_IsComputed_a7db28e0cea6 BOOLEAN;
  p_ComputationDescription_a7db28e0cea6 TEXT;
  p_IsSummary_a7db28e0cea6 BOOLEAN;
  p_SummaryDescription_a7db28e0cea6 TEXT;
  p_DetectionMethod_a7db28e0cea6 VARCHAR(50);
  p_AutoDetectConfidenceScore_a7db28e0cea6 NUMERIC(3,2);
  p_SourceEntityFieldID_a7db28e0cea6 UUID;
  p_IsNullable_a7db28e0cea6 BOOLEAN;
  p_SourceObjectName_a7db28e0cea6 VARCHAR(500);
BEGIN
  p_ID_a7db28e0cea6 := '31473fa7-289f-405a-880c-f0d6c6962897';
  p_QueryID_a7db28e0cea6 := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_a7db28e0cea6 := 'PeopleMissingOrganization';
  p_Sequence_a7db28e0cea6 := 4;
  p_SQLBaseType_a7db28e0cea6 := 'int';
  p_SQLFullType_a7db28e0cea6 := 'int';
  p_IsComputed_a7db28e0cea6 := TRUE;
  p_IsSummary_a7db28e0cea6 := FALSE;
  p_DetectionMethod_a7db28e0cea6 := 'Database';
  p_IsNullable_a7db28e0cea6 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_a7db28e0cea6
                    OR ("QueryID" = p_QueryID_a7db28e0cea6 AND "Name" = p_Name_a7db28e0cea6)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_a7db28e0cea6,
    'QueryID', p_QueryID_a7db28e0cea6,
    'Name', p_Name_a7db28e0cea6,
    'Description', p_Description_a7db28e0cea6,
    'Sequence', p_Sequence_a7db28e0cea6,
    'SQLBaseType', p_SQLBaseType_a7db28e0cea6,
    'SQLFullType', p_SQLFullType_a7db28e0cea6,
    'SourceEntityID', p_SourceEntityID_a7db28e0cea6,
    'SourceFieldName', p_SourceFieldName_a7db28e0cea6,
    'IsComputed', p_IsComputed_a7db28e0cea6,
    'ComputationDescription', p_ComputationDescription_a7db28e0cea6,
    'IsSummary', p_IsSummary_a7db28e0cea6,
    'SummaryDescription', p_SummaryDescription_a7db28e0cea6,
    'DetectionMethod', p_DetectionMethod_a7db28e0cea6,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_a7db28e0cea6,
    'SourceEntityFieldID', p_SourceEntityFieldID_a7db28e0cea6,
    'IsNullable', p_IsNullable_a7db28e0cea6,
    'SourceObjectName', p_SourceObjectName_a7db28e0cea6
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_a7db28e0cea6, p_QueryID := p_QueryID_a7db28e0cea6, p_Name := p_Name_a7db28e0cea6, p_Description := p_Description_a7db28e0cea6, p_Description_Clear := TRUE, p_Sequence := p_Sequence_a7db28e0cea6, p_SQLBaseType := p_SQLBaseType_a7db28e0cea6, p_SQLFullType := p_SQLFullType_a7db28e0cea6, p_SourceEntityID := p_SourceEntityID_a7db28e0cea6, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_a7db28e0cea6, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_a7db28e0cea6, p_ComputationDescription := p_ComputationDescription_a7db28e0cea6, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_a7db28e0cea6, p_SummaryDescription := p_SummaryDescription_a7db28e0cea6, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_a7db28e0cea6, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_a7db28e0cea6, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_a7db28e0cea6, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_a7db28e0cea6, p_SourceObjectName := p_SourceObjectName_a7db28e0cea6, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0f84046eeb6d UUID;
  p_QueryID_0f84046eeb6d UUID;
  p_Name_0f84046eeb6d VARCHAR(255);
  p_Description_0f84046eeb6d TEXT;
  p_Sequence_0f84046eeb6d INTEGER;
  p_SQLBaseType_0f84046eeb6d VARCHAR(50);
  p_SQLFullType_0f84046eeb6d VARCHAR(100);
  p_SourceEntityID_0f84046eeb6d UUID;
  p_SourceFieldName_0f84046eeb6d VARCHAR(255);
  p_IsComputed_0f84046eeb6d BOOLEAN;
  p_ComputationDescription_0f84046eeb6d TEXT;
  p_IsSummary_0f84046eeb6d BOOLEAN;
  p_SummaryDescription_0f84046eeb6d TEXT;
  p_DetectionMethod_0f84046eeb6d VARCHAR(50);
  p_AutoDetectConfidenceScore_0f84046eeb6d NUMERIC(3,2);
  p_SourceEntityFieldID_0f84046eeb6d UUID;
  p_IsNullable_0f84046eeb6d BOOLEAN;
  p_SourceObjectName_0f84046eeb6d VARCHAR(500);
BEGIN
  p_ID_0f84046eeb6d := '30fa4952-6180-4929-80f3-14b45995a148';
  p_QueryID_0f84046eeb6d := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_0f84046eeb6d := 'AttentionEmailPersonID';
  p_Sequence_0f84046eeb6d := 5;
  p_SQLBaseType_0f84046eeb6d := 'uniqueidentifier';
  p_SQLFullType_0f84046eeb6d := 'uniqueidentifier';
  p_SourceEntityID_0f84046eeb6d := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_SourceFieldName_0f84046eeb6d := 'ID';
  p_IsComputed_0f84046eeb6d := FALSE;
  p_IsSummary_0f84046eeb6d := FALSE;
  p_DetectionMethod_0f84046eeb6d := 'Database';
  p_SourceEntityFieldID_0f84046eeb6d := '2A0B54F1-94F8-466C-86C2-931E200258C1';
  p_IsNullable_0f84046eeb6d := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_0f84046eeb6d
                    OR ("QueryID" = p_QueryID_0f84046eeb6d AND "Name" = p_Name_0f84046eeb6d)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_0f84046eeb6d,
    'QueryID', p_QueryID_0f84046eeb6d,
    'Name', p_Name_0f84046eeb6d,
    'Description', p_Description_0f84046eeb6d,
    'Sequence', p_Sequence_0f84046eeb6d,
    'SQLBaseType', p_SQLBaseType_0f84046eeb6d,
    'SQLFullType', p_SQLFullType_0f84046eeb6d,
    'SourceEntityID', p_SourceEntityID_0f84046eeb6d,
    'SourceFieldName', p_SourceFieldName_0f84046eeb6d,
    'IsComputed', p_IsComputed_0f84046eeb6d,
    'ComputationDescription', p_ComputationDescription_0f84046eeb6d,
    'IsSummary', p_IsSummary_0f84046eeb6d,
    'SummaryDescription', p_SummaryDescription_0f84046eeb6d,
    'DetectionMethod', p_DetectionMethod_0f84046eeb6d,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_0f84046eeb6d,
    'SourceEntityFieldID', p_SourceEntityFieldID_0f84046eeb6d,
    'IsNullable', p_IsNullable_0f84046eeb6d,
    'SourceObjectName', p_SourceObjectName_0f84046eeb6d
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_0f84046eeb6d, p_QueryID := p_QueryID_0f84046eeb6d, p_Name := p_Name_0f84046eeb6d, p_Description := p_Description_0f84046eeb6d, p_Description_Clear := TRUE, p_Sequence := p_Sequence_0f84046eeb6d, p_SQLBaseType := p_SQLBaseType_0f84046eeb6d, p_SQLFullType := p_SQLFullType_0f84046eeb6d, p_SourceEntityID := p_SourceEntityID_0f84046eeb6d, p_SourceFieldName := p_SourceFieldName_0f84046eeb6d, p_IsComputed := p_IsComputed_0f84046eeb6d, p_ComputationDescription := p_ComputationDescription_0f84046eeb6d, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_0f84046eeb6d, p_SummaryDescription := p_SummaryDescription_0f84046eeb6d, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_0f84046eeb6d, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_0f84046eeb6d, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_0f84046eeb6d, p_IsNullable := p_IsNullable_0f84046eeb6d, p_SourceObjectName := p_SourceObjectName_0f84046eeb6d, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5d97ae8bad66 UUID;
  p_QueryID_5d97ae8bad66 UUID;
  p_Name_5d97ae8bad66 VARCHAR(255);
  p_Description_5d97ae8bad66 TEXT;
  p_Sequence_5d97ae8bad66 INTEGER;
  p_SQLBaseType_5d97ae8bad66 VARCHAR(50);
  p_SQLFullType_5d97ae8bad66 VARCHAR(100);
  p_SourceEntityID_5d97ae8bad66 UUID;
  p_SourceFieldName_5d97ae8bad66 VARCHAR(255);
  p_IsComputed_5d97ae8bad66 BOOLEAN;
  p_ComputationDescription_5d97ae8bad66 TEXT;
  p_IsSummary_5d97ae8bad66 BOOLEAN;
  p_SummaryDescription_5d97ae8bad66 TEXT;
  p_DetectionMethod_5d97ae8bad66 VARCHAR(50);
  p_AutoDetectConfidenceScore_5d97ae8bad66 NUMERIC(3,2);
  p_SourceEntityFieldID_5d97ae8bad66 UUID;
  p_IsNullable_5d97ae8bad66 BOOLEAN;
  p_SourceObjectName_5d97ae8bad66 VARCHAR(500);
BEGIN
  p_ID_5d97ae8bad66 := 'adbb1bfa-a7bc-4a9f-b9e4-e662d7e39b26';
  p_QueryID_5d97ae8bad66 := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_5d97ae8bad66 := 'AttentionEmailName';
  p_Description_5d97ae8bad66 := 'Full name for display: FirstName LastName Suffix ("John Smith Jr."). Blank parts are skipped; empty when every part is blank. Computed and stored; this is the entity name field.';
  p_Sequence_5d97ae8bad66 := 6;
  p_SQLBaseType_5d97ae8bad66 := 'nvarchar';
  p_SQLFullType_5d97ae8bad66 := 'nvarchar(250)';
  p_SourceEntityID_5d97ae8bad66 := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_SourceFieldName_5d97ae8bad66 := 'DisplayName';
  p_IsComputed_5d97ae8bad66 := FALSE;
  p_IsSummary_5d97ae8bad66 := FALSE;
  p_DetectionMethod_5d97ae8bad66 := 'Database';
  p_SourceEntityFieldID_5d97ae8bad66 := '76D49448-C586-4701-9FFF-63F390EC78C0';
  p_IsNullable_5d97ae8bad66 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_5d97ae8bad66
                    OR ("QueryID" = p_QueryID_5d97ae8bad66 AND "Name" = p_Name_5d97ae8bad66)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_5d97ae8bad66,
    'QueryID', p_QueryID_5d97ae8bad66,
    'Name', p_Name_5d97ae8bad66,
    'Description', p_Description_5d97ae8bad66,
    'Sequence', p_Sequence_5d97ae8bad66,
    'SQLBaseType', p_SQLBaseType_5d97ae8bad66,
    'SQLFullType', p_SQLFullType_5d97ae8bad66,
    'SourceEntityID', p_SourceEntityID_5d97ae8bad66,
    'SourceFieldName', p_SourceFieldName_5d97ae8bad66,
    'IsComputed', p_IsComputed_5d97ae8bad66,
    'ComputationDescription', p_ComputationDescription_5d97ae8bad66,
    'IsSummary', p_IsSummary_5d97ae8bad66,
    'SummaryDescription', p_SummaryDescription_5d97ae8bad66,
    'DetectionMethod', p_DetectionMethod_5d97ae8bad66,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_5d97ae8bad66,
    'SourceEntityFieldID', p_SourceEntityFieldID_5d97ae8bad66,
    'IsNullable', p_IsNullable_5d97ae8bad66,
    'SourceObjectName', p_SourceObjectName_5d97ae8bad66
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_5d97ae8bad66, p_QueryID := p_QueryID_5d97ae8bad66, p_Name := p_Name_5d97ae8bad66, p_Description := p_Description_5d97ae8bad66, p_Sequence := p_Sequence_5d97ae8bad66, p_SQLBaseType := p_SQLBaseType_5d97ae8bad66, p_SQLFullType := p_SQLFullType_5d97ae8bad66, p_SourceEntityID := p_SourceEntityID_5d97ae8bad66, p_SourceFieldName := p_SourceFieldName_5d97ae8bad66, p_IsComputed := p_IsComputed_5d97ae8bad66, p_ComputationDescription := p_ComputationDescription_5d97ae8bad66, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_5d97ae8bad66, p_SummaryDescription := p_SummaryDescription_5d97ae8bad66, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_5d97ae8bad66, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_5d97ae8bad66, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_5d97ae8bad66, p_IsNullable := p_IsNullable_5d97ae8bad66, p_SourceObjectName := p_SourceObjectName_5d97ae8bad66, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_635ab6d2d82f UUID;
  p_QueryID_635ab6d2d82f UUID;
  p_Name_635ab6d2d82f VARCHAR(255);
  p_Description_635ab6d2d82f TEXT;
  p_Sequence_635ab6d2d82f INTEGER;
  p_SQLBaseType_635ab6d2d82f VARCHAR(50);
  p_SQLFullType_635ab6d2d82f VARCHAR(100);
  p_SourceEntityID_635ab6d2d82f UUID;
  p_SourceFieldName_635ab6d2d82f VARCHAR(255);
  p_IsComputed_635ab6d2d82f BOOLEAN;
  p_ComputationDescription_635ab6d2d82f TEXT;
  p_IsSummary_635ab6d2d82f BOOLEAN;
  p_SummaryDescription_635ab6d2d82f TEXT;
  p_DetectionMethod_635ab6d2d82f VARCHAR(50);
  p_AutoDetectConfidenceScore_635ab6d2d82f NUMERIC(3,2);
  p_SourceEntityFieldID_635ab6d2d82f UUID;
  p_IsNullable_635ab6d2d82f BOOLEAN;
  p_SourceObjectName_635ab6d2d82f VARCHAR(500);
BEGIN
  p_ID_635ab6d2d82f := 'ae73d2b4-84bd-4ed6-a888-c0e878756eb7';
  p_QueryID_635ab6d2d82f := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_635ab6d2d82f := 'AttentionEmailOrg';
  p_Sequence_635ab6d2d82f := 7;
  p_SQLBaseType_635ab6d2d82f := 'nvarchar';
  p_SQLFullType_635ab6d2d82f := 'nvarchar(255)';
  p_SourceEntityID_635ab6d2d82f := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_SourceFieldName_635ab6d2d82f := 'CurrentOrganizationName';
  p_IsComputed_635ab6d2d82f := FALSE;
  p_IsSummary_635ab6d2d82f := FALSE;
  p_DetectionMethod_635ab6d2d82f := 'Database';
  p_SourceEntityFieldID_635ab6d2d82f := '0904A337-B7D5-4EF5-A431-D780F5EA6140';
  p_IsNullable_635ab6d2d82f := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_635ab6d2d82f
                    OR ("QueryID" = p_QueryID_635ab6d2d82f AND "Name" = p_Name_635ab6d2d82f)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_635ab6d2d82f,
    'QueryID', p_QueryID_635ab6d2d82f,
    'Name', p_Name_635ab6d2d82f,
    'Description', p_Description_635ab6d2d82f,
    'Sequence', p_Sequence_635ab6d2d82f,
    'SQLBaseType', p_SQLBaseType_635ab6d2d82f,
    'SQLFullType', p_SQLFullType_635ab6d2d82f,
    'SourceEntityID', p_SourceEntityID_635ab6d2d82f,
    'SourceFieldName', p_SourceFieldName_635ab6d2d82f,
    'IsComputed', p_IsComputed_635ab6d2d82f,
    'ComputationDescription', p_ComputationDescription_635ab6d2d82f,
    'IsSummary', p_IsSummary_635ab6d2d82f,
    'SummaryDescription', p_SummaryDescription_635ab6d2d82f,
    'DetectionMethod', p_DetectionMethod_635ab6d2d82f,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_635ab6d2d82f,
    'SourceEntityFieldID', p_SourceEntityFieldID_635ab6d2d82f,
    'IsNullable', p_IsNullable_635ab6d2d82f,
    'SourceObjectName', p_SourceObjectName_635ab6d2d82f
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_635ab6d2d82f, p_QueryID := p_QueryID_635ab6d2d82f, p_Name := p_Name_635ab6d2d82f, p_Description := p_Description_635ab6d2d82f, p_Description_Clear := TRUE, p_Sequence := p_Sequence_635ab6d2d82f, p_SQLBaseType := p_SQLBaseType_635ab6d2d82f, p_SQLFullType := p_SQLFullType_635ab6d2d82f, p_SourceEntityID := p_SourceEntityID_635ab6d2d82f, p_SourceFieldName := p_SourceFieldName_635ab6d2d82f, p_IsComputed := p_IsComputed_635ab6d2d82f, p_ComputationDescription := p_ComputationDescription_635ab6d2d82f, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_635ab6d2d82f, p_SummaryDescription := p_SummaryDescription_635ab6d2d82f, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_635ab6d2d82f, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_635ab6d2d82f, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_635ab6d2d82f, p_IsNullable := p_IsNullable_635ab6d2d82f, p_SourceObjectName := p_SourceObjectName_635ab6d2d82f, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_980a95359544 UUID;
  p_QueryID_980a95359544 UUID;
  p_Name_980a95359544 VARCHAR(255);
  p_Description_980a95359544 TEXT;
  p_Sequence_980a95359544 INTEGER;
  p_SQLBaseType_980a95359544 VARCHAR(50);
  p_SQLFullType_980a95359544 VARCHAR(100);
  p_SourceEntityID_980a95359544 UUID;
  p_SourceFieldName_980a95359544 VARCHAR(255);
  p_IsComputed_980a95359544 BOOLEAN;
  p_ComputationDescription_980a95359544 TEXT;
  p_IsSummary_980a95359544 BOOLEAN;
  p_SummaryDescription_980a95359544 TEXT;
  p_DetectionMethod_980a95359544 VARCHAR(50);
  p_AutoDetectConfidenceScore_980a95359544 NUMERIC(3,2);
  p_SourceEntityFieldID_980a95359544 UUID;
  p_IsNullable_980a95359544 BOOLEAN;
  p_SourceObjectName_980a95359544 VARCHAR(500);
BEGIN
  p_ID_980a95359544 := '1aa0bfa8-f839-4f04-b071-041162c73c3b';
  p_QueryID_980a95359544 := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_980a95359544 := 'TotalOrganizations';
  p_Sequence_980a95359544 := 8;
  p_SQLBaseType_980a95359544 := 'int';
  p_SQLFullType_980a95359544 := 'int';
  p_IsComputed_980a95359544 := TRUE;
  p_IsSummary_980a95359544 := FALSE;
  p_DetectionMethod_980a95359544 := 'Database';
  p_IsNullable_980a95359544 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_980a95359544
                    OR ("QueryID" = p_QueryID_980a95359544 AND "Name" = p_Name_980a95359544)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_980a95359544,
    'QueryID', p_QueryID_980a95359544,
    'Name', p_Name_980a95359544,
    'Description', p_Description_980a95359544,
    'Sequence', p_Sequence_980a95359544,
    'SQLBaseType', p_SQLBaseType_980a95359544,
    'SQLFullType', p_SQLFullType_980a95359544,
    'SourceEntityID', p_SourceEntityID_980a95359544,
    'SourceFieldName', p_SourceFieldName_980a95359544,
    'IsComputed', p_IsComputed_980a95359544,
    'ComputationDescription', p_ComputationDescription_980a95359544,
    'IsSummary', p_IsSummary_980a95359544,
    'SummaryDescription', p_SummaryDescription_980a95359544,
    'DetectionMethod', p_DetectionMethod_980a95359544,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_980a95359544,
    'SourceEntityFieldID', p_SourceEntityFieldID_980a95359544,
    'IsNullable', p_IsNullable_980a95359544,
    'SourceObjectName', p_SourceObjectName_980a95359544
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_980a95359544, p_QueryID := p_QueryID_980a95359544, p_Name := p_Name_980a95359544, p_Description := p_Description_980a95359544, p_Description_Clear := TRUE, p_Sequence := p_Sequence_980a95359544, p_SQLBaseType := p_SQLBaseType_980a95359544, p_SQLFullType := p_SQLFullType_980a95359544, p_SourceEntityID := p_SourceEntityID_980a95359544, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_980a95359544, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_980a95359544, p_ComputationDescription := p_ComputationDescription_980a95359544, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_980a95359544, p_SummaryDescription := p_SummaryDescription_980a95359544, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_980a95359544, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_980a95359544, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_980a95359544, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_980a95359544, p_SourceObjectName := p_SourceObjectName_980a95359544, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e42d5f99c63d UUID;
  p_QueryID_e42d5f99c63d UUID;
  p_Name_e42d5f99c63d VARCHAR(255);
  p_Description_e42d5f99c63d TEXT;
  p_Sequence_e42d5f99c63d INTEGER;
  p_SQLBaseType_e42d5f99c63d VARCHAR(50);
  p_SQLFullType_e42d5f99c63d VARCHAR(100);
  p_SourceEntityID_e42d5f99c63d UUID;
  p_SourceFieldName_e42d5f99c63d VARCHAR(255);
  p_IsComputed_e42d5f99c63d BOOLEAN;
  p_ComputationDescription_e42d5f99c63d TEXT;
  p_IsSummary_e42d5f99c63d BOOLEAN;
  p_SummaryDescription_e42d5f99c63d TEXT;
  p_DetectionMethod_e42d5f99c63d VARCHAR(50);
  p_AutoDetectConfidenceScore_e42d5f99c63d NUMERIC(3,2);
  p_SourceEntityFieldID_e42d5f99c63d UUID;
  p_IsNullable_e42d5f99c63d BOOLEAN;
  p_SourceObjectName_e42d5f99c63d VARCHAR(500);
BEGIN
  p_ID_e42d5f99c63d := '5e4f6267-a0e4-4e86-851e-cc332263cd0d';
  p_QueryID_e42d5f99c63d := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_e42d5f99c63d := 'ActiveOrganizations';
  p_Sequence_e42d5f99c63d := 9;
  p_SQLBaseType_e42d5f99c63d := 'int';
  p_SQLFullType_e42d5f99c63d := 'int';
  p_IsComputed_e42d5f99c63d := TRUE;
  p_IsSummary_e42d5f99c63d := FALSE;
  p_DetectionMethod_e42d5f99c63d := 'Database';
  p_IsNullable_e42d5f99c63d := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_e42d5f99c63d
                    OR ("QueryID" = p_QueryID_e42d5f99c63d AND "Name" = p_Name_e42d5f99c63d)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_e42d5f99c63d,
    'QueryID', p_QueryID_e42d5f99c63d,
    'Name', p_Name_e42d5f99c63d,
    'Description', p_Description_e42d5f99c63d,
    'Sequence', p_Sequence_e42d5f99c63d,
    'SQLBaseType', p_SQLBaseType_e42d5f99c63d,
    'SQLFullType', p_SQLFullType_e42d5f99c63d,
    'SourceEntityID', p_SourceEntityID_e42d5f99c63d,
    'SourceFieldName', p_SourceFieldName_e42d5f99c63d,
    'IsComputed', p_IsComputed_e42d5f99c63d,
    'ComputationDescription', p_ComputationDescription_e42d5f99c63d,
    'IsSummary', p_IsSummary_e42d5f99c63d,
    'SummaryDescription', p_SummaryDescription_e42d5f99c63d,
    'DetectionMethod', p_DetectionMethod_e42d5f99c63d,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_e42d5f99c63d,
    'SourceEntityFieldID', p_SourceEntityFieldID_e42d5f99c63d,
    'IsNullable', p_IsNullable_e42d5f99c63d,
    'SourceObjectName', p_SourceObjectName_e42d5f99c63d
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_e42d5f99c63d, p_QueryID := p_QueryID_e42d5f99c63d, p_Name := p_Name_e42d5f99c63d, p_Description := p_Description_e42d5f99c63d, p_Description_Clear := TRUE, p_Sequence := p_Sequence_e42d5f99c63d, p_SQLBaseType := p_SQLBaseType_e42d5f99c63d, p_SQLFullType := p_SQLFullType_e42d5f99c63d, p_SourceEntityID := p_SourceEntityID_e42d5f99c63d, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_e42d5f99c63d, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_e42d5f99c63d, p_ComputationDescription := p_ComputationDescription_e42d5f99c63d, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_e42d5f99c63d, p_SummaryDescription := p_SummaryDescription_e42d5f99c63d, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_e42d5f99c63d, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_e42d5f99c63d, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_e42d5f99c63d, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_e42d5f99c63d, p_SourceObjectName := p_SourceObjectName_e42d5f99c63d, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ab87037c3d46 UUID;
  p_QueryID_ab87037c3d46 UUID;
  p_Name_ab87037c3d46 VARCHAR(255);
  p_Description_ab87037c3d46 TEXT;
  p_Sequence_ab87037c3d46 INTEGER;
  p_SQLBaseType_ab87037c3d46 VARCHAR(50);
  p_SQLFullType_ab87037c3d46 VARCHAR(100);
  p_SourceEntityID_ab87037c3d46 UUID;
  p_SourceFieldName_ab87037c3d46 VARCHAR(255);
  p_IsComputed_ab87037c3d46 BOOLEAN;
  p_ComputationDescription_ab87037c3d46 TEXT;
  p_IsSummary_ab87037c3d46 BOOLEAN;
  p_SummaryDescription_ab87037c3d46 TEXT;
  p_DetectionMethod_ab87037c3d46 VARCHAR(50);
  p_AutoDetectConfidenceScore_ab87037c3d46 NUMERIC(3,2);
  p_SourceEntityFieldID_ab87037c3d46 UUID;
  p_IsNullable_ab87037c3d46 BOOLEAN;
  p_SourceObjectName_ab87037c3d46 VARCHAR(500);
BEGIN
  p_ID_ab87037c3d46 := '2eaf150f-b62d-4005-90b7-96995821f6b9';
  p_QueryID_ab87037c3d46 := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_ab87037c3d46 := 'OrganizationsMissingType';
  p_Sequence_ab87037c3d46 := 10;
  p_SQLBaseType_ab87037c3d46 := 'int';
  p_SQLFullType_ab87037c3d46 := 'int';
  p_IsComputed_ab87037c3d46 := TRUE;
  p_IsSummary_ab87037c3d46 := FALSE;
  p_DetectionMethod_ab87037c3d46 := 'Database';
  p_IsNullable_ab87037c3d46 := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_ab87037c3d46
                    OR ("QueryID" = p_QueryID_ab87037c3d46 AND "Name" = p_Name_ab87037c3d46)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_ab87037c3d46,
    'QueryID', p_QueryID_ab87037c3d46,
    'Name', p_Name_ab87037c3d46,
    'Description', p_Description_ab87037c3d46,
    'Sequence', p_Sequence_ab87037c3d46,
    'SQLBaseType', p_SQLBaseType_ab87037c3d46,
    'SQLFullType', p_SQLFullType_ab87037c3d46,
    'SourceEntityID', p_SourceEntityID_ab87037c3d46,
    'SourceFieldName', p_SourceFieldName_ab87037c3d46,
    'IsComputed', p_IsComputed_ab87037c3d46,
    'ComputationDescription', p_ComputationDescription_ab87037c3d46,
    'IsSummary', p_IsSummary_ab87037c3d46,
    'SummaryDescription', p_SummaryDescription_ab87037c3d46,
    'DetectionMethod', p_DetectionMethod_ab87037c3d46,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_ab87037c3d46,
    'SourceEntityFieldID', p_SourceEntityFieldID_ab87037c3d46,
    'IsNullable', p_IsNullable_ab87037c3d46,
    'SourceObjectName', p_SourceObjectName_ab87037c3d46
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_ab87037c3d46, p_QueryID := p_QueryID_ab87037c3d46, p_Name := p_Name_ab87037c3d46, p_Description := p_Description_ab87037c3d46, p_Description_Clear := TRUE, p_Sequence := p_Sequence_ab87037c3d46, p_SQLBaseType := p_SQLBaseType_ab87037c3d46, p_SQLFullType := p_SQLFullType_ab87037c3d46, p_SourceEntityID := p_SourceEntityID_ab87037c3d46, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_ab87037c3d46, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_ab87037c3d46, p_ComputationDescription := p_ComputationDescription_ab87037c3d46, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_ab87037c3d46, p_SummaryDescription := p_SummaryDescription_ab87037c3d46, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_ab87037c3d46, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_ab87037c3d46, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_ab87037c3d46, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_ab87037c3d46, p_SourceObjectName := p_SourceObjectName_ab87037c3d46, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_29dd5dc8333a UUID;
  p_QueryID_29dd5dc8333a UUID;
  p_Name_29dd5dc8333a VARCHAR(255);
  p_Description_29dd5dc8333a TEXT;
  p_Sequence_29dd5dc8333a INTEGER;
  p_SQLBaseType_29dd5dc8333a VARCHAR(50);
  p_SQLFullType_29dd5dc8333a VARCHAR(100);
  p_SourceEntityID_29dd5dc8333a UUID;
  p_SourceFieldName_29dd5dc8333a VARCHAR(255);
  p_IsComputed_29dd5dc8333a BOOLEAN;
  p_ComputationDescription_29dd5dc8333a TEXT;
  p_IsSummary_29dd5dc8333a BOOLEAN;
  p_SummaryDescription_29dd5dc8333a TEXT;
  p_DetectionMethod_29dd5dc8333a VARCHAR(50);
  p_AutoDetectConfidenceScore_29dd5dc8333a NUMERIC(3,2);
  p_SourceEntityFieldID_29dd5dc8333a UUID;
  p_IsNullable_29dd5dc8333a BOOLEAN;
  p_SourceObjectName_29dd5dc8333a VARCHAR(500);
BEGIN
  p_ID_29dd5dc8333a := '2adcedb6-5161-4e99-b456-4ecb8df3b664';
  p_QueryID_29dd5dc8333a := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_29dd5dc8333a := 'OrganizationsMissingWebsite';
  p_Sequence_29dd5dc8333a := 11;
  p_SQLBaseType_29dd5dc8333a := 'int';
  p_SQLFullType_29dd5dc8333a := 'int';
  p_IsComputed_29dd5dc8333a := TRUE;
  p_IsSummary_29dd5dc8333a := FALSE;
  p_DetectionMethod_29dd5dc8333a := 'Database';
  p_IsNullable_29dd5dc8333a := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_29dd5dc8333a
                    OR ("QueryID" = p_QueryID_29dd5dc8333a AND "Name" = p_Name_29dd5dc8333a)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_29dd5dc8333a,
    'QueryID', p_QueryID_29dd5dc8333a,
    'Name', p_Name_29dd5dc8333a,
    'Description', p_Description_29dd5dc8333a,
    'Sequence', p_Sequence_29dd5dc8333a,
    'SQLBaseType', p_SQLBaseType_29dd5dc8333a,
    'SQLFullType', p_SQLFullType_29dd5dc8333a,
    'SourceEntityID', p_SourceEntityID_29dd5dc8333a,
    'SourceFieldName', p_SourceFieldName_29dd5dc8333a,
    'IsComputed', p_IsComputed_29dd5dc8333a,
    'ComputationDescription', p_ComputationDescription_29dd5dc8333a,
    'IsSummary', p_IsSummary_29dd5dc8333a,
    'SummaryDescription', p_SummaryDescription_29dd5dc8333a,
    'DetectionMethod', p_DetectionMethod_29dd5dc8333a,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_29dd5dc8333a,
    'SourceEntityFieldID', p_SourceEntityFieldID_29dd5dc8333a,
    'IsNullable', p_IsNullable_29dd5dc8333a,
    'SourceObjectName', p_SourceObjectName_29dd5dc8333a
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_29dd5dc8333a, p_QueryID := p_QueryID_29dd5dc8333a, p_Name := p_Name_29dd5dc8333a, p_Description := p_Description_29dd5dc8333a, p_Description_Clear := TRUE, p_Sequence := p_Sequence_29dd5dc8333a, p_SQLBaseType := p_SQLBaseType_29dd5dc8333a, p_SQLFullType := p_SQLFullType_29dd5dc8333a, p_SourceEntityID := p_SourceEntityID_29dd5dc8333a, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_29dd5dc8333a, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_29dd5dc8333a, p_ComputationDescription := p_ComputationDescription_29dd5dc8333a, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_29dd5dc8333a, p_SummaryDescription := p_SummaryDescription_29dd5dc8333a, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_29dd5dc8333a, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_29dd5dc8333a, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_29dd5dc8333a, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_29dd5dc8333a, p_SourceObjectName := p_SourceObjectName_29dd5dc8333a, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b648bce014f2 UUID;
  p_QueryID_b648bce014f2 UUID;
  p_Name_b648bce014f2 VARCHAR(255);
  p_Description_b648bce014f2 TEXT;
  p_Sequence_b648bce014f2 INTEGER;
  p_SQLBaseType_b648bce014f2 VARCHAR(50);
  p_SQLFullType_b648bce014f2 VARCHAR(100);
  p_SourceEntityID_b648bce014f2 UUID;
  p_SourceFieldName_b648bce014f2 VARCHAR(255);
  p_IsComputed_b648bce014f2 BOOLEAN;
  p_ComputationDescription_b648bce014f2 TEXT;
  p_IsSummary_b648bce014f2 BOOLEAN;
  p_SummaryDescription_b648bce014f2 TEXT;
  p_DetectionMethod_b648bce014f2 VARCHAR(50);
  p_AutoDetectConfidenceScore_b648bce014f2 NUMERIC(3,2);
  p_SourceEntityFieldID_b648bce014f2 UUID;
  p_IsNullable_b648bce014f2 BOOLEAN;
  p_SourceObjectName_b648bce014f2 VARCHAR(500);
BEGIN
  p_ID_b648bce014f2 := 'a903421f-d644-4ac6-aa7e-fb0137361b90';
  p_QueryID_b648bce014f2 := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_b648bce014f2 := 'AttentionTypeOrgID';
  p_Sequence_b648bce014f2 := 12;
  p_SQLBaseType_b648bce014f2 := 'uniqueidentifier';
  p_SQLFullType_b648bce014f2 := 'uniqueidentifier';
  p_SourceEntityID_b648bce014f2 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_SourceFieldName_b648bce014f2 := 'ID';
  p_IsComputed_b648bce014f2 := FALSE;
  p_IsSummary_b648bce014f2 := FALSE;
  p_DetectionMethod_b648bce014f2 := 'Database';
  p_SourceEntityFieldID_b648bce014f2 := 'B194EE44-85DB-4D2A-A76F-9FEB0B5F1AEB';
  p_IsNullable_b648bce014f2 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_b648bce014f2
                    OR ("QueryID" = p_QueryID_b648bce014f2 AND "Name" = p_Name_b648bce014f2)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_b648bce014f2,
    'QueryID', p_QueryID_b648bce014f2,
    'Name', p_Name_b648bce014f2,
    'Description', p_Description_b648bce014f2,
    'Sequence', p_Sequence_b648bce014f2,
    'SQLBaseType', p_SQLBaseType_b648bce014f2,
    'SQLFullType', p_SQLFullType_b648bce014f2,
    'SourceEntityID', p_SourceEntityID_b648bce014f2,
    'SourceFieldName', p_SourceFieldName_b648bce014f2,
    'IsComputed', p_IsComputed_b648bce014f2,
    'ComputationDescription', p_ComputationDescription_b648bce014f2,
    'IsSummary', p_IsSummary_b648bce014f2,
    'SummaryDescription', p_SummaryDescription_b648bce014f2,
    'DetectionMethod', p_DetectionMethod_b648bce014f2,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_b648bce014f2,
    'SourceEntityFieldID', p_SourceEntityFieldID_b648bce014f2,
    'IsNullable', p_IsNullable_b648bce014f2,
    'SourceObjectName', p_SourceObjectName_b648bce014f2
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_b648bce014f2, p_QueryID := p_QueryID_b648bce014f2, p_Name := p_Name_b648bce014f2, p_Description := p_Description_b648bce014f2, p_Description_Clear := TRUE, p_Sequence := p_Sequence_b648bce014f2, p_SQLBaseType := p_SQLBaseType_b648bce014f2, p_SQLFullType := p_SQLFullType_b648bce014f2, p_SourceEntityID := p_SourceEntityID_b648bce014f2, p_SourceFieldName := p_SourceFieldName_b648bce014f2, p_IsComputed := p_IsComputed_b648bce014f2, p_ComputationDescription := p_ComputationDescription_b648bce014f2, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_b648bce014f2, p_SummaryDescription := p_SummaryDescription_b648bce014f2, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_b648bce014f2, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_b648bce014f2, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_b648bce014f2, p_IsNullable := p_IsNullable_b648bce014f2, p_SourceObjectName := p_SourceObjectName_b648bce014f2, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_f56fd5b046f8 UUID;
  p_QueryID_f56fd5b046f8 UUID;
  p_Name_f56fd5b046f8 VARCHAR(255);
  p_Description_f56fd5b046f8 TEXT;
  p_Sequence_f56fd5b046f8 INTEGER;
  p_SQLBaseType_f56fd5b046f8 VARCHAR(50);
  p_SQLFullType_f56fd5b046f8 VARCHAR(100);
  p_SourceEntityID_f56fd5b046f8 UUID;
  p_SourceFieldName_f56fd5b046f8 VARCHAR(255);
  p_IsComputed_f56fd5b046f8 BOOLEAN;
  p_ComputationDescription_f56fd5b046f8 TEXT;
  p_IsSummary_f56fd5b046f8 BOOLEAN;
  p_SummaryDescription_f56fd5b046f8 TEXT;
  p_DetectionMethod_f56fd5b046f8 VARCHAR(50);
  p_AutoDetectConfidenceScore_f56fd5b046f8 NUMERIC(3,2);
  p_SourceEntityFieldID_f56fd5b046f8 UUID;
  p_IsNullable_f56fd5b046f8 BOOLEAN;
  p_SourceObjectName_f56fd5b046f8 VARCHAR(500);
BEGIN
  p_ID_f56fd5b046f8 := 'fbedd2ca-3ec6-4162-a979-fbb82824a681';
  p_QueryID_f56fd5b046f8 := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_f56fd5b046f8 := 'AttentionTypeOrgName';
  p_Description_f56fd5b046f8 := 'Common or display name of the organization';
  p_Sequence_f56fd5b046f8 := 13;
  p_SQLBaseType_f56fd5b046f8 := 'nvarchar';
  p_SQLFullType_f56fd5b046f8 := 'nvarchar(255)';
  p_SourceEntityID_f56fd5b046f8 := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_SourceFieldName_f56fd5b046f8 := 'Name';
  p_IsComputed_f56fd5b046f8 := FALSE;
  p_IsSummary_f56fd5b046f8 := FALSE;
  p_DetectionMethod_f56fd5b046f8 := 'Database';
  p_SourceEntityFieldID_f56fd5b046f8 := '9F465E98-0614-4987-BED8-90B8A1450685';
  p_IsNullable_f56fd5b046f8 := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_f56fd5b046f8
                    OR ("QueryID" = p_QueryID_f56fd5b046f8 AND "Name" = p_Name_f56fd5b046f8)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_f56fd5b046f8,
    'QueryID', p_QueryID_f56fd5b046f8,
    'Name', p_Name_f56fd5b046f8,
    'Description', p_Description_f56fd5b046f8,
    'Sequence', p_Sequence_f56fd5b046f8,
    'SQLBaseType', p_SQLBaseType_f56fd5b046f8,
    'SQLFullType', p_SQLFullType_f56fd5b046f8,
    'SourceEntityID', p_SourceEntityID_f56fd5b046f8,
    'SourceFieldName', p_SourceFieldName_f56fd5b046f8,
    'IsComputed', p_IsComputed_f56fd5b046f8,
    'ComputationDescription', p_ComputationDescription_f56fd5b046f8,
    'IsSummary', p_IsSummary_f56fd5b046f8,
    'SummaryDescription', p_SummaryDescription_f56fd5b046f8,
    'DetectionMethod', p_DetectionMethod_f56fd5b046f8,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_f56fd5b046f8,
    'SourceEntityFieldID', p_SourceEntityFieldID_f56fd5b046f8,
    'IsNullable', p_IsNullable_f56fd5b046f8,
    'SourceObjectName', p_SourceObjectName_f56fd5b046f8
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_f56fd5b046f8, p_QueryID := p_QueryID_f56fd5b046f8, p_Name := p_Name_f56fd5b046f8, p_Description := p_Description_f56fd5b046f8, p_Sequence := p_Sequence_f56fd5b046f8, p_SQLBaseType := p_SQLBaseType_f56fd5b046f8, p_SQLFullType := p_SQLFullType_f56fd5b046f8, p_SourceEntityID := p_SourceEntityID_f56fd5b046f8, p_SourceFieldName := p_SourceFieldName_f56fd5b046f8, p_IsComputed := p_IsComputed_f56fd5b046f8, p_ComputationDescription := p_ComputationDescription_f56fd5b046f8, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_f56fd5b046f8, p_SummaryDescription := p_SummaryDescription_f56fd5b046f8, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_f56fd5b046f8, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_f56fd5b046f8, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_f56fd5b046f8, p_IsNullable := p_IsNullable_f56fd5b046f8, p_SourceObjectName := p_SourceObjectName_f56fd5b046f8, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_3b574c6e4dfa UUID;
  p_QueryID_3b574c6e4dfa UUID;
  p_Name_3b574c6e4dfa VARCHAR(255);
  p_Description_3b574c6e4dfa TEXT;
  p_Sequence_3b574c6e4dfa INTEGER;
  p_SQLBaseType_3b574c6e4dfa VARCHAR(50);
  p_SQLFullType_3b574c6e4dfa VARCHAR(100);
  p_SourceEntityID_3b574c6e4dfa UUID;
  p_SourceFieldName_3b574c6e4dfa VARCHAR(255);
  p_IsComputed_3b574c6e4dfa BOOLEAN;
  p_ComputationDescription_3b574c6e4dfa TEXT;
  p_IsSummary_3b574c6e4dfa BOOLEAN;
  p_SummaryDescription_3b574c6e4dfa TEXT;
  p_DetectionMethod_3b574c6e4dfa VARCHAR(50);
  p_AutoDetectConfidenceScore_3b574c6e4dfa NUMERIC(3,2);
  p_SourceEntityFieldID_3b574c6e4dfa UUID;
  p_IsNullable_3b574c6e4dfa BOOLEAN;
  p_SourceObjectName_3b574c6e4dfa VARCHAR(500);
BEGIN
  p_ID_3b574c6e4dfa := '13c3c110-5309-420f-b08f-c8f1303afbc9';
  p_QueryID_3b574c6e4dfa := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_3b574c6e4dfa := 'AttentionTypeWebsite';
  p_Description_3b574c6e4dfa := 'Primary website URL';
  p_Sequence_3b574c6e4dfa := 14;
  p_SQLBaseType_3b574c6e4dfa := 'nvarchar';
  p_SQLFullType_3b574c6e4dfa := 'nvarchar(1000)';
  p_SourceEntityID_3b574c6e4dfa := 'C70448F9-9792-41D7-A82C-784B66429D54';
  p_SourceFieldName_3b574c6e4dfa := 'Website';
  p_IsComputed_3b574c6e4dfa := FALSE;
  p_IsSummary_3b574c6e4dfa := FALSE;
  p_DetectionMethod_3b574c6e4dfa := 'Database';
  p_SourceEntityFieldID_3b574c6e4dfa := 'C8C255E3-D3C1-4F3D-84AA-07B30981FB3E';
  p_IsNullable_3b574c6e4dfa := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_3b574c6e4dfa
                    OR ("QueryID" = p_QueryID_3b574c6e4dfa AND "Name" = p_Name_3b574c6e4dfa)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_3b574c6e4dfa,
    'QueryID', p_QueryID_3b574c6e4dfa,
    'Name', p_Name_3b574c6e4dfa,
    'Description', p_Description_3b574c6e4dfa,
    'Sequence', p_Sequence_3b574c6e4dfa,
    'SQLBaseType', p_SQLBaseType_3b574c6e4dfa,
    'SQLFullType', p_SQLFullType_3b574c6e4dfa,
    'SourceEntityID', p_SourceEntityID_3b574c6e4dfa,
    'SourceFieldName', p_SourceFieldName_3b574c6e4dfa,
    'IsComputed', p_IsComputed_3b574c6e4dfa,
    'ComputationDescription', p_ComputationDescription_3b574c6e4dfa,
    'IsSummary', p_IsSummary_3b574c6e4dfa,
    'SummaryDescription', p_SummaryDescription_3b574c6e4dfa,
    'DetectionMethod', p_DetectionMethod_3b574c6e4dfa,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_3b574c6e4dfa,
    'SourceEntityFieldID', p_SourceEntityFieldID_3b574c6e4dfa,
    'IsNullable', p_IsNullable_3b574c6e4dfa,
    'SourceObjectName', p_SourceObjectName_3b574c6e4dfa
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_3b574c6e4dfa, p_QueryID := p_QueryID_3b574c6e4dfa, p_Name := p_Name_3b574c6e4dfa, p_Description := p_Description_3b574c6e4dfa, p_Sequence := p_Sequence_3b574c6e4dfa, p_SQLBaseType := p_SQLBaseType_3b574c6e4dfa, p_SQLFullType := p_SQLFullType_3b574c6e4dfa, p_SourceEntityID := p_SourceEntityID_3b574c6e4dfa, p_SourceFieldName := p_SourceFieldName_3b574c6e4dfa, p_IsComputed := p_IsComputed_3b574c6e4dfa, p_ComputationDescription := p_ComputationDescription_3b574c6e4dfa, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_3b574c6e4dfa, p_SummaryDescription := p_SummaryDescription_3b574c6e4dfa, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_3b574c6e4dfa, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_3b574c6e4dfa, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_3b574c6e4dfa, p_IsNullable := p_IsNullable_3b574c6e4dfa, p_SourceObjectName := p_SourceObjectName_3b574c6e4dfa, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_049e319ee0ea UUID;
  p_QueryID_049e319ee0ea UUID;
  p_Name_049e319ee0ea VARCHAR(255);
  p_Description_049e319ee0ea TEXT;
  p_Sequence_049e319ee0ea INTEGER;
  p_SQLBaseType_049e319ee0ea VARCHAR(50);
  p_SQLFullType_049e319ee0ea VARCHAR(100);
  p_SourceEntityID_049e319ee0ea UUID;
  p_SourceFieldName_049e319ee0ea VARCHAR(255);
  p_IsComputed_049e319ee0ea BOOLEAN;
  p_ComputationDescription_049e319ee0ea TEXT;
  p_IsSummary_049e319ee0ea BOOLEAN;
  p_SummaryDescription_049e319ee0ea TEXT;
  p_DetectionMethod_049e319ee0ea VARCHAR(50);
  p_AutoDetectConfidenceScore_049e319ee0ea NUMERIC(3,2);
  p_SourceEntityFieldID_049e319ee0ea UUID;
  p_IsNullable_049e319ee0ea BOOLEAN;
  p_SourceObjectName_049e319ee0ea VARCHAR(500);
BEGIN
  p_ID_049e319ee0ea := '0857a516-98b0-4a71-897b-31bf977a3eaa';
  p_QueryID_049e319ee0ea := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_049e319ee0ea := 'OrgTypeMixJson';
  p_Sequence_049e319ee0ea := 15;
  p_SQLBaseType_049e319ee0ea := 'nvarchar';
  p_SQLFullType_049e319ee0ea := 'nvarchar(max)';
  p_IsComputed_049e319ee0ea := TRUE;
  p_IsSummary_049e319ee0ea := FALSE;
  p_DetectionMethod_049e319ee0ea := 'Database';
  p_IsNullable_049e319ee0ea := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_049e319ee0ea
                    OR ("QueryID" = p_QueryID_049e319ee0ea AND "Name" = p_Name_049e319ee0ea)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_049e319ee0ea,
    'QueryID', p_QueryID_049e319ee0ea,
    'Name', p_Name_049e319ee0ea,
    'Description', p_Description_049e319ee0ea,
    'Sequence', p_Sequence_049e319ee0ea,
    'SQLBaseType', p_SQLBaseType_049e319ee0ea,
    'SQLFullType', p_SQLFullType_049e319ee0ea,
    'SourceEntityID', p_SourceEntityID_049e319ee0ea,
    'SourceFieldName', p_SourceFieldName_049e319ee0ea,
    'IsComputed', p_IsComputed_049e319ee0ea,
    'ComputationDescription', p_ComputationDescription_049e319ee0ea,
    'IsSummary', p_IsSummary_049e319ee0ea,
    'SummaryDescription', p_SummaryDescription_049e319ee0ea,
    'DetectionMethod', p_DetectionMethod_049e319ee0ea,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_049e319ee0ea,
    'SourceEntityFieldID', p_SourceEntityFieldID_049e319ee0ea,
    'IsNullable', p_IsNullable_049e319ee0ea,
    'SourceObjectName', p_SourceObjectName_049e319ee0ea
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_049e319ee0ea, p_QueryID := p_QueryID_049e319ee0ea, p_Name := p_Name_049e319ee0ea, p_Description := p_Description_049e319ee0ea, p_Description_Clear := TRUE, p_Sequence := p_Sequence_049e319ee0ea, p_SQLBaseType := p_SQLBaseType_049e319ee0ea, p_SQLFullType := p_SQLFullType_049e319ee0ea, p_SourceEntityID := p_SourceEntityID_049e319ee0ea, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_049e319ee0ea, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_049e319ee0ea, p_ComputationDescription := p_ComputationDescription_049e319ee0ea, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_049e319ee0ea, p_SummaryDescription := p_SummaryDescription_049e319ee0ea, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_049e319ee0ea, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_049e319ee0ea, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_049e319ee0ea, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_049e319ee0ea, p_SourceObjectName := p_SourceObjectName_049e319ee0ea, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_40de8b77210a UUID;
  p_QueryID_40de8b77210a UUID;
  p_Name_40de8b77210a VARCHAR(255);
  p_Description_40de8b77210a TEXT;
  p_Sequence_40de8b77210a INTEGER;
  p_SQLBaseType_40de8b77210a VARCHAR(50);
  p_SQLFullType_40de8b77210a VARCHAR(100);
  p_SourceEntityID_40de8b77210a UUID;
  p_SourceFieldName_40de8b77210a VARCHAR(255);
  p_IsComputed_40de8b77210a BOOLEAN;
  p_ComputationDescription_40de8b77210a TEXT;
  p_IsSummary_40de8b77210a BOOLEAN;
  p_SummaryDescription_40de8b77210a TEXT;
  p_DetectionMethod_40de8b77210a VARCHAR(50);
  p_AutoDetectConfidenceScore_40de8b77210a NUMERIC(3,2);
  p_SourceEntityFieldID_40de8b77210a UUID;
  p_IsNullable_40de8b77210a BOOLEAN;
  p_SourceObjectName_40de8b77210a VARCHAR(500);
BEGIN
  p_ID_40de8b77210a := '6caae87b-d146-430b-b2d2-563520624d36';
  p_QueryID_40de8b77210a := '6C0A1000-0001-4000-A000-00000000000E';
  p_Name_40de8b77210a := 'RelationshipCount';
  p_Sequence_40de8b77210a := 16;
  p_SQLBaseType_40de8b77210a := 'int';
  p_SQLFullType_40de8b77210a := 'int';
  p_IsComputed_40de8b77210a := TRUE;
  p_IsSummary_40de8b77210a := FALSE;
  p_DetectionMethod_40de8b77210a := 'Database';
  p_IsNullable_40de8b77210a := TRUE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_40de8b77210a
                    OR ("QueryID" = p_QueryID_40de8b77210a AND "Name" = p_Name_40de8b77210a)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_40de8b77210a,
    'QueryID', p_QueryID_40de8b77210a,
    'Name', p_Name_40de8b77210a,
    'Description', p_Description_40de8b77210a,
    'Sequence', p_Sequence_40de8b77210a,
    'SQLBaseType', p_SQLBaseType_40de8b77210a,
    'SQLFullType', p_SQLFullType_40de8b77210a,
    'SourceEntityID', p_SourceEntityID_40de8b77210a,
    'SourceFieldName', p_SourceFieldName_40de8b77210a,
    'IsComputed', p_IsComputed_40de8b77210a,
    'ComputationDescription', p_ComputationDescription_40de8b77210a,
    'IsSummary', p_IsSummary_40de8b77210a,
    'SummaryDescription', p_SummaryDescription_40de8b77210a,
    'DetectionMethod', p_DetectionMethod_40de8b77210a,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_40de8b77210a,
    'SourceEntityFieldID', p_SourceEntityFieldID_40de8b77210a,
    'IsNullable', p_IsNullable_40de8b77210a,
    'SourceObjectName', p_SourceObjectName_40de8b77210a
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_40de8b77210a, p_QueryID := p_QueryID_40de8b77210a, p_Name := p_Name_40de8b77210a, p_Description := p_Description_40de8b77210a, p_Description_Clear := TRUE, p_Sequence := p_Sequence_40de8b77210a, p_SQLBaseType := p_SQLBaseType_40de8b77210a, p_SQLFullType := p_SQLFullType_40de8b77210a, p_SourceEntityID := p_SourceEntityID_40de8b77210a, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_40de8b77210a, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_40de8b77210a, p_ComputationDescription := p_ComputationDescription_40de8b77210a, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_40de8b77210a, p_SummaryDescription := p_SummaryDescription_40de8b77210a, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_40de8b77210a, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_40de8b77210a, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_40de8b77210a, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_40de8b77210a, p_SourceObjectName := p_SourceObjectName_40de8b77210a, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Entities (core SP call only)
DO $mj$
DECLARE
  p_ID_f997cc1c68df UUID;
  p_QueryID_f997cc1c68df UUID;
  p_EntityID_f997cc1c68df UUID;
  p_DetectionMethod_f997cc1c68df VARCHAR(50);
  p_AutoDetectConfidenceScore_f997cc1c68df NUMERIC(3,2);
  p_AlternateBaseViewID_f997cc1c68df UUID;
BEGIN
  p_ID_f997cc1c68df := '3713204c-b6f6-4cec-b784-2ea08454a100';
  p_QueryID_f997cc1c68df := '6C0A1000-0001-4000-A000-00000000000E';
  p_EntityID_f997cc1c68df := '5F214F43-109C-407D-B505-7B0B3B72ACB5';
  p_DetectionMethod_f997cc1c68df := 'Parser';
  p_AutoDetectConfidenceScore_f997cc1c68df := 1;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryEntity"
                 WHERE "ID" = p_ID_f997cc1c68df
                    OR ("QueryID" = p_QueryID_f997cc1c68df AND "EntityID" = p_EntityID_f997cc1c68df)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryEntity'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryEntity"(p_data := jsonb_build_object(
    'ID', p_ID_f997cc1c68df,
    'QueryID', p_QueryID_f997cc1c68df,
    'EntityID', p_EntityID_f997cc1c68df,
    'DetectionMethod', p_DetectionMethod_f997cc1c68df,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_f997cc1c68df,
    'AlternateBaseViewID', p_AlternateBaseViewID_f997cc1c68df
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryEntity"(p_ID := p_ID_f997cc1c68df, p_QueryID := p_QueryID_f997cc1c68df, p_EntityID := p_EntityID_f997cc1c68df, p_DetectionMethod := p_DetectionMethod_f997cc1c68df, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_f997cc1c68df, p_AlternateBaseViewID := p_AlternateBaseViewID_f997cc1c68df, p_AlternateBaseViewID_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Queries (core SP call only)
DO $mj$
DECLARE
  p_ID_9341040ddb73 UUID;
  p_Name_9341040ddb73 VARCHAR(255);
  p_CategoryID_9341040ddb73 UUID;
  p_UserQuestion_9341040ddb73 TEXT;
  p_Description_9341040ddb73 TEXT;
  p_SQL_9341040ddb73 TEXT;
  p_TechnicalDescription_9341040ddb73 TEXT;
  p_OriginalSQL_9341040ddb73 TEXT;
  p_Feedback_9341040ddb73 TEXT;
  p_Status_9341040ddb73 VARCHAR(15);
  p_QualityRank_9341040ddb73 INTEGER;
  p_ExecutionCostRank_9341040ddb73 INTEGER;
  p_UsesTemplate_9341040ddb73 BOOLEAN;
  p_AuditQueryRuns_9341040ddb73 BOOLEAN;
  p_CacheEnabled_9341040ddb73 BOOLEAN;
  p_CacheTTLMinutes_9341040ddb73 INTEGER;
  p_CacheMaxSize_9341040ddb73 INTEGER;
  p_EmbeddingVector_9341040ddb73 TEXT;
  p_EmbeddingModelID_9341040ddb73 UUID;
  p_CacheValidationSQL_9341040ddb73 TEXT;
  p_SQLDialectID_9341040ddb73 UUID;
  p_Reusable_9341040ddb73 BOOLEAN;
  p_ExternalDataSourceID_9341040ddb73 UUID;
  p_IsMaterialized_9341040ddb73 BOOLEAN;
  p_Configuration_9341040ddb73 TEXT;
  p_EmbeddingVectorBinary_9341040ddb73 BYTEA;
  p_ApprovalComments_9341040ddb73 TEXT;
  p_ApprovedByUserID_9341040ddb73 UUID;
  p_ApprovedAt_9341040ddb73 TIMESTAMPTZ;
  p_ApprovedFingerprint_9341040ddb73 VARCHAR(100);
  p_ExtractedSQLHash_9341040ddb73 VARCHAR(64);
  p_ExtractionStatus_9341040ddb73 VARCHAR(20);
  p_ExtractionMessage_9341040ddb73 TEXT;
BEGIN
  p_ID_9341040ddb73 := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_9341040ddb73 := 'Common: Directory People Per Day';
  p_CategoryID_9341040ddb73 := (
    SELECT
      "ID"
    FROM
      "${mjSchema}"."QueryCategory"
    WHERE
      LOWER("Name") = LOWER('Common')
  );
  p_UserQuestion_9341040ddb73 := 'How many people were added on each of the last seven business days?';
  p_Description_9341040ddb73 := 'The directory dashboard''s "people added" bars: one row with a count for each of the last seven business days, today first.';
  p_SQL_9341040ddb73 := '-- People added on each of the last seven BUSINESS days, as one row: PeopleAddedD0 is today,
-- PeopleAddedD6 six days ago. Read by the directory dashboard''s "people added" bars.
--
-- __mj_CreatedAt is a UTC instant; fnBusinessDayOf turns it into the day it was in the business
-- time zone, the same zone fnBusinessToday() reads for "today" (bc-aidp-next-golive#168). A UTC
-- day put Thursday evening''s signups in Friday''s bar for anyone in the Americas.
--
-- Kept apart from Common: Directory Dashboard Summary on purpose. fnBusinessDayOf is a scalar
-- function SQL Server cannot inline (it converts time zones), so it runs once per row and makes
-- any statement that calls it single-threaded. Here it runs only for the rows the WHERE keeps
-- (the last eight days); in the summary it slowed every count with it.
-- No inline AT TIME ZONE: MJ''s SQL parser cannot read it.
--
-- Single SELECT (no DECLARE / temp tables) so RunQuery can wrap it.
SELECT
    ISNULL(SUM(CASE WHEN d.CreatedDay = bt.Today THEN 1 ELSE 0 END), 0) AS PeopleAddedD0,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -1, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD1,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -2, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD2,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -3, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD3,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -4, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD4,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -5, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD5,
    ISNULL(SUM(CASE WHEN d.CreatedDay = DATEADD(DAY, -6, bt.Today) THEN 1 ELSE 0 END), 0) AS PeopleAddedD6
FROM [${flyway:defaultSchema}].[fnBusinessToday]() AS bt
LEFT JOIN
(
    SELECT [${flyway:defaultSchema}].[fnBusinessDayOf](x.__mj_CreatedAt) AS CreatedDay
    FROM [${flyway:defaultSchema}].[vwPeople] x
    WHERE x.__mj_CreatedAt >= DATEADD(DAY, -8, SYSDATETIMEOFFSET())
) d ON 1 = 1
;
';
  p_TechnicalDescription_9341040ddb73 := 'Grain: one row. PeopleAddedD0 (today) to PeopleAddedD6: vwPeople rows whose __mj_CreatedAt falls on that business day, by fnBusinessDayOf against fnBusinessToday().Today (the BizApps business time zone). fnBusinessDayOf runs only on rows created in the last eight days. Separate from Common: Directory Dashboard Summary because fnBusinessDayOf cannot be inlined, which makes any statement that calls it single-threaded. No template parameters.';
  p_Status_9341040ddb73 := 'Approved';
  p_QualityRank_9341040ddb73 := 9;
  p_ExecutionCostRank_9341040ddb73 := 1;
  p_UsesTemplate_9341040ddb73 := FALSE;
  p_AuditQueryRuns_9341040ddb73 := FALSE;
  p_CacheEnabled_9341040ddb73 := FALSE;
  p_Reusable_9341040ddb73 := FALSE;
  p_IsMaterialized_9341040ddb73 := FALSE;
  p_ApprovedByUserID_9341040ddb73 := 'ECAFCCEC-6A37-EF11-86D4-000D3A4E707E';
  p_ApprovedAt_9341040ddb73 := '2026-11-10T23:15:32.124Z';
  p_ExtractedSQLHash_9341040ddb73 := '6a109dedc10f37924fcd7d1bdccfe9946df657556e3dc5560baeeaeb91d5a349';
  p_ExtractionStatus_9341040ddb73 := 'OK';
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."Query"
                 WHERE "ID" = p_ID_9341040ddb73
                    OR ("CategoryID" = p_CategoryID_9341040ddb73 AND "Name" = p_Name_9341040ddb73)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQuery'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQuery"(p_data := jsonb_build_object(
    'ID', p_ID_9341040ddb73,
    'Name', p_Name_9341040ddb73,
    'CategoryID', p_CategoryID_9341040ddb73,
    'UserQuestion', p_UserQuestion_9341040ddb73,
    'Description', p_Description_9341040ddb73,
    'SQL', p_SQL_9341040ddb73,
    'TechnicalDescription', p_TechnicalDescription_9341040ddb73,
    'OriginalSQL', p_OriginalSQL_9341040ddb73,
    'Feedback', p_Feedback_9341040ddb73,
    'Status', p_Status_9341040ddb73,
    'QualityRank', p_QualityRank_9341040ddb73,
    'ExecutionCostRank', p_ExecutionCostRank_9341040ddb73,
    'UsesTemplate', p_UsesTemplate_9341040ddb73,
    'AuditQueryRuns', p_AuditQueryRuns_9341040ddb73,
    'CacheEnabled', p_CacheEnabled_9341040ddb73,
    'CacheTTLMinutes', p_CacheTTLMinutes_9341040ddb73,
    'CacheMaxSize', p_CacheMaxSize_9341040ddb73,
    'EmbeddingVector', p_EmbeddingVector_9341040ddb73,
    'EmbeddingModelID', p_EmbeddingModelID_9341040ddb73,
    'CacheValidationSQL', p_CacheValidationSQL_9341040ddb73,
    'SQLDialectID', p_SQLDialectID_9341040ddb73,
    'Reusable', p_Reusable_9341040ddb73,
    'ExternalDataSourceID', p_ExternalDataSourceID_9341040ddb73,
    'IsMaterialized', p_IsMaterialized_9341040ddb73,
    'Configuration', p_Configuration_9341040ddb73,
    'EmbeddingVectorBinary', p_EmbeddingVectorBinary_9341040ddb73,
    'ApprovalComments', p_ApprovalComments_9341040ddb73,
    'ApprovedByUserID', p_ApprovedByUserID_9341040ddb73,
    'ApprovedAt', p_ApprovedAt_9341040ddb73,
    'ApprovedFingerprint', p_ApprovedFingerprint_9341040ddb73,
    'ExtractedSQLHash', p_ExtractedSQLHash_9341040ddb73,
    'ExtractionStatus', p_ExtractionStatus_9341040ddb73,
    'ExtractionMessage', p_ExtractionMessage_9341040ddb73
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQuery"(p_ID := p_ID_9341040ddb73, p_Name := p_Name_9341040ddb73, p_CategoryID := p_CategoryID_9341040ddb73, p_UserQuestion := p_UserQuestion_9341040ddb73, p_Description := p_Description_9341040ddb73, p_SQL := p_SQL_9341040ddb73, p_TechnicalDescription := p_TechnicalDescription_9341040ddb73, p_OriginalSQL := p_OriginalSQL_9341040ddb73, p_OriginalSQL_Clear := TRUE, p_Feedback := p_Feedback_9341040ddb73, p_Feedback_Clear := TRUE, p_Status := p_Status_9341040ddb73, p_QualityRank := p_QualityRank_9341040ddb73, p_ExecutionCostRank := p_ExecutionCostRank_9341040ddb73, p_UsesTemplate := p_UsesTemplate_9341040ddb73, p_AuditQueryRuns := p_AuditQueryRuns_9341040ddb73, p_CacheEnabled := p_CacheEnabled_9341040ddb73, p_CacheTTLMinutes := p_CacheTTLMinutes_9341040ddb73, p_CacheTTLMinutes_Clear := TRUE, p_CacheMaxSize := p_CacheMaxSize_9341040ddb73, p_CacheMaxSize_Clear := TRUE, p_EmbeddingVector := p_EmbeddingVector_9341040ddb73, p_EmbeddingVector_Clear := TRUE, p_EmbeddingModelID := p_EmbeddingModelID_9341040ddb73, p_EmbeddingModelID_Clear := TRUE, p_CacheValidationSQL := p_CacheValidationSQL_9341040ddb73, p_CacheValidationSQL_Clear := TRUE, p_SQLDialectID := p_SQLDialectID_9341040ddb73, p_Reusable := p_Reusable_9341040ddb73, p_ExternalDataSourceID := p_ExternalDataSourceID_9341040ddb73, p_ExternalDataSourceID_Clear := TRUE, p_IsMaterialized := p_IsMaterialized_9341040ddb73, p_Configuration := p_Configuration_9341040ddb73, p_Configuration_Clear := TRUE, p_EmbeddingVectorBinary := p_EmbeddingVectorBinary_9341040ddb73, p_EmbeddingVectorBinary_Clear := TRUE, p_ApprovalComments := p_ApprovalComments_9341040ddb73, p_ApprovalComments_Clear := TRUE, p_ApprovedByUserID := p_ApprovedByUserID_9341040ddb73, p_ApprovedAt := p_ApprovedAt_9341040ddb73, p_ApprovedFingerprint := p_ApprovedFingerprint_9341040ddb73, p_ApprovedFingerprint_Clear := TRUE, p_ExtractedSQLHash := p_ExtractedSQLHash_9341040ddb73, p_ExtractionStatus := p_ExtractionStatus_9341040ddb73, p_ExtractionMessage := p_ExtractionMessage_9341040ddb73, p_ExtractionMessage_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5f48f597eb70 UUID;
  p_QueryID_5f48f597eb70 UUID;
  p_Name_5f48f597eb70 VARCHAR(255);
  p_Description_5f48f597eb70 TEXT;
  p_Sequence_5f48f597eb70 INTEGER;
  p_SQLBaseType_5f48f597eb70 VARCHAR(50);
  p_SQLFullType_5f48f597eb70 VARCHAR(100);
  p_SourceEntityID_5f48f597eb70 UUID;
  p_SourceFieldName_5f48f597eb70 VARCHAR(255);
  p_IsComputed_5f48f597eb70 BOOLEAN;
  p_ComputationDescription_5f48f597eb70 TEXT;
  p_IsSummary_5f48f597eb70 BOOLEAN;
  p_SummaryDescription_5f48f597eb70 TEXT;
  p_DetectionMethod_5f48f597eb70 VARCHAR(50);
  p_AutoDetectConfidenceScore_5f48f597eb70 NUMERIC(3,2);
  p_SourceEntityFieldID_5f48f597eb70 UUID;
  p_IsNullable_5f48f597eb70 BOOLEAN;
  p_SourceObjectName_5f48f597eb70 VARCHAR(500);
BEGIN
  p_ID_5f48f597eb70 := 'fe651d98-d425-41ce-b1c0-52fcb89adf29';
  p_QueryID_5f48f597eb70 := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_5f48f597eb70 := 'PeopleAddedD0';
  p_Sequence_5f48f597eb70 := 1;
  p_SQLBaseType_5f48f597eb70 := 'int';
  p_SQLFullType_5f48f597eb70 := 'int';
  p_IsComputed_5f48f597eb70 := TRUE;
  p_IsSummary_5f48f597eb70 := FALSE;
  p_DetectionMethod_5f48f597eb70 := 'Database';
  p_IsNullable_5f48f597eb70 := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_5f48f597eb70
                    OR ("QueryID" = p_QueryID_5f48f597eb70 AND "Name" = p_Name_5f48f597eb70)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_5f48f597eb70,
    'QueryID', p_QueryID_5f48f597eb70,
    'Name', p_Name_5f48f597eb70,
    'Description', p_Description_5f48f597eb70,
    'Sequence', p_Sequence_5f48f597eb70,
    'SQLBaseType', p_SQLBaseType_5f48f597eb70,
    'SQLFullType', p_SQLFullType_5f48f597eb70,
    'SourceEntityID', p_SourceEntityID_5f48f597eb70,
    'SourceFieldName', p_SourceFieldName_5f48f597eb70,
    'IsComputed', p_IsComputed_5f48f597eb70,
    'ComputationDescription', p_ComputationDescription_5f48f597eb70,
    'IsSummary', p_IsSummary_5f48f597eb70,
    'SummaryDescription', p_SummaryDescription_5f48f597eb70,
    'DetectionMethod', p_DetectionMethod_5f48f597eb70,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_5f48f597eb70,
    'SourceEntityFieldID', p_SourceEntityFieldID_5f48f597eb70,
    'IsNullable', p_IsNullable_5f48f597eb70,
    'SourceObjectName', p_SourceObjectName_5f48f597eb70
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_5f48f597eb70, p_QueryID := p_QueryID_5f48f597eb70, p_Name := p_Name_5f48f597eb70, p_Description := p_Description_5f48f597eb70, p_Description_Clear := TRUE, p_Sequence := p_Sequence_5f48f597eb70, p_SQLBaseType := p_SQLBaseType_5f48f597eb70, p_SQLFullType := p_SQLFullType_5f48f597eb70, p_SourceEntityID := p_SourceEntityID_5f48f597eb70, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_5f48f597eb70, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_5f48f597eb70, p_ComputationDescription := p_ComputationDescription_5f48f597eb70, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_5f48f597eb70, p_SummaryDescription := p_SummaryDescription_5f48f597eb70, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_5f48f597eb70, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_5f48f597eb70, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_5f48f597eb70, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_5f48f597eb70, p_SourceObjectName := p_SourceObjectName_5f48f597eb70, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d732662a63b4 UUID;
  p_QueryID_d732662a63b4 UUID;
  p_Name_d732662a63b4 VARCHAR(255);
  p_Description_d732662a63b4 TEXT;
  p_Sequence_d732662a63b4 INTEGER;
  p_SQLBaseType_d732662a63b4 VARCHAR(50);
  p_SQLFullType_d732662a63b4 VARCHAR(100);
  p_SourceEntityID_d732662a63b4 UUID;
  p_SourceFieldName_d732662a63b4 VARCHAR(255);
  p_IsComputed_d732662a63b4 BOOLEAN;
  p_ComputationDescription_d732662a63b4 TEXT;
  p_IsSummary_d732662a63b4 BOOLEAN;
  p_SummaryDescription_d732662a63b4 TEXT;
  p_DetectionMethod_d732662a63b4 VARCHAR(50);
  p_AutoDetectConfidenceScore_d732662a63b4 NUMERIC(3,2);
  p_SourceEntityFieldID_d732662a63b4 UUID;
  p_IsNullable_d732662a63b4 BOOLEAN;
  p_SourceObjectName_d732662a63b4 VARCHAR(500);
BEGIN
  p_ID_d732662a63b4 := '56d14cd2-6494-48cd-9ba3-cb72f38ccb70';
  p_QueryID_d732662a63b4 := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_d732662a63b4 := 'PeopleAddedD1';
  p_Sequence_d732662a63b4 := 2;
  p_SQLBaseType_d732662a63b4 := 'int';
  p_SQLFullType_d732662a63b4 := 'int';
  p_IsComputed_d732662a63b4 := TRUE;
  p_IsSummary_d732662a63b4 := FALSE;
  p_DetectionMethod_d732662a63b4 := 'Database';
  p_IsNullable_d732662a63b4 := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_d732662a63b4
                    OR ("QueryID" = p_QueryID_d732662a63b4 AND "Name" = p_Name_d732662a63b4)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_d732662a63b4,
    'QueryID', p_QueryID_d732662a63b4,
    'Name', p_Name_d732662a63b4,
    'Description', p_Description_d732662a63b4,
    'Sequence', p_Sequence_d732662a63b4,
    'SQLBaseType', p_SQLBaseType_d732662a63b4,
    'SQLFullType', p_SQLFullType_d732662a63b4,
    'SourceEntityID', p_SourceEntityID_d732662a63b4,
    'SourceFieldName', p_SourceFieldName_d732662a63b4,
    'IsComputed', p_IsComputed_d732662a63b4,
    'ComputationDescription', p_ComputationDescription_d732662a63b4,
    'IsSummary', p_IsSummary_d732662a63b4,
    'SummaryDescription', p_SummaryDescription_d732662a63b4,
    'DetectionMethod', p_DetectionMethod_d732662a63b4,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_d732662a63b4,
    'SourceEntityFieldID', p_SourceEntityFieldID_d732662a63b4,
    'IsNullable', p_IsNullable_d732662a63b4,
    'SourceObjectName', p_SourceObjectName_d732662a63b4
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_d732662a63b4, p_QueryID := p_QueryID_d732662a63b4, p_Name := p_Name_d732662a63b4, p_Description := p_Description_d732662a63b4, p_Description_Clear := TRUE, p_Sequence := p_Sequence_d732662a63b4, p_SQLBaseType := p_SQLBaseType_d732662a63b4, p_SQLFullType := p_SQLFullType_d732662a63b4, p_SourceEntityID := p_SourceEntityID_d732662a63b4, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_d732662a63b4, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_d732662a63b4, p_ComputationDescription := p_ComputationDescription_d732662a63b4, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_d732662a63b4, p_SummaryDescription := p_SummaryDescription_d732662a63b4, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_d732662a63b4, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_d732662a63b4, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_d732662a63b4, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_d732662a63b4, p_SourceObjectName := p_SourceObjectName_d732662a63b4, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c7f6a61249fd UUID;
  p_QueryID_c7f6a61249fd UUID;
  p_Name_c7f6a61249fd VARCHAR(255);
  p_Description_c7f6a61249fd TEXT;
  p_Sequence_c7f6a61249fd INTEGER;
  p_SQLBaseType_c7f6a61249fd VARCHAR(50);
  p_SQLFullType_c7f6a61249fd VARCHAR(100);
  p_SourceEntityID_c7f6a61249fd UUID;
  p_SourceFieldName_c7f6a61249fd VARCHAR(255);
  p_IsComputed_c7f6a61249fd BOOLEAN;
  p_ComputationDescription_c7f6a61249fd TEXT;
  p_IsSummary_c7f6a61249fd BOOLEAN;
  p_SummaryDescription_c7f6a61249fd TEXT;
  p_DetectionMethod_c7f6a61249fd VARCHAR(50);
  p_AutoDetectConfidenceScore_c7f6a61249fd NUMERIC(3,2);
  p_SourceEntityFieldID_c7f6a61249fd UUID;
  p_IsNullable_c7f6a61249fd BOOLEAN;
  p_SourceObjectName_c7f6a61249fd VARCHAR(500);
BEGIN
  p_ID_c7f6a61249fd := '27d5b160-3862-4b4e-85d4-3e2877e32590';
  p_QueryID_c7f6a61249fd := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_c7f6a61249fd := 'PeopleAddedD2';
  p_Sequence_c7f6a61249fd := 3;
  p_SQLBaseType_c7f6a61249fd := 'int';
  p_SQLFullType_c7f6a61249fd := 'int';
  p_IsComputed_c7f6a61249fd := TRUE;
  p_IsSummary_c7f6a61249fd := FALSE;
  p_DetectionMethod_c7f6a61249fd := 'Database';
  p_IsNullable_c7f6a61249fd := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_c7f6a61249fd
                    OR ("QueryID" = p_QueryID_c7f6a61249fd AND "Name" = p_Name_c7f6a61249fd)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_c7f6a61249fd,
    'QueryID', p_QueryID_c7f6a61249fd,
    'Name', p_Name_c7f6a61249fd,
    'Description', p_Description_c7f6a61249fd,
    'Sequence', p_Sequence_c7f6a61249fd,
    'SQLBaseType', p_SQLBaseType_c7f6a61249fd,
    'SQLFullType', p_SQLFullType_c7f6a61249fd,
    'SourceEntityID', p_SourceEntityID_c7f6a61249fd,
    'SourceFieldName', p_SourceFieldName_c7f6a61249fd,
    'IsComputed', p_IsComputed_c7f6a61249fd,
    'ComputationDescription', p_ComputationDescription_c7f6a61249fd,
    'IsSummary', p_IsSummary_c7f6a61249fd,
    'SummaryDescription', p_SummaryDescription_c7f6a61249fd,
    'DetectionMethod', p_DetectionMethod_c7f6a61249fd,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_c7f6a61249fd,
    'SourceEntityFieldID', p_SourceEntityFieldID_c7f6a61249fd,
    'IsNullable', p_IsNullable_c7f6a61249fd,
    'SourceObjectName', p_SourceObjectName_c7f6a61249fd
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_c7f6a61249fd, p_QueryID := p_QueryID_c7f6a61249fd, p_Name := p_Name_c7f6a61249fd, p_Description := p_Description_c7f6a61249fd, p_Description_Clear := TRUE, p_Sequence := p_Sequence_c7f6a61249fd, p_SQLBaseType := p_SQLBaseType_c7f6a61249fd, p_SQLFullType := p_SQLFullType_c7f6a61249fd, p_SourceEntityID := p_SourceEntityID_c7f6a61249fd, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_c7f6a61249fd, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_c7f6a61249fd, p_ComputationDescription := p_ComputationDescription_c7f6a61249fd, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_c7f6a61249fd, p_SummaryDescription := p_SummaryDescription_c7f6a61249fd, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_c7f6a61249fd, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_c7f6a61249fd, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_c7f6a61249fd, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_c7f6a61249fd, p_SourceObjectName := p_SourceObjectName_c7f6a61249fd, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ccf8142f33ba UUID;
  p_QueryID_ccf8142f33ba UUID;
  p_Name_ccf8142f33ba VARCHAR(255);
  p_Description_ccf8142f33ba TEXT;
  p_Sequence_ccf8142f33ba INTEGER;
  p_SQLBaseType_ccf8142f33ba VARCHAR(50);
  p_SQLFullType_ccf8142f33ba VARCHAR(100);
  p_SourceEntityID_ccf8142f33ba UUID;
  p_SourceFieldName_ccf8142f33ba VARCHAR(255);
  p_IsComputed_ccf8142f33ba BOOLEAN;
  p_ComputationDescription_ccf8142f33ba TEXT;
  p_IsSummary_ccf8142f33ba BOOLEAN;
  p_SummaryDescription_ccf8142f33ba TEXT;
  p_DetectionMethod_ccf8142f33ba VARCHAR(50);
  p_AutoDetectConfidenceScore_ccf8142f33ba NUMERIC(3,2);
  p_SourceEntityFieldID_ccf8142f33ba UUID;
  p_IsNullable_ccf8142f33ba BOOLEAN;
  p_SourceObjectName_ccf8142f33ba VARCHAR(500);
BEGIN
  p_ID_ccf8142f33ba := 'bb445289-46bc-4fcc-8ef0-22ebf5dabc81';
  p_QueryID_ccf8142f33ba := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_ccf8142f33ba := 'PeopleAddedD3';
  p_Sequence_ccf8142f33ba := 4;
  p_SQLBaseType_ccf8142f33ba := 'int';
  p_SQLFullType_ccf8142f33ba := 'int';
  p_IsComputed_ccf8142f33ba := TRUE;
  p_IsSummary_ccf8142f33ba := FALSE;
  p_DetectionMethod_ccf8142f33ba := 'Database';
  p_IsNullable_ccf8142f33ba := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_ccf8142f33ba
                    OR ("QueryID" = p_QueryID_ccf8142f33ba AND "Name" = p_Name_ccf8142f33ba)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_ccf8142f33ba,
    'QueryID', p_QueryID_ccf8142f33ba,
    'Name', p_Name_ccf8142f33ba,
    'Description', p_Description_ccf8142f33ba,
    'Sequence', p_Sequence_ccf8142f33ba,
    'SQLBaseType', p_SQLBaseType_ccf8142f33ba,
    'SQLFullType', p_SQLFullType_ccf8142f33ba,
    'SourceEntityID', p_SourceEntityID_ccf8142f33ba,
    'SourceFieldName', p_SourceFieldName_ccf8142f33ba,
    'IsComputed', p_IsComputed_ccf8142f33ba,
    'ComputationDescription', p_ComputationDescription_ccf8142f33ba,
    'IsSummary', p_IsSummary_ccf8142f33ba,
    'SummaryDescription', p_SummaryDescription_ccf8142f33ba,
    'DetectionMethod', p_DetectionMethod_ccf8142f33ba,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_ccf8142f33ba,
    'SourceEntityFieldID', p_SourceEntityFieldID_ccf8142f33ba,
    'IsNullable', p_IsNullable_ccf8142f33ba,
    'SourceObjectName', p_SourceObjectName_ccf8142f33ba
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_ccf8142f33ba, p_QueryID := p_QueryID_ccf8142f33ba, p_Name := p_Name_ccf8142f33ba, p_Description := p_Description_ccf8142f33ba, p_Description_Clear := TRUE, p_Sequence := p_Sequence_ccf8142f33ba, p_SQLBaseType := p_SQLBaseType_ccf8142f33ba, p_SQLFullType := p_SQLFullType_ccf8142f33ba, p_SourceEntityID := p_SourceEntityID_ccf8142f33ba, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_ccf8142f33ba, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_ccf8142f33ba, p_ComputationDescription := p_ComputationDescription_ccf8142f33ba, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_ccf8142f33ba, p_SummaryDescription := p_SummaryDescription_ccf8142f33ba, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_ccf8142f33ba, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_ccf8142f33ba, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_ccf8142f33ba, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_ccf8142f33ba, p_SourceObjectName := p_SourceObjectName_ccf8142f33ba, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_22c5dff96c75 UUID;
  p_QueryID_22c5dff96c75 UUID;
  p_Name_22c5dff96c75 VARCHAR(255);
  p_Description_22c5dff96c75 TEXT;
  p_Sequence_22c5dff96c75 INTEGER;
  p_SQLBaseType_22c5dff96c75 VARCHAR(50);
  p_SQLFullType_22c5dff96c75 VARCHAR(100);
  p_SourceEntityID_22c5dff96c75 UUID;
  p_SourceFieldName_22c5dff96c75 VARCHAR(255);
  p_IsComputed_22c5dff96c75 BOOLEAN;
  p_ComputationDescription_22c5dff96c75 TEXT;
  p_IsSummary_22c5dff96c75 BOOLEAN;
  p_SummaryDescription_22c5dff96c75 TEXT;
  p_DetectionMethod_22c5dff96c75 VARCHAR(50);
  p_AutoDetectConfidenceScore_22c5dff96c75 NUMERIC(3,2);
  p_SourceEntityFieldID_22c5dff96c75 UUID;
  p_IsNullable_22c5dff96c75 BOOLEAN;
  p_SourceObjectName_22c5dff96c75 VARCHAR(500);
BEGIN
  p_ID_22c5dff96c75 := '4ae9d21c-f2ef-461d-be3f-60ccfe650afc';
  p_QueryID_22c5dff96c75 := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_22c5dff96c75 := 'PeopleAddedD4';
  p_Sequence_22c5dff96c75 := 5;
  p_SQLBaseType_22c5dff96c75 := 'int';
  p_SQLFullType_22c5dff96c75 := 'int';
  p_IsComputed_22c5dff96c75 := TRUE;
  p_IsSummary_22c5dff96c75 := FALSE;
  p_DetectionMethod_22c5dff96c75 := 'Database';
  p_IsNullable_22c5dff96c75 := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_22c5dff96c75
                    OR ("QueryID" = p_QueryID_22c5dff96c75 AND "Name" = p_Name_22c5dff96c75)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_22c5dff96c75,
    'QueryID', p_QueryID_22c5dff96c75,
    'Name', p_Name_22c5dff96c75,
    'Description', p_Description_22c5dff96c75,
    'Sequence', p_Sequence_22c5dff96c75,
    'SQLBaseType', p_SQLBaseType_22c5dff96c75,
    'SQLFullType', p_SQLFullType_22c5dff96c75,
    'SourceEntityID', p_SourceEntityID_22c5dff96c75,
    'SourceFieldName', p_SourceFieldName_22c5dff96c75,
    'IsComputed', p_IsComputed_22c5dff96c75,
    'ComputationDescription', p_ComputationDescription_22c5dff96c75,
    'IsSummary', p_IsSummary_22c5dff96c75,
    'SummaryDescription', p_SummaryDescription_22c5dff96c75,
    'DetectionMethod', p_DetectionMethod_22c5dff96c75,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_22c5dff96c75,
    'SourceEntityFieldID', p_SourceEntityFieldID_22c5dff96c75,
    'IsNullable', p_IsNullable_22c5dff96c75,
    'SourceObjectName', p_SourceObjectName_22c5dff96c75
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_22c5dff96c75, p_QueryID := p_QueryID_22c5dff96c75, p_Name := p_Name_22c5dff96c75, p_Description := p_Description_22c5dff96c75, p_Description_Clear := TRUE, p_Sequence := p_Sequence_22c5dff96c75, p_SQLBaseType := p_SQLBaseType_22c5dff96c75, p_SQLFullType := p_SQLFullType_22c5dff96c75, p_SourceEntityID := p_SourceEntityID_22c5dff96c75, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_22c5dff96c75, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_22c5dff96c75, p_ComputationDescription := p_ComputationDescription_22c5dff96c75, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_22c5dff96c75, p_SummaryDescription := p_SummaryDescription_22c5dff96c75, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_22c5dff96c75, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_22c5dff96c75, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_22c5dff96c75, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_22c5dff96c75, p_SourceObjectName := p_SourceObjectName_22c5dff96c75, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cbb0b8da3a98 UUID;
  p_QueryID_cbb0b8da3a98 UUID;
  p_Name_cbb0b8da3a98 VARCHAR(255);
  p_Description_cbb0b8da3a98 TEXT;
  p_Sequence_cbb0b8da3a98 INTEGER;
  p_SQLBaseType_cbb0b8da3a98 VARCHAR(50);
  p_SQLFullType_cbb0b8da3a98 VARCHAR(100);
  p_SourceEntityID_cbb0b8da3a98 UUID;
  p_SourceFieldName_cbb0b8da3a98 VARCHAR(255);
  p_IsComputed_cbb0b8da3a98 BOOLEAN;
  p_ComputationDescription_cbb0b8da3a98 TEXT;
  p_IsSummary_cbb0b8da3a98 BOOLEAN;
  p_SummaryDescription_cbb0b8da3a98 TEXT;
  p_DetectionMethod_cbb0b8da3a98 VARCHAR(50);
  p_AutoDetectConfidenceScore_cbb0b8da3a98 NUMERIC(3,2);
  p_SourceEntityFieldID_cbb0b8da3a98 UUID;
  p_IsNullable_cbb0b8da3a98 BOOLEAN;
  p_SourceObjectName_cbb0b8da3a98 VARCHAR(500);
BEGIN
  p_ID_cbb0b8da3a98 := 'b7b323ff-6fe5-4071-891f-4f8ef9087cd2';
  p_QueryID_cbb0b8da3a98 := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_cbb0b8da3a98 := 'PeopleAddedD5';
  p_Sequence_cbb0b8da3a98 := 6;
  p_SQLBaseType_cbb0b8da3a98 := 'int';
  p_SQLFullType_cbb0b8da3a98 := 'int';
  p_IsComputed_cbb0b8da3a98 := TRUE;
  p_IsSummary_cbb0b8da3a98 := FALSE;
  p_DetectionMethod_cbb0b8da3a98 := 'Database';
  p_IsNullable_cbb0b8da3a98 := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_cbb0b8da3a98
                    OR ("QueryID" = p_QueryID_cbb0b8da3a98 AND "Name" = p_Name_cbb0b8da3a98)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_cbb0b8da3a98,
    'QueryID', p_QueryID_cbb0b8da3a98,
    'Name', p_Name_cbb0b8da3a98,
    'Description', p_Description_cbb0b8da3a98,
    'Sequence', p_Sequence_cbb0b8da3a98,
    'SQLBaseType', p_SQLBaseType_cbb0b8da3a98,
    'SQLFullType', p_SQLFullType_cbb0b8da3a98,
    'SourceEntityID', p_SourceEntityID_cbb0b8da3a98,
    'SourceFieldName', p_SourceFieldName_cbb0b8da3a98,
    'IsComputed', p_IsComputed_cbb0b8da3a98,
    'ComputationDescription', p_ComputationDescription_cbb0b8da3a98,
    'IsSummary', p_IsSummary_cbb0b8da3a98,
    'SummaryDescription', p_SummaryDescription_cbb0b8da3a98,
    'DetectionMethod', p_DetectionMethod_cbb0b8da3a98,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_cbb0b8da3a98,
    'SourceEntityFieldID', p_SourceEntityFieldID_cbb0b8da3a98,
    'IsNullable', p_IsNullable_cbb0b8da3a98,
    'SourceObjectName', p_SourceObjectName_cbb0b8da3a98
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_cbb0b8da3a98, p_QueryID := p_QueryID_cbb0b8da3a98, p_Name := p_Name_cbb0b8da3a98, p_Description := p_Description_cbb0b8da3a98, p_Description_Clear := TRUE, p_Sequence := p_Sequence_cbb0b8da3a98, p_SQLBaseType := p_SQLBaseType_cbb0b8da3a98, p_SQLFullType := p_SQLFullType_cbb0b8da3a98, p_SourceEntityID := p_SourceEntityID_cbb0b8da3a98, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_cbb0b8da3a98, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_cbb0b8da3a98, p_ComputationDescription := p_ComputationDescription_cbb0b8da3a98, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_cbb0b8da3a98, p_SummaryDescription := p_SummaryDescription_cbb0b8da3a98, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_cbb0b8da3a98, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_cbb0b8da3a98, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_cbb0b8da3a98, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_cbb0b8da3a98, p_SourceObjectName := p_SourceObjectName_cbb0b8da3a98, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_9f52c671a7a8 UUID;
  p_QueryID_9f52c671a7a8 UUID;
  p_Name_9f52c671a7a8 VARCHAR(255);
  p_Description_9f52c671a7a8 TEXT;
  p_Sequence_9f52c671a7a8 INTEGER;
  p_SQLBaseType_9f52c671a7a8 VARCHAR(50);
  p_SQLFullType_9f52c671a7a8 VARCHAR(100);
  p_SourceEntityID_9f52c671a7a8 UUID;
  p_SourceFieldName_9f52c671a7a8 VARCHAR(255);
  p_IsComputed_9f52c671a7a8 BOOLEAN;
  p_ComputationDescription_9f52c671a7a8 TEXT;
  p_IsSummary_9f52c671a7a8 BOOLEAN;
  p_SummaryDescription_9f52c671a7a8 TEXT;
  p_DetectionMethod_9f52c671a7a8 VARCHAR(50);
  p_AutoDetectConfidenceScore_9f52c671a7a8 NUMERIC(3,2);
  p_SourceEntityFieldID_9f52c671a7a8 UUID;
  p_IsNullable_9f52c671a7a8 BOOLEAN;
  p_SourceObjectName_9f52c671a7a8 VARCHAR(500);
BEGIN
  p_ID_9f52c671a7a8 := '8b34f894-c0a0-4a9d-8a3a-93d9e5f7c59e';
  p_QueryID_9f52c671a7a8 := '6C0A1000-0001-4000-A000-000000000010';
  p_Name_9f52c671a7a8 := 'PeopleAddedD6';
  p_Sequence_9f52c671a7a8 := 7;
  p_SQLBaseType_9f52c671a7a8 := 'int';
  p_SQLFullType_9f52c671a7a8 := 'int';
  p_IsComputed_9f52c671a7a8 := TRUE;
  p_IsSummary_9f52c671a7a8 := FALSE;
  p_DetectionMethod_9f52c671a7a8 := 'Database';
  p_IsNullable_9f52c671a7a8 := FALSE;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryField"
                 WHERE "ID" = p_ID_9f52c671a7a8
                    OR ("QueryID" = p_QueryID_9f52c671a7a8 AND "Name" = p_Name_9f52c671a7a8)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryField'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryField"(p_data := jsonb_build_object(
    'ID', p_ID_9f52c671a7a8,
    'QueryID', p_QueryID_9f52c671a7a8,
    'Name', p_Name_9f52c671a7a8,
    'Description', p_Description_9f52c671a7a8,
    'Sequence', p_Sequence_9f52c671a7a8,
    'SQLBaseType', p_SQLBaseType_9f52c671a7a8,
    'SQLFullType', p_SQLFullType_9f52c671a7a8,
    'SourceEntityID', p_SourceEntityID_9f52c671a7a8,
    'SourceFieldName', p_SourceFieldName_9f52c671a7a8,
    'IsComputed', p_IsComputed_9f52c671a7a8,
    'ComputationDescription', p_ComputationDescription_9f52c671a7a8,
    'IsSummary', p_IsSummary_9f52c671a7a8,
    'SummaryDescription', p_SummaryDescription_9f52c671a7a8,
    'DetectionMethod', p_DetectionMethod_9f52c671a7a8,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_9f52c671a7a8,
    'SourceEntityFieldID', p_SourceEntityFieldID_9f52c671a7a8,
    'IsNullable', p_IsNullable_9f52c671a7a8,
    'SourceObjectName', p_SourceObjectName_9f52c671a7a8
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryField"(p_ID := p_ID_9f52c671a7a8, p_QueryID := p_QueryID_9f52c671a7a8, p_Name := p_Name_9f52c671a7a8, p_Description := p_Description_9f52c671a7a8, p_Description_Clear := TRUE, p_Sequence := p_Sequence_9f52c671a7a8, p_SQLBaseType := p_SQLBaseType_9f52c671a7a8, p_SQLFullType := p_SQLFullType_9f52c671a7a8, p_SourceEntityID := p_SourceEntityID_9f52c671a7a8, p_SourceEntityID_Clear := TRUE, p_SourceFieldName := p_SourceFieldName_9f52c671a7a8, p_SourceFieldName_Clear := TRUE, p_IsComputed := p_IsComputed_9f52c671a7a8, p_ComputationDescription := p_ComputationDescription_9f52c671a7a8, p_ComputationDescription_Clear := TRUE, p_IsSummary := p_IsSummary_9f52c671a7a8, p_SummaryDescription := p_SummaryDescription_9f52c671a7a8, p_SummaryDescription_Clear := TRUE, p_DetectionMethod := p_DetectionMethod_9f52c671a7a8, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_9f52c671a7a8, p_AutoDetectConfidenceScore_Clear := TRUE, p_SourceEntityFieldID := p_SourceEntityFieldID_9f52c671a7a8, p_SourceEntityFieldID_Clear := TRUE, p_IsNullable := p_IsNullable_9f52c671a7a8, p_SourceObjectName := p_SourceObjectName_9f52c671a7a8, p_SourceObjectName_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Query Entities (core SP call only)
DO $mj$
DECLARE
  p_ID_b0e3e9a8c97c UUID;
  p_QueryID_b0e3e9a8c97c UUID;
  p_EntityID_b0e3e9a8c97c UUID;
  p_DetectionMethod_b0e3e9a8c97c VARCHAR(50);
  p_AutoDetectConfidenceScore_b0e3e9a8c97c NUMERIC(3,2);
  p_AlternateBaseViewID_b0e3e9a8c97c UUID;
BEGIN
  p_ID_b0e3e9a8c97c := 'f213ec5f-a667-44ef-9444-1b48cede15e2';
  p_QueryID_b0e3e9a8c97c := '6C0A1000-0001-4000-A000-000000000010';
  p_EntityID_b0e3e9a8c97c := '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F';
  p_DetectionMethod_b0e3e9a8c97c := 'Parser';
  p_AutoDetectConfidenceScore_b0e3e9a8c97c := 1;
  IF NOT EXISTS (SELECT 1 FROM "${mjSchema}"."QueryEntity"
                 WHERE "ID" = p_ID_b0e3e9a8c97c
                    OR ("QueryID" = p_QueryID_b0e3e9a8c97c AND "EntityID" = p_EntityID_b0e3e9a8c97c)) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spCreateQueryEntity'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spCreateQueryEntity"(p_data := jsonb_build_object(
    'ID', p_ID_b0e3e9a8c97c,
    'QueryID', p_QueryID_b0e3e9a8c97c,
    'EntityID', p_EntityID_b0e3e9a8c97c,
    'DetectionMethod', p_DetectionMethod_b0e3e9a8c97c,
    'AutoDetectConfidenceScore', p_AutoDetectConfidenceScore_b0e3e9a8c97c,
    'AlternateBaseViewID', p_AlternateBaseViewID_b0e3e9a8c97c
  ));
    ELSE
      PERFORM "${mjSchema}"."spCreateQueryEntity"(p_ID := p_ID_b0e3e9a8c97c, p_QueryID := p_QueryID_b0e3e9a8c97c, p_EntityID := p_EntityID_b0e3e9a8c97c, p_DetectionMethod := p_DetectionMethod_b0e3e9a8c97c, p_AutoDetectConfidenceScore := p_AutoDetectConfidenceScore_b0e3e9a8c97c, p_AlternateBaseViewID := p_AlternateBaseViewID_b0e3e9a8c97c, p_AlternateBaseViewID_Clear := TRUE);
    END IF;
  END IF;
END $mj$;

-- Save MJ: Queries (core SP call only)
DO $mj$
DECLARE
  p_ApprovedFingerprint_9341040ddb73 VARCHAR(100);
  p_ID_9341040ddb73 UUID;
BEGIN
  p_ApprovedFingerprint_9341040ddb73 := '43014bbbb47098fabc59adfd9eb9c356257f2abd80af74094c057457e7249347';
  p_ID_9341040ddb73 := '6C0A1000-0001-4000-A000-000000000010';
  -- Set only while the query has no approved fingerprint, so a host's own approval is kept.
  IF EXISTS (SELECT 1 FROM "${mjSchema}"."Query"
             WHERE "ID" = p_ID_9341040ddb73 AND "ApprovedFingerprint" IS NULL) THEN
    IF EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = '${mjSchema}' AND p.proname = 'spUpdateQuery'
         AND p.pronargs = 1 AND p.proargtypes[0] = 'jsonb'::regtype
    ) THEN
      PERFORM "${mjSchema}"."spUpdateQuery"(p_data := jsonb_build_object(
      'ApprovedFingerprint', p_ApprovedFingerprint_9341040ddb73,
      'ID', p_ID_9341040ddb73
    ));
    ELSE
      PERFORM "${mjSchema}"."spUpdateQuery"(p_ApprovedFingerprint := p_ApprovedFingerprint_9341040ddb73, p_ID := p_ID_9341040ddb73);
    END IF;
  END IF;
END $mj$;
