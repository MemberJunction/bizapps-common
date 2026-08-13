-- =============================================================================
-- Layered base views for People and Organizations — PART 2 of 2 (the wrappers)
-- =============================================================================
--
-- Pairs with V202608132239, which flips both entities to layered base views and carries
-- the CodeGen output that CREATES the inner views this file selects from. Run that first;
-- timestamp ordering guarantees it.
--
-- WHAT WAS BROKEN. The Person and Organization forms render a "Primary Address" panel
-- bound to PrimaryAddressLine1 / City / State / PostalCode / Country / Type. Those
-- columns only ever existed on `vwPeopleExtended` / `vwOrganizationsExtended` — separate
-- hand-written views whose migration now lives in archive/ and which exist in no current
-- database. So every field in the panel named a column that does not exist, the fields
-- were absent from entity metadata, and the panel rendered completely empty.
--
-- WHY LAYERED RATHER THAN RESTORING THE OLD VIEWS. The archived views were
-- `BaseViewGenerated = 0` with no inner view, so they had to restate the whole
-- CodeGen-generated FK-denormalisation block. That restated half is pure liability: a
-- foreign key added later silently loses its display column, because nothing regenerates
-- the join and the column is ABSENT rather than wrong. Layering keeps the mechanical half
-- generating forever (`vwPeopleGenerated` / `vwOrganizationsGenerated`) and leaves this
-- file owning only what CodeGen cannot produce.
--
-- WHY THIS IS A SEPARATE FILE. These wrappers SELECT from the inner views. SQL Server has
-- no deferred name resolution for views — creating one over a missing object fails
-- outright — so the wrappers cannot live in the same file as, or before, the CodeGen
-- section that creates the inner views. Splitting them is also what makes a FRESH INSTALL
-- work: migrations alone produce the finished shape, with no dependency on the host
-- running CodeGen first (the Open App installer does not run it).
--
-- NO CODEGEN SECTION HERE. The EntityField rows for the columns below ship in PART 1's
-- CodeGen output. Nothing in this file needs regenerating, which is why it stays pure
-- hand-written SQL.
--
-- BUG CARRIED OVER FROM THE ARCHIVED VIEWS — DO NOT REINTRODUCE. Those views resolved the
-- polymorphic AddressLink with `WHERE [Name] = 'MJ.BizApps.Common: People'` — DOTTED. The
-- authoritative prefix is UNDERSCORED (`MJ_BizApps_Common: `, per this repo's own
-- metadata/schema-info/.schema-info.json). The dotted subquery returns NULL, `al.EntityID
-- = NULL` matches nothing, and every primary-address column comes back NULL — a silent
-- failure that looks exactly like "this person has no primary address". The same
-- dots-vs-underscores mistake broke ORDER CONFIRM in bizapps-orders and the address editor
-- in this repo. Fixed here.
--
-- Both wrappers expose a SUPERSET of what the CodeGen base views expose; no column is lost.
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
    emp_rel.Title       AS [CurrentJobTitle]

FROM
    [${flyway:defaultSchema}].[vwPeopleGenerated] AS g

LEFT OUTER JOIN
    [${flyway:defaultSchema}].[AddressLink] AS al
  ON
    al.[RecordID] = CAST(g.[ID] AS NVARCHAR(MAX))
    AND al.[EntityID] = (
        SELECT [ID] FROM [__mj].[Entity]
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

    addr.Line1          AS [PrimaryAddressLine1],
    addr.Line2          AS [PrimaryAddressLine2],
    addr.City           AS [PrimaryAddressCity],
    addr.StateProvince  AS [PrimaryAddressState],
    addr.PostalCode     AS [PrimaryAddressPostalCode],
    addr.Country        AS [PrimaryAddressCountry],
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
    al.[RecordID] = CAST(g.[ID] AS NVARCHAR(MAX))
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
