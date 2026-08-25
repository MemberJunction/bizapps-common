-- =============================================================================
-- Scoped CodeGen emit for __mj_BizAppsCommon (mj codegen --skipfiles with
-- includeSchemas). Inspected: paired DROP+CREATE of common views; Activities
-- EntityField.ID restored (fixes CONCAT() save-capture); vwOrganizationsGenerated
-- keeps RootParentID / GetHierarchyMeta. Joined-DB EntityField inserts for
-- Orders entities were stripped.
-- Source: migrations/codegen/CodeGen_Run_2026-08-25_21-03-04.sql
-- =============================================================================

/* SQL text to update existing entities from schema */
EXEC [${mjSchema}].[spUpdateExistingEntitiesFromSchema] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys';

/* SQL text to insert 52 new entity field(s) */


      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'a77e31c4-88df-4a47-8d5e-66d9d772027a' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'a77e31c4-88df-4a47-8d5e-66d9d772027a',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 1,
            'ID',
            'ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            'newsequentialid()',
            0,
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            1,
            0,
            0,
            1,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7d436256-f1ba-4c03-8f90-f368e1ccaf0e' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'StartedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '7d436256-f1ba-4c03-8f90-f368e1ccaf0e',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 3,
            'StartedAt',
            'Started At',
            'Sort key for every timeline. Instant events use the date/time of the event.',
            'datetimeoffset',
            10,
            34,
            7,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '68ad9d59-4f16-4e52-a13a-93e2664bfeff' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'EndedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '68ad9d59-4f16-4e52-a13a-93e2664bfeff',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 4,
            'EndedAt',
            'Ended At',
            'End of a meeting/call. Leave null for a point-in-time log. Must be >= StartedAt when set. Duration is derived; do not store it.',
            'datetimeoffset',
            10,
            34,
            7,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '0c5459b1-2a7c-4b61-bb47-66f11e8da353' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'Title')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '0c5459b1-2a7c-4b61-bb47-66f11e8da353',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 5,
            'Title',
            'Title',
            'Subject / one-line card title (e.g. Called Jane about renewal).',
            'nvarchar',
            1000,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '64dd388e-5094-417d-8f4b-ea5de773d736' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'Status')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '64dd388e-5094-417d-8f4b-ea5de773d736',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 8,
            'Status',
            'Status',
            'Logged (default for a past event), Scheduled, Completed, Cancelled, or Failed.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Logged',
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f143d296-772a-4e87-81ee-7d542c5ae6d0' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'Outcome')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'f143d296-772a-4e87-81ee-7d542c5ae6d0',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 9,
            'Outcome',
            'Outcome',
            'Optional disposition: Connected, LeftVoicemail, NoAnswer, NoShow, Bounced, Interested, NotInterested. A filter, not a type.',
            'nvarchar',
            80,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '36846e42-d608-46b0-b914-63b113bddb48' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'Visibility')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '36846e42-d608-46b0-b914-63b113bddb48',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 10,
            'Visibility',
            'Visibility',
            'Internal (anyone who can read a Regarding record) or Private (LoggedByUserID only, until a PermissionEngine domain exists). Manual default is Internal; synced mail should default Private in the engine.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Internal',
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '59ed2435-0a40-48df-b907-8ed46bde7594' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'Source')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '59ed2435-0a40-48df-b907-8ed46bde7594',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 11,
            'Source',
            'Source',
            'How the row was written: Manual, System, or Integration.',
            'nvarchar',
            40,
            0,
            0,
            0,
            'Manual',
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd52954ad-1668-4d93-8eb5-0a9430e9dd46' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'SourceSystem')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'd52954ad-1668-4d93-8eb5-0a9430e9dd46',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 12,
            'SourceSystem',
            'Source System',
            'Provider name for idempotent sync (Microsoft365, Gmail, Zoom). Required when ExternalID is set.',
            'nvarchar',
            160,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '1dd06bda-9a1a-499e-921a-75f7421e8886' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ExternalID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '1dd06bda-9a1a-499e-921a-75f7421e8886',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 13,
            'ExternalID',
            'External ID',
            'Provider message/event id. Unique with SourceSystem where set — never dedup by subject.',
            'nvarchar',
            800,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            1,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '5387bcae-7cf0-417a-9a90-00a724980cd8' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ExternalThreadID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '5387bcae-7cf0-417a-9a90-00a724980cd8',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 14,
            'ExternalThreadID',
            'External Thread ID',
            'Email or calendar thread id used to group replies.',
            'nvarchar',
            800,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e9908ffa-72f7-4f3c-99b1-18697cfa92a2' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'LoggedByUserID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'e9908ffa-72f7-4f3c-99b1-18697cfa92a2',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 16,
            'LoggedByUserID',
            'Logged By User ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            0,
            NULL,
            0,
            1,
            0,
            0,
            'E1238F34-2837-EF11-86D4-6045BDEE16E6',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'be249655-29f6-4b9f-9c65-b75818f1d943' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'Location')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'be249655-29f6-4b9f-9c65-b75818f1d943',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 17,
            'Location',
            'Location',
            'Meeting place as text. Optional AddressID is the structured location.',
            'nvarchar',
            1000,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4d848bc2-b12b-4ecc-a5ac-11519b3962c3' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'AddressID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '4d848bc2-b12b-4ecc-a5ac-11519b3962c3',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 18,
            'AddressID',
            'Address ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            NULL,
            0,
            1,
            0,
            0,
            '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E',
            'ID',
            0,
            0,
            1,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '929ab16d-299d-4942-b2a9-b907c0273122' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = '__mj_CreatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '929ab16d-299d-4942-b2a9-b907c0273122',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 21,
            '__mj_CreatedAt',
            'Created At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c70a8646-f64d-40a8-ba96-6dac95f980d0' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = '__mj_UpdatedAt')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'c70a8646-f64d-40a8-ba96-6dac95f980d0',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 22,
            '__mj_UpdatedAt',
            'Updated At',
            NULL,
            'datetimeoffset',
            10,
            34,
            7,
            0,
            'getutcdate()',
            0,
            0,
            0,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'afac551b-ea9a-4bdf-9f54-bb7b47e3e79f' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'LoggedByUser')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'afac551b-ea9a-4bdf-9f54-bb7b47e3e79f',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 24,
            'LoggedByUser',
            'Logged By User',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            0,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6060d1ad-ed2c-4465-b52a-df4c07783cf2' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'Address')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '6060d1ad-ed2c-4465-b52a-df4c07783cf2',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 25,
            'Address',
            'Address',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;


      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd70b6ee4-51d2-40f5-a8fa-7ecd8f1e6477' OR (EntityID = '21B78371-132C-4507-AED8-D44E366468F2' AND Name = 'ActivityType')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'd70b6ee4-51d2-40f5-a8fa-7ecd8f1e6477',
            '21B78371-132C-4507-AED8-D44E366468F2', -- Entity: MJ_BizApps_Common: Activity Sync Rules
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '21B78371-132C-4507-AED8-D44E366468F2') + 16,
            'ActivityType',
            'Activity Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;


/* SQL text to update existing entity fields from schema */
EXEC [${mjSchema}].[spUpdateExistingEntityFieldsFromSchema] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys';

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].[spSetDefaultColumnWidthWhereNeeded] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys';

/* SQL text to insert entity field value with ID b3bbf531-de64-4de8-bccc-9006c967e7e4 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b3bbf531-de64-4de8-bccc-9006c967e7e4', 'F73D370A-4708-4E90-AF7F-6194848DF918', 1, 'Generic', 'Generic', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 784b01d2-ba32-4036-8955-6da7decfef17 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('784b01d2-ba32-4036-8955-6da7decfef17', 'F73D370A-4708-4E90-AF7F-6194848DF918', 2, 'Gmail', 'Gmail', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d4311757-4335-43d4-9b43-22957bcc5e54 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d4311757-4335-43d4-9b43-22957bcc5e54', 'F73D370A-4708-4E90-AF7F-6194848DF918', 3, 'Microsoft365', 'Microsoft365', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 387db63f-ef88-462d-9d4c-dabac48bae0e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('387db63f-ef88-462d-9d4c-dabac48bae0e', 'F73D370A-4708-4E90-AF7F-6194848DF918', 4, 'Zoom', 'Zoom', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID F73D370A-4708-4E90-AF7F-6194848DF918 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='F73D370A-4708-4E90-AF7F-6194848DF918';

/* SQL text to insert entity field value with ID 39a427c3-e0a2-490f-b847-a777172250bd */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('39a427c3-e0a2-490f-b847-a777172250bd', 'C66A81AA-25FF-461B-8C8D-F8E99382F5A0', 1, 'Active', 'Active', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID acc3df3f-8ca1-4644-9253-3d9ae2843318 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('acc3df3f-8ca1-4644-9253-3d9ae2843318', 'C66A81AA-25FF-461B-8C8D-F8E99382F5A0', 2, 'Disabled', 'Disabled', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID ee12ddf0-07bc-4362-ab54-286ddfc7a58a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('ee12ddf0-07bc-4362-ab54-286ddfc7a58a', 'C66A81AA-25FF-461B-8C8D-F8E99382F5A0', 3, 'Error', 'Error', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 53cbbe3d-233a-49ac-98c3-31334c93a57a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('53cbbe3d-233a-49ac-98c3-31334c93a57a', 'C66A81AA-25FF-461B-8C8D-F8E99382F5A0', 4, 'Paused', 'Paused', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID C66A81AA-25FF-461B-8C8D-F8E99382F5A0 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='C66A81AA-25FF-461B-8C8D-F8E99382F5A0';

/* SQL text to insert entity field value with ID 45818c5c-358b-41b3-9b8d-1f1a3540a783 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('45818c5c-358b-41b3-9b8d-1f1a3540a783', '1F569493-170C-42FB-BD80-821BEB6C75ED', 1, 'Bidirectional', 'Bidirectional', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 09dfe203-c804-4937-ab89-97f8a142fe4e */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('09dfe203-c804-4937-ab89-97f8a142fe4e', '1F569493-170C-42FB-BD80-821BEB6C75ED', 2, 'Inbound', 'Inbound', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID c3eb3b62-2b90-4c9a-9bf7-5180d9d9ced5 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('c3eb3b62-2b90-4c9a-9bf7-5180d9d9ced5', '1F569493-170C-42FB-BD80-821BEB6C75ED', 3, 'Outbound', 'Outbound', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 1F569493-170C-42FB-BD80-821BEB6C75ED */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='1F569493-170C-42FB-BD80-821BEB6C75ED';

/* SQL text to insert entity field value with ID a0381323-d458-4e44-a0cd-928a67972b78 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('a0381323-d458-4e44-a0cd-928a67972b78', '55B36A7F-5704-4F3E-8271-FF127FF080E0', 1, 'Inbound', 'Inbound', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID ac00a083-2bfc-49a6-901b-73a345eda5bd */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('ac00a083-2bfc-49a6-901b-73a345eda5bd', '55B36A7F-5704-4F3E-8271-FF127FF080E0', 2, 'Internal', 'Internal', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 531e25cc-681a-4e28-ae3e-e43d574495a6 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('531e25cc-681a-4e28-ae3e-e43d574495a6', '55B36A7F-5704-4F3E-8271-FF127FF080E0', 3, 'Outbound', 'Outbound', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 55B36A7F-5704-4F3E-8271-FF127FF080E0 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='55B36A7F-5704-4F3E-8271-FF127FF080E0';

/* SQL text to insert entity field value with ID 91815dd6-869a-4f6e-a24b-7d404af16690 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('91815dd6-869a-4f6e-a24b-7d404af16690', '64DD388E-5094-417D-8F4B-EA5DE773D736', 1, 'Cancelled', 'Cancelled', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 5b1a9497-1fa3-4eaf-8fff-b00e763f9598 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('5b1a9497-1fa3-4eaf-8fff-b00e763f9598', '64DD388E-5094-417D-8F4B-EA5DE773D736', 2, 'Completed', 'Completed', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 5a4b218b-9be7-4716-94c4-5cbc4bf75b12 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('5a4b218b-9be7-4716-94c4-5cbc4bf75b12', '64DD388E-5094-417D-8F4B-EA5DE773D736', 3, 'Failed', 'Failed', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 000f5ae1-f9fe-4a59-80dd-7134c829a023 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('000f5ae1-f9fe-4a59-80dd-7134c829a023', '64DD388E-5094-417D-8F4B-EA5DE773D736', 4, 'Logged', 'Logged', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 268b9db8-d20e-4ffd-81e7-52dcfc91a462 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('268b9db8-d20e-4ffd-81e7-52dcfc91a462', '64DD388E-5094-417D-8F4B-EA5DE773D736', 5, 'Scheduled', 'Scheduled', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 64DD388E-5094-417D-8F4B-EA5DE773D736 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='64DD388E-5094-417D-8F4B-EA5DE773D736';

/* SQL text to insert entity field value with ID d531fa66-ea94-4946-b4e8-10c7ed4bbeb2 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d531fa66-ea94-4946-b4e8-10c7ed4bbeb2', '36846E42-D608-46B0-B914-63B113BDDB48', 1, 'Internal', 'Internal', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d4e764b6-f4e4-4892-b213-9e6ecda82599 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d4e764b6-f4e4-4892-b213-9e6ecda82599', '36846E42-D608-46B0-B914-63B113BDDB48', 2, 'Private', 'Private', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 36846E42-D608-46B0-B914-63B113BDDB48 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='36846E42-D608-46B0-B914-63B113BDDB48';

/* SQL text to insert entity field value with ID 94c238bd-dcc1-40b9-8170-52e121beaaca */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('94c238bd-dcc1-40b9-8170-52e121beaaca', '59ED2435-0A40-48DF-B907-8ED46BDE7594', 1, 'Integration', 'Integration', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID fe036b1b-71af-4359-b2f9-f4013c6359d9 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('fe036b1b-71af-4359-b2f9-f4013c6359d9', '59ED2435-0A40-48DF-B907-8ED46BDE7594', 2, 'Manual', 'Manual', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 38c77831-e0fa-4ca9-824c-b35853e04a83 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('38c77831-e0fa-4ca9-824c-b35853e04a83', '59ED2435-0A40-48DF-B907-8ED46BDE7594', 3, 'System', 'System', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 59ED2435-0A40-48DF-B907-8ED46BDE7594 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='59ED2435-0A40-48DF-B907-8ED46BDE7594';

/* SQL text to insert entity field value with ID b40c6d83-f62d-4446-8ff5-7af1b490bef6 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b40c6d83-f62d-4446-8ff5-7af1b490bef6', 'F143D296-772A-4E87-81EE-7D542C5AE6D0', 1, 'Bounced', 'Bounced', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID bd3e47b2-533c-4593-9b96-d28dc1e14063 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('bd3e47b2-533c-4593-9b96-d28dc1e14063', 'F143D296-772A-4E87-81EE-7D542C5AE6D0', 2, 'Connected', 'Connected', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 457de93e-f051-4908-9143-cb9ae534542b */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('457de93e-f051-4908-9143-cb9ae534542b', 'F143D296-772A-4E87-81EE-7D542C5AE6D0', 3, 'Interested', 'Interested', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID b3c367ed-0f5c-4aec-90c7-932ae9aa33c8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b3c367ed-0f5c-4aec-90c7-932ae9aa33c8', 'F143D296-772A-4E87-81EE-7D542C5AE6D0', 4, 'LeftVoicemail', 'LeftVoicemail', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d136b35b-fce2-497d-b835-66a35a91c76a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d136b35b-fce2-497d-b835-66a35a91c76a', 'F143D296-772A-4E87-81EE-7D542C5AE6D0', 5, 'NoAnswer', 'NoAnswer', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d411e5fe-e61f-486f-8f82-04cd0d825085 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d411e5fe-e61f-486f-8f82-04cd0d825085', 'F143D296-772A-4E87-81EE-7D542C5AE6D0', 6, 'NoShow', 'NoShow', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 19f1302b-2b67-4f4d-a359-ab9c3598e01c */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('19f1302b-2b67-4f4d-a359-ab9c3598e01c', 'F143D296-772A-4E87-81EE-7D542C5AE6D0', 7, 'NotInterested', 'NotInterested', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID F143D296-772A-4E87-81EE-7D542C5AE6D0 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='F143D296-772A-4E87-81EE-7D542C5AE6D0';

/* SQL text to insert entity field value with ID 0a26469f-2af2-4020-abeb-c39feef30b21 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('0a26469f-2af2-4020-abeb-c39feef30b21', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 1, 'Attendee', 'Attendee', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 09aa9b42-3dc8-44de-a6ed-02a4f7822b0a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('09aa9b42-3dc8-44de-a6ed-02a4f7822b0a', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 2, 'Bcc', 'Bcc', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 3cb151d6-8125-43f5-a640-ec48b2a06747 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('3cb151d6-8125-43f5-a640-ec48b2a06747', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 3, 'Cc', 'Cc', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID c9416130-7c84-4ff0-8efc-abf49fc5aa6a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('c9416130-7c84-4ff0-8efc-abf49fc5aa6a', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 4, 'From', 'From', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d4f740db-d800-42be-9c27-c6467791e574 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d4f740db-d800-42be-9c27-c6467791e574', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 5, 'LoggedFor', 'LoggedFor', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID cf5e65af-2173-4c61-9861-009c25ee70bb */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('cf5e65af-2173-4c61-9861-009c25ee70bb', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 6, 'Organizer', 'Organizer', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 8d833df8-1ed4-40dd-aa9f-7218dcf0a084 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('8d833df8-1ed4-40dd-aa9f-7218dcf0a084', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 7, 'Participant', 'Participant', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID b3e7aaf3-57e7-4ab8-bbd8-5e01aa11eaa6 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b3e7aaf3-57e7-4ab8-bbd8-5e01aa11eaa6', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 8, 'Regarding', 'Regarding', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID b269bd90-b785-4e41-9a9a-914d312642a8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('b269bd90-b785-4e41-9a9a-914d312642a8', 'FF3B032B-00DF-4B00-98C2-E83C4E634DF5', 9, 'To', 'To', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID FF3B032B-00DF-4B00-98C2-E83C4E634DF5 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='FF3B032B-00DF-4B00-98C2-E83C4E634DF5';

/* SQL text to insert entity field value with ID 6864a7c8-6296-497f-8665-829f8695d869 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('6864a7c8-6296-497f-8665-829f8695d869', '4C13D5F6-4517-474B-B7EB-4455553B741D', 1, 'Email', 'Email', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d424aef5-e5f5-41b3-a7ef-09ada9ac959b */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d424aef5-e5f5-41b3-a7ef-09ada9ac959b', '4C13D5F6-4517-474B-B7EB-4455553B741D', 2, 'ExternalUser', 'ExternalUser', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 48e34d25-800c-44f9-9734-ffdc12009a6f */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('48e34d25-800c-44f9-9734-ffdc12009a6f', '4C13D5F6-4517-474B-B7EB-4455553B741D', 3, 'Phone', 'Phone', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 4C13D5F6-4517-474B-B7EB-4455553B741D */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='4C13D5F6-4517-474B-B7EB-4455553B741D';

/* SQL text to insert entity field value with ID 2a6459ca-b896-4585-8395-5c6d4c27cc35 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('2a6459ca-b896-4585-8395-5c6d4c27cc35', '201F0A1C-B553-4C4F-AF83-A3BFB4979143', 1, 'Attachment', 'Attachment', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID e747bd15-b295-4494-9392-76da19be3150 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('e747bd15-b295-4494-9392-76da19be3150', '201F0A1C-B553-4C4F-AF83-A3BFB4979143', 2, 'Body', 'Body', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID fcf1b873-15b0-4597-b11a-06b337baa53a */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('fcf1b873-15b0-4597-b11a-06b337baa53a', '201F0A1C-B553-4C4F-AF83-A3BFB4979143', 3, 'Ics', 'Ics', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 201F0A1C-B553-4C4F-AF83-A3BFB4979143 */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='201F0A1C-B553-4C4F-AF83-A3BFB4979143';

/* SQL text to insert entity field value with ID 803445a0-9720-4777-8dba-79d0909c8a37 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('803445a0-9720-4777-8dba-79d0909c8a37', 'D4794101-7846-413E-8858-6EB0C756206F', 1, 'Exclude', 'Exclude', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID 1110a66a-8b08-48c0-bd63-74f5e19ddfe7 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('1110a66a-8b08-48c0-bd63-74f5e19ddfe7', 'D4794101-7846-413E-8858-6EB0C756206F', 2, 'Include', 'Include', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID D4794101-7846-413E-8858-6EB0C756206F */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='D4794101-7846-413E-8858-6EB0C756206F';

/* SQL text to insert entity field value with ID a98f6343-bcef-4eed-baa8-db66ede4ed59 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('a98f6343-bcef-4eed-baa8-db66ede4ed59', '082DF2CA-E47E-4FF3-969A-A6B8D090A39A', 1, 'Inbound', 'Inbound', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID d99f5ca7-a42d-472b-b250-614c2d415cc8 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('d99f5ca7-a42d-472b-b250-614c2d415cc8', '082DF2CA-E47E-4FF3-969A-A6B8D090A39A', 2, 'Internal', 'Internal', GETUTCDATE(), GETUTCDATE());

/* SQL text to insert entity field value with ID a5eb38cf-8f7b-4517-b4a0-981d4c448532 */
INSERT INTO [${mjSchema}].[EntityFieldValue]
                                       ([ID], [EntityFieldID], [Sequence], [Value], [Code], [__mj_CreatedAt], [__mj_UpdatedAt])
                                    VALUES
                                       ('a5eb38cf-8f7b-4517-b4a0-981d4c448532', '082DF2CA-E47E-4FF3-969A-A6B8D090A39A', 3, 'Outbound', 'Outbound', GETUTCDATE(), GETUTCDATE());

/* SQL text to update ValueListType for entity field ID 082DF2CA-E47E-4FF3-969A-A6B8D090A39A */
UPDATE [${mjSchema}].[EntityField] SET ValueListType='List' WHERE ID='082DF2CA-E47E-4FF3-969A-A6B8D090A39A';


/* Create Entity Relationship: MJ_BizApps_Common: Activities -> MJ_BizApps_Common: Activities (One To Many via ParentActivityID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'd107ada6-7936-4552-90aa-46769514c711'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('d107ada6-7936-4552-90aa-46769514c711', '72E55425-8822-4E70-A075-116219CA5A5D', '72E55425-8822-4E70-A075-116219CA5A5D', 'ParentActivityID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activities -> MJ_BizApps_Common: Activity Files (One To Many via ActivityID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '8ef06cc0-7dda-48a6-a21f-c4e77d3556c0'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('8ef06cc0-7dda-48a6-a21f-c4e77d3556c0', '72E55425-8822-4E70-A075-116219CA5A5D', '232C27E0-0AAC-450B-B902-251EF20A2802', 'ActivityID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activities -> MJ_BizApps_Common: Activity Links (One To Many via ActivityID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '3609b0ed-0e93-44f4-90e4-8b4cc4e4e9e9'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('3609b0ed-0e93-44f4-90e4-8b4cc4e4e9e9', '72E55425-8822-4E70-A075-116219CA5A5D', '9C48DF77-E4A1-4ADB-AABF-916F5798B894', 'ActivityID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Connections -> MJ_BizApps_Common: Activities (One To Many via ActivitySyncConnectionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '26a85a44-c969-4260-88c0-b882c6a8554f'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('26a85a44-c969-4260-88c0-b882c6a8554f', 'C22591BB-B33A-439C-9567-5494A7B71D8A', '72E55425-8822-4E70-A075-116219CA5A5D', 'ActivitySyncConnectionID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Sync Connections -> MJ_BizApps_Common: Activity Sync Rules (One To Many via ActivitySyncConnectionID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'b0b10252-170e-4d0d-a7ef-acf729f18ded'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('b0b10252-170e-4d0d-a7ef-acf729f18ded', 'C22591BB-B33A-439C-9567-5494A7B71D8A', '21B78371-132C-4507-AED8-D44E366468F2', 'ActivitySyncConnectionID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Entities -> MJ_BizApps_Common: Activity Links (One To Many via EntityID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '6e00d32e-5a86-4999-a7c3-4727b50cf13e'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('6e00d32e-5a86-4999-a7c3-4727b50cf13e', 'E0238F34-2837-EF11-86D4-6045BDEE16E6', '9C48DF77-E4A1-4ADB-AABF-916F5798B894', 'EntityID', 'One To Many', 1, 1, 86, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ: Users -> MJ_BizApps_Common: Activity Sync Connections (One To Many via OwnerUserID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'ed7dc265-4734-42d0-82e2-59c3358854fe'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('ed7dc265-4734-42d0-82e2-59c3358854fe', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', 'C22591BB-B33A-439C-9567-5494A7B71D8A', 'OwnerUserID', 'One To Many', 1, 1, 114, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ: Users -> MJ_BizApps_Common: Activities (One To Many via LoggedByUserID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '395d49c8-90dc-45d0-acab-c1bcd9dc4190'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('395d49c8-90dc-45d0-acab-c1bcd9dc4190', 'E1238F34-2837-EF11-86D4-6045BDEE16E6', '72E55425-8822-4E70-A075-116219CA5A5D', 'LoggedByUserID', 'One To Many', 1, 1, 115, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ: Files -> MJ_BizApps_Common: Activity Files (One To Many via FileID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = '078ce2c6-bc56-497d-9053-47ad1f3721e7'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('078ce2c6-bc56-497d-9053-47ad1f3721e7', '29248F34-2837-EF11-86D4-6045BDEE16E6', '232C27E0-0AAC-450B-B902-251EF20A2802', 'FileID', 'One To Many', 1, 1, 10, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Activity Types -> MJ_BizApps_Common: Activity Types (One To Many via ParentID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'fb8c1891-14cd-4eb1-9518-bc5875504b67'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('fb8c1891-14cd-4eb1-9518-bc5875504b67', '8B748643-85FF-4B07-B3B6-B12EC7A399E6', '8B748643-85FF-4B07-B3B6-B12EC7A399E6', 'ParentID', 'One To Many', 1, 1, 1, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Types -> MJ_BizApps_Common: Activities (One To Many via ActivityTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'e87f74fb-d7d9-41f3-8599-643acd06e4c9'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('e87f74fb-d7d9-41f3-8599-643acd06e4c9', '8B748643-85FF-4B07-B3B6-B12EC7A399E6', '72E55425-8822-4E70-A075-116219CA5A5D', 'ActivityTypeID', 'One To Many', 1, 1, 2, GETUTCDATE(), GETUTCDATE())
   END;
                    
/* Create Entity Relationship: MJ_BizApps_Common: Activity Types -> MJ_BizApps_Common: Activity Sync Rules (One To Many via ActivityTypeID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'b0ee93dc-8187-4493-90b0-df9ed4c5a5d6'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('b0ee93dc-8187-4493-90b0-df9ed4c5a5d6', '8B748643-85FF-4B07-B3B6-B12EC7A399E6', '21B78371-132C-4507-AED8-D44E366468F2', 'ActivityTypeID', 'One To Many', 1, 1, 3, GETUTCDATE(), GETUTCDATE())
   END;


/* Create Entity Relationship: MJ_BizApps_Common: Addresses -> MJ_BizApps_Common: Activities (One To Many via AddressID) */
   IF NOT EXISTS (
      SELECT 1 FROM [${mjSchema}].[EntityRelationship] WHERE [ID] = 'a84c4fb7-b289-48f2-b3dd-5d9afd24cc84'
   )
   BEGIN
      INSERT INTO [${mjSchema}].[EntityRelationship] ([ID], [EntityID], [RelatedEntityID], [RelatedEntityJoinField], [Type], [BundleInAPI], [DisplayInForm], [Sequence], [__mj_CreatedAt], [__mj_UpdatedAt])
                    VALUES ('a84c4fb7-b289-48f2-b3dd-5d9afd24cc84', '61B5C6FB-7317-46D1-8E05-F669B7BC6F3E', '72E55425-8822-4E70-A075-116219CA5A5D', 'AddressID', 'One To Many', 1, 1, 5, GETUTCDATE(), GETUTCDATE())
   END;

/* SQL text to sync schema info from database schemas */
EXEC [${mjSchema}].[spUpdateSchemaInfoFromDatabase] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys';

/* Index for Foreign Keys for Activity */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivityTypeID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_ActivityTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ActivityTypeID ON [${flyway:defaultSchema}].[Activity] ([ActivityTypeID]);

-- Index for foreign key ParentActivityID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_ParentActivityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ParentActivityID ON [${flyway:defaultSchema}].[Activity] ([ParentActivityID]);

-- Index for foreign key LoggedByUserID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_LoggedByUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_LoggedByUserID ON [${flyway:defaultSchema}].[Activity] ([LoggedByUserID]);

-- Index for foreign key AddressID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_AddressID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_AddressID ON [${flyway:defaultSchema}].[Activity] ([AddressID]);

-- Index for foreign key ActivitySyncConnectionID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_ActivitySyncConnectionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ActivitySyncConnectionID ON [${flyway:defaultSchema}].[Activity] ([ActivitySyncConnectionID]);

/* SQL text to update entity field related entity name field map for entity field ID 79A0584E-E51E-44ED-86C0-E10087BE3D70 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='79A0584E-E51E-44ED-86C0-E10087BE3D70', @RelatedEntityNameFieldMap='ActivityType';

/* SQL text to update entity field related entity name field map for entity field ID 509A0C21-FCB7-4D1F-BCB1-DBEF43BE23F3 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='509A0C21-FCB7-4D1F-BCB1-DBEF43BE23F3', @RelatedEntityNameFieldMap='File';

/* SQL text to update entity field related entity name field map for entity field ID 771D21DD-7AAB-42E3-BC00-F147B7767D99 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='771D21DD-7AAB-42E3-BC00-F147B7767D99', @RelatedEntityNameFieldMap='Entity';

/* SQL text to update entity field related entity name field map for entity field ID C875E212-006C-44F9-9A31-D19F78D5146B */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='C875E212-006C-44F9-9A31-D19F78D5146B', @RelatedEntityNameFieldMap='OwnerUser';

/* Index for Foreign Keys for ActivitySyncRule */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivitySyncConnectionID in table ActivitySyncRule
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivitySyncConnectionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRule]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivitySyncConnectionID ON [${flyway:defaultSchema}].[ActivitySyncRule] ([ActivitySyncConnectionID]);

-- Index for foreign key ActivityTypeID in table ActivitySyncRule
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivityTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[ActivitySyncRule]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_ActivitySyncRule_ActivityTypeID ON [${flyway:defaultSchema}].[ActivitySyncRule] ([ActivityTypeID]);

/* SQL text to update entity field related entity name field map for entity field ID 59023ECB-98AD-4950-B328-C1384AA89E32 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='59023ECB-98AD-4950-B328-C1384AA89E32', @RelatedEntityNameFieldMap='ActivitySyncConnection';

/* SQL text to update entity field related entity name field map for entity field ID E9908FFA-72F7-4F3C-99B1-18697CFA92A2 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='E9908FFA-72F7-4F3C-99B1-18697CFA92A2', @RelatedEntityNameFieldMap='LoggedByUser';

/* Base View SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: vwActivitySyncRules
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Sync Rules
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivitySyncRule
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivitySyncRules]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivitySyncRules];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivitySyncRules]
AS
SELECT
    a.*,
    mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[Name] AS [ActivitySyncConnection],
    mjBizAppsCommonActivityType_ActivityTypeID.[Name] AS [ActivityType]
FROM
    [${flyway:defaultSchema}].[ActivitySyncRule] AS a
INNER JOIN
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    [a].[ActivitySyncConnectionID] = mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivityType] AS mjBizAppsCommonActivityType_ActivityTypeID
  ON
    [a].[ActivityTypeID] = mjBizAppsCommonActivityType_ActivityTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRules] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: Permissions for vwActivitySyncRules
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivitySyncRules] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: spCreateActivitySyncRule
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivitySyncRule
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivitySyncRule]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRule];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivitySyncRule]
    @ID uniqueidentifier = NULL,
    @ActivitySyncConnectionID uniqueidentifier,
    @Name nvarchar(200),
    @IsEnabled bit = NULL,
    @Sequence int = NULL,
    @Action nvarchar(20) = NULL,
    @ActivityTypeID_Clear bit = 0,
    @ActivityTypeID uniqueidentifier = NULL,
    @Direction_Clear bit = 0,
    @Direction nvarchar(20) = NULL,
    @DateFrom_Clear bit = 0,
    @DateFrom datetimeoffset = NULL,
    @DateTo_Clear bit = 0,
    @DateTo datetimeoffset = NULL,
    @IncludeAttachments bit = NULL,
    @Filter_Clear bit = 0,
    @Filter nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRule]
            (
                [ID],
                [ActivitySyncConnectionID],
                [Name],
                [IsEnabled],
                [Sequence],
                [Action],
                [ActivityTypeID],
                [Direction],
                [DateFrom],
                [DateTo],
                [IncludeAttachments],
                [Filter]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivitySyncConnectionID,
                @Name,
                ISNULL(@IsEnabled, 1),
                ISNULL(@Sequence, 0),
                ISNULL(@Action, 'Include'),
                CASE WHEN @ActivityTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityTypeID, NULL) END,
                CASE WHEN @Direction_Clear = 1 THEN NULL ELSE ISNULL(@Direction, NULL) END,
                CASE WHEN @DateFrom_Clear = 1 THEN NULL ELSE ISNULL(@DateFrom, NULL) END,
                CASE WHEN @DateTo_Clear = 1 THEN NULL ELSE ISNULL(@DateTo, NULL) END,
                ISNULL(@IncludeAttachments, 0),
                CASE WHEN @Filter_Clear = 1 THEN NULL ELSE ISNULL(@Filter, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivitySyncRule]
            (
                [ActivitySyncConnectionID],
                [Name],
                [IsEnabled],
                [Sequence],
                [Action],
                [ActivityTypeID],
                [Direction],
                [DateFrom],
                [DateTo],
                [IncludeAttachments],
                [Filter]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivitySyncConnectionID,
                @Name,
                ISNULL(@IsEnabled, 1),
                ISNULL(@Sequence, 0),
                ISNULL(@Action, 'Include'),
                CASE WHEN @ActivityTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityTypeID, NULL) END,
                CASE WHEN @Direction_Clear = 1 THEN NULL ELSE ISNULL(@Direction, NULL) END,
                CASE WHEN @DateFrom_Clear = 1 THEN NULL ELSE ISNULL(@DateFrom, NULL) END,
                CASE WHEN @DateTo_Clear = 1 THEN NULL ELSE ISNULL(@DateTo, NULL) END,
                ISNULL(@IncludeAttachments, 0),
                CASE WHEN @Filter_Clear = 1 THEN NULL ELSE ISNULL(@Filter, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivitySyncRules] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Sync Rules */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: spUpdateActivitySyncRule
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivitySyncRule
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivitySyncRule]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRule];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivitySyncRule]
    @ID uniqueidentifier,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Name nvarchar(200) = NULL,
    @IsEnabled bit = NULL,
    @Sequence int = NULL,
    @Action nvarchar(20) = NULL,
    @ActivityTypeID_Clear bit = 0,
    @ActivityTypeID uniqueidentifier = NULL,
    @Direction_Clear bit = 0,
    @Direction nvarchar(20) = NULL,
    @DateFrom_Clear bit = 0,
    @DateFrom datetimeoffset = NULL,
    @DateTo_Clear bit = 0,
    @DateTo datetimeoffset = NULL,
    @IncludeAttachments bit = NULL,
    @Filter_Clear bit = 0,
    @Filter nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRule]
    SET
        [ActivitySyncConnectionID] = ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]),
        [Name] = ISNULL(@Name, [Name]),
        [IsEnabled] = ISNULL(@IsEnabled, [IsEnabled]),
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [Action] = ISNULL(@Action, [Action]),
        [ActivityTypeID] = CASE WHEN @ActivityTypeID_Clear = 1 THEN NULL ELSE ISNULL(@ActivityTypeID, [ActivityTypeID]) END,
        [Direction] = CASE WHEN @Direction_Clear = 1 THEN NULL ELSE ISNULL(@Direction, [Direction]) END,
        [DateFrom] = CASE WHEN @DateFrom_Clear = 1 THEN NULL ELSE ISNULL(@DateFrom, [DateFrom]) END,
        [DateTo] = CASE WHEN @DateTo_Clear = 1 THEN NULL ELSE ISNULL(@DateTo, [DateTo]) END,
        [IncludeAttachments] = ISNULL(@IncludeAttachments, [IncludeAttachments]),
        [Filter] = CASE WHEN @Filter_Clear = 1 THEN NULL ELSE ISNULL(@Filter, [Filter]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivitySyncRules] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivitySyncRules]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRule] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivitySyncRule table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivitySyncRule]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivitySyncRule];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivitySyncRule
ON [${flyway:defaultSchema}].[ActivitySyncRule]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivitySyncRule]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivitySyncRule] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Sync Rules */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Sync Rules */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Sync Rules
-- Item: spDeleteActivitySyncRule
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivitySyncRule
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivitySyncRule]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRule];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivitySyncRule]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivitySyncRule]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Sync Rules */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivitySyncRule] TO [cdp_Developer], [cdp_Integration];

/* SQL text to update entity field related entity name field map for entity field ID 4D848BC2-B12B-4ECC-A5AC-11519B3962C3 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='4D848BC2-B12B-4ECC-A5AC-11519B3962C3', @RelatedEntityNameFieldMap='Address';

/* Hierarchy Metadata Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetHierarchyMeta
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentActivityID],
            0 AS [Depth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentActivityID],
            c.[Depth] + 1 AS [Depth],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentActivityID]
        WHERE
            c.[Depth] < 100
    )
    SELECT TOP 1
        a.[ID] AS [RootID],
        (SELECT MAX([Depth]) FROM CTE_Ancestors) AS [Depth],
        (SELECT TOP 1 [Path] FROM CTE_Ancestors ORDER BY [Depth] DESC) AS [Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = @RecordID) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = @RecordID) AS [ChildCount]
    FROM
        CTE_Ancestors a
    WHERE
        a.[ParentActivityID] IS NULL OR @ParentID IS NULL
    ORDER BY
        a.[Depth] DESC
);
GO

/* Descendants Traversal Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetDescendants
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- DESCENDANTS FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetDescendants]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetDescendants];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetDescendants]
(
    @RootID uniqueidentifier,
    @MaxDepth INT = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Descendants AS (
        SELECT
            [ID],
            [ParentActivityID],
            0 AS [RelativeDepth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = @RootID

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentActivityID],
            p.[RelativeDepth] + 1 AS [RelativeDepth],
            CAST(p.[Path] + CAST(c.[ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity] c
        INNER JOIN
            CTE_Descendants p ON c.[ParentActivityID] = p.[ID]
        WHERE
            (@MaxDepth IS NULL OR p.[RelativeDepth] < @MaxDepth)
            AND p.[RelativeDepth] < 100
    )
    SELECT
        d.[ID] AS [ID],
        d.[RelativeDepth] AS [Depth],
        d.[Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = d.[ID]) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = d.[ID]) AS [ChildCount]
    FROM
        CTE_Descendants d
);
GO

/* Ancestors Traversal Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetAncestors
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ANCESTORS FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetAncestors]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetAncestors];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetAncestors]
(
    @RecordID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentActivityID],
            0 AS [LevelUp],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentActivityID],
            c.[LevelUp] + 1 AS [LevelUp],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentActivityID]
        WHERE
            c.[LevelUp] < 100
    )
    SELECT
        a.[ID] AS [ID],
        a.[LevelUp],
        a.[Path]
    FROM
        CTE_Ancestors a
);
GO

/* Root ID Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetRootID
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ROOT ID FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetRootID]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetRootID];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetRootID]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_RootParent AS (
        SELECT
            [ID],
            [ParentActivityID],
            [ID] AS [RootParentID],
            0 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = COALESCE(@ParentID, @RecordID)

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentActivityID],
            c.[ID] AS [RootParentID],
            p.[Depth] + 1 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Activity] c
        INNER JOIN
            CTE_RootParent p ON c.[ID] = p.[ParentActivityID]
        WHERE
            p.[Depth] < 100
    )
    SELECT TOP 1
        [RootParentID] AS RootID
    FROM
        CTE_RootParent
    WHERE
        [ParentActivityID] IS NULL
    ORDER BY
        [RootParentID]
);
GO

/* Base View SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: vwActivities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activities
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Activity
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivities]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivities];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivities]
AS
SELECT
    a.*,
    mjBizAppsCommonActivityType_ActivityTypeID.[Name] AS [ActivityType],
    MJUser_LoggedByUserID.[Name] AS [LoggedByUser],
    mjBizAppsCommonAddress_AddressID.[Line1] AS [Address],
    mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[Name] AS [ActivitySyncConnection],
    hier_ParentActivityID.RootID AS [RootParentActivityID],
    hier_ParentActivityID.Depth AS [ParentActivityIDDepth],
    hier_ParentActivityID.Path AS [ParentActivityIDPath],
    hier_ParentActivityID.IsLeaf AS [ParentActivityIDIsLeaf],
    hier_ParentActivityID.ChildCount AS [ParentActivityIDChildCount]
FROM
    [${flyway:defaultSchema}].[Activity] AS a
INNER JOIN
    [${flyway:defaultSchema}].[ActivityType] AS mjBizAppsCommonActivityType_ActivityTypeID
  ON
    [a].[ActivityTypeID] = mjBizAppsCommonActivityType_ActivityTypeID.[ID]
INNER JOIN
    [${mjSchema}].[User] AS MJUser_LoggedByUserID
  ON
    [a].[LoggedByUserID] = MJUser_LoggedByUserID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Address] AS mjBizAppsCommonAddress_AddressID
  ON
    [a].[AddressID] = mjBizAppsCommonAddress_AddressID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    [a].[ActivitySyncConnectionID] = mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[ID]
OUTER APPLY
    [${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta]([a].[ID], [a].[ParentActivityID]) AS hier_ParentActivityID
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivities] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: Permissions for vwActivities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivities] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spCreateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Activity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivity]
    @ID uniqueidentifier = NULL,
    @ActivityTypeID uniqueidentifier,
    @StartedAt datetimeoffset,
    @EndedAt_Clear bit = 0,
    @EndedAt datetimeoffset = NULL,
    @Title nvarchar(500),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Direction nvarchar(20),
    @Status nvarchar(20) = NULL,
    @Outcome_Clear bit = 0,
    @Outcome nvarchar(40) = NULL,
    @Visibility nvarchar(20) = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL,
    @ExternalID_Clear bit = 0,
    @ExternalID nvarchar(400) = NULL,
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @ParentActivityID_Clear bit = 0,
    @ParentActivityID uniqueidentifier = NULL,
    @LoggedByUserID uniqueidentifier,
    @Location_Clear bit = 0,
    @Location nvarchar(500) = NULL,
    @AddressID_Clear bit = 0,
    @AddressID uniqueidentifier = NULL,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Details_Clear bit = 0,
    @Details nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Activity]
            (
                [ID],
                [ActivityTypeID],
                [StartedAt],
                [EndedAt],
                [Title],
                [Description],
                [Direction],
                [Status],
                [Outcome],
                [Visibility],
                [Source],
                [SourceSystem],
                [ExternalID],
                [ExternalThreadID],
                [ParentActivityID],
                [LoggedByUserID],
                [Location],
                [AddressID],
                [ActivitySyncConnectionID],
                [Details]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivityTypeID,
                @StartedAt,
                CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, NULL) END,
                @Title,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @Direction,
                ISNULL(@Status, 'Logged'),
                CASE WHEN @Outcome_Clear = 1 THEN NULL ELSE ISNULL(@Outcome, NULL) END,
                ISNULL(@Visibility, 'Internal'),
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END,
                CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, NULL) END,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @ParentActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ParentActivityID, NULL) END,
                @LoggedByUserID,
                CASE WHEN @Location_Clear = 1 THEN NULL ELSE ISNULL(@Location, NULL) END,
                CASE WHEN @AddressID_Clear = 1 THEN NULL ELSE ISNULL(@AddressID, NULL) END,
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                CASE WHEN @Details_Clear = 1 THEN NULL ELSE ISNULL(@Details, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Activity]
            (
                [ActivityTypeID],
                [StartedAt],
                [EndedAt],
                [Title],
                [Description],
                [Direction],
                [Status],
                [Outcome],
                [Visibility],
                [Source],
                [SourceSystem],
                [ExternalID],
                [ExternalThreadID],
                [ParentActivityID],
                [LoggedByUserID],
                [Location],
                [AddressID],
                [ActivitySyncConnectionID],
                [Details]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivityTypeID,
                @StartedAt,
                CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, NULL) END,
                @Title,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @Direction,
                ISNULL(@Status, 'Logged'),
                CASE WHEN @Outcome_Clear = 1 THEN NULL ELSE ISNULL(@Outcome, NULL) END,
                ISNULL(@Visibility, 'Internal'),
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END,
                CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, NULL) END,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @ParentActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ParentActivityID, NULL) END,
                @LoggedByUserID,
                CASE WHEN @Location_Clear = 1 THEN NULL ELSE ISNULL(@Location, NULL) END,
                CASE WHEN @AddressID_Clear = 1 THEN NULL ELSE ISNULL(@AddressID, NULL) END,
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                CASE WHEN @Details_Clear = 1 THEN NULL ELSE ISNULL(@Details, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivities] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivity] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivity] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spUpdateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Activity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivity]
    @ID uniqueidentifier,
    @ActivityTypeID uniqueidentifier = NULL,
    @StartedAt datetimeoffset = NULL,
    @EndedAt_Clear bit = 0,
    @EndedAt datetimeoffset = NULL,
    @Title nvarchar(500) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Direction nvarchar(20) = NULL,
    @Status nvarchar(20) = NULL,
    @Outcome_Clear bit = 0,
    @Outcome nvarchar(40) = NULL,
    @Visibility nvarchar(20) = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL,
    @ExternalID_Clear bit = 0,
    @ExternalID nvarchar(400) = NULL,
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @ParentActivityID_Clear bit = 0,
    @ParentActivityID uniqueidentifier = NULL,
    @LoggedByUserID uniqueidentifier = NULL,
    @Location_Clear bit = 0,
    @Location nvarchar(500) = NULL,
    @AddressID_Clear bit = 0,
    @AddressID uniqueidentifier = NULL,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Details_Clear bit = 0,
    @Details nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Activity]
    SET
        [ActivityTypeID] = ISNULL(@ActivityTypeID, [ActivityTypeID]),
        [StartedAt] = ISNULL(@StartedAt, [StartedAt]),
        [EndedAt] = CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, [EndedAt]) END,
        [Title] = ISNULL(@Title, [Title]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Direction] = ISNULL(@Direction, [Direction]),
        [Status] = ISNULL(@Status, [Status]),
        [Outcome] = CASE WHEN @Outcome_Clear = 1 THEN NULL ELSE ISNULL(@Outcome, [Outcome]) END,
        [Visibility] = ISNULL(@Visibility, [Visibility]),
        [Source] = ISNULL(@Source, [Source]),
        [SourceSystem] = CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, [SourceSystem]) END,
        [ExternalID] = CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, [ExternalID]) END,
        [ExternalThreadID] = CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, [ExternalThreadID]) END,
        [ParentActivityID] = CASE WHEN @ParentActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ParentActivityID, [ParentActivityID]) END,
        [LoggedByUserID] = ISNULL(@LoggedByUserID, [LoggedByUserID]),
        [Location] = CASE WHEN @Location_Clear = 1 THEN NULL ELSE ISNULL(@Location, [Location]) END,
        [AddressID] = CASE WHEN @AddressID_Clear = 1 THEN NULL ELSE ISNULL(@AddressID, [AddressID]) END,
        [ActivitySyncConnectionID] = CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]) END,
        [Details] = CASE WHEN @Details_Clear = 1 THEN NULL ELSE ISNULL(@Details, [Details]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivities] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivities]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivity] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Activity table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivity]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivity];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivity
ON [${flyway:defaultSchema}].[Activity]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Activity]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[Activity] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivity] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spDeleteActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Activity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivity]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[Activity]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivity] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivity] TO [cdp_Developer], [cdp_Integration];

/* Hierarchy Metadata Function SQL for MJ_BizApps_Common: Activity Types.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: fnActivityTypeParentID_GetHierarchyMeta
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: [ActivityType].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityTypeParentID_GetHierarchyMeta]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetHierarchyMeta];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetHierarchyMeta]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [Depth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[ActivityType]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentID],
            c.[Depth] + 1 AS [Depth],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[ActivityType] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentID]
        WHERE
            c.[Depth] < 100
    )
    SELECT TOP 1
        a.[ID] AS [RootID],
        (SELECT MAX([Depth]) FROM CTE_Ancestors) AS [Depth],
        (SELECT TOP 1 [Path] FROM CTE_Ancestors ORDER BY [Depth] DESC) AS [Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[ActivityType] WHERE [ParentID] = @RecordID) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[ActivityType] WHERE [ParentID] = @RecordID) AS [ChildCount]
    FROM
        CTE_Ancestors a
    WHERE
        a.[ParentID] IS NULL OR @ParentID IS NULL
    ORDER BY
        a.[Depth] DESC
);
GO

/* Descendants Traversal Function SQL for MJ_BizApps_Common: Activity Types.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: fnActivityTypeParentID_GetDescendants
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- DESCENDANTS FUNCTION FOR: [ActivityType].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityTypeParentID_GetDescendants]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetDescendants];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetDescendants]
(
    @RootID uniqueidentifier,
    @MaxDepth INT = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Descendants AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [RelativeDepth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[ActivityType]
        WHERE
            [ID] = @RootID

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentID],
            p.[RelativeDepth] + 1 AS [RelativeDepth],
            CAST(p.[Path] + CAST(c.[ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[ActivityType] c
        INNER JOIN
            CTE_Descendants p ON c.[ParentID] = p.[ID]
        WHERE
            (@MaxDepth IS NULL OR p.[RelativeDepth] < @MaxDepth)
            AND p.[RelativeDepth] < 100
    )
    SELECT
        d.[ID] AS [ID],
        d.[RelativeDepth] AS [Depth],
        d.[Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[ActivityType] WHERE [ParentID] = d.[ID]) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[ActivityType] WHERE [ParentID] = d.[ID]) AS [ChildCount]
    FROM
        CTE_Descendants d
);
GO

/* Ancestors Traversal Function SQL for MJ_BizApps_Common: Activity Types.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: fnActivityTypeParentID_GetAncestors
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ANCESTORS FUNCTION FOR: [ActivityType].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityTypeParentID_GetAncestors]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetAncestors];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetAncestors]
(
    @RecordID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [LevelUp],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[ActivityType]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentID],
            c.[LevelUp] + 1 AS [LevelUp],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[ActivityType] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentID]
        WHERE
            c.[LevelUp] < 100
    )
    SELECT
        a.[ID] AS [ID],
        a.[LevelUp],
        a.[Path]
    FROM
        CTE_Ancestors a
);
GO

/* Root ID Function SQL for MJ_BizApps_Common: Activity Types.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: fnActivityTypeParentID_GetRootID
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ROOT ID FUNCTION FOR: [ActivityType].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityTypeParentID_GetRootID]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetRootID];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityTypeParentID_GetRootID]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_RootParent AS (
        SELECT
            [ID],
            [ParentID],
            [ID] AS [RootParentID],
            0 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[ActivityType]
        WHERE
            [ID] = COALESCE(@ParentID, @RecordID)

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentID],
            c.[ID] AS [RootParentID],
            p.[Depth] + 1 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[ActivityType] c
        INNER JOIN
            CTE_RootParent p ON c.[ID] = p.[ParentID]
        WHERE
            p.[Depth] < 100
    )
    SELECT TOP 1
        [RootParentID] AS RootID
    FROM
        CTE_RootParent
    WHERE
        [ParentID] IS NULL
    ORDER BY
        [RootParentID]
);
GO

/* Base View SQL for MJ_BizApps_Common: Activity Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: vwActivityTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activity Types
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ActivityType
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivityTypes]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivityTypes];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivityTypes]
AS
SELECT
    a.*,
    mjBizAppsCommonActivityType_ParentID.[Name] AS [Parent],
    hier_ParentID.RootID AS [RootParentID],
    hier_ParentID.Depth AS [ParentIDDepth],
    hier_ParentID.Path AS [ParentIDPath],
    hier_ParentID.IsLeaf AS [ParentIDIsLeaf],
    hier_ParentID.ChildCount AS [ParentIDChildCount]
FROM
    [${flyway:defaultSchema}].[ActivityType] AS a
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivityType] AS mjBizAppsCommonActivityType_ParentID
  ON
    [a].[ParentID] = mjBizAppsCommonActivityType_ParentID.[ID]
OUTER APPLY
    [${flyway:defaultSchema}].[fnActivityTypeParentID_GetHierarchyMeta]([a].[ID], [a].[ParentID]) AS hier_ParentID
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivityTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activity Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: Permissions for vwActivityTypes
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivityTypes] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activity Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: spCreateActivityType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ActivityType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivityType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivityType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivityType]
    @ID uniqueidentifier = NULL,
    @Code nvarchar(50),
    @Name nvarchar(100),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @Color_Clear bit = 0,
    @Color nvarchar(30) = NULL,
    @Sequence int = NULL,
    @IsSystem bit = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ActivityType]
            (
                [ID],
                [Code],
                [Name],
                [Description],
                [ParentID],
                [IconClass],
                [Color],
                [Sequence],
                [IsSystem],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Code,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, NULL) END,
                CASE WHEN @Color_Clear = 1 THEN NULL ELSE ISNULL(@Color, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsSystem, 0),
                ISNULL(@IsActive, 1)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ActivityType]
            (
                [Code],
                [Name],
                [Description],
                [ParentID],
                [IconClass],
                [Color],
                [Sequence],
                [IsSystem],
                [IsActive]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Code,
                @Name,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, NULL) END,
                CASE WHEN @Color_Clear = 1 THEN NULL ELSE ISNULL(@Color, NULL) END,
                ISNULL(@Sequence, 0),
                ISNULL(@IsSystem, 0),
                ISNULL(@IsActive, 1)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivityTypes] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivityType] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activity Types */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivityType] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activity Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: spUpdateActivityType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ActivityType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivityType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivityType]
    @ID uniqueidentifier,
    @Code nvarchar(50) = NULL,
    @Name nvarchar(100) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @IconClass_Clear bit = 0,
    @IconClass nvarchar(100) = NULL,
    @Color_Clear bit = 0,
    @Color nvarchar(30) = NULL,
    @Sequence int = NULL,
    @IsSystem bit = NULL,
    @IsActive bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityType]
    SET
        [Code] = ISNULL(@Code, [Code]),
        [Name] = ISNULL(@Name, [Name]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [ParentID] = CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, [ParentID]) END,
        [IconClass] = CASE WHEN @IconClass_Clear = 1 THEN NULL ELSE ISNULL(@IconClass, [IconClass]) END,
        [Color] = CASE WHEN @Color_Clear = 1 THEN NULL ELSE ISNULL(@Color, [Color]) END,
        [Sequence] = ISNULL(@Sequence, [Sequence]),
        [IsSystem] = ISNULL(@IsSystem, [IsSystem]),
        [IsActive] = ISNULL(@IsActive, [IsActive])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivityTypes] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivityTypes]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityType] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ActivityType table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivityType]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivityType];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivityType
ON [${flyway:defaultSchema}].[ActivityType]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ActivityType]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ActivityType] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activity Types */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivityType] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activity Types */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activity Types
-- Item: spDeleteActivityType
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ActivityType
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivityType]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivityType];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivityType]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ActivityType]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivityType] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activity Types */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivityType] TO [cdp_Developer], [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Contact Methods
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  ContactMethod
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwContactMethods]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwContactMethods];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwContactMethods]
AS
SELECT
    c.*,
    mjBizAppsCommonPerson_PersonID.[DisplayName] AS [Person],
    mjBizAppsCommonOrganization_OrganizationID.[Name] AS [Organization],
    mjBizAppsCommonContactType_ContactTypeID.[Name] AS [ContactType]
FROM
    [${flyway:defaultSchema}].[ContactMethod] AS c
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_PersonID
  ON
    [c].[PersonID] = mjBizAppsCommonPerson_PersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_OrganizationID
  ON
    [c].[OrganizationID] = mjBizAppsCommonOrganization_OrganizationID.[ID]
INNER JOIN
    [${flyway:defaultSchema}].[ContactType] AS mjBizAppsCommonContactType_ContactTypeID
  ON
    [c].[ContactTypeID] = mjBizAppsCommonContactType_ContactTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: Permissions for vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spCreateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateContactMethod]
    @ID uniqueidentifier = NULL,
    @PersonID_Clear bit = 0,
    @PersonID uniqueidentifier = NULL,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @ContactTypeID uniqueidentifier,
    @Value nvarchar(500),
    @Label_Clear bit = 0,
    @Label nvarchar(100) = NULL,
    @IsPrimary bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[ContactMethod]
            (
                [ID],
                [PersonID],
                [OrganizationID],
                [ContactTypeID],
                [Value],
                [Label],
                [IsPrimary]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, NULL) END,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                @ContactTypeID,
                @Value,
                CASE WHEN @Label_Clear = 1 THEN NULL ELSE ISNULL(@Label, NULL) END,
                ISNULL(@IsPrimary, 0)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[ContactMethod]
            (
                [PersonID],
                [OrganizationID],
                [ContactTypeID],
                [Value],
                [Label],
                [IsPrimary]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, NULL) END,
                CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, NULL) END,
                @ContactTypeID,
                @Value,
                CASE WHEN @Label_Clear = 1 THEN NULL ELSE ISNULL(@Label, NULL) END,
                ISNULL(@IsPrimary, 0)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwContactMethods] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spUpdateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateContactMethod]
    @ID uniqueidentifier,
    @PersonID_Clear bit = 0,
    @PersonID uniqueidentifier = NULL,
    @OrganizationID_Clear bit = 0,
    @OrganizationID uniqueidentifier = NULL,
    @ContactTypeID uniqueidentifier = NULL,
    @Value nvarchar(500) = NULL,
    @Label_Clear bit = 0,
    @Label nvarchar(100) = NULL,
    @IsPrimary bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactMethod]
    SET
        [PersonID] = CASE WHEN @PersonID_Clear = 1 THEN NULL ELSE ISNULL(@PersonID, [PersonID]) END,
        [OrganizationID] = CASE WHEN @OrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationID, [OrganizationID]) END,
        [ContactTypeID] = ISNULL(@ContactTypeID, [ContactTypeID]),
        [Value] = ISNULL(@Value, [Value]),
        [Label] = CASE WHEN @Label_Clear = 1 THEN NULL ELSE ISNULL(@Label, [Label]) END,
        [IsPrimary] = ISNULL(@IsPrimary, [IsPrimary])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwContactMethods] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwContactMethods]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactMethod table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateContactMethod]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateContactMethod];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateContactMethod
ON [${flyway:defaultSchema}].[ContactMethod]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[ContactMethod]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[ContactMethod] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Contact Methods
-- Item: spDeleteContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteContactMethod]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[ContactMethod]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethod] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteContactMethod] TO [cdp_Integration];

/* Hierarchy Metadata Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetHierarchyMeta
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [Depth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentID],
            c.[Depth] + 1 AS [Depth],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentID]
        WHERE
            c.[Depth] < 100
    )
    SELECT TOP 1
        a.[ID] AS [RootID],
        (SELECT MAX([Depth]) FROM CTE_Ancestors) AS [Depth],
        (SELECT TOP 1 [Path] FROM CTE_Ancestors ORDER BY [Depth] DESC) AS [Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = @RecordID) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = @RecordID) AS [ChildCount]
    FROM
        CTE_Ancestors a
    WHERE
        a.[ParentID] IS NULL OR @ParentID IS NULL
    ORDER BY
        a.[Depth] DESC
);
GO

/* Descendants Traversal Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetDescendants
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- DESCENDANTS FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetDescendants]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetDescendants];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetDescendants]
(
    @RootID uniqueidentifier,
    @MaxDepth INT = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Descendants AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [RelativeDepth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = @RootID

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentID],
            p.[RelativeDepth] + 1 AS [RelativeDepth],
            CAST(p.[Path] + CAST(c.[ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization] c
        INNER JOIN
            CTE_Descendants p ON c.[ParentID] = p.[ID]
        WHERE
            (@MaxDepth IS NULL OR p.[RelativeDepth] < @MaxDepth)
            AND p.[RelativeDepth] < 100
    )
    SELECT
        d.[ID] AS [ID],
        d.[RelativeDepth] AS [Depth],
        d.[Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = d.[ID]) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Organization] WHERE [ParentID] = d.[ID]) AS [ChildCount]
    FROM
        CTE_Descendants d
);
GO

/* Ancestors Traversal Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetAncestors
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ANCESTORS FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetAncestors]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetAncestors];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetAncestors]
(
    @RecordID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentID],
            0 AS [LevelUp],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentID],
            c.[LevelUp] + 1 AS [LevelUp],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Organization] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentID]
        WHERE
            c.[LevelUp] < 100
    )
    SELECT
        a.[ID] AS [ID],
        a.[LevelUp],
        a.[Path]
    FROM
        CTE_Ancestors a
);
GO

/* Root ID Function SQL for MJ_BizApps_Common: Organizations.ParentID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: fnOrganizationParentID_GetRootID
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ROOT ID FUNCTION FOR: [Organization].[ParentID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnOrganizationParentID_GetRootID]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetRootID];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnOrganizationParentID_GetRootID]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_RootParent AS (
        SELECT
            [ID],
            [ParentID],
            [ID] AS [RootParentID],
            0 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Organization]
        WHERE
            [ID] = COALESCE(@ParentID, @RecordID)

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentID],
            c.[ID] AS [RootParentID],
            p.[Depth] + 1 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Organization] c
        INNER JOIN
            CTE_RootParent p ON c.[ID] = p.[ParentID]
        WHERE
            p.[Depth] < 100
    )
    SELECT TOP 1
        [RootParentID] AS RootID
    FROM
        CTE_RootParent
    WHERE
        [ParentID] IS NULL
    ORDER BY
        [RootParentID]
);
GO

/* Base View SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: vwOrganizationsGenerated
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Organizations
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Organization
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizationsGenerated]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwOrganizationsGenerated];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwOrganizationsGenerated]
AS
SELECT
    o.*,
    mjBizAppsCommonOrganizationType_OrganizationTypeID.[Name] AS [OrganizationType],
    mjBizAppsCommonOrganization_ParentID.[Name] AS [Parent],
    ${mjSchema}_rgc.[Latitude] AS [${mjSchema}_Latitude],
    ${mjSchema}_rgc.[Longitude] AS [${mjSchema}_Longitude],
    hier_ParentID.RootID AS [RootParentID],
    hier_ParentID.Depth AS [ParentIDDepth],
    hier_ParentID.Path AS [ParentIDPath],
    hier_ParentID.IsLeaf AS [ParentIDIsLeaf],
    hier_ParentID.ChildCount AS [ParentIDChildCount]
FROM
    [${flyway:defaultSchema}].[Organization] AS o
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[OrganizationType] AS mjBizAppsCommonOrganizationType_OrganizationTypeID
  ON
    [o].[OrganizationTypeID] = mjBizAppsCommonOrganizationType_OrganizationTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_ParentID
  ON
    [o].[ParentID] = mjBizAppsCommonOrganization_ParentID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[vwRecordGeoCodes] AS ${mjSchema}_rgc
  ON
    ${mjSchema}_rgc.[EntityID] = 'C70448F9-9792-41D7-A82C-784B66429D54'
    AND ${mjSchema}_rgc.[RecordID] = CAST([o].[ID] AS NVARCHAR(450))
    AND ${mjSchema}_rgc.[LocationType] = 'Primary'
OUTER APPLY
    [${flyway:defaultSchema}].[fnOrganizationParentID_GetHierarchyMeta]([o].[ID], [o].[ParentID]) AS hier_ParentID
GO
IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

/* Base View Permissions SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: Permissions for vwOrganizations
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

IF OBJECT_ID('[${flyway:defaultSchema}].[vwOrganizations]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'GRANT SELECT ON [${flyway:defaultSchema}].[vwOrganizations] TO [cdp_UI], [cdp_Developer], [cdp_Integration]';
END;

/* spCreate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spCreateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateOrganization]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(255),
    @LegalName_Clear bit = 0,
    @LegalName nvarchar(255) = NULL,
    @OrganizationTypeID_Clear bit = 0,
    @OrganizationTypeID uniqueidentifier = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @Website_Clear bit = 0,
    @Website nvarchar(1000) = NULL,
    @LogoURL_Clear bit = 0,
    @LogoURL nvarchar(1000) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @FoundedDate_Clear bit = 0,
    @FoundedDate date = NULL,
    @TaxID_Clear bit = 0,
    @TaxID nvarchar(50) = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Organization]
            (
                [ID],
                [Name],
                [LegalName],
                [OrganizationTypeID],
                [ParentID],
                [Website],
                [LogoURL],
                [Description],
                [Email],
                [Phone],
                [FoundedDate],
                [TaxID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @Name,
                CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, NULL) END,
                CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, NULL) END,
                CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, NULL) END,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, NULL) END,
                CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Organization]
            (
                [Name],
                [LegalName],
                [OrganizationTypeID],
                [ParentID],
                [Website],
                [LogoURL],
                [Description],
                [Email],
                [Phone],
                [FoundedDate],
                [TaxID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @Name,
                CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, NULL) END,
                CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, NULL) END,
                CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, NULL) END,
                CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, NULL) END,
                CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, NULL) END,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, NULL) END,
                CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, NULL) END,
                CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, NULL) END,
                CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, NULL) END,
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwOrganizations] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spUpdateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateOrganization]
    @ID uniqueidentifier,
    @Name nvarchar(255) = NULL,
    @LegalName_Clear bit = 0,
    @LegalName nvarchar(255) = NULL,
    @OrganizationTypeID_Clear bit = 0,
    @OrganizationTypeID uniqueidentifier = NULL,
    @ParentID_Clear bit = 0,
    @ParentID uniqueidentifier = NULL,
    @Website_Clear bit = 0,
    @Website nvarchar(1000) = NULL,
    @LogoURL_Clear bit = 0,
    @LogoURL nvarchar(1000) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Email_Clear bit = 0,
    @Email nvarchar(255) = NULL,
    @Phone_Clear bit = 0,
    @Phone nvarchar(50) = NULL,
    @FoundedDate_Clear bit = 0,
    @FoundedDate date = NULL,
    @TaxID_Clear bit = 0,
    @TaxID nvarchar(50) = NULL,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Organization]
    SET
        [Name] = ISNULL(@Name, [Name]),
        [LegalName] = CASE WHEN @LegalName_Clear = 1 THEN NULL ELSE ISNULL(@LegalName, [LegalName]) END,
        [OrganizationTypeID] = CASE WHEN @OrganizationTypeID_Clear = 1 THEN NULL ELSE ISNULL(@OrganizationTypeID, [OrganizationTypeID]) END,
        [ParentID] = CASE WHEN @ParentID_Clear = 1 THEN NULL ELSE ISNULL(@ParentID, [ParentID]) END,
        [Website] = CASE WHEN @Website_Clear = 1 THEN NULL ELSE ISNULL(@Website, [Website]) END,
        [LogoURL] = CASE WHEN @LogoURL_Clear = 1 THEN NULL ELSE ISNULL(@LogoURL, [LogoURL]) END,
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Email] = CASE WHEN @Email_Clear = 1 THEN NULL ELSE ISNULL(@Email, [Email]) END,
        [Phone] = CASE WHEN @Phone_Clear = 1 THEN NULL ELSE ISNULL(@Phone, [Phone]) END,
        [FoundedDate] = CASE WHEN @FoundedDate_Clear = 1 THEN NULL ELSE ISNULL(@FoundedDate, [FoundedDate]) END,
        [TaxID] = CASE WHEN @TaxID_Clear = 1 THEN NULL ELSE ISNULL(@TaxID, [TaxID]) END,
        [Status] = ISNULL(@Status, [Status])
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwOrganizations] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwOrganizations]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Organization table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateOrganization]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateOrganization];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateOrganization
ON [${flyway:defaultSchema}].[Organization]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Organization]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[Organization] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Organizations
-- Item: spDeleteOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteOrganization]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    -- Cascade update on ContactMethod using cursor to call spUpdateContactMethod
    DECLARE @mjBizAppsCommonContactMethods_OrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsCommonContactMethods_OrganizationID_PersonID uniqueidentifier
    DECLARE @mjBizAppsCommonContactMethods_OrganizationID_OrganizationID uniqueidentifier
    DECLARE @mjBizAppsCommonContactMethods_OrganizationID_ContactTypeID uniqueidentifier
    DECLARE @mjBizAppsCommonContactMethods_OrganizationID_Value nvarchar(500)
    DECLARE @mjBizAppsCommonContactMethods_OrganizationID_Label nvarchar(100)
    DECLARE @mjBizAppsCommonContactMethods_OrganizationID_IsPrimary bit
    DECLARE cascade_update_mjBizAppsCommonContactMethods_OrganizationID_cursor CURSOR FOR
        SELECT [ID], [PersonID], [OrganizationID], [ContactTypeID], [Value], [Label], [IsPrimary]
        FROM [${flyway:defaultSchema}].[ContactMethod]
        WHERE [OrganizationID] = @ID

    OPEN cascade_update_mjBizAppsCommonContactMethods_OrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsCommonContactMethods_OrganizationID_cursor INTO @mjBizAppsCommonContactMethods_OrganizationIDID, @mjBizAppsCommonContactMethods_OrganizationID_PersonID, @mjBizAppsCommonContactMethods_OrganizationID_OrganizationID, @mjBizAppsCommonContactMethods_OrganizationID_ContactTypeID, @mjBizAppsCommonContactMethods_OrganizationID_Value, @mjBizAppsCommonContactMethods_OrganizationID_Label, @mjBizAppsCommonContactMethods_OrganizationID_IsPrimary

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsCommonContactMethods_OrganizationID_OrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${flyway:defaultSchema}].[spUpdateContactMethod] @ID = @mjBizAppsCommonContactMethods_OrganizationIDID, @PersonID = @mjBizAppsCommonContactMethods_OrganizationID_PersonID, @OrganizationID_Clear = 1, @OrganizationID = @mjBizAppsCommonContactMethods_OrganizationID_OrganizationID, @ContactTypeID = @mjBizAppsCommonContactMethods_OrganizationID_ContactTypeID, @Value = @mjBizAppsCommonContactMethods_OrganizationID_Value, @Label = @mjBizAppsCommonContactMethods_OrganizationID_Label, @IsPrimary = @mjBizAppsCommonContactMethods_OrganizationID_IsPrimary

        FETCH NEXT FROM cascade_update_mjBizAppsCommonContactMethods_OrganizationID_cursor INTO @mjBizAppsCommonContactMethods_OrganizationIDID, @mjBizAppsCommonContactMethods_OrganizationID_PersonID, @mjBizAppsCommonContactMethods_OrganizationID_OrganizationID, @mjBizAppsCommonContactMethods_OrganizationID_ContactTypeID, @mjBizAppsCommonContactMethods_OrganizationID_Value, @mjBizAppsCommonContactMethods_OrganizationID_Label, @mjBizAppsCommonContactMethods_OrganizationID_IsPrimary
    END

    CLOSE cascade_update_mjBizAppsCommonContactMethods_OrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsCommonContactMethods_OrganizationID_cursor
    
    -- Cascade update on Organization using cursor to call spUpdateOrganization
    DECLARE @mjBizAppsCommonOrganizations_ParentIDID uniqueidentifier
    DECLARE @mjBizAppsCommonOrganizations_ParentID_Name nvarchar(255)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_LegalName nvarchar(255)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_OrganizationTypeID uniqueidentifier
    DECLARE @mjBizAppsCommonOrganizations_ParentID_ParentID uniqueidentifier
    DECLARE @mjBizAppsCommonOrganizations_ParentID_Website nvarchar(1000)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_LogoURL nvarchar(1000)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_Description nvarchar(MAX)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_Email nvarchar(255)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_Phone nvarchar(50)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_FoundedDate date
    DECLARE @mjBizAppsCommonOrganizations_ParentID_TaxID nvarchar(50)
    DECLARE @mjBizAppsCommonOrganizations_ParentID_Status nvarchar(50)
    DECLARE cascade_update_mjBizAppsCommonOrganizations_ParentID_cursor CURSOR FOR
        SELECT [ID], [Name], [LegalName], [OrganizationTypeID], [ParentID], [Website], [LogoURL], [Description], [Email], [Phone], [FoundedDate], [TaxID], [Status]
        FROM [${flyway:defaultSchema}].[Organization]
        WHERE [ParentID] = @ID

    OPEN cascade_update_mjBizAppsCommonOrganizations_ParentID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsCommonOrganizations_ParentID_cursor INTO @mjBizAppsCommonOrganizations_ParentIDID, @mjBizAppsCommonOrganizations_ParentID_Name, @mjBizAppsCommonOrganizations_ParentID_LegalName, @mjBizAppsCommonOrganizations_ParentID_OrganizationTypeID, @mjBizAppsCommonOrganizations_ParentID_ParentID, @mjBizAppsCommonOrganizations_ParentID_Website, @mjBizAppsCommonOrganizations_ParentID_LogoURL, @mjBizAppsCommonOrganizations_ParentID_Description, @mjBizAppsCommonOrganizations_ParentID_Email, @mjBizAppsCommonOrganizations_ParentID_Phone, @mjBizAppsCommonOrganizations_ParentID_FoundedDate, @mjBizAppsCommonOrganizations_ParentID_TaxID, @mjBizAppsCommonOrganizations_ParentID_Status

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsCommonOrganizations_ParentID_ParentID = NULL

        -- Call the update SP for the related entity
        EXEC [${flyway:defaultSchema}].[spUpdateOrganization] @ID = @mjBizAppsCommonOrganizations_ParentIDID, @Name = @mjBizAppsCommonOrganizations_ParentID_Name, @LegalName = @mjBizAppsCommonOrganizations_ParentID_LegalName, @OrganizationTypeID = @mjBizAppsCommonOrganizations_ParentID_OrganizationTypeID, @ParentID_Clear = 1, @ParentID = @mjBizAppsCommonOrganizations_ParentID_ParentID, @Website = @mjBizAppsCommonOrganizations_ParentID_Website, @LogoURL = @mjBizAppsCommonOrganizations_ParentID_LogoURL, @Description = @mjBizAppsCommonOrganizations_ParentID_Description, @Email = @mjBizAppsCommonOrganizations_ParentID_Email, @Phone = @mjBizAppsCommonOrganizations_ParentID_Phone, @FoundedDate = @mjBizAppsCommonOrganizations_ParentID_FoundedDate, @TaxID = @mjBizAppsCommonOrganizations_ParentID_TaxID, @Status = @mjBizAppsCommonOrganizations_ParentID_Status

        FETCH NEXT FROM cascade_update_mjBizAppsCommonOrganizations_ParentID_cursor INTO @mjBizAppsCommonOrganizations_ParentIDID, @mjBizAppsCommonOrganizations_ParentID_Name, @mjBizAppsCommonOrganizations_ParentID_LegalName, @mjBizAppsCommonOrganizations_ParentID_OrganizationTypeID, @mjBizAppsCommonOrganizations_ParentID_ParentID, @mjBizAppsCommonOrganizations_ParentID_Website, @mjBizAppsCommonOrganizations_ParentID_LogoURL, @mjBizAppsCommonOrganizations_ParentID_Description, @mjBizAppsCommonOrganizations_ParentID_Email, @mjBizAppsCommonOrganizations_ParentID_Phone, @mjBizAppsCommonOrganizations_ParentID_FoundedDate, @mjBizAppsCommonOrganizations_ParentID_TaxID, @mjBizAppsCommonOrganizations_ParentID_Status
    END

    CLOSE cascade_update_mjBizAppsCommonOrganizations_ParentID_cursor
    DEALLOCATE cascade_update_mjBizAppsCommonOrganizations_ParentID_cursor
    
    -- Cascade update on Relationship using cursor to call spUpdateRelationship
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_RelationshipTypeID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_FromPersonID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_FromOrganizationID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_ToPersonID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_ToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_Title nvarchar(255)
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_StartDate date
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_EndDate date
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_Status nvarchar(50)
    DECLARE @mjBizAppsCommonRelationships_FromOrganizationID_Notes nvarchar(MAX)
    DECLARE cascade_update_mjBizAppsCommonRelationships_FromOrganizationID_cursor CURSOR FOR
        SELECT [ID], [RelationshipTypeID], [FromPersonID], [FromOrganizationID], [ToPersonID], [ToOrganizationID], [Title], [StartDate], [EndDate], [Status], [Notes]
        FROM [${flyway:defaultSchema}].[Relationship]
        WHERE [FromOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsCommonRelationships_FromOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsCommonRelationships_FromOrganizationID_cursor INTO @mjBizAppsCommonRelationships_FromOrganizationIDID, @mjBizAppsCommonRelationships_FromOrganizationID_RelationshipTypeID, @mjBizAppsCommonRelationships_FromOrganizationID_FromPersonID, @mjBizAppsCommonRelationships_FromOrganizationID_FromOrganizationID, @mjBizAppsCommonRelationships_FromOrganizationID_ToPersonID, @mjBizAppsCommonRelationships_FromOrganizationID_ToOrganizationID, @mjBizAppsCommonRelationships_FromOrganizationID_Title, @mjBizAppsCommonRelationships_FromOrganizationID_StartDate, @mjBizAppsCommonRelationships_FromOrganizationID_EndDate, @mjBizAppsCommonRelationships_FromOrganizationID_Status, @mjBizAppsCommonRelationships_FromOrganizationID_Notes

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsCommonRelationships_FromOrganizationID_FromOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${flyway:defaultSchema}].[spUpdateRelationship] @ID = @mjBizAppsCommonRelationships_FromOrganizationIDID, @RelationshipTypeID = @mjBizAppsCommonRelationships_FromOrganizationID_RelationshipTypeID, @FromPersonID = @mjBizAppsCommonRelationships_FromOrganizationID_FromPersonID, @FromOrganizationID_Clear = 1, @FromOrganizationID = @mjBizAppsCommonRelationships_FromOrganizationID_FromOrganizationID, @ToPersonID = @mjBizAppsCommonRelationships_FromOrganizationID_ToPersonID, @ToOrganizationID = @mjBizAppsCommonRelationships_FromOrganizationID_ToOrganizationID, @Title = @mjBizAppsCommonRelationships_FromOrganizationID_Title, @StartDate = @mjBizAppsCommonRelationships_FromOrganizationID_StartDate, @EndDate = @mjBizAppsCommonRelationships_FromOrganizationID_EndDate, @Status = @mjBizAppsCommonRelationships_FromOrganizationID_Status, @Notes = @mjBizAppsCommonRelationships_FromOrganizationID_Notes

        FETCH NEXT FROM cascade_update_mjBizAppsCommonRelationships_FromOrganizationID_cursor INTO @mjBizAppsCommonRelationships_FromOrganizationIDID, @mjBizAppsCommonRelationships_FromOrganizationID_RelationshipTypeID, @mjBizAppsCommonRelationships_FromOrganizationID_FromPersonID, @mjBizAppsCommonRelationships_FromOrganizationID_FromOrganizationID, @mjBizAppsCommonRelationships_FromOrganizationID_ToPersonID, @mjBizAppsCommonRelationships_FromOrganizationID_ToOrganizationID, @mjBizAppsCommonRelationships_FromOrganizationID_Title, @mjBizAppsCommonRelationships_FromOrganizationID_StartDate, @mjBizAppsCommonRelationships_FromOrganizationID_EndDate, @mjBizAppsCommonRelationships_FromOrganizationID_Status, @mjBizAppsCommonRelationships_FromOrganizationID_Notes
    END

    CLOSE cascade_update_mjBizAppsCommonRelationships_FromOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsCommonRelationships_FromOrganizationID_cursor
    
    -- Cascade update on Relationship using cursor to call spUpdateRelationship
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_RelationshipTypeID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_FromPersonID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_FromOrganizationID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_ToPersonID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_ToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_Title nvarchar(255)
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_StartDate date
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_EndDate date
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_Status nvarchar(50)
    DECLARE @mjBizAppsCommonRelationships_ToOrganizationID_Notes nvarchar(MAX)
    DECLARE cascade_update_mjBizAppsCommonRelationships_ToOrganizationID_cursor CURSOR FOR
        SELECT [ID], [RelationshipTypeID], [FromPersonID], [FromOrganizationID], [ToPersonID], [ToOrganizationID], [Title], [StartDate], [EndDate], [Status], [Notes]
        FROM [${flyway:defaultSchema}].[Relationship]
        WHERE [ToOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsCommonRelationships_ToOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsCommonRelationships_ToOrganizationID_cursor INTO @mjBizAppsCommonRelationships_ToOrganizationIDID, @mjBizAppsCommonRelationships_ToOrganizationID_RelationshipTypeID, @mjBizAppsCommonRelationships_ToOrganizationID_FromPersonID, @mjBizAppsCommonRelationships_ToOrganizationID_FromOrganizationID, @mjBizAppsCommonRelationships_ToOrganizationID_ToPersonID, @mjBizAppsCommonRelationships_ToOrganizationID_ToOrganizationID, @mjBizAppsCommonRelationships_ToOrganizationID_Title, @mjBizAppsCommonRelationships_ToOrganizationID_StartDate, @mjBizAppsCommonRelationships_ToOrganizationID_EndDate, @mjBizAppsCommonRelationships_ToOrganizationID_Status, @mjBizAppsCommonRelationships_ToOrganizationID_Notes

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsCommonRelationships_ToOrganizationID_ToOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${flyway:defaultSchema}].[spUpdateRelationship] @ID = @mjBizAppsCommonRelationships_ToOrganizationIDID, @RelationshipTypeID = @mjBizAppsCommonRelationships_ToOrganizationID_RelationshipTypeID, @FromPersonID = @mjBizAppsCommonRelationships_ToOrganizationID_FromPersonID, @FromOrganizationID = @mjBizAppsCommonRelationships_ToOrganizationID_FromOrganizationID, @ToPersonID = @mjBizAppsCommonRelationships_ToOrganizationID_ToPersonID, @ToOrganizationID_Clear = 1, @ToOrganizationID = @mjBizAppsCommonRelationships_ToOrganizationID_ToOrganizationID, @Title = @mjBizAppsCommonRelationships_ToOrganizationID_Title, @StartDate = @mjBizAppsCommonRelationships_ToOrganizationID_StartDate, @EndDate = @mjBizAppsCommonRelationships_ToOrganizationID_EndDate, @Status = @mjBizAppsCommonRelationships_ToOrganizationID_Status, @Notes = @mjBizAppsCommonRelationships_ToOrganizationID_Notes

        FETCH NEXT FROM cascade_update_mjBizAppsCommonRelationships_ToOrganizationID_cursor INTO @mjBizAppsCommonRelationships_ToOrganizationIDID, @mjBizAppsCommonRelationships_ToOrganizationID_RelationshipTypeID, @mjBizAppsCommonRelationships_ToOrganizationID_FromPersonID, @mjBizAppsCommonRelationships_ToOrganizationID_FromOrganizationID, @mjBizAppsCommonRelationships_ToOrganizationID_ToPersonID, @mjBizAppsCommonRelationships_ToOrganizationID_ToOrganizationID, @mjBizAppsCommonRelationships_ToOrganizationID_Title, @mjBizAppsCommonRelationships_ToOrganizationID_StartDate, @mjBizAppsCommonRelationships_ToOrganizationID_EndDate, @mjBizAppsCommonRelationships_ToOrganizationID_Status, @mjBizAppsCommonRelationships_ToOrganizationID_Notes
    END

    CLOSE cascade_update_mjBizAppsCommonRelationships_ToOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsCommonRelationships_ToOrganizationID_cursor
    
    -- Cascade update on CustomerPaymentMethod using cursor to call spUpdateCustomerPaymentMethod
    DECLARE @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_PaymentDetailID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_Nickname nvarchar(100)
    DECLARE @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsDefault bit
    DECLARE @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsActive bit
    DECLARE cascade_update_mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_cursor CURSOR FOR
        SELECT [ID], [OwnerPersonID], [OwnerOrganizationID], [PaymentDetailID], [Nickname], [IsDefault], [IsActive]
        FROM [${mjSchema}_BizAppsOrders].[CustomerPaymentMethod]
        WHERE [OwnerOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_cursor INTO @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationIDID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerPersonID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerOrganizationID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_PaymentDetailID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_Nickname, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsDefault, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsActive

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateCustomerPaymentMethod] @ID = @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationIDID, @OwnerPersonID = @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerPersonID, @OwnerOrganizationID_Clear = 1, @OwnerOrganizationID = @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerOrganizationID, @PaymentDetailID = @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_PaymentDetailID, @Nickname = @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_Nickname, @IsDefault = @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsDefault, @IsActive = @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsActive

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_cursor INTO @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationIDID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerPersonID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_OwnerOrganizationID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_PaymentDetailID, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_Nickname, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsDefault, @mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_IsActive
    END

    CLOSE cascade_update_mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersCustomerPaymentMethods_OwnerOrganizationID_cursor
    
    -- Cascade update on CustomerTaxExemption using cursor to call spUpdateCustomerTaxExemption
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_OrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_PersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxJurisdictionID uniqueidentifier
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxCategory nvarchar(50)
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_ExemptionType nvarchar(30)
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateRef nvarchar(200)
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateIssuedAt date
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateExpiresAt date
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_StartedAt datetimeoffset
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_EndedAt datetimeoffset
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Status nvarchar(10)
    DECLARE @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Comments nvarchar(MAX)
    DECLARE cascade_update_mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_cursor CURSOR FOR
        SELECT [ID], [OrganizationID], [PersonID], [TaxJurisdictionID], [TaxCategory], [ExemptionType], [CertificateRef], [CertificateIssuedAt], [CertificateExpiresAt], [StartedAt], [EndedAt], [Status], [Comments]
        FROM [${mjSchema}_BizAppsOrders].[CustomerTaxExemption]
        WHERE [OrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_cursor INTO @mjBizAppsOrdersCustomerTaxExemptions_OrganizationIDID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_OrganizationID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_PersonID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxJurisdictionID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxCategory, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_ExemptionType, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateRef, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateIssuedAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateExpiresAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_StartedAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_EndedAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Status, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Comments

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_OrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateCustomerTaxExemption] @ID = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationIDID, @OrganizationID_Clear = 1, @OrganizationID = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_OrganizationID, @PersonID = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_PersonID, @TaxJurisdictionID = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxJurisdictionID, @TaxCategory = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxCategory, @ExemptionType = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_ExemptionType, @CertificateRef = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateRef, @CertificateIssuedAt = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateIssuedAt, @CertificateExpiresAt = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateExpiresAt, @StartedAt = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_StartedAt, @EndedAt = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_EndedAt, @Status = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Status, @Comments = @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Comments

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_cursor INTO @mjBizAppsOrdersCustomerTaxExemptions_OrganizationIDID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_OrganizationID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_PersonID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxJurisdictionID, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_TaxCategory, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_ExemptionType, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateRef, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateIssuedAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_CertificateExpiresAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_StartedAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_EndedAt, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Status, @mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_Comments
    END

    CLOSE cascade_update_mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersCustomerTaxExemptions_OrganizationID_cursor
    
    -- Cascade update on EntitlementGrant using cursor to call spUpdateEntitlementGrant
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProductEntitlementID uniqueidentifier
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_OrderLineID uniqueidentifier
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionID uniqueidentifier
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Quantity decimal(18, 4)
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidFrom datetimeoffset
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidTo datetimeoffset
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Status nvarchar(20)
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProvisionedAt datetimeoffset
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidityModeApplied nvarchar(20)
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionTermID uniqueidentifier
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevokedAt datetimeoffset
    DECLARE @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevocationReason nvarchar(300)
    DECLARE cascade_update_mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_cursor CURSOR FOR
        SELECT [ID], [ProductEntitlementID], [OrderLineID], [SubscriptionID], [BeneficiaryPersonID], [BeneficiaryOrganizationID], [Quantity], [ValidFrom], [ValidTo], [Status], [ProvisionedAt], [ValidityModeApplied], [SubscriptionTermID], [RevokedAt], [RevocationReason]
        FROM [${mjSchema}_BizAppsOrders].[EntitlementGrant]
        WHERE [BeneficiaryOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_cursor INTO @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationIDID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProductEntitlementID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_OrderLineID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryPersonID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryOrganizationID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Quantity, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidFrom, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidTo, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Status, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProvisionedAt, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidityModeApplied, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionTermID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevokedAt, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevocationReason

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateEntitlementGrant] @ID = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationIDID, @ProductEntitlementID = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProductEntitlementID, @OrderLineID = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_OrderLineID, @SubscriptionID = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionID, @BeneficiaryPersonID = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryPersonID, @BeneficiaryOrganizationID_Clear = 1, @BeneficiaryOrganizationID = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryOrganizationID, @Quantity = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Quantity, @ValidFrom = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidFrom, @ValidTo = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidTo, @Status = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Status, @ProvisionedAt = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProvisionedAt, @ValidityModeApplied = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidityModeApplied, @SubscriptionTermID = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionTermID, @RevokedAt = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevokedAt, @RevocationReason = @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevocationReason

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_cursor INTO @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationIDID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProductEntitlementID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_OrderLineID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryPersonID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_BeneficiaryOrganizationID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Quantity, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidFrom, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidTo, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_Status, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ProvisionedAt, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_ValidityModeApplied, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_SubscriptionTermID, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevokedAt, @mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_RevocationReason
    END

    CLOSE cascade_update_mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersEntitlementGrants_BeneficiaryOrganizationID_cursor
    
    -- Cascade update on OrderHeader using cursor to call spUpdateOrderHeader
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderNumber nvarchar(40)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderType nvarchar(20)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderDate date
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Status nvarchar(20)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_CompanyID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SalesRepUserID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToAddressID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToAddressID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PaymentTermsTypeID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_TotalGross decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_AmountPaid decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Balance decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_DueDate date
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ExternalDocumentNumber nvarchar(80)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentTypeID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentAmount decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentDetailID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedAt datetimeoffset
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedByUserID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversesOrderHeaderID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversalReason nvarchar(MAX)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_RequestedDeliveryDate date
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ApprovalTaskID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Description nvarchar(MAX)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Notes nvarchar(MAX)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ConfirmedAt datetimeoffset
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_FulfillmentStatus nvarchar(20)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Origin nvarchar(50)
    DECLARE @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SourceCheckoutWidgetID uniqueidentifier
    DECLARE cascade_update_mjBizAppsOrdersOrderHeaders_BillToOrganizationID_cursor CURSOR FOR
        SELECT [ID], [OrderNumber], [OrderType], [OrderDate], [Status], [CompanyID], [BillToPersonID], [BillToOrganizationID], [SalesRepUserID], [BillToAddressID], [ShipToAddressID], [ShipToOrganizationID], [ShipToPersonID], [PaymentTermsTypeID], [TotalGross], [AmountPaid], [Balance], [DueDate], [ExternalDocumentNumber], [InitialPaymentTypeID], [InitialPaymentAmount], [InitialPaymentDetailID], [PostedAt], [PostedByUserID], [ReversesOrderHeaderID], [ReversalReason], [RequestedDeliveryDate], [ApprovalTaskID], [Description], [Notes], [ConfirmedAt], [FulfillmentStatus], [Origin], [SourceCheckoutWidgetID]
        FROM [${mjSchema}_BizAppsOrders].[OrderHeader]
        WHERE [BillToOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersOrderHeaders_BillToOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersOrderHeaders_BillToOrganizationID_cursor INTO @mjBizAppsOrdersOrderHeaders_BillToOrganizationIDID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderNumber, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderType, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderDate, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Status, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_CompanyID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToPersonID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SalesRepUserID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToAddressID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToAddressID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToOrganizationID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToPersonID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PaymentTermsTypeID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_TotalGross, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_AmountPaid, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Balance, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_DueDate, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ExternalDocumentNumber, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentTypeID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentAmount, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentDetailID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedAt, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedByUserID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversesOrderHeaderID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversalReason, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_RequestedDeliveryDate, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ApprovalTaskID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Description, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Notes, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ConfirmedAt, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_FulfillmentStatus, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Origin, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SourceCheckoutWidgetID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateOrderHeader] @ID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationIDID, @OrderNumber = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderNumber, @OrderType = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderType, @OrderDate = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderDate, @Status = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Status, @CompanyID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_CompanyID, @BillToPersonID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToPersonID, @BillToOrganizationID_Clear = 1, @BillToOrganizationID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToOrganizationID, @SalesRepUserID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SalesRepUserID, @BillToAddressID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToAddressID, @ShipToAddressID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToAddressID, @ShipToOrganizationID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToOrganizationID, @ShipToPersonID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToPersonID, @PaymentTermsTypeID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PaymentTermsTypeID, @TotalGross = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_TotalGross, @AmountPaid = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_AmountPaid, @Balance = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Balance, @DueDate = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_DueDate, @ExternalDocumentNumber = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ExternalDocumentNumber, @InitialPaymentTypeID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentTypeID, @InitialPaymentAmount = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentAmount, @InitialPaymentDetailID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentDetailID, @PostedAt = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedAt, @PostedByUserID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedByUserID, @ReversesOrderHeaderID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversesOrderHeaderID, @ReversalReason = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversalReason, @RequestedDeliveryDate = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_RequestedDeliveryDate, @ApprovalTaskID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ApprovalTaskID, @Description = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Description, @Notes = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Notes, @ConfirmedAt = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ConfirmedAt, @FulfillmentStatus = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_FulfillmentStatus, @Origin = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Origin, @SourceCheckoutWidgetID = @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SourceCheckoutWidgetID

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersOrderHeaders_BillToOrganizationID_cursor INTO @mjBizAppsOrdersOrderHeaders_BillToOrganizationIDID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderNumber, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderType, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_OrderDate, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Status, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_CompanyID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToPersonID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SalesRepUserID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_BillToAddressID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToAddressID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToOrganizationID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ShipToPersonID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PaymentTermsTypeID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_TotalGross, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_AmountPaid, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Balance, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_DueDate, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ExternalDocumentNumber, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentTypeID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentAmount, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_InitialPaymentDetailID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedAt, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_PostedByUserID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversesOrderHeaderID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ReversalReason, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_RequestedDeliveryDate, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ApprovalTaskID, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Description, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Notes, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_ConfirmedAt, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_FulfillmentStatus, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_Origin, @mjBizAppsOrdersOrderHeaders_BillToOrganizationID_SourceCheckoutWidgetID
    END

    CLOSE cascade_update_mjBizAppsOrdersOrderHeaders_BillToOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersOrderHeaders_BillToOrganizationID_cursor
    
    -- Cascade update on OrderHeader using cursor to call spUpdateOrderHeader
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderNumber nvarchar(40)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderType nvarchar(20)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderDate date
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Status nvarchar(20)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_CompanyID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SalesRepUserID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToAddressID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToAddressID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PaymentTermsTypeID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_TotalGross decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_AmountPaid decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Balance decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_DueDate date
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ExternalDocumentNumber nvarchar(80)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentTypeID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentAmount decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentDetailID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedAt datetimeoffset
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedByUserID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversesOrderHeaderID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversalReason nvarchar(MAX)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_RequestedDeliveryDate date
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ApprovalTaskID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Description nvarchar(MAX)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Notes nvarchar(MAX)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ConfirmedAt datetimeoffset
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_FulfillmentStatus nvarchar(20)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Origin nvarchar(50)
    DECLARE @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SourceCheckoutWidgetID uniqueidentifier
    DECLARE cascade_update_mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_cursor CURSOR FOR
        SELECT [ID], [OrderNumber], [OrderType], [OrderDate], [Status], [CompanyID], [BillToPersonID], [BillToOrganizationID], [SalesRepUserID], [BillToAddressID], [ShipToAddressID], [ShipToOrganizationID], [ShipToPersonID], [PaymentTermsTypeID], [TotalGross], [AmountPaid], [Balance], [DueDate], [ExternalDocumentNumber], [InitialPaymentTypeID], [InitialPaymentAmount], [InitialPaymentDetailID], [PostedAt], [PostedByUserID], [ReversesOrderHeaderID], [ReversalReason], [RequestedDeliveryDate], [ApprovalTaskID], [Description], [Notes], [ConfirmedAt], [FulfillmentStatus], [Origin], [SourceCheckoutWidgetID]
        FROM [${mjSchema}_BizAppsOrders].[OrderHeader]
        WHERE [ShipToOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_cursor INTO @mjBizAppsOrdersOrderHeaders_ShipToOrganizationIDID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderNumber, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderType, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderDate, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Status, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_CompanyID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToPersonID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SalesRepUserID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToAddressID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToAddressID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToOrganizationID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToPersonID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PaymentTermsTypeID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_TotalGross, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_AmountPaid, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Balance, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_DueDate, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ExternalDocumentNumber, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentTypeID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentAmount, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentDetailID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedAt, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedByUserID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversesOrderHeaderID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversalReason, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_RequestedDeliveryDate, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ApprovalTaskID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Description, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Notes, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ConfirmedAt, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_FulfillmentStatus, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Origin, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SourceCheckoutWidgetID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateOrderHeader] @ID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationIDID, @OrderNumber = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderNumber, @OrderType = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderType, @OrderDate = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderDate, @Status = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Status, @CompanyID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_CompanyID, @BillToPersonID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToPersonID, @BillToOrganizationID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToOrganizationID, @SalesRepUserID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SalesRepUserID, @BillToAddressID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToAddressID, @ShipToAddressID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToAddressID, @ShipToOrganizationID_Clear = 1, @ShipToOrganizationID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToOrganizationID, @ShipToPersonID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToPersonID, @PaymentTermsTypeID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PaymentTermsTypeID, @TotalGross = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_TotalGross, @AmountPaid = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_AmountPaid, @Balance = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Balance, @DueDate = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_DueDate, @ExternalDocumentNumber = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ExternalDocumentNumber, @InitialPaymentTypeID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentTypeID, @InitialPaymentAmount = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentAmount, @InitialPaymentDetailID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentDetailID, @PostedAt = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedAt, @PostedByUserID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedByUserID, @ReversesOrderHeaderID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversesOrderHeaderID, @ReversalReason = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversalReason, @RequestedDeliveryDate = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_RequestedDeliveryDate, @ApprovalTaskID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ApprovalTaskID, @Description = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Description, @Notes = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Notes, @ConfirmedAt = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ConfirmedAt, @FulfillmentStatus = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_FulfillmentStatus, @Origin = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Origin, @SourceCheckoutWidgetID = @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SourceCheckoutWidgetID

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_cursor INTO @mjBizAppsOrdersOrderHeaders_ShipToOrganizationIDID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderNumber, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderType, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_OrderDate, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Status, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_CompanyID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToPersonID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SalesRepUserID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_BillToAddressID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToAddressID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToOrganizationID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ShipToPersonID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PaymentTermsTypeID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_TotalGross, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_AmountPaid, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Balance, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_DueDate, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ExternalDocumentNumber, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentTypeID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentAmount, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_InitialPaymentDetailID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedAt, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_PostedByUserID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversesOrderHeaderID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ReversalReason, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_RequestedDeliveryDate, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ApprovalTaskID, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Description, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Notes, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_ConfirmedAt, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_FulfillmentStatus, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_Origin, @mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_SourceCheckoutWidgetID
    END

    CLOSE cascade_update_mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersOrderHeaders_ShipToOrganizationID_cursor
    
    -- Cascade update on OrderLine using cursor to call spUpdateOrderLine
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_OrderHeaderID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_CompanyID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineNumber int
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Quantity decimal(18, 4)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_UnitPrice decimal(19, 4)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductPriceID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountPct decimal(7, 4)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountAmount decimal(19, 4)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalNet decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ChargeAmount decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTax decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalGross decimal(18, 2)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToAddressID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_RenewsSubscriptionID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodStart date
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodEnd date
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_FulfillmentStatus nvarchar(20)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ReversesOrderLineID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SourceBundleProductID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ParentOrderLineID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsRollupParent bit
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsQuantityOverridden bit
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SubscriptionID uniqueidentifier
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Description nvarchar(500)
    DECLARE @mjBizAppsOrdersOrderLines_ShipToOrganizationID_JournalEntryID uniqueidentifier
    DECLARE cascade_update_mjBizAppsOrdersOrderLines_ShipToOrganizationID_cursor CURSOR FOR
        SELECT [ID], [OrderHeaderID], [ProductID], [CompanyID], [LineNumber], [Quantity], [UnitPrice], [ProductPriceID], [DiscountPct], [DiscountAmount], [LineTotalNet], [ChargeAmount], [LineTax], [LineTotalGross], [ShipToAddressID], [ShipToOrganizationID], [ShipToPersonID], [RenewsSubscriptionID], [ServicePeriodStart], [ServicePeriodEnd], [FulfillmentStatus], [ReversesOrderLineID], [SourceBundleProductID], [ParentOrderLineID], [IsRollupParent], [IsQuantityOverridden], [SubscriptionID], [Description], [JournalEntryID]
        FROM [${mjSchema}_BizAppsOrders].[OrderLine]
        WHERE [ShipToOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersOrderLines_ShipToOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersOrderLines_ShipToOrganizationID_cursor INTO @mjBizAppsOrdersOrderLines_ShipToOrganizationIDID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_OrderHeaderID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_CompanyID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineNumber, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Quantity, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_UnitPrice, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductPriceID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountPct, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountAmount, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalNet, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ChargeAmount, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTax, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalGross, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToAddressID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToOrganizationID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToPersonID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_RenewsSubscriptionID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodStart, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodEnd, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_FulfillmentStatus, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ReversesOrderLineID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SourceBundleProductID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ParentOrderLineID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsRollupParent, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsQuantityOverridden, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SubscriptionID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Description, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_JournalEntryID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateOrderLine] @ID = @mjBizAppsOrdersOrderLines_ShipToOrganizationIDID, @OrderHeaderID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_OrderHeaderID, @ProductID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductID, @CompanyID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_CompanyID, @LineNumber = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineNumber, @Quantity = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Quantity, @UnitPrice = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_UnitPrice, @ProductPriceID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductPriceID, @DiscountPct = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountPct, @DiscountAmount = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountAmount, @LineTotalNet = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalNet, @ChargeAmount = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ChargeAmount, @LineTax = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTax, @LineTotalGross = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalGross, @ShipToAddressID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToAddressID, @ShipToOrganizationID_Clear = 1, @ShipToOrganizationID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToOrganizationID, @ShipToPersonID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToPersonID, @RenewsSubscriptionID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_RenewsSubscriptionID, @ServicePeriodStart = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodStart, @ServicePeriodEnd = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodEnd, @FulfillmentStatus = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_FulfillmentStatus, @ReversesOrderLineID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ReversesOrderLineID, @SourceBundleProductID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SourceBundleProductID, @ParentOrderLineID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ParentOrderLineID, @IsRollupParent = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsRollupParent, @IsQuantityOverridden = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsQuantityOverridden, @SubscriptionID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SubscriptionID, @Description = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Description, @JournalEntryID = @mjBizAppsOrdersOrderLines_ShipToOrganizationID_JournalEntryID

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersOrderLines_ShipToOrganizationID_cursor INTO @mjBizAppsOrdersOrderLines_ShipToOrganizationIDID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_OrderHeaderID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_CompanyID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineNumber, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Quantity, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_UnitPrice, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ProductPriceID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountPct, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_DiscountAmount, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalNet, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ChargeAmount, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTax, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_LineTotalGross, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToAddressID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToOrganizationID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ShipToPersonID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_RenewsSubscriptionID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodStart, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ServicePeriodEnd, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_FulfillmentStatus, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ReversesOrderLineID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SourceBundleProductID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_ParentOrderLineID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsRollupParent, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_IsQuantityOverridden, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_SubscriptionID, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_Description, @mjBizAppsOrdersOrderLines_ShipToOrganizationID_JournalEntryID
    END

    CLOSE cascade_update_mjBizAppsOrdersOrderLines_ShipToOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersOrderLines_ShipToOrganizationID_cursor
    
    -- Cascade update on PaymentHeader using cursor to call spUpdatePaymentHeader
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentNumber nvarchar(40)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReceivingCompanyID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDate date
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentTypeID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Amount decimal(18, 2)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProcessingFeeAmount decimal(18, 2)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_NetAmount decimal(18, 2)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentProviderID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentIntentID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDetailID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderChargeID nvarchar(100)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderRefundID nvarchar(100)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversesPaymentHeaderID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversalReason nvarchar(MAX)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Status nvarchar(20)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_JournalEntryID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Description nvarchar(MAX)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Notes nvarchar(MAX)
    DECLARE @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_IdempotencyKey nvarchar(200)
    DECLARE cascade_update_mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_cursor CURSOR FOR
        SELECT [ID], [PaymentNumber], [ReceivingCompanyID], [BillToPersonID], [BillToOrganizationID], [PaymentDate], [PaymentTypeID], [Amount], [ProcessingFeeAmount], [NetAmount], [PaymentProviderID], [PaymentIntentID], [PaymentDetailID], [ProviderChargeID], [ProviderRefundID], [ReversesPaymentHeaderID], [ReversalReason], [Status], [JournalEntryID], [Description], [Notes], [IdempotencyKey]
        FROM [${mjSchema}_BizAppsOrders].[PaymentHeader]
        WHERE [BillToOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_cursor INTO @mjBizAppsOrdersPaymentHeaders_BillToOrganizationIDID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentNumber, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReceivingCompanyID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToPersonID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDate, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentTypeID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Amount, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProcessingFeeAmount, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_NetAmount, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentProviderID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentIntentID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDetailID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderChargeID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderRefundID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversesPaymentHeaderID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversalReason, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Status, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_JournalEntryID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Description, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Notes, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_IdempotencyKey

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdatePaymentHeader] @ID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationIDID, @PaymentNumber = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentNumber, @ReceivingCompanyID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReceivingCompanyID, @BillToPersonID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToPersonID, @BillToOrganizationID_Clear = 1, @BillToOrganizationID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToOrganizationID, @PaymentDate = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDate, @PaymentTypeID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentTypeID, @Amount = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Amount, @ProcessingFeeAmount = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProcessingFeeAmount, @NetAmount = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_NetAmount, @PaymentProviderID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentProviderID, @PaymentIntentID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentIntentID, @PaymentDetailID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDetailID, @ProviderChargeID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderChargeID, @ProviderRefundID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderRefundID, @ReversesPaymentHeaderID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversesPaymentHeaderID, @ReversalReason = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversalReason, @Status = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Status, @JournalEntryID = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_JournalEntryID, @Description = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Description, @Notes = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Notes, @IdempotencyKey = @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_IdempotencyKey

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_cursor INTO @mjBizAppsOrdersPaymentHeaders_BillToOrganizationIDID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentNumber, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReceivingCompanyID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToPersonID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDate, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentTypeID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Amount, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProcessingFeeAmount, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_NetAmount, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentProviderID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentIntentID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_PaymentDetailID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderChargeID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ProviderRefundID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversesPaymentHeaderID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_ReversalReason, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Status, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_JournalEntryID, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Description, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_Notes, @mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_IdempotencyKey
    END

    CLOSE cascade_update_mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersPaymentHeaders_BillToOrganizationID_cursor
    
    -- Cascade update on PaymentIntent using cursor to call spUpdatePaymentIntent
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_PaymentProviderID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderIntentID nvarchar(100)
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Status nvarchar(30)
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Amount decimal(18, 2)
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_OrderHeaderID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderEventID nvarchar(100)
    DECLARE @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_LastEventAt datetimeoffset
    DECLARE cascade_update_mjBizAppsOrdersPaymentIntents_BillToOrganizationID_cursor CURSOR FOR
        SELECT [ID], [PaymentProviderID], [ProviderIntentID], [Status], [Amount], [OrderHeaderID], [BillToPersonID], [BillToOrganizationID], [ProviderEventID], [LastEventAt]
        FROM [${mjSchema}_BizAppsOrders].[PaymentIntent]
        WHERE [BillToOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersPaymentIntents_BillToOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersPaymentIntents_BillToOrganizationID_cursor INTO @mjBizAppsOrdersPaymentIntents_BillToOrganizationIDID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_PaymentProviderID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderIntentID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Status, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Amount, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_OrderHeaderID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToPersonID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderEventID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_LastEventAt

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdatePaymentIntent] @ID = @mjBizAppsOrdersPaymentIntents_BillToOrganizationIDID, @PaymentProviderID = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_PaymentProviderID, @ProviderIntentID = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderIntentID, @Status = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Status, @Amount = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Amount, @OrderHeaderID = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_OrderHeaderID, @BillToPersonID = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToPersonID, @BillToOrganizationID_Clear = 1, @BillToOrganizationID = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToOrganizationID, @ProviderEventID = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderEventID, @LastEventAt = @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_LastEventAt

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersPaymentIntents_BillToOrganizationID_cursor INTO @mjBizAppsOrdersPaymentIntents_BillToOrganizationIDID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_PaymentProviderID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderIntentID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Status, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_Amount, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_OrderHeaderID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToPersonID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_BillToOrganizationID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_ProviderEventID, @mjBizAppsOrdersPaymentIntents_BillToOrganizationID_LastEventAt
    END

    CLOSE cascade_update_mjBizAppsOrdersPaymentIntents_BillToOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersPaymentIntents_BillToOrganizationID_cursor
    
    -- Cascade update on PriceListAssignment using cursor to call spUpdatePriceListAssignment
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_PriceListID uniqueidentifier
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_OrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_PersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_Priority int
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_StartedAt datetimeoffset
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_EndedAt datetimeoffset
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_Status nvarchar(10)
    DECLARE @mjBizAppsOrdersPriceListAssignments_OrganizationID_Comments nvarchar(MAX)
    DECLARE cascade_update_mjBizAppsOrdersPriceListAssignments_OrganizationID_cursor CURSOR FOR
        SELECT [ID], [PriceListID], [OrganizationID], [PersonID], [Priority], [StartedAt], [EndedAt], [Status], [Comments]
        FROM [${mjSchema}_BizAppsOrders].[PriceListAssignment]
        WHERE [OrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersPriceListAssignments_OrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersPriceListAssignments_OrganizationID_cursor INTO @mjBizAppsOrdersPriceListAssignments_OrganizationIDID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_PriceListID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_OrganizationID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_PersonID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_Priority, @mjBizAppsOrdersPriceListAssignments_OrganizationID_StartedAt, @mjBizAppsOrdersPriceListAssignments_OrganizationID_EndedAt, @mjBizAppsOrdersPriceListAssignments_OrganizationID_Status, @mjBizAppsOrdersPriceListAssignments_OrganizationID_Comments

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersPriceListAssignments_OrganizationID_OrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdatePriceListAssignment] @ID = @mjBizAppsOrdersPriceListAssignments_OrganizationIDID, @PriceListID = @mjBizAppsOrdersPriceListAssignments_OrganizationID_PriceListID, @OrganizationID_Clear = 1, @OrganizationID = @mjBizAppsOrdersPriceListAssignments_OrganizationID_OrganizationID, @PersonID = @mjBizAppsOrdersPriceListAssignments_OrganizationID_PersonID, @Priority = @mjBizAppsOrdersPriceListAssignments_OrganizationID_Priority, @StartedAt = @mjBizAppsOrdersPriceListAssignments_OrganizationID_StartedAt, @EndedAt = @mjBizAppsOrdersPriceListAssignments_OrganizationID_EndedAt, @Status = @mjBizAppsOrdersPriceListAssignments_OrganizationID_Status, @Comments = @mjBizAppsOrdersPriceListAssignments_OrganizationID_Comments

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersPriceListAssignments_OrganizationID_cursor INTO @mjBizAppsOrdersPriceListAssignments_OrganizationIDID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_PriceListID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_OrganizationID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_PersonID, @mjBizAppsOrdersPriceListAssignments_OrganizationID_Priority, @mjBizAppsOrdersPriceListAssignments_OrganizationID_StartedAt, @mjBizAppsOrdersPriceListAssignments_OrganizationID_EndedAt, @mjBizAppsOrdersPriceListAssignments_OrganizationID_Status, @mjBizAppsOrdersPriceListAssignments_OrganizationID_Comments
    END

    CLOSE cascade_update_mjBizAppsOrdersPriceListAssignments_OrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersPriceListAssignments_OrganizationID_cursor
    
    -- Cascade update on PromotionCode using cursor to call spUpdatePromotionCode
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_PromotionID uniqueidentifier
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Code nvarchar(60)
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_MaxRedemptions int
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveFrom datetimeoffset
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveTo datetimeoffset
    DECLARE @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Status nvarchar(10)
    DECLARE cascade_update_mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_cursor CURSOR FOR
        SELECT [ID], [PromotionID], [Code], [MaxRedemptions], [AssignedOrganizationID], [AssignedPersonID], [EffectiveFrom], [EffectiveTo], [Status]
        FROM [${mjSchema}_BizAppsOrders].[PromotionCode]
        WHERE [AssignedOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_cursor INTO @mjBizAppsOrdersPromotionCodes_AssignedOrganizationIDID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_PromotionID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Code, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_MaxRedemptions, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedOrganizationID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedPersonID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveFrom, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveTo, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Status

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdatePromotionCode] @ID = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationIDID, @PromotionID = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_PromotionID, @Code = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Code, @MaxRedemptions = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_MaxRedemptions, @AssignedOrganizationID_Clear = 1, @AssignedOrganizationID = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedOrganizationID, @AssignedPersonID = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedPersonID, @EffectiveFrom = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveFrom, @EffectiveTo = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveTo, @Status = @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Status

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_cursor INTO @mjBizAppsOrdersPromotionCodes_AssignedOrganizationIDID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_PromotionID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Code, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_MaxRedemptions, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedOrganizationID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_AssignedPersonID, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveFrom, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_EffectiveTo, @mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_Status
    END

    CLOSE cascade_update_mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersPromotionCodes_AssignedOrganizationID_cursor
    
    -- Cascade update on StoredValueAccount using cursor to call spUpdateStoredValueAccount
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Code nvarchar(60)
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuingCompanyID uniqueidentifier
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_InitialAmount decimal(18, 2)
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_CurrentBalance decimal(18, 2)
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Status nvarchar(20)
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuedFromOrderLineID uniqueidentifier
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_ExpiresAt date
    DECLARE cascade_update_mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_cursor CURSOR FOR
        SELECT [ID], [Code], [IssuingCompanyID], [InitialAmount], [CurrentBalance], [Status], [IssuedFromOrderLineID], [BeneficiaryPersonID], [BeneficiaryOrganizationID], [ExpiresAt]
        FROM [${mjSchema}_BizAppsOrders].[StoredValueAccount]
        WHERE [BeneficiaryOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_cursor INTO @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationIDID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Code, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuingCompanyID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_InitialAmount, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_CurrentBalance, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Status, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuedFromOrderLineID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryPersonID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryOrganizationID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_ExpiresAt

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateStoredValueAccount] @ID = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationIDID, @Code = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Code, @IssuingCompanyID = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuingCompanyID, @InitialAmount = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_InitialAmount, @CurrentBalance = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_CurrentBalance, @Status = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Status, @IssuedFromOrderLineID = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuedFromOrderLineID, @BeneficiaryPersonID = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryPersonID, @BeneficiaryOrganizationID_Clear = 1, @BeneficiaryOrganizationID = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryOrganizationID, @ExpiresAt = @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_ExpiresAt

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_cursor INTO @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationIDID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Code, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuingCompanyID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_InitialAmount, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_CurrentBalance, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_Status, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_IssuedFromOrderLineID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryPersonID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_BeneficiaryOrganizationID, @mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_ExpiresAt
    END

    CLOSE cascade_update_mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersStoredValueAccounts_BeneficiaryOrganizationID_cursor
    
    -- Cascade update on Subscription using cursor to call spUpdateSubscription
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationIDID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionNumber nvarchar(40)
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CompanyID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_OrderLineID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionTypeID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProductID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_HolderOrganizationID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_BeneficiaryPersonID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_Status nvarchar(20)
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_StartDate date
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_TrialEndDate date
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CanceledAt datetimeoffset
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_EndDate date
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_AutoRenew bit
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_RenewalLeadDays int
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_PaymentProviderID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProviderSubscriptionID nvarchar(100)
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesFromSubscriptionID uniqueidentifier
    DECLARE @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesToSubscriptionID uniqueidentifier
    DECLARE cascade_update_mjBizAppsOrdersSubscriptions_HolderOrganizationID_cursor CURSOR FOR
        SELECT [ID], [SubscriptionNumber], [CompanyID], [OrderLineID], [SubscriptionTypeID], [ProductID], [HolderOrganizationID], [BeneficiaryPersonID], [Status], [StartDate], [TrialEndDate], [CanceledAt], [EndDate], [AutoRenew], [RenewalLeadDays], [PaymentProviderID], [ProviderSubscriptionID], [MigratesFromSubscriptionID], [MigratesToSubscriptionID]
        FROM [${mjSchema}_BizAppsOrders].[Subscription]
        WHERE [HolderOrganizationID] = @ID

    OPEN cascade_update_mjBizAppsOrdersSubscriptions_HolderOrganizationID_cursor
    FETCH NEXT FROM cascade_update_mjBizAppsOrdersSubscriptions_HolderOrganizationID_cursor INTO @mjBizAppsOrdersSubscriptions_HolderOrganizationIDID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionNumber, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CompanyID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_OrderLineID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionTypeID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProductID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_HolderOrganizationID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_BeneficiaryPersonID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_Status, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_StartDate, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_TrialEndDate, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CanceledAt, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_EndDate, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_AutoRenew, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_RenewalLeadDays, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_PaymentProviderID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProviderSubscriptionID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesFromSubscriptionID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesToSubscriptionID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set the FK field to NULL
        SET @mjBizAppsOrdersSubscriptions_HolderOrganizationID_HolderOrganizationID = NULL

        -- Call the update SP for the related entity
        EXEC [${mjSchema}_BizAppsOrders].[spUpdateSubscription] @ID = @mjBizAppsOrdersSubscriptions_HolderOrganizationIDID, @SubscriptionNumber = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionNumber, @CompanyID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CompanyID, @OrderLineID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_OrderLineID, @SubscriptionTypeID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionTypeID, @ProductID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProductID, @HolderOrganizationID_Clear = 1, @HolderOrganizationID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_HolderOrganizationID, @BeneficiaryPersonID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_BeneficiaryPersonID, @Status = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_Status, @StartDate = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_StartDate, @TrialEndDate = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_TrialEndDate, @CanceledAt = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CanceledAt, @EndDate = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_EndDate, @AutoRenew = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_AutoRenew, @RenewalLeadDays = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_RenewalLeadDays, @PaymentProviderID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_PaymentProviderID, @ProviderSubscriptionID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProviderSubscriptionID, @MigratesFromSubscriptionID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesFromSubscriptionID, @MigratesToSubscriptionID = @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesToSubscriptionID

        FETCH NEXT FROM cascade_update_mjBizAppsOrdersSubscriptions_HolderOrganizationID_cursor INTO @mjBizAppsOrdersSubscriptions_HolderOrganizationIDID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionNumber, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CompanyID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_OrderLineID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_SubscriptionTypeID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProductID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_HolderOrganizationID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_BeneficiaryPersonID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_Status, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_StartDate, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_TrialEndDate, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_CanceledAt, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_EndDate, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_AutoRenew, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_RenewalLeadDays, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_PaymentProviderID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_ProviderSubscriptionID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesFromSubscriptionID, @mjBizAppsOrdersSubscriptions_HolderOrganizationID_MigratesToSubscriptionID
    END

    CLOSE cascade_update_mjBizAppsOrdersSubscriptions_HolderOrganizationID_cursor
    DEALLOCATE cascade_update_mjBizAppsOrdersSubscriptions_HolderOrganizationID_cursor
    

    DELETE FROM
        [${flyway:defaultSchema}].[Organization]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteOrganization] TO [cdp_Integration];

/* Base View SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Relationships
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Relationship
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwRelationships]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwRelationships];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwRelationships]
AS
SELECT
    r.*,
    mjBizAppsCommonRelationshipType_RelationshipTypeID.[Name] AS [RelationshipType],
    mjBizAppsCommonPerson_FromPersonID.[DisplayName] AS [FromPerson],
    mjBizAppsCommonOrganization_FromOrganizationID.[Name] AS [FromOrganization],
    mjBizAppsCommonPerson_ToPersonID.[DisplayName] AS [ToPerson],
    mjBizAppsCommonOrganization_ToOrganizationID.[Name] AS [ToOrganization]
FROM
    [${flyway:defaultSchema}].[Relationship] AS r
INNER JOIN
    [${flyway:defaultSchema}].[RelationshipType] AS mjBizAppsCommonRelationshipType_RelationshipTypeID
  ON
    [r].[RelationshipTypeID] = mjBizAppsCommonRelationshipType_RelationshipTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_FromPersonID
  ON
    [r].[FromPersonID] = mjBizAppsCommonPerson_FromPersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_FromOrganizationID
  ON
    [r].[FromOrganizationID] = mjBizAppsCommonOrganization_FromOrganizationID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Person] AS mjBizAppsCommonPerson_ToPersonID
  ON
    [r].[ToPersonID] = mjBizAppsCommonPerson_ToPersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Organization] AS mjBizAppsCommonOrganization_ToOrganizationID
  ON
    [r].[ToOrganizationID] = mjBizAppsCommonOrganization_ToOrganizationID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: Permissions for vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spCreateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateRelationship]
    @ID uniqueidentifier = NULL,
    @RelationshipTypeID uniqueidentifier,
    @FromPersonID_Clear bit = 0,
    @FromPersonID uniqueidentifier = NULL,
    @FromOrganizationID_Clear bit = 0,
    @FromOrganizationID uniqueidentifier = NULL,
    @ToPersonID_Clear bit = 0,
    @ToPersonID uniqueidentifier = NULL,
    @ToOrganizationID_Clear bit = 0,
    @ToOrganizationID uniqueidentifier = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(255) = NULL,
    @StartDate_Clear bit = 0,
    @StartDate date = NULL,
    @EndDate_Clear bit = 0,
    @EndDate date = NULL,
    @Status nvarchar(50) = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Relationship]
            (
                [ID],
                [RelationshipTypeID],
                [FromPersonID],
                [FromOrganizationID],
                [ToPersonID],
                [ToOrganizationID],
                [Title],
                [StartDate],
                [EndDate],
                [Status],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @RelationshipTypeID,
                CASE WHEN @FromPersonID_Clear = 1 THEN NULL ELSE ISNULL(@FromPersonID, NULL) END,
                CASE WHEN @FromOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@FromOrganizationID, NULL) END,
                CASE WHEN @ToPersonID_Clear = 1 THEN NULL ELSE ISNULL(@ToPersonID, NULL) END,
                CASE WHEN @ToOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@ToOrganizationID, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, NULL) END,
                CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, NULL) END,
                ISNULL(@Status, 'Active'),
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Relationship]
            (
                [RelationshipTypeID],
                [FromPersonID],
                [FromOrganizationID],
                [ToPersonID],
                [ToOrganizationID],
                [Title],
                [StartDate],
                [EndDate],
                [Status],
                [Notes]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @RelationshipTypeID,
                CASE WHEN @FromPersonID_Clear = 1 THEN NULL ELSE ISNULL(@FromPersonID, NULL) END,
                CASE WHEN @FromOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@FromOrganizationID, NULL) END,
                CASE WHEN @ToPersonID_Clear = 1 THEN NULL ELSE ISNULL(@ToPersonID, NULL) END,
                CASE WHEN @ToOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@ToOrganizationID, NULL) END,
                CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, NULL) END,
                CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, NULL) END,
                CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, NULL) END,
                ISNULL(@Status, 'Active'),
                CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwRelationships] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spUpdateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateRelationship]
    @ID uniqueidentifier,
    @RelationshipTypeID uniqueidentifier = NULL,
    @FromPersonID_Clear bit = 0,
    @FromPersonID uniqueidentifier = NULL,
    @FromOrganizationID_Clear bit = 0,
    @FromOrganizationID uniqueidentifier = NULL,
    @ToPersonID_Clear bit = 0,
    @ToPersonID uniqueidentifier = NULL,
    @ToOrganizationID_Clear bit = 0,
    @ToOrganizationID uniqueidentifier = NULL,
    @Title_Clear bit = 0,
    @Title nvarchar(255) = NULL,
    @StartDate_Clear bit = 0,
    @StartDate date = NULL,
    @EndDate_Clear bit = 0,
    @EndDate date = NULL,
    @Status nvarchar(50) = NULL,
    @Notes_Clear bit = 0,
    @Notes nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Relationship]
    SET
        [RelationshipTypeID] = ISNULL(@RelationshipTypeID, [RelationshipTypeID]),
        [FromPersonID] = CASE WHEN @FromPersonID_Clear = 1 THEN NULL ELSE ISNULL(@FromPersonID, [FromPersonID]) END,
        [FromOrganizationID] = CASE WHEN @FromOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@FromOrganizationID, [FromOrganizationID]) END,
        [ToPersonID] = CASE WHEN @ToPersonID_Clear = 1 THEN NULL ELSE ISNULL(@ToPersonID, [ToPersonID]) END,
        [ToOrganizationID] = CASE WHEN @ToOrganizationID_Clear = 1 THEN NULL ELSE ISNULL(@ToOrganizationID, [ToOrganizationID]) END,
        [Title] = CASE WHEN @Title_Clear = 1 THEN NULL ELSE ISNULL(@Title, [Title]) END,
        [StartDate] = CASE WHEN @StartDate_Clear = 1 THEN NULL ELSE ISNULL(@StartDate, [StartDate]) END,
        [EndDate] = CASE WHEN @EndDate_Clear = 1 THEN NULL ELSE ISNULL(@EndDate, [EndDate]) END,
        [Status] = ISNULL(@Status, [Status]),
        [Notes] = CASE WHEN @Notes_Clear = 1 THEN NULL ELSE ISNULL(@Notes, [Notes]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwRelationships] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwRelationships]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Relationship table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateRelationship]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateRelationship];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateRelationship
ON [${flyway:defaultSchema}].[Relationship]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Relationship]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[Relationship] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Relationships
-- Item: spDeleteRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteRelationship]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[Relationship]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteRelationship] TO [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteRelationship] TO [cdp_Integration];

/* SQL text to delete unneeded entity fields (17 scoped entities) */
EXEC [${mjSchema}].[spDeleteUnneededEntityFields] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys', @EntityIDs='C2F418C4-8239-4486-B036-0BC4EAE4D24E,72E55425-8822-4E70-A075-116219CA5A5D,83A06268-2C96-400F-9CC8-21EEEF6654D1,8936D4D1-EB07-4EE8-A7AC-24131A1C48A8,FC529BC8-FF09-44A9-B454-26EAFDAC791B,4B5B0D73-496E-4CFA-92B9-3299A1E29E17,C96F379A-3E15-4DE5-BA94-4ECC90960C6D,EC59C50D-92BD-4247-80B1-51139BE93D35,66D82C24-9C9F-4CD6-B019-53C20274AB00,EB009F74-F4C5-4596-86C3-5893B9453200,7D7C4D5F-E410-4803-9762-A060C536C098,572AC8CE-8446-418B-979A-A7EE4E1F5AFD,CE97BF15-F7C6-4C50-A744-A89C714A4DDD,9E638C8F-6447-45D9-9137-B24E1047BCE5,22E31028-E862-424B-8C10-C167B2C9E304,21B78371-132C-4507-AED8-D44E366468F2,E9B55146-3351-440C-AD47-FD4DE05BDA05';

/* SQL text to insert 5 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '15085e8a-f107-4d09-8e95-d809d886a855' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'RootParentActivityID')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '15085e8a-f107-4d09-8e95-d809d886a855',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 27,
            'RootParentActivityID',
            'Root Parent Activity ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'e1b95f39-7f1d-4359-9d83-e56903210bed' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ParentActivityIDDepth')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'e1b95f39-7f1d-4359-9d83-e56903210bed',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 28,
            'ParentActivityIDDepth',
            'Parent Activity ID Depth',
            NULL,
            'int',
            4,
            10,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '26d7d771-7b58-4efe-bda9-3e332ca8b0e5' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ParentActivityIDPath')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '26d7d771-7b58-4efe-bda9-3e332ca8b0e5',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 29,
            'ParentActivityIDPath',
            'Parent Activity ID Path',
            NULL,
            'nvarchar',
            -1,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '6498dc84-5a50-43aa-a894-af0217adeb70' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ParentActivityIDIsLeaf')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '6498dc84-5a50-43aa-a894-af0217adeb70',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 30,
            'ParentActivityIDIsLeaf',
            'Parent Activity ID Is Leaf',
            NULL,
            'bit',
            1,
            1,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c3b07ce4-a244-4c3d-bd57-eed427a44d23' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ParentActivityIDChildCount')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'c3b07ce4-a244-4c3d-bd57-eed427a44d23',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 31,
            'ParentActivityIDChildCount',
            'Parent Activity ID Child Count',
            NULL,
            'int',
            4,
            10,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

/* SQL text to update existing entity fields from schema (17 scoped entities) */
EXEC [${mjSchema}].[spUpdateExistingEntityFieldsFromSchema] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys', @EntityIDs='C2F418C4-8239-4486-B036-0BC4EAE4D24E,72E55425-8822-4E70-A075-116219CA5A5D,83A06268-2C96-400F-9CC8-21EEEF6654D1,8936D4D1-EB07-4EE8-A7AC-24131A1C48A8,FC529BC8-FF09-44A9-B454-26EAFDAC791B,4B5B0D73-496E-4CFA-92B9-3299A1E29E17,C96F379A-3E15-4DE5-BA94-4ECC90960C6D,EC59C50D-92BD-4247-80B1-51139BE93D35,66D82C24-9C9F-4CD6-B019-53C20274AB00,EB009F74-F4C5-4596-86C3-5893B9453200,7D7C4D5F-E410-4803-9762-A060C536C098,572AC8CE-8446-418B-979A-A7EE4E1F5AFD,CE97BF15-F7C6-4C50-A744-A89C714A4DDD,9E638C8F-6447-45D9-9137-B24E1047BCE5,22E31028-E862-424B-8C10-C167B2C9E304,21B78371-132C-4507-AED8-D44E366468F2,E9B55146-3351-440C-AD47-FD4DE05BDA05';

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].[spSetDefaultColumnWidthWhereNeeded] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys';

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'E13550D7-7D7E-41D0-A80D-3A19801854B2'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'AF9411C8-092E-4CE2-9154-5233819CA56D'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'D4794101-7846-413E-8858-6EB0C756206F'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '8673C6DF-0291-480E-9A7E-1D3A05F1BD99'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'D70B6EE4-51D2-40F5-A8FA-7ECD8F1E6477'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = '21B78371-132C-4507-AED8-D44E366468F2'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set field properties for entity */

               UPDATE [${mjSchema}].[EntityField]
               SET IsNameField = 1
               WHERE ID = '0C5459B1-2A7C-4B61-BB47-66F11E8DA353'
               AND AutoUpdateIsNameField = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '7D436256-F1BA-4C03-8F90-F368E1CCAF0E'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '0C5459B1-2A7C-4B61-BB47-66F11E8DA353'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '55B36A7F-5704-4F3E-8271-FF127FF080E0'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = '64DD388E-5094-417D-8F4B-EA5DE773D736'
               AND AutoUpdateDefaultInView = 1;

               UPDATE [${mjSchema}].[EntityField]
               SET DefaultInView = 1
               WHERE ID = 'F4D298BF-193C-4AB9-B144-65B5A851BD5C'
               AND AutoUpdateDefaultInView = 1;

            UPDATE [${mjSchema}].[Entity]
            SET AllowUserSearchAPI = 0
            WHERE ID = '72E55425-8822-4E70-A075-116219CA5A5D'
            AND AutoUpdateAllowUserSearchAPI = 1;

/* Set categories for 16 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E1B36B74-715B-4E9D-9258-614FF7101FFE' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivitySyncConnectionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync Connection',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '59023ECB-98AD-4950-B328-C1384AA89E32' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivitySyncConnection 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Configuration',
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync Connection Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8673C6DF-0291-480E-9A7E-1D3A05F1BD99' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Name 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Definition',
   GeneratedFormSection = 'Category',
   DisplayName = 'Rule Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F1702A65-5058-4203-81FD-7BCA32FA800D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.IsEnabled 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E13550D7-7D7E-41D0-A80D-3A19801854B2' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Sequence 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AF9411C8-092E-4CE2-9154-5233819CA56D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Action 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Rule Definition',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D4794101-7846-413E-8858-6EB0C756206F' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivityTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Criteria',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '551E82A3-0C8C-42A1-82FE-C0194883E318' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.ActivityType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Criteria',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D70B6EE4-51D2-40F5-A8FA-7ECD8F1E6477' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Direction 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Criteria',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '082DF2CA-E47E-4FF3-969A-A6B8D090A39A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.DateFrom 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Window',
   GeneratedFormSection = 'Category',
   DisplayName = 'Start Date',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4A9BD72C-C439-457D-8F76-B655F8C7CBF6' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.DateTo 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Window',
   GeneratedFormSection = 'Category',
   DisplayName = 'End Date',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '09A7CD6F-F752-4B2A-A91F-09FC926E4CC3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.IncludeAttachments 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Sync Criteria',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1B5E756E-B7B5-43C8-BCC9-D4219331D68A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.Filter 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Advanced Filtering',
   GeneratedFormSection = 'Category',
   DisplayName = 'Filter JSON',
   ExtendedType = 'Code',
   CodeType = 'Other'
WHERE 
   ID = 'AF4D4277-FA14-4AB6-84BD-A232458C9783' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '552E9653-CD6D-4AE2-9ECE-97D1F826A059' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activity Sync Rules.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A29D4B01-5A2B-466B-84BD-BFF484743805' AND AutoUpdateCategory = 1;

/* Set entity icon to fa fa-sync-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-sync-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '21B78371-132C-4507-AED8-D44E366468F2';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('45f3b824-e993-4a00-9870-f35d9d385b0b', '21B78371-132C-4507-AED8-D44E366468F2', 'FieldCategoryInfo', '{"Sync Configuration":{"icon":"fa fa-link","description":"Links and references to the parent activity sync connection"},"Rule Definition":{"icon":"fa fa-sliders-h","description":"Core rule settings including naming, activation, and evaluation order"},"Sync Criteria":{"icon":"fa fa-filter","description":"Specific criteria for filtering activities, including type, direction, and attachments"},"Sync Window":{"icon":"fa fa-calendar-alt","description":"Time-based boundaries for the synchronization process"},"Advanced Filtering":{"icon":"fa fa-code","description":"Advanced technical filters defined via JSON"},"System Metadata":{"icon":"fa fa-cog","description":"System-managed audit and tracking fields"}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('5b47c06a-5356-4ba3-8be3-10618b248db5', '21B78371-132C-4507-AED8-D44E366468F2', 'FieldCategoryIcons', '{"Sync Configuration":"fa fa-link","Rule Definition":"fa fa-sliders-h","Sync Criteria":"fa fa-filter","Sync Window":"fa fa-calendar-alt","Advanced Filtering":"fa fa-code","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE());

/* Set categories for 31 fields */

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A77E31C4-88DF-4A47-8D5E-66D9D772027A' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ActivityTypeID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '79A0584E-E51E-44ED-86C0-E10087BE3D70' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.StartedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Timeline',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '7D436256-F1BA-4C03-8F90-F368E1CCAF0E' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.EndedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Timeline',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '68AD9D59-4F16-4E52-A13A-93E2664BFEFF' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Title 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0C5459B1-2A7C-4B61-BB47-66F11E8DA353' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Description 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A874BB02-9463-4C6C-A9E1-6F8E43E8190D' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Direction 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '55B36A7F-5704-4F3E-8271-FF127FF080E0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Status 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '64DD388E-5094-417D-8F4B-EA5DE773D736' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Outcome 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F143D296-772A-4E87-81EE-7D542C5AE6D0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Visibility 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Access',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '36846E42-D608-46B0-B914-63B113BDDB48' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Source 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '59ED2435-0A40-48DF-B907-8ED46BDE7594' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.SourceSystem 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D52954AD-1668-4D93-8EB5-0A9430E9DD46' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ExternalID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1DD06BDA-9A1A-499E-921A-75F7421E8886' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ExternalThreadID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5387BCAE-7CF0-417A-9A90-00A724980CD8' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ParentActivityID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationships',
   GeneratedFormSection = 'Category',
   DisplayName = 'Parent Activity',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'A26E5B16-23BF-4081-990F-B72C6CF59DB9' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.LoggedByUserID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Access',
   GeneratedFormSection = 'Category',
   DisplayName = 'Logged By User',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E9908FFA-72F7-4F3C-99B1-18697CFA92A2' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Location 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location',
   GeneratedFormSection = 'Category',
   ExtendedType = 'GeoAddress',
   CodeType = NULL
WHERE 
   ID = 'BE249655-29F6-4B9F-9C65-B75818F1D943' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.AddressID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4D848BC2-B12B-4ECC-A5AC-11519B3962C3' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ActivitySyncConnectionID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync Connection',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5D5AA28B-8CBC-4A15-A10B-F4B7E9DFEF86' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Details 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '1B2F4190-4AAB-4477-A858-EF64945F9C24' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.__mj_CreatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '929AB16D-299D-4942-B2A9-B907C0273122' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.__mj_UpdatedAt 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C70A8646-F64D-40A8-BA96-6DAC95F980D0' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ActivityType 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Activity Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Activity Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F4D298BF-193C-4AB9-B144-65B5A851BD5C' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.LoggedByUser 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Security and Access',
   GeneratedFormSection = 'Category',
   DisplayName = 'Logged By',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AFAC551B-EA9A-4BDF-9F54-BB7B47E3E79F' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.Address 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Location',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Details',
   ExtendedType = 'GeoAddress',
   CodeType = NULL
WHERE 
   ID = '6060D1AD-ED2C-4465-B52A-DF4C07783CF2' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ActivitySyncConnection 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'System Metadata',
   GeneratedFormSection = 'Category',
   DisplayName = 'Sync Connection Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4EE99682-5B0B-4481-A03A-9EA576739044' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.RootParentActivityID 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationships',
   GeneratedFormSection = 'Category',
   DisplayName = 'Root Parent Activity',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '15085E8A-F107-4D09-8E95-D809D886A855' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ParentActivityIDDepth 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationships',
   GeneratedFormSection = 'Category',
   DisplayName = 'Hierarchy Depth',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E1B95F39-7F1D-4359-9D83-E56903210BED' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ParentActivityIDPath 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationships',
   GeneratedFormSection = 'Category',
   DisplayName = 'Hierarchy Path',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '26D7D771-7B58-4EFE-BDA9-3E332CA8B0E5' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ParentActivityIDIsLeaf 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationships',
   GeneratedFormSection = 'Category',
   DisplayName = 'Is Leaf',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '6498DC84-5A50-43AA-A894-AF0217ADEB70' AND AutoUpdateCategory = 1;

-- UPDATE Entity Field Category Info MJ_BizApps_Common: Activities.ParentActivityIDChildCount 
UPDATE [${mjSchema}].[EntityField]
SET 
   Category = 'Relationships',
   GeneratedFormSection = 'Category',
   DisplayName = 'Child Count',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C3B07CE4-A244-4C3D-BD57-EED427A44D23' AND AutoUpdateCategory = 1;

/* Set SupportsGeoCoding = true for MJ_BizApps_Common: Activities */

            UPDATE [${mjSchema}].[Entity]
            SET [SupportsGeoCoding] = 1
            WHERE [ID] = '72E55425-8822-4E70-A075-116219CA5A5D' AND [AutoUpdateSupportsGeoCoding] = 1;

/* Set entity icon to fa fa-calendar-alt */

               UPDATE [${mjSchema}].[Entity]
               SET [Icon] = 'fa fa-calendar-alt', [__mj_UpdatedAt] = GETUTCDATE()
               WHERE [ID] = '72E55425-8822-4E70-A075-116219CA5A5D';

/* Insert FieldCategoryInfo setting for entity */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('e045808a-1a0b-482c-ada4-78b12c3bd02a', '72E55425-8822-4E70-A075-116219CA5A5D', 'FieldCategoryInfo', '{"Activity Details":{"icon":"fa fa-info-circle","description":"Core information regarding the nature, status, and content of the interaction."},"Timeline":{"icon":"fa fa-clock","description":"Temporal data defining when the interaction occurred and its duration."},"Location":{"icon":"fa fa-map-marker-alt","description":"Physical or virtual location details for the activity."},"Relationships":{"icon":"fa fa-sitemap","description":"Hierarchical structure and links to related activities."},"Security and Access":{"icon":"fa fa-shield-alt","description":"Permissions, visibility settings, and user ownership information."},"System Metadata":{"icon":"fa fa-cog","description":"Technical audit, synchronization, and system-managed fields."}}', GETUTCDATE(), GETUTCDATE());

/* Insert FieldCategoryIcons setting (legacy) */

               INSERT INTO [${mjSchema}].[EntitySetting] ([ID], [EntityID], [Name], [Value], [__mj_CreatedAt], [__mj_UpdatedAt])
               VALUES ('9a3c5a2a-36be-41c9-9eaa-97e93797e654', '72E55425-8822-4E70-A075-116219CA5A5D', 'FieldCategoryIcons', '{"Activity Details":"fa fa-info-circle","Timeline":"fa fa-clock","Location":"fa fa-map-marker-alt","Relationships":"fa fa-sitemap","Security and Access":"fa fa-shield-alt","System Metadata":"fa fa-cog"}', GETUTCDATE(), GETUTCDATE());

/* Index for Foreign Keys for Activity */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key ActivityTypeID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_ActivityTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ActivityTypeID ON [${flyway:defaultSchema}].[Activity] ([ActivityTypeID]);

-- Index for foreign key ParentActivityID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_ParentActivityID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ParentActivityID ON [${flyway:defaultSchema}].[Activity] ([ParentActivityID]);

-- Index for foreign key LoggedByUserID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_LoggedByUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_LoggedByUserID ON [${flyway:defaultSchema}].[Activity] ([LoggedByUserID]);

-- Index for foreign key AddressID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_AddressID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_AddressID ON [${flyway:defaultSchema}].[Activity] ([AddressID]);

-- Index for foreign key ActivitySyncConnectionID in table Activity
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Activity_ActivitySyncConnectionID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}].[Activity]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ActivitySyncConnectionID ON [${flyway:defaultSchema}].[Activity] ([ActivitySyncConnectionID]);

/* SQL text to update entity field related entity name field map for entity field ID A26E5B16-23BF-4081-990F-B72C6CF59DB9 */
EXEC [${mjSchema}].[spUpdateEntityFieldRelatedEntityNameFieldMap] @EntityFieldID='A26E5B16-23BF-4081-990F-B72C6CF59DB9', @RelatedEntityNameFieldMap='ParentActivity';

/* Hierarchy Metadata Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetHierarchyMeta
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- HIERARCHY METADATA FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentActivityID],
            0 AS [Depth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentActivityID],
            c.[Depth] + 1 AS [Depth],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentActivityID]
        WHERE
            c.[Depth] < 100
    )
    SELECT TOP 1
        a.[ID] AS [RootID],
        (SELECT MAX([Depth]) FROM CTE_Ancestors) AS [Depth],
        (SELECT TOP 1 [Path] FROM CTE_Ancestors ORDER BY [Depth] DESC) AS [Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = @RecordID) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = @RecordID) AS [ChildCount]
    FROM
        CTE_Ancestors a
    WHERE
        a.[ParentActivityID] IS NULL OR @ParentID IS NULL
    ORDER BY
        a.[Depth] DESC
);
GO

/* Descendants Traversal Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetDescendants
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- DESCENDANTS FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetDescendants]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetDescendants];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetDescendants]
(
    @RootID uniqueidentifier,
    @MaxDepth INT = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Descendants AS (
        SELECT
            [ID],
            [ParentActivityID],
            0 AS [RelativeDepth],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = @RootID

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentActivityID],
            p.[RelativeDepth] + 1 AS [RelativeDepth],
            CAST(p.[Path] + CAST(c.[ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity] c
        INNER JOIN
            CTE_Descendants p ON c.[ParentActivityID] = p.[ID]
        WHERE
            (@MaxDepth IS NULL OR p.[RelativeDepth] < @MaxDepth)
            AND p.[RelativeDepth] < 100
    )
    SELECT
        d.[ID] AS [ID],
        d.[RelativeDepth] AS [Depth],
        d.[Path],
        CAST(CASE WHEN EXISTS (SELECT 1 FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = d.[ID]) THEN 0 ELSE 1 END AS BIT) AS [IsLeaf],
        (SELECT COUNT(1) FROM [${flyway:defaultSchema}].[Activity] WHERE [ParentActivityID] = d.[ID]) AS [ChildCount]
    FROM
        CTE_Descendants d
);
GO

/* Ancestors Traversal Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetAncestors
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ANCESTORS FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetAncestors]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetAncestors];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetAncestors]
(
    @RecordID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_Ancestors AS (
        SELECT
            [ID],
            [ParentActivityID],
            0 AS [LevelUp],
            CAST('/' + CAST([ID] AS NVARCHAR(36)) + '/' AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = @RecordID

        UNION ALL

        SELECT
            p.[ID],
            p.[ParentActivityID],
            c.[LevelUp] + 1 AS [LevelUp],
            CAST('/' + CAST(p.[ID] AS NVARCHAR(36)) + c.[Path] AS NVARCHAR(MAX)) AS [Path]
        FROM
            [${flyway:defaultSchema}].[Activity] p
        INNER JOIN
            CTE_Ancestors c ON p.[ID] = c.[ParentActivityID]
        WHERE
            c.[LevelUp] < 100
    )
    SELECT
        a.[ID] AS [ID],
        a.[LevelUp],
        a.[Path]
    FROM
        CTE_Ancestors a
);
GO

/* Root ID Function SQL for MJ_BizApps_Common: Activities.ParentActivityID */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: fnActivityParentActivityID_GetRootID
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
------------------------------------------------------------
----- ROOT ID FUNCTION FOR: [Activity].[ParentActivityID]
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[fnActivityParentActivityID_GetRootID]', 'IF') IS NOT NULL
    DROP FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetRootID];
GO

CREATE FUNCTION [${flyway:defaultSchema}].[fnActivityParentActivityID_GetRootID]
(
    @RecordID uniqueidentifier,
    @ParentID uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_RootParent AS (
        SELECT
            [ID],
            [ParentActivityID],
            [ID] AS [RootParentID],
            0 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Activity]
        WHERE
            [ID] = COALESCE(@ParentID, @RecordID)

        UNION ALL

        SELECT
            c.[ID],
            c.[ParentActivityID],
            c.[ID] AS [RootParentID],
            p.[Depth] + 1 AS [Depth]
        FROM
            [${flyway:defaultSchema}].[Activity] c
        INNER JOIN
            CTE_RootParent p ON c.[ID] = p.[ParentActivityID]
        WHERE
            p.[Depth] < 100
    )
    SELECT TOP 1
        [RootParentID] AS RootID
    FROM
        CTE_RootParent
    WHERE
        [ParentActivityID] IS NULL
    ORDER BY
        [RootParentID]
);
GO

/* Base View SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: vwActivities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ_BizApps_Common: Activities
-----               SCHEMA:      ${flyway:defaultSchema}
-----               BASE TABLE:  Activity
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[vwActivities]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}].[vwActivities];
GO

CREATE VIEW [${flyway:defaultSchema}].[vwActivities]
AS
SELECT
    a.*,
    mjBizAppsCommonActivityType_ActivityTypeID.[Name] AS [ActivityType],
    mjBizAppsCommonActivity_ParentActivityID.[Title] AS [ParentActivity],
    MJUser_LoggedByUserID.[Name] AS [LoggedByUser],
    mjBizAppsCommonAddress_AddressID.[Line1] AS [Address],
    mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[Name] AS [ActivitySyncConnection],
    ${mjSchema}_rgc.[Latitude] AS [${mjSchema}_Latitude],
    ${mjSchema}_rgc.[Longitude] AS [${mjSchema}_Longitude],
    hier_ParentActivityID.RootID AS [RootParentActivityID],
    hier_ParentActivityID.Depth AS [ParentActivityIDDepth],
    hier_ParentActivityID.Path AS [ParentActivityIDPath],
    hier_ParentActivityID.IsLeaf AS [ParentActivityIDIsLeaf],
    hier_ParentActivityID.ChildCount AS [ParentActivityIDChildCount]
FROM
    [${flyway:defaultSchema}].[Activity] AS a
INNER JOIN
    [${flyway:defaultSchema}].[ActivityType] AS mjBizAppsCommonActivityType_ActivityTypeID
  ON
    [a].[ActivityTypeID] = mjBizAppsCommonActivityType_ActivityTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Activity] AS mjBizAppsCommonActivity_ParentActivityID
  ON
    [a].[ParentActivityID] = mjBizAppsCommonActivity_ParentActivityID.[ID]
INNER JOIN
    [${mjSchema}].[User] AS MJUser_LoggedByUserID
  ON
    [a].[LoggedByUserID] = MJUser_LoggedByUserID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[Address] AS mjBizAppsCommonAddress_AddressID
  ON
    [a].[AddressID] = mjBizAppsCommonAddress_AddressID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}].[ActivitySyncConnection] AS mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID
  ON
    [a].[ActivitySyncConnectionID] = mjBizAppsCommonActivitySyncConnection_ActivitySyncConnectionID.[ID]
LEFT OUTER JOIN
    [${mjSchema}].[vwRecordGeoCodes] AS ${mjSchema}_rgc
  ON
    ${mjSchema}_rgc.[EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D'
    AND ${mjSchema}_rgc.[RecordID] = CAST([a].[ID] AS NVARCHAR(450))
    AND ${mjSchema}_rgc.[LocationType] = 'Primary'
OUTER APPLY
    [${flyway:defaultSchema}].[fnActivityParentActivityID_GetHierarchyMeta]([a].[ID], [a].[ParentActivityID]) AS hier_ParentActivityID
GO
GRANT SELECT ON [${flyway:defaultSchema}].[vwActivities] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* Base View Permissions SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: Permissions for vwActivities
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}].[vwActivities] TO [cdp_UI], [cdp_Developer], [cdp_Integration];

/* spCreate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spCreateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Activity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spCreateActivity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spCreateActivity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spCreateActivity]
    @ID uniqueidentifier = NULL,
    @ActivityTypeID uniqueidentifier,
    @StartedAt datetimeoffset,
    @EndedAt_Clear bit = 0,
    @EndedAt datetimeoffset = NULL,
    @Title nvarchar(500),
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Direction nvarchar(20),
    @Status nvarchar(20) = NULL,
    @Outcome_Clear bit = 0,
    @Outcome nvarchar(40) = NULL,
    @Visibility nvarchar(20) = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL,
    @ExternalID_Clear bit = 0,
    @ExternalID nvarchar(400) = NULL,
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @ParentActivityID_Clear bit = 0,
    @ParentActivityID uniqueidentifier = NULL,
    @LoggedByUserID uniqueidentifier,
    @Location_Clear bit = 0,
    @Location nvarchar(500) = NULL,
    @AddressID_Clear bit = 0,
    @AddressID uniqueidentifier = NULL,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Details_Clear bit = 0,
    @Details nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)

    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}].[Activity]
            (
                [ID],
                [ActivityTypeID],
                [StartedAt],
                [EndedAt],
                [Title],
                [Description],
                [Direction],
                [Status],
                [Outcome],
                [Visibility],
                [Source],
                [SourceSystem],
                [ExternalID],
                [ExternalThreadID],
                [ParentActivityID],
                [LoggedByUserID],
                [Location],
                [AddressID],
                [ActivitySyncConnectionID],
                [Details]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @ActivityTypeID,
                @StartedAt,
                CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, NULL) END,
                @Title,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @Direction,
                ISNULL(@Status, 'Logged'),
                CASE WHEN @Outcome_Clear = 1 THEN NULL ELSE ISNULL(@Outcome, NULL) END,
                ISNULL(@Visibility, 'Internal'),
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END,
                CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, NULL) END,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @ParentActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ParentActivityID, NULL) END,
                @LoggedByUserID,
                CASE WHEN @Location_Clear = 1 THEN NULL ELSE ISNULL(@Location, NULL) END,
                CASE WHEN @AddressID_Clear = 1 THEN NULL ELSE ISNULL(@AddressID, NULL) END,
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                CASE WHEN @Details_Clear = 1 THEN NULL ELSE ISNULL(@Details, NULL) END
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}].[Activity]
            (
                [ActivityTypeID],
                [StartedAt],
                [EndedAt],
                [Title],
                [Description],
                [Direction],
                [Status],
                [Outcome],
                [Visibility],
                [Source],
                [SourceSystem],
                [ExternalID],
                [ExternalThreadID],
                [ParentActivityID],
                [LoggedByUserID],
                [Location],
                [AddressID],
                [ActivitySyncConnectionID],
                [Details]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ActivityTypeID,
                @StartedAt,
                CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, NULL) END,
                @Title,
                CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, NULL) END,
                @Direction,
                ISNULL(@Status, 'Logged'),
                CASE WHEN @Outcome_Clear = 1 THEN NULL ELSE ISNULL(@Outcome, NULL) END,
                ISNULL(@Visibility, 'Internal'),
                ISNULL(@Source, 'Manual'),
                CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, NULL) END,
                CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, NULL) END,
                CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, NULL) END,
                CASE WHEN @ParentActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ParentActivityID, NULL) END,
                @LoggedByUserID,
                CASE WHEN @Location_Clear = 1 THEN NULL ELSE ISNULL(@Location, NULL) END,
                CASE WHEN @AddressID_Clear = 1 THEN NULL ELSE ISNULL(@AddressID, NULL) END,
                CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, NULL) END,
                CASE WHEN @Details_Clear = 1 THEN NULL ELSE ISNULL(@Details, NULL) END
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}].[vwActivities] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivity] TO [cdp_Developer], [cdp_Integration];

/* spCreate Permissions for MJ_BizApps_Common: Activities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spCreateActivity] TO [cdp_Developer], [cdp_Integration];

/* spUpdate SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spUpdateActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Activity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spUpdateActivity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spUpdateActivity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spUpdateActivity]
    @ID uniqueidentifier,
    @ActivityTypeID uniqueidentifier = NULL,
    @StartedAt datetimeoffset = NULL,
    @EndedAt_Clear bit = 0,
    @EndedAt datetimeoffset = NULL,
    @Title nvarchar(500) = NULL,
    @Description_Clear bit = 0,
    @Description nvarchar(MAX) = NULL,
    @Direction nvarchar(20) = NULL,
    @Status nvarchar(20) = NULL,
    @Outcome_Clear bit = 0,
    @Outcome nvarchar(40) = NULL,
    @Visibility nvarchar(20) = NULL,
    @Source nvarchar(20) = NULL,
    @SourceSystem_Clear bit = 0,
    @SourceSystem nvarchar(80) = NULL,
    @ExternalID_Clear bit = 0,
    @ExternalID nvarchar(400) = NULL,
    @ExternalThreadID_Clear bit = 0,
    @ExternalThreadID nvarchar(400) = NULL,
    @ParentActivityID_Clear bit = 0,
    @ParentActivityID uniqueidentifier = NULL,
    @LoggedByUserID uniqueidentifier = NULL,
    @Location_Clear bit = 0,
    @Location nvarchar(500) = NULL,
    @AddressID_Clear bit = 0,
    @AddressID uniqueidentifier = NULL,
    @ActivitySyncConnectionID_Clear bit = 0,
    @ActivitySyncConnectionID uniqueidentifier = NULL,
    @Details_Clear bit = 0,
    @Details nvarchar(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Activity]
    SET
        [ActivityTypeID] = ISNULL(@ActivityTypeID, [ActivityTypeID]),
        [StartedAt] = ISNULL(@StartedAt, [StartedAt]),
        [EndedAt] = CASE WHEN @EndedAt_Clear = 1 THEN NULL ELSE ISNULL(@EndedAt, [EndedAt]) END,
        [Title] = ISNULL(@Title, [Title]),
        [Description] = CASE WHEN @Description_Clear = 1 THEN NULL ELSE ISNULL(@Description, [Description]) END,
        [Direction] = ISNULL(@Direction, [Direction]),
        [Status] = ISNULL(@Status, [Status]),
        [Outcome] = CASE WHEN @Outcome_Clear = 1 THEN NULL ELSE ISNULL(@Outcome, [Outcome]) END,
        [Visibility] = ISNULL(@Visibility, [Visibility]),
        [Source] = ISNULL(@Source, [Source]),
        [SourceSystem] = CASE WHEN @SourceSystem_Clear = 1 THEN NULL ELSE ISNULL(@SourceSystem, [SourceSystem]) END,
        [ExternalID] = CASE WHEN @ExternalID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalID, [ExternalID]) END,
        [ExternalThreadID] = CASE WHEN @ExternalThreadID_Clear = 1 THEN NULL ELSE ISNULL(@ExternalThreadID, [ExternalThreadID]) END,
        [ParentActivityID] = CASE WHEN @ParentActivityID_Clear = 1 THEN NULL ELSE ISNULL(@ParentActivityID, [ParentActivityID]) END,
        [LoggedByUserID] = ISNULL(@LoggedByUserID, [LoggedByUserID]),
        [Location] = CASE WHEN @Location_Clear = 1 THEN NULL ELSE ISNULL(@Location, [Location]) END,
        [AddressID] = CASE WHEN @AddressID_Clear = 1 THEN NULL ELSE ISNULL(@AddressID, [AddressID]) END,
        [ActivitySyncConnectionID] = CASE WHEN @ActivitySyncConnectionID_Clear = 1 THEN NULL ELSE ISNULL(@ActivitySyncConnectionID, [ActivitySyncConnectionID]) END,
        [Details] = CASE WHEN @Details_Clear = 1 THEN NULL ELSE ISNULL(@Details, [Details]) END
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}].[vwActivities] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}].[vwActivities]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivity] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Activity table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[trgUpdateActivity]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}].[trgUpdateActivity];
GO
CREATE TRIGGER [${flyway:defaultSchema}].trgUpdateActivity
ON [${flyway:defaultSchema}].[Activity]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}].[Activity]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}].[Activity] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO

/* spUpdate Permissions for MJ_BizApps_Common: Activities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spUpdateActivity] TO [cdp_Developer], [cdp_Integration];

/* spDelete SQL for MJ_BizApps_Common: Activities */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ_BizApps_Common: Activities
-- Item: spDeleteActivity
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Activity
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}].[spDeleteActivity]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}].[spDeleteActivity];
GO

CREATE PROCEDURE [${flyway:defaultSchema}].[spDeleteActivity]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}].[Activity]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivity] TO [cdp_Developer], [cdp_Integration];

/* spDelete Permissions for MJ_BizApps_Common: Activities */

GRANT EXECUTE ON [${flyway:defaultSchema}].[spDeleteActivity] TO [cdp_Developer], [cdp_Integration];

/* SQL text to delete unneeded entity fields (1 scoped entities) */
EXEC [${mjSchema}].[spDeleteUnneededEntityFields] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys', @EntityIDs='72E55425-8822-4E70-A075-116219CA5A5D';

/* SQL text to insert 3 new entity field(s) */

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '7dad09c3-0203-4de1-8655-d882d3bc5875' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = 'ParentActivity')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            '7dad09c3-0203-4de1-8655-d882d3bc5875',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 24,
            'ParentActivity',
            'Parent Activity',
            NULL,
            'nvarchar',
            1000,
            0,
            0,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'c5ad14b9-deb5-41ae-b1e7-0e928085ae39' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = '${mjSchema}_Latitude')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'c5ad14b9-deb5-41ae-b1e7-0e928085ae39',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 28,
            '${mjSchema}_Latitude',
            'Mj Latitude',
            NULL,
            'decimal',
            9,
            10,
            6,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

      IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'baa8c311-ee92-4f3b-bb5f-000810af4894' OR (EntityID = '72E55425-8822-4E70-A075-116219CA5A5D' AND Name = '${mjSchema}_Longitude')) BEGIN
         INSERT INTO [${mjSchema}].[EntityField]
         (
            [ID],
            [EntityID],
            [Sequence],
            [Name],
            [DisplayName],
            [Description],
            [Type],
            [Length],
            [Precision],
            [Scale],
            [AllowsNull],
            [DefaultValue],
            [AutoIncrement],
            [AllowUpdateAPI],
            [IsVirtual],
            [IsComputed],
            [RelatedEntityID],
            [RelatedEntityFieldName],
            [IsNameField],
            [IncludeInUserSearchAPI],
            [IncludeRelatedEntityNameFieldInBaseView],
            [DefaultInView],
            [IsPrimaryKey],
            [IsUnique],
            [RelatedEntityDisplayType],
            [__mj_CreatedAt],
            [__mj_UpdatedAt]
         )
         VALUES
         (
            'baa8c311-ee92-4f3b-bb5f-000810af4894',
            '72E55425-8822-4E70-A075-116219CA5A5D', -- Entity: MJ_BizApps_Common: Activities
            (SELECT COALESCE(MAX([Sequence]), 0) FROM [${mjSchema}].[EntityField] WHERE [EntityID] = '72E55425-8822-4E70-A075-116219CA5A5D') + 29,
            '${mjSchema}_Longitude',
            'Mj Longitude',
            NULL,
            'decimal',
            9,
            10,
            6,
            1,
            NULL,
            0,
            0,
            1,
            0,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search',
            GETUTCDATE(),
            GETUTCDATE()
         )
      END;

/* SQL text to update existing entity fields from schema (1 scoped entities) */
EXEC [${mjSchema}].[spUpdateExistingEntityFieldsFromSchema] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys', @EntityIDs='72E55425-8822-4E70-A075-116219CA5A5D';

/* SQL text to set default column width where needed */
EXEC [${mjSchema}].[spSetDefaultColumnWidthWhereNeeded] @ExcludedSchemaNames='${mjSchema}_BizAppsAccounting,${mjSchema}_BizAppsIssues,${mjSchema}_BizAppsOrders,${mjSchema}_BizAppsTasks,${mjSchema},sys';

/* Set ExtendedType=GeoLatitude on virtual geo fields */
UPDATE [${mjSchema}].[EntityField] SET [ExtendedType] = 'GeoLatitude' WHERE [Name] = '${mjSchema}_Latitude' AND [ExtendedType] IS NULL AND [EntityID] IN ('72E55425-8822-4E70-A075-116219CA5A5D');

/* Set ExtendedType=GeoLongitude on virtual geo fields */
UPDATE [${mjSchema}].[EntityField] SET [ExtendedType] = 'GeoLongitude' WHERE [Name] = '${mjSchema}_Longitude' AND [ExtendedType] IS NULL AND [EntityID] IN ('72E55425-8822-4E70-A075-116219CA5A5D');

/* Refresh custom base views for modified entities so schema changes are picked up */
EXEC sp_refreshview '${mjSchema}_BizAppsOrders.vwOrderHeadersGenerated';
IF OBJECT_ID('[${mjSchema}_BizAppsOrders].[vwOrderHeaders]', 'V') IS NOT NULL
BEGIN
    EXEC sp_executesql N'EXEC sp_refreshview ''${mjSchema}_BizAppsOrders.vwOrderHeaders'';';
END;

