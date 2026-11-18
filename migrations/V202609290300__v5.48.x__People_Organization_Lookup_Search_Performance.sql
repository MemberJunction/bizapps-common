-- =============================================================================================
-- People / Organization lookup search performance
--
-- Symptom (AIDP Next, 1.19M People / 423K Organizations): Bill To Person / Bill To Organization
-- lookups sat on "Searching..." and hit the 30 s command timeout; worst observed 57 s and 3.7M
-- page reads for one TOP 15 lookup. Causes, fixed together:
--
--   1. The curated user-search configuration (6fa900c, v5.44) lives in
--      metadata/entities/.entities.json and has not yet shipped in a Metadata_Sync (the last one is
--      v5.38.x), so installed databases still carry CodeGen's defaults: MiddleName, PreferredName,
--      Title, Email, Phone (People) and Website, Phone (Organizations) searched as '%x%' Contains.
--      One leading-wildcard term in the OR forces a full scan. -> Metadata, so NOT in this file:
--      it reaches installed databases through the release's generated Metadata_Sync.
--   2. People searched PrimaryEmail (Exact). PrimaryEmail is COALESCE(ContactMethod.Value, Email)
--      computed inside vwPeople, so no index can serve it and every lookup evaluated the whole
--      view per Person row (18.9 s with every other fix in place). -> Metadata: removed from
--      search in .entities.json; Email (the Person column) stays as the Exact email match.
--   3. No indexes served the curated prefix/exact terms. -> Section 1 (one index per searched
--      column: Person DisplayName, LastName, Title, Email; Organization Name, LegalName, TaxID,
--      Email). Website is taken out of user search in .entities.json instead of indexed: 77% of
--      AIDP values carry a scheme, so BeginsWith missed them, and an unindexed leg in the OR
--      would scan Organization.
--   4. vwPeople / vwOrganizations joined AddressLink on RecordID = CAST(g.ID AS NVARCHAR(MAX)).
--      RecordID is NVARCHAR(700); an NVARCHAR(MAX) comparison cannot use
--      IX_AddressLink_EntityRecord_Primary. -> Section 2: CONVERT(NVARCHAR(700), g.ID). The views
--      are otherwise byte-identical to their latest definitions (vwPeople: v5.45.x
--      Job_Function_Seniority, vwOrganizations: v5.39.x Address_Geo_Source_And_Org_PrimaryAddress_Coords).
--
-- The speedup below needs BOTH this migration and the curated search configuration applied
-- (the release Metadata_Sync); indexes alone do not help while any Contains term remains.
-- Measured on a restored copy of the AIDP Next database (SQL Server 2022), TOP 15 lookups, with
-- this migration applied inside a rolled-back transaction:
--   People  rare term 15-19 s / 10.9M reads -> 2-5 ms
--   Orgs    rare term 837 ms               -> 2-4 ms
-- (An earlier step-by-step bench, timed through SELECT INTO a temp table and before the view
-- change, read 47 ms / 862 reads and 71 ms / 358 reads; the figures above are the final state.)
-- Index builds took 1-6 s each at that size and hold a table lock while they run (ONLINE builds
-- are Enterprise-only, so none is requested).
-- Postgres: see the .pg.sql twin (indexes only; PG views compare text to text).
-- =============================================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;  -- required to index a table with a computed column (Person.DisplayName)
GO

-- 1. Indexes for the searched columns (guarded: some databases already carry IX_Organization_Name)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Person_DisplayName' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]'))
    CREATE INDEX IX_Person_DisplayName ON [${flyway:defaultSchema}].[Person] ([DisplayName]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Person_LastName' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]'))
    CREATE INDEX IX_Person_LastName ON [${flyway:defaultSchema}].[Person] ([LastName]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Person_Title' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]'))
    CREATE INDEX IX_Person_Title ON [${flyway:defaultSchema}].[Person] ([Title]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Person_Email' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Person]'))
    CREATE INDEX IX_Person_Email ON [${flyway:defaultSchema}].[Person] ([Email]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Organization_Name' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]'))
    CREATE INDEX IX_Organization_Name ON [${flyway:defaultSchema}].[Organization] ([Name]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Organization_LegalName' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]'))
    CREATE INDEX IX_Organization_LegalName ON [${flyway:defaultSchema}].[Organization] ([LegalName]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Organization_TaxID' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]'))
    CREATE INDEX IX_Organization_TaxID ON [${flyway:defaultSchema}].[Organization] ([TaxID]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Organization_Email' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]'))
    CREATE INDEX IX_Organization_Email ON [${flyway:defaultSchema}].[Organization] ([Email]);
GO

-- 2. Views: AddressLink join made sargable
IF OBJECT_ID('[${flyway:defaultSchema}].[vwPeople]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwPeople];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwPeople]
AS
SELECT
    -- Everything CodeGen generates: base columns, DisplayName, LinkedUser, and any
    -- foreign-key display field added from here on, without this file changing.
    g.*,

    -- Primary address, resolved through the polymorphic AddressLink (IsPrimary = 1).
    addr.Line1          AS [PrimaryAddressLine1],
    addr.Line2          AS [PrimaryAddressLine2],
    addr.City           AS [PrimaryAddressCity],
    addr.StateProvince  AS [PrimaryAddressState],
    addr.PostalCode     AS [PrimaryAddressPostalCode],
    addr.Country        AS [PrimaryAddressCountry],
    addr.Latitude       AS [PrimaryAddressLatitude],
    addr.Longitude      AS [PrimaryAddressLongitude],
    addrType.Name       AS [PrimaryAddressType],

    -- Primary contact methods, falling back to the columns on Person itself.
    COALESCE(cm_email.Value, g.Email) AS [PrimaryEmail],
    COALESCE(cm_phone.Value, g.Phone) AS [PrimaryPhone],

    -- Current employer: most recent active Employee relationship.
    emp_org.ID          AS [CurrentOrganizationID],
    emp_org.Name        AS [CurrentOrganizationName],
    emp_rel.Title       AS [CurrentJobTitle],

    -- Primary job function: lowest Sequence PersonJobFunction row.
    primary_jf.JobFunctionID   AS [PrimaryJobFunctionID],
    primary_jf.JobFunctionName AS [PrimaryJobFunction]

FROM
    [${flyway:defaultSchema}].[vwPeopleGenerated] AS g

LEFT OUTER JOIN
    [${flyway:defaultSchema}].[AddressLink] AS al
  ON
    al.[RecordID] = CONVERT(NVARCHAR(700), g.[ID])
    AND al.[EntityID] = (
        SELECT [ID] FROM [${mjSchema}].[Entity]
        WHERE [Name] = 'MJ_BizApps_Common: People'
    )
    AND al.[IsPrimary] = 1
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Address] AS addr
  ON
    addr.[ID] = al.[AddressID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[AddressType] AS addrType
  ON
    addrType.[ID] = al.[AddressTypeID]

LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS cm_email
  ON
    cm_email.[PersonID] = g.[ID]
    AND cm_email.[IsPrimary] = 1
    AND cm_email.[ContactTypeID] = (
        SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
        WHERE [Name] = 'Email'
    )
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS cm_phone
  ON
    cm_phone.[PersonID] = g.[ID]
    AND cm_phone.[IsPrimary] = 1
    AND cm_phone.[ContactTypeID] = (
        SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
        WHERE [Name] = 'Mobile Phone'
    )

OUTER APPLY (
    SELECT TOP 1
        r.[Title],
        r.[ToOrganizationID]
    FROM
        [${flyway:defaultSchema}].[Relationship] AS r
    INNER JOIN
        [${flyway:defaultSchema}].[RelationshipType] AS rt
      ON
        rt.[ID] = r.[RelationshipTypeID]
    WHERE
        rt.[Name] = 'Employee'
        AND r.[FromPersonID] = g.[ID]
        AND r.[Status] = 'Active'
    ORDER BY
        r.[StartDate] DESC
) AS emp_rel
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS emp_org
  ON
    emp_org.[ID] = emp_rel.[ToOrganizationID]

OUTER APPLY (
    SELECT TOP 1
        pjf.[JobFunctionID],
        jf.[Name] AS [JobFunctionName]
    FROM
        [${flyway:defaultSchema}].[PersonJobFunction] AS pjf
    INNER JOIN
        [${flyway:defaultSchema}].[JobFunction] AS jf
      ON
        jf.[ID] = pjf.[JobFunctionID]
    WHERE
        pjf.[PersonID] = g.[ID]
    ORDER BY
        pjf.[Sequence] ASC,
        jf.[Name] ASC
) AS primary_jf;
GO

REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwPeople] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwPeople] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwOrganizations];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwOrganizations]
AS
SELECT
    -- Everything CodeGen generates: base columns, OrganizationType, Parent, and the
    -- recursive RootParentID — all of which the hand-written view used to restate.
    g.*,

    addr.Line1          AS [PrimaryAddressLine1],
    addr.Line2          AS [PrimaryAddressLine2],
    addr.City           AS [PrimaryAddressCity],
    addr.StateProvince  AS [PrimaryAddressState],
    addr.PostalCode     AS [PrimaryAddressPostalCode],
    addr.Country        AS [PrimaryAddressCountry],
    addr.Latitude       AS [PrimaryAddressLatitude],
    addr.Longitude      AS [PrimaryAddressLongitude],
    addrType.Name       AS [PrimaryAddressType],

    COALESCE(cm_email.Value, g.Email) AS [PrimaryEmail],
    COALESCE(cm_phone.Value, g.Phone) AS [PrimaryPhone],

    (
        SELECT COUNT(*)
        FROM [${flyway:defaultSchema}].[Relationship] AS r
        INNER JOIN [${flyway:defaultSchema}].[RelationshipType] AS rt
          ON rt.[ID] = r.[RelationshipTypeID]
        WHERE rt.[Category] = 'PersonToOrganization'
          AND r.[ToOrganizationID] = g.[ID]
          AND r.[Status] = 'Active'
    ) AS [ActivePersonCount],

    (
        SELECT COUNT(*)
        FROM [${flyway:defaultSchema}].[Organization] AS child
        WHERE child.[ParentID] = g.[ID]
          AND child.[Status] = 'Active'
    ) AS [ChildOrgCount]

FROM
    [${flyway:defaultSchema}].[vwOrganizationsGenerated] AS g

LEFT OUTER JOIN
    [${flyway:defaultSchema}].[AddressLink] AS al
  ON
    al.[RecordID] = CONVERT(NVARCHAR(700), g.[ID])
    AND al.[EntityID] = (
        SELECT [ID] FROM [${mjSchema}].[Entity]
        WHERE [Name] = 'MJ_BizApps_Common: Organizations'
    )
    AND al.[IsPrimary] = 1
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Address] AS addr
  ON
    addr.[ID] = al.[AddressID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[AddressType] AS addrType
  ON
    addrType.[ID] = al.[AddressTypeID]

LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS cm_email
  ON
    cm_email.[OrganizationID] = g.[ID]
    AND cm_email.[IsPrimary] = 1
    AND cm_email.[ContactTypeID] = (
        SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
        WHERE [Name] = 'Email'
    )
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ContactMethod] AS cm_phone
  ON
    cm_phone.[OrganizationID] = g.[ID]
    AND cm_phone.[IsPrimary] = 1
    AND cm_phone.[ContactTypeID] = (
        SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
        WHERE [Name] = 'Mobile Phone'
    );
GO

REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO
