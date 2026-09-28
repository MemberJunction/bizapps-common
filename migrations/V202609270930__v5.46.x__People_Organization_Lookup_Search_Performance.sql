-- =============================================================================================
-- People / Organization lookup search performance
--
-- Symptom (AIDP Next, 1.19M People / 423K Organizations): Bill To Person / Bill To Organization
-- lookups sat on "Searching..." and hit the 30 s command timeout; worst observed 57 s and 3.7M
-- page reads for one TOP 15 lookup. Causes, fixed together:
--
--   1. The curated user-search configuration (6fa900c, v5.44) only ever lived in
--      metadata/entities/.entities.json. Open App upgrades apply migrations, not metadata/, so
--      installed databases kept CodeGen's defaults: MiddleName, PreferredName, Title, Email, Phone
--      (People) and Website, Phone (Organizations) searched as '%x%' Contains. One leading-wildcard
--      term in the OR forces a full scan. -> Section 2 applies .entities.json verbatim.
--   2. People searched PrimaryEmail (Exact). PrimaryEmail is COALESCE(ContactMethod.Value, Email)
--      computed inside vwPeople, so no index can serve it and every lookup evaluated the whole
--      view per Person row (18.9 s with every other fix in place). -> PrimaryEmail removed from
--      search in .entities.json; Email (the Person column) stays as the Exact email match.
--   3. No indexes served the remaining prefix/exact terms. -> Section 1 (one index per searched
--      column: Person DisplayName, LastName, Title, Email; Organization Name, LegalName, TaxID,
--      Email, Website).
--   4. vwPeople / vwOrganizations joined AddressLink on RecordID = CAST(g.ID AS NVARCHAR(MAX)).
--      RecordID is NVARCHAR(700); an NVARCHAR(MAX) comparison cannot use
--      IX_AddressLink_EntityRecord_Primary. -> Section 3: CONVERT(NVARCHAR(700), g.ID). The views
--      are otherwise byte-identical to their latest definitions (vwPeople: v5.45.x
--      Job_Function_Seniority, vwOrganizations: v5.39.x Address_Geo_Source_And_Org_PrimaryAddress_Coords).
--
-- Measured on a restored copy of the AIDP Next database (SQL Server 2022), TOP 15 lookups:
--   People  rare term 15-19 s / 10.9M reads -> 47 ms / 862 reads; no match 3 ms; 'smith' 13 ms
--   Orgs    rare term 837 ms               -> 71 ms / 358 reads;  no match 3 ms
-- Index builds took 1-6 s each at that size and hold a table lock while they run (ONLINE builds
-- are Enterprise-only, so none is requested).
-- Postgres: see the .pg.sql twin (indexes + search configuration; PG views compare text to text).
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
-- Website is NVARCHAR(1000) (2000 bytes) but real values are short (max 135 chars on AIDP). Index keys
-- are capped at 1700 bytes, so a Website over 850 characters would be rejected on save; accepted,
-- because the party picker must reach the domain (see the Website comment in .entities.json).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Organization_Website' AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]'))
    CREATE INDEX IX_Organization_Website ON [${flyway:defaultSchema}].[Organization] ([Website]);
GO

-- 2. User-search configuration, generated from metadata/entities/.entities.json (source of truth)
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 1, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: People';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'BeginsWith', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'DisplayName';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'FirstName';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'BeginsWith', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'LastName';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'PrimaryEmail';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'Exact', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'Email';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'MiddleName';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'PreferredName';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'BeginsWith', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'Title';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'Phone';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: People' AND f.[Name] = N'ID';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 1, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Organizations';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'BeginsWith', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: Organizations' AND f.[Name] = N'Name';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'BeginsWith', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: Organizations' AND f.[Name] = N'LegalName';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'Exact', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: Organizations' AND f.[Name] = N'TaxID';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'Exact', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: Organizations' AND f.[Name] = N'Email';
UPDATE f SET f.[IncludeInUserSearchAPI] = 1, f.[UserSearchPredicateAPI] = N'BeginsWith', f.[AutoUpdateIncludeInUserSearchAPI] = 0, f.[AutoUpdateUserSearchPredicate] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: Organizations' AND f.[Name] = N'Website';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: Organizations' AND f.[Name] = N'Phone';
UPDATE f SET f.[IncludeInUserSearchAPI] = 0, f.[AutoUpdateIncludeInUserSearchAPI] = 0 FROM [${mjSchema}].[EntityField] f INNER JOIN [${mjSchema}].[Entity] e ON e.[ID] = f.[EntityID] WHERE e.[Name] = N'MJ_BizApps_Common: Organizations' AND f.[Name] = N'ID';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Addresses';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Address Links';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Activity Types';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Activity Files';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Activity Links';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Activity Sync Connections';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Activity Sync Rule Sets';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Activity Sync Rules';
UPDATE [${mjSchema}].[Entity] SET [AllowUserSearchAPI] = 0, [AutoUpdateAllowUserSearchAPI] = 0 WHERE [Name] = N'MJ_BizApps_Common: Activity Sync Exclusions';
GO

-- 3. Views: AddressLink join made sargable
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
        SELECT [ID] FROM [__mj].[Entity]
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
