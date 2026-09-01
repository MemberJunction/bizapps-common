-- =============================================================================
-- Layered base views: make COUNT(*) cheap on vwPeople and vwOrganizations
-- =============================================================================
--
-- Follows V202608132240, which introduced these wrappers. It changes only HOW the
-- wrappers join — the SELECT list, column names, order and values are untouched, so
-- no EntityField changes and no CodeGen section are needed here (same reasoning as
-- PART 2's "NO CODEGEN SECTION HERE").
--
-- WHAT IS BROKEN. MJ's RunView computes TotalRowCount as an unfiltered
-- `SELECT COUNT(*) FROM <base view>` for pagination. Both wrappers resolve the primary
-- address and the primary email/phone with LEFT OUTER JOINs. SQL Server cannot prove a
-- LEFT JOIN is 1:1, so it must evaluate all of them even for a bare row count — the
-- enrichment is computed for every row purely to count rows.
--
-- Measured on SQL Server against production-scale data:
--
--   Organizations (327,575 rows)
--     COUNT(*) vwOrganizationsGenerated (inner) .......     36 ms
--     COUNT(*) vwOrganizations         (wrapper) ..... 11,939 ms
--
--   People (1,063,303 rows)
--     COUNT(*) vwPeopleGenerated       (inner) .......     94 ms
--     COUNT(*) vwPeople                (wrapper) .....  4,775 ms
--
-- The record page issues a batched RunViews call covering every related-entity panel.
-- One 12-second count inside that batch pushes the request past the 30s timeout, and the
-- whole batch fails — so EVERY TAB on an Organization record returns 504, not just the
-- one that needed the count. That is how this presents in the field: unrelated panels
-- breaking, with nothing in the UI pointing at the count.
--
-- THE FIX. Express each enrichment as OUTER APPLY (SELECT TOP 1 ...). TOP 1 is provably
-- at most one row, so the optimizer can eliminate the apply entirely for COUNT(*) while
-- producing identical values for SELECT. This is the same construct this file already
-- uses for vwPeople's employer lookup (emp_rel) — applied consistently to the rest.
--
-- VALUE-IDENTICAL, NOT MERELY EQUIVALENT. TOP 1 over a set that never holds more than one
-- row returns exactly what the LEFT JOIN returned. Verified on 327,575 organizations and
-- 1,063,303 people: zero rows have duplicate primary address, primary email, or primary
-- phone. Row counts are unchanged (327,575 and 1,063,303 before and after). Where a
-- duplicate primary ever did exist, the LEFT JOIN silently MULTIPLIED the row and inflated
-- every count built on it; TOP 1 collapses it. So this also removes a latent correctness
-- bug rather than trading correctness for speed.
--
-- ALSO FIXED — AN OVERSIZED CAST THAT DEFEATS THE INDEX. Both wrappers matched the
-- polymorphic AddressLink with `CAST(g.[ID] AS NVARCHAR(MAX))`, but AddressLink.RecordID
-- is nvarchar(700). Comparing against an NVARCHAR(MAX) expression prevents a seek on
-- IX_AddressLink_EntityRecord_Primary (EntityID, RecordID, IsPrimary) INCLUDE (AddressID,
-- AddressTypeID), forcing a scan of the AddressLink table. Casting to the column's actual
-- width restores the seek. Same matching semantics — a GUID rendered as text is 36
-- characters and fits either width.
--
-- AND A MISSING INDEX ON Organization.Name. The Organizations directory sorts by Name and
-- nothing supported it, so every load sorted the full table: 11,500 ms at 327k rows, 2 ms
-- with the index below.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- People
-- -----------------------------------------------------------------------------
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
    pa.[Line1]          AS [PrimaryAddressLine1],
    pa.[Line2]          AS [PrimaryAddressLine2],
    pa.[City]           AS [PrimaryAddressCity],
    pa.[StateProvince]  AS [PrimaryAddressState],
    pa.[PostalCode]     AS [PrimaryAddressPostalCode],
    pa.[Country]        AS [PrimaryAddressCountry],
    pa.[Latitude]       AS [PrimaryAddressLatitude],
    pa.[Longitude]      AS [PrimaryAddressLongitude],
    pa.[AddressType]    AS [PrimaryAddressType],

    -- Primary contact methods, falling back to the columns on Person itself.
    COALESCE(cm_email.[Value], g.[Email]) AS [PrimaryEmail],
    COALESCE(cm_phone.[Value], g.[Phone]) AS [PrimaryPhone],

    -- Current employer: most recent active Employee relationship.
    emp_org.[ID]        AS [CurrentOrganizationID],
    emp_org.[Name]      AS [CurrentOrganizationName],
    emp_rel.[Title]     AS [CurrentJobTitle]

FROM
    [${flyway:defaultSchema}].[vwPeopleGenerated] AS g

OUTER APPLY (
    SELECT TOP 1
        addr.[Line1], addr.[Line2], addr.[City], addr.[StateProvince],
        addr.[PostalCode], addr.[Country], addr.[Latitude], addr.[Longitude],
        addrType.[Name] AS [AddressType]
    FROM
        [${flyway:defaultSchema}].[AddressLink] AS al
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[Address] AS addr
      ON
        addr.[ID] = al.[AddressID]
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[AddressType] AS addrType
      ON
        addrType.[ID] = al.[AddressTypeID]
    WHERE
        al.[EntityID] = (
            SELECT [ID] FROM [__mj].[Entity]
            WHERE [Name] = 'MJ_BizApps_Common: People'
        )
        AND al.[RecordID] = CAST(g.[ID] AS NVARCHAR(700))
        AND al.[IsPrimary] = 1
) AS pa

OUTER APPLY (
    SELECT TOP 1 cm.[Value]
    FROM [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE cm.[PersonID] = g.[ID]
      AND cm.[ContactTypeID] = (
          SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
          WHERE [Name] = 'Email'
      )
      AND cm.[IsPrimary] = 1
) AS cm_email

OUTER APPLY (
    SELECT TOP 1 cm.[Value]
    FROM [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE cm.[PersonID] = g.[ID]
      AND cm.[ContactTypeID] = (
          SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
          WHERE [Name] = 'Mobile Phone'
      )
      AND cm.[IsPrimary] = 1
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
-- PK join: provably at most one row, so it is eliminable for COUNT(*) as written.
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS emp_org
  ON
    emp_org.[ID] = emp_rel.[ToOrganizationID];
GO

-- -----------------------------------------------------------------------------
-- Organizations
-- -----------------------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwOrganizations];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwOrganizations]
AS
SELECT
    -- Everything CodeGen generates: base columns, OrganizationType, Parent, and the
    -- recursive RootParentID — all of which the hand-written view used to restate.
    g.*,

    pa.[Line1]          AS [PrimaryAddressLine1],
    pa.[Line2]          AS [PrimaryAddressLine2],
    pa.[City]           AS [PrimaryAddressCity],
    pa.[StateProvince]  AS [PrimaryAddressState],
    pa.[PostalCode]     AS [PrimaryAddressPostalCode],
    pa.[Country]        AS [PrimaryAddressCountry],
    pa.[AddressType]    AS [PrimaryAddressType],

    COALESCE(cm_email.[Value], g.[Email]) AS [PrimaryEmail],
    COALESCE(cm_phone.[Value], g.[Phone]) AS [PrimaryPhone],

    -- Scalar subqueries in the SELECT list are already eliminated for COUNT(*).
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
        addr.[Line1], addr.[Line2], addr.[City], addr.[StateProvince],
        addr.[PostalCode], addr.[Country],
        addrType.[Name] AS [AddressType]
    FROM
        [${flyway:defaultSchema}].[AddressLink] AS al
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[Address] AS addr
      ON
        addr.[ID] = al.[AddressID]
    LEFT OUTER JOIN
        [${flyway:defaultSchema}].[AddressType] AS addrType
      ON
        addrType.[ID] = al.[AddressTypeID]
    WHERE
        al.[EntityID] = (
            SELECT [ID] FROM [__mj].[Entity]
            WHERE [Name] = 'MJ_BizApps_Common: Organizations'
        )
        AND al.[RecordID] = CAST(g.[ID] AS NVARCHAR(700))
        AND al.[IsPrimary] = 1
) AS pa

OUTER APPLY (
    SELECT TOP 1 cm.[Value]
    FROM [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE cm.[OrganizationID] = g.[ID]
      AND cm.[ContactTypeID] = (
          SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
          WHERE [Name] = 'Email'
      )
      AND cm.[IsPrimary] = 1
) AS cm_email

OUTER APPLY (
    SELECT TOP 1 cm.[Value]
    FROM [${flyway:defaultSchema}].[ContactMethod] AS cm
    WHERE cm.[OrganizationID] = g.[ID]
      AND cm.[ContactTypeID] = (
          SELECT [ID] FROM [${flyway:defaultSchema}].[ContactType]
          WHERE [Name] = 'Mobile Phone'
      )
      AND cm.[IsPrimary] = 1
) AS cm_phone;
GO

-- -----------------------------------------------------------------------------
-- Organizations directory sort index
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Organization_Name'
      AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Organization]')
)
    CREATE INDEX IX_Organization_Name
        ON [${flyway:defaultSchema}].[Organization] (Name) INCLUDE (Status);
GO
