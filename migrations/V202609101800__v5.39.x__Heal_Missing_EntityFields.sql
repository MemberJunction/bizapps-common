-- =============================================================================
-- Forward heal: Re-register missing EntityField rows deleted by historical prunes
-- or omitted during initial schema creation.
--
-- See plans/entityfield-prune-replay-defect.md.
--
-- Heals 4 fields across 3 entities:
-- 1. MJ_BizApps_Common: Addresses (61B5C6FB-7317-46D1-8E05-F669B7BC6F3E)
--    __mj_Latitude and __mj_Longitude: computed columns in vwAddresses that lacked
--    EntityField registrations.
-- 2. MJ_BizApps_Common: Activity Files (232C27E0-0AAC-450B-B902-251EF20A2802)
--    Activity: related entity name virtual from ActivityID, added in V202608261015
--    and deleted by unscoped spDeleteUnneededEntityFields in V202609051800.
-- 3. MJ_BizApps_Common: Activity Links (9C48DF77-E4A1-4ADB-AABF-916F5798B894)
--    Activity: related entity name virtual from ActivityID, added in V202608261015
--    and deleted by unscoped spDeleteUnneededEntityFields in V202609051800.
--
-- Idempotent, hardcoded UUIDs, apply-time MAX(Sequence)+1.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. MJ_BizApps_Common: Addresses (__mj_Latitude, __mj_Longitude)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
    WHERE ID = '7b94ad01-7880-4fae-97d8-db0e934c3f5f'
       OR (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = '__mj_Latitude')
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Type], [Length], [Precision], [Scale], [AllowsNull],
        [AutoIncrement], [AllowUpdateAPI], [IsVirtual], [IsComputed],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [ExtendedType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        '7b94ad01-7880-4fae-97d8-db0e934c3f5f',
        '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E',
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'),
        '__mj_Latitude', '__mj_Latitude',
        'decimal', 5, 9, 6, 1,
        0, 0, 1, 0,
        0, 0, 0,
        0, 0, 0, 'Search',
        'GeoLatitude',
        GETUTCDATE(), GETUTCDATE()
    );
END;
ELSE
BEGIN
    UPDATE [${mjSchema}].[EntityField]
    SET [ExtendedType] = 'GeoLatitude', [__mj_UpdatedAt] = GETUTCDATE()
    WHERE [EntityID] = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'
      AND [Name] = '__mj_Latitude'
      AND ([ExtendedType] IS NULL OR [ExtendedType] <> 'GeoLatitude');
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
    WHERE ID = '7b94ad02-7880-4fae-97d8-db0e934c3f5f'
       OR (EntityID = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E' AND Name = '__mj_Longitude')
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Type], [Length], [Precision], [Scale], [AllowsNull],
        [AutoIncrement], [AllowUpdateAPI], [IsVirtual], [IsComputed],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [ExtendedType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        '7b94ad02-7880-4fae-97d8-db0e934c3f5f',
        '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E',
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'),
        '__mj_Longitude', '__mj_Longitude',
        'decimal', 5, 9, 6, 1,
        0, 0, 1, 0,
        0, 0, 0,
        0, 0, 0, 'Search',
        'GeoLongitude',
        GETUTCDATE(), GETUTCDATE()
    );
END;
ELSE
BEGIN
    UPDATE [${mjSchema}].[EntityField]
    SET [ExtendedType] = 'GeoLongitude', [__mj_UpdatedAt] = GETUTCDATE()
    WHERE [EntityID] = '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E'
      AND [Name] = '__mj_Longitude'
      AND ([ExtendedType] IS NULL OR [ExtendedType] <> 'GeoLongitude');
END;
GO

-- -----------------------------------------------------------------------------
-- 2. MJ_BizApps_Common: Activity Files (Activity)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
    WHERE ID = '8f910bcc-a121-481b-9ff0-ae33e5bdbb87'
       OR (EntityID = '232C27E0-0AAC-450B-B902-251EF20A2802' AND Name = 'Activity')
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Type], [Length], [Precision], [Scale], [AllowsNull],
        [AutoIncrement], [AllowUpdateAPI], [IsVirtual], [IsComputed],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        '8f910bcc-a121-481b-9ff0-ae33e5bdbb87',
        '232C27E0-0AAC-450B-B902-251EF20A2802',
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '232C27E0-0AAC-450B-B902-251EF20A2802'),
        'Activity', 'Activity',
        'nvarchar', 1000, 0, 0, 0,
        0, 0, 1, 0,
        0, 0, 0,
        0, 0, 0, 'Search',
        GETUTCDATE(), GETUTCDATE()
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 3. MJ_BizApps_Common: Activity Links (Activity)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM [${mjSchema}].[EntityField]
    WHERE ID = '99ee4347-a71c-4687-ab14-ece54ccbbdcd'
       OR (EntityID = '9C48DF77-E4A1-4ADB-AABF-916F5798B894' AND Name = 'Activity')
)
BEGIN
    INSERT INTO [${mjSchema}].[EntityField] (
        [ID], [EntityID], [Sequence], [Name], [DisplayName],
        [Type], [Length], [Precision], [Scale], [AllowsNull],
        [AutoIncrement], [AllowUpdateAPI], [IsVirtual], [IsComputed],
        [IsNameField], [IncludeInUserSearchAPI], [IncludeRelatedEntityNameFieldInBaseView],
        [DefaultInView], [IsPrimaryKey], [IsUnique], [RelatedEntityDisplayType],
        [__mj_CreatedAt], [__mj_UpdatedAt]
    ) VALUES (
        '99ee4347-a71c-4687-ab14-ece54ccbbdcd',
        '9C48DF77-E4A1-4ADB-AABF-916F5798B894',
        (SELECT COALESCE(MAX([Sequence]), 0) + 1 FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '9C48DF77-E4A1-4ADB-AABF-916F5798B894'),
        'Activity', 'Activity',
        'nvarchar', 1000, 0, 0, 0,
        0, 0, 1, 0,
        0, 0, 0,
        0, 0, 0, 'Search',
        GETUTCDATE(), GETUTCDATE()
    );
END;
GO

-- -----------------------------------------------------------------------------
-- Update entity timestamps
-- -----------------------------------------------------------------------------
UPDATE [${mjSchema}].[Entity]
SET [__mj_UpdatedAt] = GETUTCDATE()
WHERE [ID] IN (
    '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', -- Addresses
    '232C27E0-0AAC-450B-B902-251EF20A2802', -- Activity Files
    '9C48DF77-E4A1-4ADB-AABF-916F5798B894'  -- Activity Links
);
GO
