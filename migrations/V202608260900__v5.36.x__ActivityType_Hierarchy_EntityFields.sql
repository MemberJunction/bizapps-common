-- vwActivityTypes is a hierarchy wrapper (RootParentID / Depth / Path / IsLeaf /
-- ChildCount). Those five virtual columns were never registered as EntityFields
-- in this repo — they leaked into an Orders CodeGen dump on a joined DB.
-- Without them, save-capture declares 13 slots against an 18-column view and
-- Activity Type metadata sync fails on a from-scratch install.

DECLARE @EntityID UNIQUEIDENTIFIER = '8B748643-85FF-4B07-B3B6-B12EC7A399E6'; -- MJ_BizApps_Common: Activity Types

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '41bb0737-cd9e-4940-b11b-fd298cf7eaae' OR (EntityID = @EntityID AND Name = 'RootParentID'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('41bb0737-cd9e-4940-b11b-fd298cf7eaae', @EntityID, 14, 'RootParentID', 'Root Parent ID', 'uniqueidentifier', 16, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'd46b9d6e-e723-4741-a738-bb86d47107c2' OR (EntityID = @EntityID AND Name = 'ParentIDDepth'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('d46b9d6e-e723-4741-a738-bb86d47107c2', @EntityID, 15, 'ParentIDDepth', 'Parent ID Depth', 'int', 4, 10, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = '4e37bf81-3d28-4ced-a7ca-a38876a4808b' OR (EntityID = @EntityID AND Name = 'ParentIDPath'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('4e37bf81-3d28-4ced-a7ca-a38876a4808b', @EntityID, 16, 'ParentIDPath', 'Parent ID Path', 'nvarchar', -1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'f897cd8f-80f1-4f53-8be7-11a1d508a8ec' OR (EntityID = @EntityID AND Name = 'ParentIDIsLeaf'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('f897cd8f-80f1-4f53-8be7-11a1d508a8ec', @EntityID, 17, 'ParentIDIsLeaf', 'Parent ID Is Leaf', 'bit', 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM [${mjSchema}].[EntityField] WHERE ID = 'fad7998a-e1cd-4344-9616-dca3641ca12c' OR (EntityID = @EntityID AND Name = 'ParentIDChildCount'))
INSERT INTO [${mjSchema}].[EntityField]
    (ID, EntityID, Sequence, Name, DisplayName, Type, Length, Precision, Scale, AllowsNull, AutoIncrement, AllowUpdateAPI, IsVirtual, IsComputed, IsNameField, IncludeInUserSearchAPI, IncludeRelatedEntityNameFieldInBaseView, DefaultInView, IsPrimaryKey, IsUnique, RelatedEntityDisplayType, __mj_CreatedAt, __mj_UpdatedAt)
VALUES
    ('fad7998a-e1cd-4344-9616-dca3641ca12c', @EntityID, 18, 'ParentIDChildCount', 'Parent ID Child Count', 'int', 4, 10, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Search', GETUTCDATE(), GETUTCDATE());
GO
