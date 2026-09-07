-- =============================================================================
-- Migration: V202609071200__v5.39.x__Address_Geo_Source_And_Org_PrimaryAddress_Coords.sql
-- Description: Address is the geo WRITE source (native lat/lng aliased as __mj_Latitude).
--              Organizations/People layered views bubble primary Address coords as
--              PrimaryAddressLatitude/Longitude and __mj_Latitude/__mj_Longitude.
--
--              Entity metadata (SupportsGeoCoding, ExtendedType pins) lives in
--              metadata/entities/.entities.json and is applied by `mj sync push`.
--              Do NOT UPDATE Entity/EntityField SupportsGeoCoding or ExtendedType here.
--
--              Authoring: overlay views on DB → mj sync push metadata/entities →
--              local `mj codegen --skipfiles` (includeSchemas Common) → fold emit below.
-- =============================================================================

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
    addr.Latitude       AS [__mj_Latitude],
    addr.Longitude      AS [__mj_Longitude],
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
    addr.Latitude       AS [PrimaryAddressLatitude],
    addr.Longitude      AS [PrimaryAddressLongitude],
    addr.Latitude       AS [__mj_Latitude],
    addr.Longitude      AS [__mj_Longitude],
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
GO



















































/**************************************************************************************************
 **************************************************************************************************
 **                                                                                              **
 **                 CODEGEN OUTPUT — Address native geo aliases + Org PrimaryAddress coords     **
 **                                                                                              **
 **  Everything below this banner is generated by local `mj codegen --skipfiles` AFTER           **
 **  metadata/entities/.entities.json was pushed (SupportsGeoCoding + GeoLatitude/GeoLongitude)  **
 **  and the layered overlays above were applied. DO NOT hand-edit below this line.              **
 **                                                                                              **
 **  Source: SQL Scripts/generated/__mj_BizAppsCommon/vwAddresses.view.generated.sql             **
 **          plus EntityField rows CodeGen registered for vwOrganizations PrimaryAddress* coords.**
 **                                                                                              **
 **************************************************************************************************
 **************************************************************************************************/

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Addresses
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Address
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwAddresses]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwAddresses];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwAddresses]
AS
SELECT
    a.*,
    [a].[Latitude] AS [__mj_Latitude],
    [a].[Longitude] AS [__mj_Longitude]
FROM
    [${flyway:defaultSchema}].[Address] AS a
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwAddresses] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
GO

/* EntityField rows CodeGen registered from the layered vwOrganizations columns.
   Sequence bump makes room after PrimaryAddressCountry (30). Idempotent. */
DECLARE @OrgEntityID UNIQUEIDENTIFIER = 'C70448F9-9792-41D7-A82C-784B66429D54';

UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = [Sequence] + 2
WHERE [EntityID] = @OrgEntityID
  AND [Sequence] >= 31
  AND [Name] NOT IN ('PrimaryAddressLatitude', 'PrimaryAddressLongitude');

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0559B852-FDB4-4231-9053-CB75E60E93F4' OR (EntityID = @OrgEntityID AND Name = 'PrimaryAddressLatitude'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, ExtendedType, AutoUpdateExtendedType, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('0559B852-FDB4-4231-9053-CB75E60E93F4', @OrgEntityID, 31, 'PrimaryAddressLatitude', 'Latitude', 'decimal', 5, 9, 6, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'GeoLatitude', 0, 'Search', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '9838E6B2-AB89-4D38-A8AF-512AC28B5CC7' OR (EntityID = @OrgEntityID AND Name = 'PrimaryAddressLongitude'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, ExtendedType, AutoUpdateExtendedType, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('9838E6B2-AB89-4D38-A8AF-512AC28B5CC7', @OrgEntityID, 32, 'PrimaryAddressLongitude', 'Longitude', 'decimal', 5, 9, 6, 1, 0, 0, 1, 0, 0, 0, 0, 0, 'GeoLongitude', 0, 'Search', GETUTCDATE(), GETUTCDATE());
GO
