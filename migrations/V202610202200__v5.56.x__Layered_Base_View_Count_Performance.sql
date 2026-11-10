-- =============================================================================================
-- Layered base views: make COUNT(*) cheap on vwPeople and vwOrganizations
--
-- Re-cut of #100 (MS-BC, "perf(views): make COUNT(*) cheap on vwPeople and vwOrganizations"),
-- which found and measured this defect and proposed the fix used here. #100 was written against
-- the v5.36 definitions and was held back from that release; since then v5.45 added the
-- PrimaryJobFunction columns to vwPeople and v5.48 (#199) shipped #100's two smaller fixes (the
-- NVARCHAR(700) AddressLink match and IX_Organization_Name). So this file starts from the current
-- definers -- V202609290300__v5.48.x__People_Organization_Lookup_Search_Performance.sql, vwPeople
-- and vwOrganizations -- and changes only how the primary address and primary email/phone are
-- joined. Every other line of both views is unchanged.
--
-- WHAT IS BROKEN. MJ's RunView computes TotalRowCount with a
-- `SELECT COUNT(*) FROM <base view>` for pagination. Both wrappers resolved the primary address
-- and the primary email/phone with LEFT OUTER JOINs. SQL Server cannot prove those joins return at
-- most one row (nothing makes (PersonID, ContactTypeID, IsPrimary) unique), so a bare count still
-- reads every matching ContactMethod and AddressLink row -- about 200,000 pages of ContactMethod
-- per count on AIDP Next, most of it from disk because that table does not stay in cache.
--
-- THE FIX. Each of those lookups becomes OUTER APPLY (SELECT TOP 1 ... ORDER BY <ID>), the
-- construct vwPeople already uses for the employer (emp_rel) and job function (primary_jf).
-- TOP 1 is provably at most one row, so the optimizer drops the apply from any query that reads
-- none of its columns. The address apply joins Address and AddressType inside it, so one apply
-- returns all nine PrimaryAddress* columns. ORDER BY the row's ID makes the pick deterministic if a
-- duplicate primary is ever written; the ID is the clustering key, so it is already in every
-- nonclustered index and costs no lookup.
--
-- VALUES. Identical while no person or organization has two primary rows of one kind. Checked on
-- a copy of AIDP Next stage (1,289,922 people, 448,142 organizations, 245,487 sales contacts; zero
-- duplicate primaries of any kind): applying this file changed no row of vwPeople, vwOrganizations
-- or vwSalesContacts (EXCEPT both ways over every column is empty), and the column list, types and
-- nullability are unchanged, matching EntityField one for one. With a duplicate primary email and a
-- duplicate primary address seeded in a rolled-back transaction, the old definition returned that
-- person 4 times (2 x 2); this returns them once, with the lowest-ID email and address.
--
-- MEASURED on AIDP Next stage (2 vCPU, 8 GB, SQL Server 2022). Before: the live views. After: this
-- file's view bodies run read-only against the same data.
--   SELECT COUNT(*) FROM vwPeople ........................................ 36.8 s  ->  0.20 s
--   SELECT COUNT(*) FROM vwOrganizations .................................  8.5 s  ->  0.08 s
--   SELECT COUNT(*) FROM __mj_BizAppsSales.vwSalesContacts (via vwPeople)  15-22 s  ->  0.05 s
--   People lookup count (LastName/Title/DisplayName LIKE 'f%', Email = 'f') 29.4 s  ->  0.10 s
-- Single-record loads, sorted list pages and the '%x%' contains searches are unchanged; the
-- contains searches still scan, because no index serves a leading wildcard.
--
-- DEPENDENTS. No column is added, removed, renamed or retyped, so no EntityField or CodeGen changes
-- are needed, and views built on these two (vwSalesContacts in bizapps-sales, the MJ Central
-- __BCSaaS views) keep a valid column list without sp_refreshview. None is schema-bound, so the
-- DROP + CREATE below does not have to touch them.
--
-- POSTGRESQL. T-SQL only, per CLAUDE.md ("The PostgreSQL twin is release work"). The twin is
-- generated at release with `pnpm run mj:migrate:convert`, after #276's PostgreSQL baseline lands,
-- because that baseline is what defines the PostgreSQL vwPeople and vwOrganizations this rewrites.
-- =============================================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
    addr.Line1           AS [PrimaryAddressLine1],
    addr.Line2           AS [PrimaryAddressLine2],
    addr.City            AS [PrimaryAddressCity],
    addr.StateProvince   AS [PrimaryAddressState],
    addr.PostalCode      AS [PrimaryAddressPostalCode],
    addr.Country         AS [PrimaryAddressCountry],
    addr.Latitude        AS [PrimaryAddressLatitude],
    addr.Longitude       AS [PrimaryAddressLongitude],
    addr.AddressTypeName AS [PrimaryAddressType],

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

OUTER APPLY (
    SELECT TOP 1
        a.[Line1],
        a.[Line2],
        a.[City],
        a.[StateProvince],
        a.[PostalCode],
        a.[Country],
        a.[Latitude],
        a.[Longitude],
        at.[Name] AS [AddressTypeName]
    FROM
        [${flyway:defaultSchema}].[AddressLink] AS al
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[Address] AS a
      ON
        a.[ID] = al.[AddressID]
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[AddressType] AS at
      ON
        at.[ID] = al.[AddressTypeID]
    WHERE
        al.[RecordID] = CONVERT(NVARCHAR(700), g.[ID])
        AND al.[EntityID] = (
            SELECT [ID] FROM [${mjSchema}].[Entity]
            WHERE [Name] = 'MJ_BizApps_Common: People'
        )
        AND al.[IsPrimary] = 1
    ORDER BY
        al.[ID]
) AS addr

OUTER APPLY (
    SELECT TOP 1
        cm.[Value]
    FROM
        [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE
        cm.[PersonID] = g.[ID]
        AND cm.[IsPrimary] = 1
        AND cm.[ContactTypeID] = (
            SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
            WHERE [Name] = 'Email'
        )
    ORDER BY
        cm.[ID]
) AS cm_email
OUTER APPLY (
    SELECT TOP 1
        cm.[Value]
    FROM
        [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE
        cm.[PersonID] = g.[ID]
        AND cm.[IsPrimary] = 1
        AND cm.[ContactTypeID] = (
            SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
            WHERE [Name] = 'Mobile Phone'
        )
    ORDER BY
        cm.[ID]
) AS cm_phone

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

    addr.Line1           AS [PrimaryAddressLine1],
    addr.Line2           AS [PrimaryAddressLine2],
    addr.City            AS [PrimaryAddressCity],
    addr.StateProvince   AS [PrimaryAddressState],
    addr.PostalCode      AS [PrimaryAddressPostalCode],
    addr.Country         AS [PrimaryAddressCountry],
    addr.Latitude        AS [PrimaryAddressLatitude],
    addr.Longitude       AS [PrimaryAddressLongitude],
    addr.AddressTypeName AS [PrimaryAddressType],

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

OUTER APPLY (
    SELECT TOP 1
        a.[Line1],
        a.[Line2],
        a.[City],
        a.[StateProvince],
        a.[PostalCode],
        a.[Country],
        a.[Latitude],
        a.[Longitude],
        at.[Name] AS [AddressTypeName]
    FROM
        [${flyway:defaultSchema}].[AddressLink] AS al
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[Address] AS a
      ON
        a.[ID] = al.[AddressID]
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[AddressType] AS at
      ON
        at.[ID] = al.[AddressTypeID]
    WHERE
        al.[RecordID] = CONVERT(NVARCHAR(700), g.[ID])
        AND al.[EntityID] = (
            SELECT [ID] FROM [${mjSchema}].[Entity]
            WHERE [Name] = 'MJ_BizApps_Common: Organizations'
        )
        AND al.[IsPrimary] = 1
    ORDER BY
        al.[ID]
) AS addr

OUTER APPLY (
    SELECT TOP 1
        cm.[Value]
    FROM
        [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE
        cm.[OrganizationID] = g.[ID]
        AND cm.[IsPrimary] = 1
        AND cm.[ContactTypeID] = (
            SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
            WHERE [Name] = 'Email'
        )
    ORDER BY
        cm.[ID]
) AS cm_email
OUTER APPLY (
    SELECT TOP 1
        cm.[Value]
    FROM
        [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE
        cm.[OrganizationID] = g.[ID]
        AND cm.[IsPrimary] = 1
        AND cm.[ContactTypeID] = (
            SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
            WHERE [Name] = 'Mobile Phone'
        )
    ORDER BY
        cm.[ID]
) AS cm_phone;
GO

REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Developer]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_Integration]
REVOKE SELECT ON [${flyway:defaultSchema}].[vwOrganizations] FROM [cdp_UI]
GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration];
GO
