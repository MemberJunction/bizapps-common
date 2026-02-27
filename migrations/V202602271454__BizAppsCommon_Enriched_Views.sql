-----------------------------------------------------------------
-- BizApps Common: Enriched Base Views
--
-- IMPORTANT: This migration must run AFTER CodeGen, because
-- vwOrganizationsExtended depends on the CodeGen-generated
-- function fnOrganizationParentID_GetRootID.
--
-- Replaces the CodeGen-generated base views for People and
-- Organizations with enriched versions that include denormalized
-- primary address, contact, and relationship data.
--
-- Pair with BaseViewGenerated = 0 in entity metadata to prevent
-- CodeGen from overwriting these views.
-----------------------------------------------------------------

--------------------------------------------------------------
-- vwPeopleExtended: Enriched with primary address, contacts, employer
--------------------------------------------------------------
DROP VIEW IF EXISTS [__mj_BizAppsCommon].[vwPeopleExtended]
GO

CREATE VIEW [__mj_BizAppsCommon].[vwPeopleExtended]
AS
SELECT
    -- All base table columns
    p.*,

    -- FK denormalization (same as CodeGen-generated version)
    MJUser_LinkedUserID.[Name] AS [LinkedUser],

    -- Computed display name
    TRIM(
        COALESCE(p.Prefix + ' ', '') +
        COALESCE(p.PreferredName, p.FirstName) + ' ' +
        p.LastName +
        COALESCE(', ' + p.Suffix, '')
    ) AS [DisplayName],

    -- Primary address (from AddressLink where IsPrimary = 1)
    addr.Line1          AS [PrimaryAddressLine1],
    addr.Line2          AS [PrimaryAddressLine2],
    addr.City           AS [PrimaryAddressCity],
    addr.StateProvince  AS [PrimaryAddressState],
    addr.PostalCode     AS [PrimaryAddressPostalCode],
    addr.Country        AS [PrimaryAddressCountry],
    addr.Latitude       AS [PrimaryAddressLatitude],
    addr.Longitude      AS [PrimaryAddressLongitude],
    addrType.Name       AS [PrimaryAddressType],

    -- Primary email (from ContactMethod, falls back to Person.Email)
    COALESCE(cm_email.Value, p.Email) AS [PrimaryEmail],

    -- Primary phone (from ContactMethod, falls back to Person.Phone)
    COALESCE(cm_phone.Value, p.Phone) AS [PrimaryPhone],

    -- Current employer (most recent active Employee relationship)
    emp_org.ID          AS [CurrentOrganizationID],
    emp_org.Name        AS [CurrentOrganizationName],
    emp_rel.Title       AS [CurrentJobTitle]

FROM
    [__mj_BizAppsCommon].[Person] AS p

-- Linked MJ User
LEFT OUTER JOIN
    [__mj].[User] AS MJUser_LinkedUserID
  ON
    [p].[LinkedUserID] = MJUser_LinkedUserID.[ID]

-- Primary address via AddressLink (polymorphic)
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[AddressLink] AS al
  ON
    al.[RecordID] = CAST(p.[ID] AS NVARCHAR(MAX))
    AND al.[EntityID] = (
        SELECT [ID] FROM [__mj].[Entity]
        WHERE [Name] = 'MJ.BizApps.Common: People'
    )
    AND al.[IsPrimary] = 1
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[Address] AS addr
  ON
    addr.[ID] = al.[AddressID]
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[AddressType] AS addrType
  ON
    addrType.[ID] = al.[AddressTypeID]

-- Primary email contact method
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[ContactMethod] AS cm_email
  ON
    cm_email.[PersonID] = p.[ID]
    AND cm_email.[IsPrimary] = 1
    AND cm_email.[ContactTypeID] = (
        SELECT [ID] FROM [__mj_BizAppsCommon].[ContactType]
        WHERE [Name] = 'Email'
    )

-- Primary phone contact method
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[ContactMethod] AS cm_phone
  ON
    cm_phone.[PersonID] = p.[ID]
    AND cm_phone.[IsPrimary] = 1
    AND cm_phone.[ContactTypeID] = (
        SELECT [ID] FROM [__mj_BizAppsCommon].[ContactType]
        WHERE [Name] = 'Mobile Phone'
    )

-- Current employer (most recent active Employee relationship)
OUTER APPLY (
    SELECT TOP 1
        r.[Title],
        r.[ToOrganizationID]
    FROM
        [__mj_BizAppsCommon].[Relationship] AS r
    INNER JOIN
        [__mj_BizAppsCommon].[RelationshipType] AS rt
      ON
        rt.[ID] = r.[RelationshipTypeID]
    WHERE
        rt.[Name] = 'Employee'
        AND r.[FromPersonID] = p.[ID]
        AND r.[Status] = 'Active'
    ORDER BY
        r.[StartDate] DESC
) AS emp_rel
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[Organization] AS emp_org
  ON
    emp_org.[ID] = emp_rel.[ToOrganizationID]

GO
GRANT SELECT ON [__mj_BizAppsCommon].[vwPeopleExtended] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
GO


--------------------------------------------------------------
-- vwOrganizationsExtended: Enriched with primary address, contacts, counts
--------------------------------------------------------------
DROP VIEW IF EXISTS [__mj_BizAppsCommon].[vwOrganizationsExtended]
GO

CREATE VIEW [__mj_BizAppsCommon].[vwOrganizationsExtended]
AS
SELECT
    -- All base table columns
    o.*,

    -- FK denormalization (same as CodeGen-generated version)
    mjBizAppsCommonOrganizationType_OrganizationTypeID.[Name] AS [OrganizationType],
    mjBizAppsCommonOrganization_ParentID.[Name] AS [Parent],
    root_ParentID.RootID AS [RootParentID],

    -- Primary address (from AddressLink where IsPrimary = 1)
    addr.Line1          AS [PrimaryAddressLine1],
    addr.Line2          AS [PrimaryAddressLine2],
    addr.City           AS [PrimaryAddressCity],
    addr.StateProvince  AS [PrimaryAddressState],
    addr.PostalCode     AS [PrimaryAddressPostalCode],
    addr.Country        AS [PrimaryAddressCountry],
    addrType.Name       AS [PrimaryAddressType],

    -- Primary email (from ContactMethod, falls back to Org.Email)
    COALESCE(cm_email.Value, o.Email) AS [PrimaryEmail],

    -- Primary phone (from ContactMethod, falls back to Org.Phone)
    COALESCE(cm_phone.Value, o.Phone) AS [PrimaryPhone],

    -- Active people linked to this org via relationships
    (
        SELECT COUNT(*)
        FROM [__mj_BizAppsCommon].[Relationship] AS r
        INNER JOIN [__mj_BizAppsCommon].[RelationshipType] AS rt
          ON rt.[ID] = r.[RelationshipTypeID]
        WHERE rt.[Category] = 'PersonToOrganization'
          AND r.[ToOrganizationID] = o.[ID]
          AND r.[Status] = 'Active'
    ) AS [ActivePersonCount],

    -- Direct child organizations
    (
        SELECT COUNT(*)
        FROM [__mj_BizAppsCommon].[Organization] AS child
        WHERE child.[ParentID] = o.[ID]
          AND child.[Status] = 'Active'
    ) AS [ChildOrgCount]

FROM
    [__mj_BizAppsCommon].[Organization] AS o

-- Organization type name
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[OrganizationType] AS mjBizAppsCommonOrganizationType_OrganizationTypeID
  ON
    [o].[OrganizationTypeID] = mjBizAppsCommonOrganizationType_OrganizationTypeID.[ID]

-- Parent org name
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_ParentID
  ON
    [o].[ParentID] = mjBizAppsCommonOrganization_ParentID.[ID]

-- Root parent via recursive function
OUTER APPLY
    [__mj_BizAppsCommon].[fnOrganizationParentID_GetRootID]([o].[ID], [o].[ParentID]) AS root_ParentID

-- Primary address via AddressLink (polymorphic)
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[AddressLink] AS al
  ON
    al.[RecordID] = CAST(o.[ID] AS NVARCHAR(MAX))
    AND al.[EntityID] = (
        SELECT [ID] FROM [__mj].[Entity]
        WHERE [Name] = 'MJ.BizApps.Common: Organizations'
    )
    AND al.[IsPrimary] = 1
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[Address] AS addr
  ON
    addr.[ID] = al.[AddressID]
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[AddressType] AS addrType
  ON
    addrType.[ID] = al.[AddressTypeID]

-- Primary email contact method
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[ContactMethod] AS cm_email
  ON
    cm_email.[OrganizationID] = o.[ID]
    AND cm_email.[IsPrimary] = 1
    AND cm_email.[ContactTypeID] = (
        SELECT [ID] FROM [__mj_BizAppsCommon].[ContactType]
        WHERE [Name] = 'Email'
    )

-- Primary phone contact method
LEFT OUTER JOIN
    [__mj_BizAppsCommon].[ContactMethod] AS cm_phone
  ON
    cm_phone.[OrganizationID] = o.[ID]
    AND cm_phone.[IsPrimary] = 1
    AND cm_phone.[ContactTypeID] = (
        SELECT [ID] FROM [__mj_BizAppsCommon].[ContactType]
        WHERE [Name] = 'Mobile Phone'
    )

GO
GRANT SELECT ON [__mj_BizAppsCommon].[vwOrganizationsExtended] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
GO
































































-- CODE GEN RUN FOR AFTER UPDATED VIEWS 
/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'b27409ac-ebe4-448d-892f-b425fea0e84b'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryAddressLine1')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'b27409ac-ebe4-448d-892f-b425fea0e84b',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100037,
            'PrimaryAddressLine1',
            'Primary Address Line 1',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'fcd65c16-7e45-4e09-a96c-491d3ca35540'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryAddressLine2')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'fcd65c16-7e45-4e09-a96c-491d3ca35540',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100038,
            'PrimaryAddressLine2',
            'Primary Address Line 2',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '8c3e3758-dcbf-4e14-8151-b0097143657c'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryAddressCity')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '8c3e3758-dcbf-4e14-8151-b0097143657c',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100039,
            'PrimaryAddressCity',
            'Primary Address City',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '695d7778-de23-4866-bc21-045a5ddc48fa'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryAddressState')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '695d7778-de23-4866-bc21-045a5ddc48fa',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100040,
            'PrimaryAddressState',
            'Primary Address State',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '01c2aa3e-498e-40cc-9e69-c1e7d0faeabe'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryAddressPostalCode')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '01c2aa3e-498e-40cc-9e69-c1e7d0faeabe',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100041,
            'PrimaryAddressPostalCode',
            'Primary Address Postal Code',
            NULL,
            'nvarchar',
            40,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '41f97d51-b1cc-4968-b7ec-b2f452d60322'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryAddressCountry')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '41f97d51-b1cc-4968-b7ec-b2f452d60322',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100042,
            'PrimaryAddressCountry',
            'Primary Address Country',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '914a8340-d376-42c8-8324-2210f36113f3'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryAddressType')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '914a8340-d376-42c8-8324-2210f36113f3',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100043,
            'PrimaryAddressType',
            'Primary Address Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '85d5d0fb-dea4-47bb-8d3e-8cb67a2dba7d'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryEmail')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '85d5d0fb-dea4-47bb-8d3e-8cb67a2dba7d',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100044,
            'PrimaryEmail',
            'Primary Email',
            NULL,
            'nvarchar',
            1000,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'ae683088-d0d6-46d3-9b36-104b2d786680'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'PrimaryPhone')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'ae683088-d0d6-46d3-9b36-104b2d786680',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100045,
            'PrimaryPhone',
            'Primary Phone',
            NULL,
            'nvarchar',
            1000,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '336459eb-5862-4bfe-b543-ccbe4805c888'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ActivePersonCount')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '336459eb-5862-4bfe-b543-ccbe4805c888',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100046,
            'ActivePersonCount',
            'Active Person Count',
            NULL,
            'int',
            4,
            10,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'f78b290a-ba8e-4056-8ca9-f8b1f4fc9dc0'  OR 
               (EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'ChildOrgCount')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'f78b290a-ba8e-4056-8ca9-f8b1f4fc9dc0',
            'C70448F9-9792-41D7-A82C-784B66429D54', -- Entity: MJ.BizApps.Common: Organizations
            100047,
            'ChildOrgCount',
            'Child Org Count',
            NULL,
            'int',
            4,
            10,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'ba7b91fc-0564-44a0-83a7-8f193e345a86'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'DisplayName')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'ba7b91fc-0564-44a0-83a7-8f193e345a86',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100039,
            'DisplayName',
            'Display Name',
            NULL,
            'nvarchar',
            488,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '253df12b-7623-47ac-bb7e-55e22722e58c'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressLine1')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '253df12b-7623-47ac-bb7e-55e22722e58c',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100040,
            'PrimaryAddressLine1',
            'Primary Address Line 1',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'ddb9e103-eaf7-4beb-8bbb-88090c70f310'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressLine2')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'ddb9e103-eaf7-4beb-8bbb-88090c70f310',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100041,
            'PrimaryAddressLine2',
            'Primary Address Line 2',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'bdd1fc14-d131-4f04-8793-4a3131d1b37a'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressCity')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'bdd1fc14-d131-4f04-8793-4a3131d1b37a',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100042,
            'PrimaryAddressCity',
            'Primary Address City',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'bfc78c12-a300-453c-860c-92030b2a2ef7'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressState')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'bfc78c12-a300-453c-860c-92030b2a2ef7',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100043,
            'PrimaryAddressState',
            'Primary Address State',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '12ea4c06-3f1a-4693-b12a-aa1b8f6b2ba4'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressPostalCode')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '12ea4c06-3f1a-4693-b12a-aa1b8f6b2ba4',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100044,
            'PrimaryAddressPostalCode',
            'Primary Address Postal Code',
            NULL,
            'nvarchar',
            40,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '92a79aaf-c17a-4840-850f-0c48b1baa537'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressCountry')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '92a79aaf-c17a-4840-850f-0c48b1baa537',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100045,
            'PrimaryAddressCountry',
            'Primary Address Country',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '2b79579d-709b-4841-a521-7d8c89e70650'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressLatitude')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '2b79579d-709b-4841-a521-7d8c89e70650',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100046,
            'PrimaryAddressLatitude',
            'Primary Address Latitude',
            NULL,
            'decimal',
            5,
            9,
            6,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'ab509acb-d6ef-46f1-8996-c17da4de9d3c'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressLongitude')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'ab509acb-d6ef-46f1-8996-c17da4de9d3c',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100047,
            'PrimaryAddressLongitude',
            'Primary Address Longitude',
            NULL,
            'decimal',
            5,
            9,
            6,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '67c990f9-36f5-4744-b8f3-d3767d83f181'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryAddressType')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '67c990f9-36f5-4744-b8f3-d3767d83f181',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100048,
            'PrimaryAddressType',
            'Primary Address Type',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'bd320531-0856-4f4d-a8b5-4b99e48a206b'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryEmail')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'bd320531-0856-4f4d-a8b5-4b99e48a206b',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100049,
            'PrimaryEmail',
            'Primary Email',
            NULL,
            'nvarchar',
            1000,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '5dc31286-72ec-43f3-ae4a-94d04d6fbf4a'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'PrimaryPhone')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '5dc31286-72ec-43f3-ae4a-94d04d6fbf4a',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100050,
            'PrimaryPhone',
            'Primary Phone',
            NULL,
            'nvarchar',
            1000,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'd0d0dea9-786a-4658-af86-ab13622bea0f'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'CurrentOrganizationID')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'd0d0dea9-786a-4658-af86-ab13622bea0f',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100051,
            'CurrentOrganizationID',
            'Current Organization ID',
            NULL,
            'uniqueidentifier',
            16,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'f1c5d341-12a1-4668-88cf-eab604a1f097'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'CurrentOrganizationName')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'f1c5d341-12a1-4668-88cf-eab604a1f097',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100052,
            'CurrentOrganizationName',
            'Current Organization Name',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '0bc215f7-f097-4246-a9f1-112d7e47c1a0'  OR 
               (EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'CurrentJobTitle')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '0bc215f7-f097-4246-a9f1-112d7e47c1a0',
            '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F', -- Entity: MJ.BizApps.Common: People
            100053,
            'CurrentJobTitle',
            'Current Job Title',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to update entity field related entity name field map for entity field ID EFFA8DD0-9FCE-4504-83A8-A1415C912621 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='EFFA8DD0-9FCE-4504-83A8-A1415C912621',
         @RelatedEntityNameFieldMap='Address'

/* SQL text to update entity field related entity name field map for entity field ID B6B5A623-F308-496E-8845-0CF1E92E9D00 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='B6B5A623-F308-496E-8845-0CF1E92E9D00',
         @RelatedEntityNameFieldMap='Person'

/* Base View SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
-- Item: vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Address Links
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  AddressLink
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks]
AS
SELECT
    a.*,
    mjBizAppsCommonAddress_AddressID.[Line1] AS [Address],
    MJEntity_EntityID.[Name] AS [Entity],
    mjBizAppsCommonAddressType_AddressTypeID.[Name] AS [AddressType]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] AS a
INNER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Address] AS mjBizAppsCommonAddress_AddressID
  ON
    [a].[AddressID] = mjBizAppsCommonAddress_AddressID.[ID]
INNER JOIN
    [${flyway:defaultSchema}].[Entity] AS MJEntity_EntityID
  ON
    [a].[EntityID] = MJEntity_EntityID.[ID]
INNER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[AddressType] AS mjBizAppsCommonAddressType_AddressTypeID
  ON
    [a].[AddressTypeID] = mjBizAppsCommonAddressType_AddressTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
-- Item: Permissions for vwAddressLinks
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
-- Item: spCreateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR AddressLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink]
    @ID uniqueidentifier = NULL,
    @AddressID uniqueidentifier,
    @EntityID uniqueidentifier,
    @RecordID nvarchar(700),
    @AddressTypeID uniqueidentifier,
    @IsPrimary bit = NULL,
    @Rank int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
            (
                [ID],
                [AddressID],
                [EntityID],
                [RecordID],
                [AddressTypeID],
                [IsPrimary],
                [Rank]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @AddressID,
                @EntityID,
                @RecordID,
                @AddressTypeID,
                ISNULL(@IsPrimary, 0),
                @Rank
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
            (
                [AddressID],
                [EntityID],
                [RecordID],
                [AddressTypeID],
                [IsPrimary],
                [Rank]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @AddressID,
                @EntityID,
                @RecordID,
                @AddressTypeID,
                ISNULL(@IsPrimary, 0),
                @Rank
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateAddressLink] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
-- Item: spUpdateAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR AddressLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink]
    @ID uniqueidentifier,
    @AddressID uniqueidentifier,
    @EntityID uniqueidentifier,
    @RecordID nvarchar(700),
    @AddressTypeID uniqueidentifier,
    @IsPrimary bit,
    @Rank int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
    SET
        [AddressID] = @AddressID,
        [EntityID] = @EntityID,
        [RecordID] = @RecordID,
        [AddressTypeID] = @AddressTypeID,
        [IsPrimary] = @IsPrimary,
        [Rank] = @Rank
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwAddressLinks]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the AddressLink table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddressLink]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateAddressLink];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateAddressLink
ON [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for MJ.BizApps.Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateAddressLink] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Address Links */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Address Links
-- Item: spDeleteAddressLink
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR AddressLink
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[AddressLink]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink] TO [cdp_Integration]
    

/* spDelete Permissions for MJ.BizApps.Common: Address Links */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteAddressLink] TO [cdp_Integration]



/* Base View SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
-- Item: vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Contact Methods
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  ContactMethod
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods]
AS
SELECT
    c.*,
    mjBizAppsCommonPerson_PersonID.[LastName] AS [Person],
    mjBizAppsCommonOrganization_OrganizationID.[Name] AS [Organization],
    mjBizAppsCommonContactType_ContactTypeID.[Name] AS [ContactType]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] AS c
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Person] AS mjBizAppsCommonPerson_PersonID
  ON
    [c].[PersonID] = mjBizAppsCommonPerson_PersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_OrganizationID
  ON
    [c].[OrganizationID] = mjBizAppsCommonOrganization_OrganizationID.[ID]
INNER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[ContactType] AS mjBizAppsCommonContactType_ContactTypeID
  ON
    [c].[ContactTypeID] = mjBizAppsCommonContactType_ContactTypeID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
-- Item: Permissions for vwContactMethods
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
-- Item: spCreateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod]
    @ID uniqueidentifier = NULL,
    @PersonID uniqueidentifier,
    @OrganizationID uniqueidentifier,
    @ContactTypeID uniqueidentifier,
    @Value nvarchar(500),
    @Label nvarchar(100),
    @IsPrimary bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
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
                @PersonID,
                @OrganizationID,
                @ContactTypeID,
                @Value,
                @Label,
                ISNULL(@IsPrimary, 0)
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
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
                @PersonID,
                @OrganizationID,
                @ContactTypeID,
                @Value,
                @Label,
                ISNULL(@IsPrimary, 0)
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateContactMethod] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
-- Item: spUpdateContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod]
    @ID uniqueidentifier,
    @PersonID uniqueidentifier,
    @OrganizationID uniqueidentifier,
    @ContactTypeID uniqueidentifier,
    @Value nvarchar(500),
    @Label nvarchar(100),
    @IsPrimary bit
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
    SET
        [PersonID] = @PersonID,
        [OrganizationID] = @OrganizationID,
        [ContactTypeID] = @ContactTypeID,
        [Value] = @Value,
        [Label] = @Label,
        [IsPrimary] = @IsPrimary
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwContactMethods]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the ContactMethod table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateContactMethod]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateContactMethod];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateContactMethod
ON [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for MJ.BizApps.Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateContactMethod] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Contact Methods */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Contact Methods
-- Item: spDeleteContactMethod
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR ContactMethod
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[ContactMethod]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod] TO [cdp_Integration]
    

/* spDelete Permissions for MJ.BizApps.Common: Contact Methods */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteContactMethod] TO [cdp_Integration]



/* Index for Foreign Keys for Organization */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key OrganizationTypeID in table Organization
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Organization]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Organization_OrganizationTypeID ON [${flyway:defaultSchema}_BizAppsCommon].[Organization] ([OrganizationTypeID]);

-- Index for foreign key ParentID in table Organization
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Organization_ParentID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Organization]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Organization_ParentID ON [${flyway:defaultSchema}_BizAppsCommon].[Organization] ([ParentID]);

/* Base View Permissions SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
-- Item: Permissions for vwOrganizationsExtended
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationsExtended] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
-- Item: spCreateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization]
    @ID uniqueidentifier = NULL,
    @Name nvarchar(255),
    @LegalName nvarchar(255),
    @OrganizationTypeID uniqueidentifier,
    @ParentID uniqueidentifier,
    @Website nvarchar(1000),
    @LogoURL nvarchar(1000),
    @Description nvarchar(MAX),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @FoundedDate date,
    @TaxID nvarchar(50),
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Organization]
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
                @LegalName,
                @OrganizationTypeID,
                @ParentID,
                @Website,
                @LogoURL,
                @Description,
                @Email,
                @Phone,
                @FoundedDate,
                @TaxID,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Organization]
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
                @LegalName,
                @OrganizationTypeID,
                @ParentID,
                @Website,
                @LogoURL,
                @Description,
                @Email,
                @Phone,
                @FoundedDate,
                @TaxID,
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationsExtended] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateOrganization] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
-- Item: spUpdateOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization]
    @ID uniqueidentifier,
    @Name nvarchar(255),
    @LegalName nvarchar(255),
    @OrganizationTypeID uniqueidentifier,
    @ParentID uniqueidentifier,
    @Website nvarchar(1000),
    @LogoURL nvarchar(1000),
    @Description nvarchar(MAX),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @FoundedDate date,
    @TaxID nvarchar(50),
    @Status nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Organization]
    SET
        [Name] = @Name,
        [LegalName] = @LegalName,
        [OrganizationTypeID] = @OrganizationTypeID,
        [ParentID] = @ParentID,
        [Website] = @Website,
        [LogoURL] = @LogoURL,
        [Description] = @Description,
        [Email] = @Email,
        [Phone] = @Phone,
        [FoundedDate] = @FoundedDate,
        [TaxID] = @TaxID,
        [Status] = @Status
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationsExtended] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwOrganizationsExtended]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Organization table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateOrganization]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateOrganization];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateOrganization
ON [${flyway:defaultSchema}_BizAppsCommon].[Organization]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Organization]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for MJ.BizApps.Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateOrganization] TO [cdp_Developer], [cdp_Integration]



/* Index for Foreign Keys for Person */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
-- Item: Index for Foreign Keys
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------
-- Index for foreign key LinkedUserID in table Person
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IDX_AUTO_MJ_FKEY_Person_LinkedUserID' 
    AND object_id = OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[Person]')
)
CREATE INDEX IDX_AUTO_MJ_FKEY_Person_LinkedUserID ON [${flyway:defaultSchema}_BizAppsCommon].[Person] ([LinkedUserID]);

/* Base View Permissions SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
-- Item: Permissions for vwPeopleExtended
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwPeopleExtended] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
-- Item: spCreatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson]
    @ID uniqueidentifier = NULL,
    @FirstName nvarchar(100),
    @LastName nvarchar(100),
    @MiddleName nvarchar(100),
    @Prefix nvarchar(20),
    @Suffix nvarchar(20),
    @PreferredName nvarchar(100),
    @Title nvarchar(200),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @DateOfBirth date,
    @Gender nvarchar(50),
    @PhotoURL nvarchar(1000),
    @Bio nvarchar(MAX),
    @LinkedUserID uniqueidentifier,
    @Status nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Person]
            (
                [ID],
                [FirstName],
                [LastName],
                [MiddleName],
                [Prefix],
                [Suffix],
                [PreferredName],
                [Title],
                [Email],
                [Phone],
                [DateOfBirth],
                [Gender],
                [PhotoURL],
                [Bio],
                [LinkedUserID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @ID,
                @FirstName,
                @LastName,
                @MiddleName,
                @Prefix,
                @Suffix,
                @PreferredName,
                @Title,
                @Email,
                @Phone,
                @DateOfBirth,
                @Gender,
                @PhotoURL,
                @Bio,
                @LinkedUserID,
                ISNULL(@Status, 'Active')
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Person]
            (
                [FirstName],
                [LastName],
                [MiddleName],
                [Prefix],
                [Suffix],
                [PreferredName],
                [Title],
                [Email],
                [Phone],
                [DateOfBirth],
                [Gender],
                [PhotoURL],
                [Bio],
                [LinkedUserID],
                [Status]
            )
        OUTPUT INSERTED.[ID] INTO @InsertedRow
        VALUES
            (
                @FirstName,
                @LastName,
                @MiddleName,
                @Prefix,
                @Suffix,
                @PreferredName,
                @Title,
                @Email,
                @Phone,
                @DateOfBirth,
                @Gender,
                @PhotoURL,
                @Bio,
                @LinkedUserID,
                ISNULL(@Status, 'Active')
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwPeopleExtended] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreatePerson] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
-- Item: spUpdatePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson]
    @ID uniqueidentifier,
    @FirstName nvarchar(100),
    @LastName nvarchar(100),
    @MiddleName nvarchar(100),
    @Prefix nvarchar(20),
    @Suffix nvarchar(20),
    @PreferredName nvarchar(100),
    @Title nvarchar(200),
    @Email nvarchar(255),
    @Phone nvarchar(50),
    @DateOfBirth date,
    @Gender nvarchar(50),
    @PhotoURL nvarchar(1000),
    @Bio nvarchar(MAX),
    @LinkedUserID uniqueidentifier,
    @Status nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Person]
    SET
        [FirstName] = @FirstName,
        [LastName] = @LastName,
        [MiddleName] = @MiddleName,
        [Prefix] = @Prefix,
        [Suffix] = @Suffix,
        [PreferredName] = @PreferredName,
        [Title] = @Title,
        [Email] = @Email,
        [Phone] = @Phone,
        [DateOfBirth] = @DateOfBirth,
        [Gender] = @Gender,
        [PhotoURL] = @PhotoURL,
        [Bio] = @Bio,
        [LinkedUserID] = @LinkedUserID,
        [Status] = @Status
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwPeopleExtended] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwPeopleExtended]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Person table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdatePerson]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdatePerson];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdatePerson
ON [${flyway:defaultSchema}_BizAppsCommon].[Person]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Person]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Person] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for MJ.BizApps.Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdatePerson] TO [cdp_Developer], [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID 8974264B-DC82-4276-B89E-C65E14F078F8 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='8974264B-DC82-4276-B89E-C65E14F078F8',
         @RelatedEntityNameFieldMap='FromPerson'

/* spDelete SQL for MJ.BizApps.Common: Organizations */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Organizations
-- Item: spDeleteOrganization
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Organization
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Organization]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization] TO [cdp_Integration]
    

/* spDelete Permissions for MJ.BizApps.Common: Organizations */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteOrganization] TO [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: People */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: People
-- Item: spDeletePerson
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Person
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Person]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson] TO [cdp_Integration]
    

/* spDelete Permissions for MJ.BizApps.Common: People */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeletePerson] TO [cdp_Integration]



/* SQL text to update entity field related entity name field map for entity field ID AD3ECDAA-E2BE-40D9-B83E-1868AB68C778 */
EXEC [${flyway:defaultSchema}].spUpdateEntityFieldRelatedEntityNameFieldMap
         @EntityFieldID='AD3ECDAA-E2BE-40D9-B83E-1868AB68C778',
         @RelatedEntityNameFieldMap='ToPerson'

/* Base View SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
-- Item: vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- BASE VIEW FOR ENTITY:      MJ.BizApps.Common: Relationships
-----               SCHEMA:      ${flyway:defaultSchema}_BizAppsCommon
-----               BASE TABLE:  Relationship
-----               PRIMARY KEY: ID
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[vwRelationships]', 'V') IS NOT NULL
    DROP VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships];
GO

CREATE VIEW [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships]
AS
SELECT
    r.*,
    mjBizAppsCommonRelationshipType_RelationshipTypeID.[Name] AS [RelationshipType],
    mjBizAppsCommonPerson_FromPersonID.[LastName] AS [FromPerson],
    mjBizAppsCommonOrganization_FromOrganizationID.[Name] AS [FromOrganization],
    mjBizAppsCommonPerson_ToPersonID.[LastName] AS [ToPerson],
    mjBizAppsCommonOrganization_ToOrganizationID.[Name] AS [ToOrganization]
FROM
    [${flyway:defaultSchema}_BizAppsCommon].[Relationship] AS r
INNER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[RelationshipType] AS mjBizAppsCommonRelationshipType_RelationshipTypeID
  ON
    [r].[RelationshipTypeID] = mjBizAppsCommonRelationshipType_RelationshipTypeID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Person] AS mjBizAppsCommonPerson_FromPersonID
  ON
    [r].[FromPersonID] = mjBizAppsCommonPerson_FromPersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_FromOrganizationID
  ON
    [r].[FromOrganizationID] = mjBizAppsCommonOrganization_FromOrganizationID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Person] AS mjBizAppsCommonPerson_ToPersonID
  ON
    [r].[ToPersonID] = mjBizAppsCommonPerson_ToPersonID.[ID]
LEFT OUTER JOIN
    [${flyway:defaultSchema}_BizAppsCommon].[Organization] AS mjBizAppsCommonOrganization_ToOrganizationID
  ON
    [r].[ToOrganizationID] = mjBizAppsCommonOrganization_ToOrganizationID.[ID]
GO
GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration]
    

/* Base View Permissions SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
-- Item: Permissions for vwRelationships
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

GRANT SELECT ON [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] TO [cdp_UI], [cdp_Developer], [cdp_Integration]

/* spCreate SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
-- Item: spCreateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- CREATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship]
    @ID uniqueidentifier = NULL,
    @RelationshipTypeID uniqueidentifier,
    @FromPersonID uniqueidentifier,
    @FromOrganizationID uniqueidentifier,
    @ToPersonID uniqueidentifier,
    @ToOrganizationID uniqueidentifier,
    @Title nvarchar(255),
    @StartDate date,
    @EndDate date,
    @Status nvarchar(50) = NULL,
    @Notes nvarchar(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedRow TABLE ([ID] UNIQUEIDENTIFIER)
    
    IF @ID IS NOT NULL
    BEGIN
        -- User provided a value, use it
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
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
                @FromPersonID,
                @FromOrganizationID,
                @ToPersonID,
                @ToOrganizationID,
                @Title,
                @StartDate,
                @EndDate,
                ISNULL(@Status, 'Active'),
                @Notes
            )
    END
    ELSE
    BEGIN
        -- No value provided, let database use its default (e.g., NEWSEQUENTIALID())
        INSERT INTO [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
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
                @FromPersonID,
                @FromOrganizationID,
                @ToPersonID,
                @ToOrganizationID,
                @Title,
                @StartDate,
                @EndDate,
                ISNULL(@Status, 'Active'),
                @Notes
            )
    END
    -- return the new record from the base view, which might have some calculated fields
    SELECT * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] WHERE [ID] = (SELECT [ID] FROM @InsertedRow)
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration]
    

/* spCreate Permissions for MJ.BizApps.Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spCreateRelationship] TO [cdp_Developer], [cdp_Integration]



/* spUpdate SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
-- Item: spUpdateRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- UPDATE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship]
    @ID uniqueidentifier,
    @RelationshipTypeID uniqueidentifier,
    @FromPersonID uniqueidentifier,
    @FromOrganizationID uniqueidentifier,
    @ToPersonID uniqueidentifier,
    @ToOrganizationID uniqueidentifier,
    @Title nvarchar(255),
    @StartDate date,
    @EndDate date,
    @Status nvarchar(50),
    @Notes nvarchar(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
    SET
        [RelationshipTypeID] = @RelationshipTypeID,
        [FromPersonID] = @FromPersonID,
        [FromOrganizationID] = @FromOrganizationID,
        [ToPersonID] = @ToPersonID,
        [ToOrganizationID] = @ToOrganizationID,
        [Title] = @Title,
        [StartDate] = @StartDate,
        [EndDate] = @EndDate,
        [Status] = @Status,
        [Notes] = @Notes
    WHERE
        [ID] = @ID

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
        -- Nothing was updated, return no rows, but column structure from base view intact, semantically correct this way.
        SELECT TOP 0 * FROM [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships] WHERE 1=0
    ELSE
        -- Return the updated record so the caller can see the updated values and any calculated fields
        SELECT
                                        *
                                    FROM
                                        [${flyway:defaultSchema}_BizAppsCommon].[vwRelationships]
                                    WHERE
                                        [ID] = @ID
                                    
END
GO

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]
GO

------------------------------------------------------------
----- TRIGGER FOR __mj_UpdatedAt field for the Relationship table
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[trgUpdateRelationship]', 'TR') IS NOT NULL
    DROP TRIGGER [${flyway:defaultSchema}_BizAppsCommon].[trgUpdateRelationship];
GO
CREATE TRIGGER [${flyway:defaultSchema}_BizAppsCommon].trgUpdateRelationship
ON [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
    SET
        __mj_UpdatedAt = GETUTCDATE()
    FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship] AS _organicTable
    INNER JOIN
        INSERTED AS I ON
        _organicTable.[ID] = I.[ID];
END;
GO
        

/* spUpdate Permissions for MJ.BizApps.Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spUpdateRelationship] TO [cdp_Developer], [cdp_Integration]



/* spDelete SQL for MJ.BizApps.Common: Relationships */
-----------------------------------------------------------------
-- SQL Code Generation
-- Entity: MJ.BizApps.Common: Relationships
-- Item: spDeleteRelationship
--
-- This was generated by the MemberJunction CodeGen tool.
-- This file should NOT be edited by hand.
-----------------------------------------------------------------

------------------------------------------------------------
----- DELETE PROCEDURE FOR Relationship
------------------------------------------------------------
IF OBJECT_ID('[${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship]', 'P') IS NOT NULL
    DROP PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship];
GO

CREATE PROCEDURE [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship]
    @ID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM
        [${flyway:defaultSchema}_BizAppsCommon].[Relationship]
    WHERE
        [ID] = @ID


    -- Check if the delete was successful
    IF @@ROWCOUNT = 0
        SELECT NULL AS [ID] -- Return NULL for all primary key fields to indicate no record was deleted
    ELSE
        SELECT @ID AS [ID] -- Return the primary key values to indicate we successfully deleted the record
END
GO
GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship] TO [cdp_Integration]
    

/* spDelete Permissions for MJ.BizApps.Common: Relationships */

GRANT EXECUTE ON [${flyway:defaultSchema}_BizAppsCommon].[spDeleteRelationship] TO [cdp_Integration]



/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '8c53840a-4f54-4259-ad08-3a9be7492380'  OR 
               (EntityID = '32C45078-D33B-4760-9BE5-0DF7F483F591' AND Name = 'Person')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '8c53840a-4f54-4259-ad08-3a9be7492380',
            '32C45078-D33B-4760-9BE5-0DF7F483F591', -- Entity: MJ.BizApps.Common: Contact Methods
            100021,
            'Person',
            'Person',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = '737947be-0997-47f6-afbc-ad1063bd69aa'  OR 
               (EntityID = 'F2FC2E85-B210-43A9-8565-290AD9D0C6E7' AND Name = 'Address')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            '737947be-0997-47f6-afbc-ad1063bd69aa',
            'F2FC2E85-B210-43A9-8565-290AD9D0C6E7', -- Entity: MJ.BizApps.Common: Address Links
            100021,
            'Address',
            'Address',
            NULL,
            'nvarchar',
            510,
            0,
            0,
            0,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'e5cbfb24-e73b-43e3-8e4b-96249bb5b2bf'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'FromPerson')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'e5cbfb24-e73b-43e3-8e4b-96249bb5b2bf',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
            100031,
            'FromPerson',
            'From Person',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* SQL text to insert new entity field */

      IF NOT EXISTS (
         SELECT 1 FROM [${flyway:defaultSchema}].EntityField 
         WHERE ID = 'c3ed1e7a-d190-4886-85b4-15a0c3c5909e'  OR 
               (EntityID = '709CA9DA-B124-4155-BE39-E857EF672D82' AND Name = 'ToPerson')
         -- check to make sure we're not inserting a duplicate entity field metadata record
      )
      BEGIN
         INSERT INTO [${flyway:defaultSchema}].EntityField
         (
            ID,
            EntityID,
            Sequence,
            Name,
            DisplayName,
            Description,
            Type,
            Length,
            Precision,
            Scale,
            AllowsNull,
            DefaultValue,
            AutoIncrement,
            AllowUpdateAPI,
            IsVirtual,
            RelatedEntityID,
            RelatedEntityFieldName,
            IsNameField,
            IncludeInUserSearchAPI,
            IncludeRelatedEntityNameFieldInBaseView,
            DefaultInView,
            IsPrimaryKey,
            IsUnique,
            RelatedEntityDisplayType
         )
         VALUES
         (
            'c3ed1e7a-d190-4886-85b4-15a0c3c5909e',
            '709CA9DA-B124-4155-BE39-E857EF672D82', -- Entity: MJ.BizApps.Common: Relationships
            100033,
            'ToPerson',
            'To Person',
            NULL,
            'nvarchar',
            200,
            0,
            0,
            1,
            'null',
            0,
            0,
            1,
            NULL,
            NULL,
            0,
            0,
            0,
            0,
            0,
            0,
            'Search'
         )
      END

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8C3E3758-DCBF-4E14-8151-B0097143657C'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '695D7778-DE23-4866-BC21-045A5DDC48FA'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '85D5D0FB-DEA4-47BB-8D3E-8CB67A2DBA7D'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'AE683088-D0D6-46D3-9B36-104B2D786680'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '8C3E3758-DCBF-4E14-8151-B0097143657C'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '01C2AA3E-498E-40CC-9E69-C1E7D0FAEABE'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '85D5D0FB-DEA4-47BB-8D3E-8CB67A2DBA7D'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'AE683088-D0D6-46D3-9B36-104B2D786680'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '8C53840A-4F54-4259-AD08-3A9BE7492380'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '86227274-0D90-4F5E-B43F-8B303EBE4844'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '8C53840A-4F54-4259-AD08-3A9BE7492380'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = '737947BE-0997-47F6-AFBC-AD1063BD69AA'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = '737947BE-0997-47F6-AFBC-AD1063BD69AA'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '737947BE-0997-47F6-AFBC-AD1063BD69AA'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

            UPDATE [${flyway:defaultSchema}].EntityField
            SET IsNameField = 1
            WHERE ID = 'BA7B91FC-0564-44A0-83A7-8F193E345A86'
            AND AutoUpdateIsNameField = 1
         

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'BA7B91FC-0564-44A0-83A7-8F193E345A86'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'BD320531-0856-4F4D-A8B5-4B99E48A206B'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'F1C5D341-12A1-4668-88CF-EAB604A1F097'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'BA7B91FC-0564-44A0-83A7-8F193E345A86'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'BD320531-0856-4F4D-A8B5-4B99E48A206B'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '5DC31286-72EC-43F3-AE4A-94D04D6FBF4A'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'F1C5D341-12A1-4668-88CF-EAB604A1F097'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = '0BC215F7-F097-4246-A9F1-112D7E47C1A0'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set field properties for entity */

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'E5CBFB24-E73B-43E3-8E4B-96249BB5B2BF'
               AND AutoUpdateDefaultInView = 1
            

               UPDATE [${flyway:defaultSchema}].EntityField
               SET DefaultInView = 1
               WHERE ID = 'C3ED1E7A-D190-4886-85B4-15A0C3C5909E'
               AND AutoUpdateDefaultInView = 1
            

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'E5CBFB24-E73B-43E3-8E4B-96249BB5B2BF'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

                  UPDATE [${flyway:defaultSchema}].EntityField
                  SET IncludeInUserSearchAPI = 1
                  WHERE ID = 'C3ED1E7A-D190-4886-85B4-15A0C3C5909E'
                  AND AutoUpdateIncludeInUserSearchAPI = 1
               

/* Set categories for 34 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2A0B54F1-94F8-466C-86C2-931E200258C1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '86C714E8-B200-4F9F-817A-BAF052AEEE3D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CC25D06A-8F7E-433D-9658-500F225D55EC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.FirstName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4942CBCC-6D0B-44F5-BE38-9D697D02B463' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.LastName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '09AD91DA-42C7-44F4-AE71-5AC6E50D7657' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.MiddleName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '528500F1-1BB8-4564-A46D-5D45362F3E05' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Prefix 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '31733EB2-A6CB-4433-8FAC-F278676855DC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Suffix 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9F22EE0D-AC30-4805-89EC-E2C8576615BE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PreferredName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '27375F71-8F8F-4DAB-8803-96AE73EA28CE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.DisplayName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Personal Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BA7B91FC-0564-44A0-83A7-8F193E345A86' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.DateOfBirth 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '45090E40-2E5C-4359-B14D-B3D902685C11' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Gender 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '69B0D1A5-C5F5-4F21-9F39-4DCB1C46F76F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Title 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Title',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0B992115-7C59-4D6E-A49E-DDAE2D7E9056' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Email 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Email',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = 'F6B2A29B-CFE9-410D-9732-3AE2ACF44DC0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Phone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Phone',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = '1B312AA3-5CCC-48E6-B034-A8BF437C9A4D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryEmail 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = 'BD320531-0856-4F4D-A8B5-4B99E48A206B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryPhone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = '5DC31286-72EC-43F3-AE4A-94D04D6FBF4A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PhotoURL 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = '6BD597E1-05B9-46F6-80FD-5A98D35C4FDD' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Bio 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '152F8F83-767B-4B4F-AF92-EF786126DEC0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.CurrentOrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   DisplayName = 'Current Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D0D0DEA9-786A-4658-AF86-AB13622BEA0F' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.CurrentOrganizationName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F1C5D341-12A1-4668-88CF-EAB604A1F097' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.CurrentJobTitle 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Professional and Profile',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0BC215F7-F097-4246-A9F1-112D7E47C1A0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.LinkedUserID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '79F1EEAB-367E-4B45-A9B8-75639F6410CB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.LinkedUser 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Linked User Account',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5F857A6E-BEFC-4C29-BC2B-FD6876C269B2' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '57F78065-E9DB-4D2C-A2F8-524D4F15D902' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressLine1 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '253DF12B-7623-47AC-BB7E-55E22722E58C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressLine2 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DDB9E103-EAF7-4BEB-8BBB-88090C70F310' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressCity 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary City',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BDD1FC14-D131-4F04-8793-4A3131D1B37A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressState 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary State',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'BFC78C12-A300-453C-860C-92030B2A2EF7' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressPostalCode 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary Postal Code',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '12EA4C06-3F1A-4693-B12A-AA1B8F6B2BA4' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressCountry 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary Country',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '92A79AAF-C17A-4840-850F-0C48B1BAA537' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressLatitude 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary Latitude',
   ExtendedType = 'Geo',
   CodeType = NULL
WHERE 
   ID = '2B79579D-709B-4841-A521-7D8C89E70650' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressLongitude 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary Longitude',
   ExtendedType = 'Geo',
   CodeType = NULL
WHERE 
   ID = 'AB509ACB-D6EF-46F1-8996-C17DA4DE9D3C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: People.PrimaryAddressType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '67C990F9-36F5-4744-B8F3-D3767D83F181' AND AutoUpdateCategory = 1

/* Update FieldCategoryInfo setting for entity */

               UPDATE [${flyway:defaultSchema}].EntitySetting
               SET Value = '{"Primary Address":{"icon":"fa fa-map-marker-alt","description":"Primary physical address and geographic location details"}}', __mj_UpdatedAt = GETUTCDATE()
               WHERE EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'FieldCategoryInfo'
            

/* Update FieldCategoryIcons setting (legacy) */

               UPDATE [${flyway:defaultSchema}].EntitySetting
               SET Value = '{"Primary Address":"fa fa-map-marker-alt"}', __mj_UpdatedAt = GETUTCDATE()
               WHERE EntityID = '7A94ADA9-7880-4FAE-97D8-DB0E934C3F5F' AND Name = 'FieldCategoryIcons'
            

/* Set categories for 18 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FEFDAD15-7BA5-470A-A689-147D9303AB34' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.RelationshipTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Relationship Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '4BFFAFBD-BF4E-4907-963B-95733C670B7E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.FromPersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8974264B-DC82-4276-B89E-C65E14F078F8' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.FromOrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '6D46F59F-FF3F-4351-A697-E7DB414A1E3E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ToPersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'AD3ECDAA-E2BE-40D9-B83E-1868AB68C778' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ToOrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '42EBA3CE-7DDB-4149-BE93-E245F351B963' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.FromPerson 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E5CBFB24-E73B-43E3-8E4B-96249BB5B2BF' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.FromOrganization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'From Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DB499EE6-8FC5-4FC7-BC36-F758D5B76BCB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ToPerson 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Relationship Participants',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C3ED1E7A-D190-4886-85B4-15A0C3C5909E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.ToOrganization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'To Organization',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E9B40366-4907-44C0-99B1-502E35D6E345' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.Title 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '2ACBD16A-2A78-4807-8B8D-D0920382EAE6' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.StartDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '62D8A345-E8AC-4EE6-88A9-1959F6258657' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.EndDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0AFC293D-E93D-4BD2-A71C-ACB2631CA278' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '80B0C5C4-915A-4E72-9978-74CB33902F08' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.Notes 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CD66C882-D041-46F1-8DE2-3807B1BD8B5A' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.RelationshipType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '07C7D2B2-8916-4220-961F-076C298DD2C9' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5F0BE392-8F9C-4995-BC97-344D361C9706' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Relationships.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B15AE830-4BCB-4AA3-847E-916885287462' AND AutoUpdateCategory = 1

/* Set categories for 12 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C66B3740-B4B9-4BA4-B53D-9CDC6A64DAFB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.PersonID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B6B5A623-F308-496E-8845-0CF1E92E9D00' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.Person 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linked Record',
   GeneratedFormSection = 'Category',
   DisplayName = 'Person Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8C53840A-4F54-4259-AD08-3A9BE7492380' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.OrganizationID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '0EC64524-99CD-484D-BF82-0E422D0C9903' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.Organization 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '86227274-0D90-4F5E-B43F-8B303EBE4844' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.ContactTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '5C42F4D1-4ABD-4CC6-B5DA-A164D5CBA7A1' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.ContactType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F261CF20-990D-44DF-B604-A603A9892A90' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.Value 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '77C20975-15E3-4A89-9414-3A829A5EA249' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.Label 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CBA68064-C466-460E-AD1B-89256634A753' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.IsPrimary 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9AAA02E5-C378-43BE-A1B3-6EF7355CDF22' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'DA376286-2631-4FA3-88DA-1D7BE44312CC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Contact Methods.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FC8DC59A-E1B5-4136-9000-99643E602806' AND AutoUpdateCategory = 1

/* Set categories for 12 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'C7EF895A-84E9-4388-8F9D-4E60A73CE67D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.AddressID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EFFA8DD0-9FCE-4504-83A8-A1415C912621' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.EntityID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '63D14E61-C4BE-4369-A775-7A93A14A6432' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.RecordID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8E6C198E-773E-4582-B020-7C7A9716B2C8' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.Entity 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '311AEC01-4C33-4CEF-9898-BD3425834C3C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.Address 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Linkage Details',
   GeneratedFormSection = 'Category',
   DisplayName = 'Address Summary',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '737947BE-0997-47F6-AFBC-AD1063BD69AA' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.AddressTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '633EAB3F-8828-4DB0-9B19-6AD04A75CB83' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.IsPrimary 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '80D85088-71D2-42F1-A9A3-086EE3F96B3D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.Rank 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'CF61A8C5-2F33-4756-AD71-257504E7B4E3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.AddressType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E79C20C4-B9D9-433F-BD0E-5134829F1A25' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8D738E18-A0BA-45EF-88C0-D8BC29D8D877' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Address Links.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B3518E84-62FF-488B-963B-4E7076932A8F' AND AutoUpdateCategory = 1

/* Set categories for 29 fields */

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.ID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B194EE44-85DB-4D2A-A76F-9FEB0B5F1AEB' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Name 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9F465E98-0614-4987-BED8-90B8A1450685' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.LegalName 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '28DAA78C-FABD-438D-8F24-055987B58B60' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.OrganizationTypeID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Type',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '9E6FCD82-BCDF-443A-A87D-E16EEF761068' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.OrganizationType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Organization Type Name',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'EFD20ADA-E18B-41DC-8F4F-F4ED58FE0165' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Description 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E1F4B6BC-8465-429B-922C-353F6D1B547C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.FoundedDate 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '012CE6D0-F4DC-4921-90D6-C56BE2F3D1B3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.TaxID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '3A676695-4DEE-4A2E-95E5-00A96DE43DAD' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Status 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8620F795-6511-4715-A823-D3C905AF3ECC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.ActivePersonCount 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Organization Identity',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '336459EB-5862-4BFE-B543-CCBE4805C888' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.ParentID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Parent',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'D78A9DB0-2ED9-4D73-A408-24B0E03981C9' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Parent 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '97844D3B-A436-4CE7-8246-976BA9FF9A87' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.RootParentID 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   DisplayName = 'Root Parent',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8F929C6B-AB7E-438C-839F-3CB4357BB69C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.ChildOrgCount 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Hierarchy and Structure',
   GeneratedFormSection = 'Category',
   DisplayName = 'Child Organization Count',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'F78B290A-BA8E-4056-8CA9-F8B1F4FC9DC0' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Website 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = 'C8C255E3-D3C1-4F3D-84AA-07B30981FB3E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.LogoURL 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = 'URL',
   CodeType = NULL
WHERE 
   ID = '428426B8-70E5-409E-BA30-8AAD6DFAF08E' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Email 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = '46B9D67F-3365-47B4-BFE1-6BB932392AE3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryEmail 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Email',
   CodeType = NULL
WHERE 
   ID = '85D5D0FB-DEA4-47BB-8D3E-8CB67A2DBA7D' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.Phone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = '9A9B834C-1D11-4A4E-98B3-904D048F89DC' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryPhone 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Contact Information',
   GeneratedFormSection = 'Category',
   ExtendedType = 'Tel',
   CodeType = NULL
WHERE 
   ID = 'AE683088-D0D6-46D3-9B36-104B2D786680' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryAddressLine1 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'B27409AC-EBE4-448D-892F-B425FEA0E84B' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryAddressLine2 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'FCD65C16-7E45-4E09-A96C-491D3CA35540' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryAddressCity 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary City',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '8C3E3758-DCBF-4E14-8151-B0097143657C' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryAddressState 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary State',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '695D7778-DE23-4866-BC21-045A5DDC48FA' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryAddressPostalCode 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary Postal Code',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '01C2AA3E-498E-40CC-9E69-C1E7D0FAEABE' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryAddressCountry 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   DisplayName = 'Primary Country',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '41F97D51-B1CC-4968-B7EC-B2F452D60322' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.PrimaryAddressType 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   Category = 'Primary Address',
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '914A8340-D376-42C8-8324-2210F36113F3' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.__mj_CreatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = '36566057-63B7-49B2-A7F2-928C0D798C02' AND AutoUpdateCategory = 1

-- UPDATE Entity Field Category Info MJ.BizApps.Common: Organizations.__mj_UpdatedAt 
UPDATE [${flyway:defaultSchema}].EntityField
SET 
   GeneratedFormSection = 'Category',
   ExtendedType = NULL,
   CodeType = NULL
WHERE 
   ID = 'E219F8E5-5247-425E-BD32-ABD41F8615BD' AND AutoUpdateCategory = 1

/* Update FieldCategoryInfo setting for entity */

               UPDATE [${flyway:defaultSchema}].EntitySetting
               SET Value = '{"Primary Address":{"icon":"fa fa-map-marker-alt","description":"The main physical location and mailing address for the organization."}}', __mj_UpdatedAt = GETUTCDATE()
               WHERE EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'FieldCategoryInfo'
            

/* Update FieldCategoryIcons setting (legacy) */

               UPDATE [${flyway:defaultSchema}].EntitySetting
               SET Value = '{"Primary Address":"fa fa-map-marker-alt"}', __mj_UpdatedAt = GETUTCDATE()
               WHERE EntityID = 'C70448F9-9792-41D7-A82C-784B66429D54' AND Name = 'FieldCategoryIcons'
            

