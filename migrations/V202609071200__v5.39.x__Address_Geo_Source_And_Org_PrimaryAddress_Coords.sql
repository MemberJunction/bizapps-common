-- Address is the geo WRITE source (native lat/lng). Person/Org are DISPLAY only
-- (virtual PrimaryAddress* / maps / distance). GeoCodeSyncService must not run
-- on Person/Org because those Geo* fields are virtual.
--
-- 1) Addresses: SupportsGeoCoding = 1; retag Latitude/Longitude Geo → GeoLatitude/GeoLongitude
--    so maps and CodeGen native-alias path see them.
-- 2) Organizations layered view: bubble addr.Latitude/Longitude as PrimaryAddressLatitude/Longitude
--    (People already do this in V202608132240). Tag the new virtuals GeoLatitude/GeoLongitude.

DECLARE @AddressEntityID UNIQUEIDENTIFIER = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E';
DECLARE @OrgEntityID UNIQUEIDENTIFIER = 'C70448F9-9792-41D7-A82C-784B66429D54';

UPDATE [${mjSchema}].[Entity]
SET [SupportsGeoCoding] = 1
WHERE [ID] = @AddressEntityID;

UPDATE [${mjSchema}].[EntityField]
SET [ExtendedType] = 'GeoLatitude'
WHERE [ID] = '66D63980-B9B5-47A0-BA8B-6B55977CB60C'; -- Addresses.Latitude

UPDATE [${mjSchema}].[EntityField]
SET [ExtendedType] = 'GeoLongitude'
WHERE [ID] = 'B03F710E-9199-4986-90BF-3ECE5037D79A'; -- Addresses.Longitude
GO

IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwOrganizations];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwOrganizations]
AS
SELECT
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

GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [public];
GO

DECLARE @OrgEntityID UNIQUEIDENTIFIER = 'C70448F9-9792-41D7-A82C-784B66429D54';

-- Make room after PrimaryAddressCountry (30) for lat/lng before Type (31).
UPDATE [${mjSchema}].[EntityField]
SET [Sequence] = [Sequence] + 2
WHERE [EntityID] = @OrgEntityID
  AND [Sequence] >= 31;

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'C8A1B2D3-4E5F-6789-ABCD-0123456789A1' OR (EntityID = @OrgEntityID AND Name = 'PrimaryAddressLatitude'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, ExtendedType, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('C8A1B2D3-4E5F-6789-ABCD-0123456789A1', @OrgEntityID, 31, 'PrimaryAddressLatitude', 'Primary Address Latitude', 'decimal', 5, 9, 6, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'GeoLatitude', 'Search', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'C8A1B2D3-4E5F-6789-ABCD-0123456789A2' OR (EntityID = @OrgEntityID AND Name = 'PrimaryAddressLongitude'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, ExtendedType, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('C8A1B2D3-4E5F-6789-ABCD-0123456789A2', @OrgEntityID, 32, 'PrimaryAddressLongitude', 'Primary Address Longitude', 'decimal', 5, 9, 6, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'GeoLongitude', 'Search', GETUTCDATE(), GETUTCDATE());
GO
