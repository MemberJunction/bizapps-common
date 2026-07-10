-- ============================================================================
-- CodeGen metadata backfill (PostgreSQL only — no T-SQL counterpart)
-- ============================================================================
-- Brings __mj metadata for this app to MJ CodeGen's fixed-point state so a
-- fresh PG install is complete without running codegen, and a subsequent
-- codegen run makes no metadata changes.
--
-- Three groups of statements, all data (no DDL):
--
-- 1. SchemaInfo.CanonicalSchemaName (MemberJunction/MJ#2992). The installer's
--    own PersistCanonicalSchemaName UPDATE fires BEFORE app migrations create
--    the SchemaInfo row, so it always misses on a fresh install; without this
--    backfill, generated class names and runtime GraphQL type names come out
--    lowercase until codegen runs. Also pre-creates the canonical-cased row
--    CodeGen otherwise auto-creates, with a pinned ID for determinism.
--
-- 2. Entity descriptions for the 10 app entities.
--
-- 3. EntityField normalization. The SS->PG migration converter translated
--    metadata literals into PG-flavored values (nvarchar->TEXT,
--    uniqueidentifier->UUID, sequences offset by 100000, defaults quoted as
--    'null') that CodeGen normalizes back on its first run. These UPDATEs ship
--    the normalized values directly. Values extracted verbatim from a
--    post-codegen v5.44 database (CodeGen's fixed point).
--
-- This file is .pgonly.sql: on SQL Server none of this is needed (the schema
-- name is stored as authored and the converter never touched the metadata).
-- ============================================================================
SET standard_conforming_strings = on;

UPDATE __mj."SchemaInfo" SET "Description" = NULL, "CanonicalSchemaName" = '__mj_BizAppsCommon' WHERE "ID" = '0a9f0fdd-cd4d-4892-ba45-85722b982032';

INSERT INTO __mj."SchemaInfo" ("ID", "SchemaName", "EntityIDMin", "EntityIDMax", "Comments", "Description", "EntityNamePrefix", "EntityNameSuffix", "CanonicalSchemaName")
VALUES ('870e2e72-9916-479c-82e0-e4548a7a9d06', '__mj_BizAppsCommon', 1, 999999999, 'Auto-created by CodeGen. Please update EntityIDMin and EntityIDMax to appropriate values for this schema.', NULL, NULL, NULL, '__mj_BizAppsCommon')
ON CONFLICT ("ID") DO NOTHING;

UPDATE __mj."Entity" SET "Description" = 'Additional contact methods for people and organizations beyond the primary email and phone fields' WHERE "ID" = '32c45078-d33b-4760-9be5-0df7f483f591';

UPDATE __mj."Entity" SET "Description" = 'Defines types of relationships between people and organizations with directionality and labeling' WHERE "ID" = '5f214f43-109c-407d-b505-7b0b3b72acb5';

UPDATE __mj."Entity" SET "Description" = 'Standalone physical address records linked to entities via AddressLink for sharing across people and organizations' WHERE "ID" = '61b5c6fb-7317-46d1-8e05-f669b7bc6f3e';

UPDATE __mj."Entity" SET "Description" = 'Typed, directional links between people and organizations supporting Person-to-Person, Person-to-Organization, and Organization-to-Organization relationships' WHERE "ID" = '709ca9da-b124-4155-be39-e857ef672d82';

UPDATE __mj."Entity" SET "Description" = 'Categories of contact methods such as Phone, Mobile, Email, LinkedIn, Website' WHERE "ID" = '7355a5ef-b3be-4d6d-b48b-5f8fd76f97b5';

UPDATE __mj."Entity" SET "Description" = 'Categories of addresses such as Home, Work, Mailing, Billing' WHERE "ID" = '7a7245d1-2316-44a4-b147-a50ff19f5942';

UPDATE __mj."Entity" SET "Description" = 'Individual people, optionally linked to MJ system user accounts' WHERE "ID" = '7a94ada9-7880-4fae-97d8-db0e934c3f5f';

UPDATE __mj."Entity" SET "Description" = 'Categories of organizations such as Company, Non-Profit, Association, Government' WHERE "ID" = 'a77d9725-4871-484b-99f0-f65461d7abee';

UPDATE __mj."Entity" SET "Description" = 'Companies, associations, government bodies, and other organizations with hierarchy support' WHERE "ID" = 'c70448f9-9792-41d7-a82c-784b66429d54';

UPDATE __mj."Entity" SET "Description" = 'Polymorphic link table connecting Address records to any entity record in the system via EntityID and RecordID' WHERE "ID" = 'f2fc2e85-b210-43a9-8565-290ad9d0c6e7';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '00865ed9-b98d-4f58-8c5d-022ac87ff8e7';

UPDATE __mj."EntityField" SET "Sequence" = 11, "Length" = 4, "Precision" = 0, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '012ce6d0-f4dc-4921-90d6-c56be2f3d1b3';

UPDATE __mj."EntityField" SET "Sequence" = 17, "DefaultColumnWidth" = 150 WHERE "ID" = '045230a0-3fed-4fec-94bd-cfc3dbf18245';

UPDATE __mj."EntityField" SET "Sequence" = 14, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '07c7d2b2-8916-4220-961f-076c298dd2c9';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'nvarchar', "DefaultValue" = NULL WHERE "ID" = '09ad91da-42c7-44f4-ae71-5ac6e50d7657';

UPDATE __mj."EntityField" SET "Sequence" = 9, "Length" = 4, "Precision" = 0, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '0afc293d-e93d-4bd2-a71c-acb2631ca278';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '0b992115-7c59-4d6e-a49e-ddae2d7e9056';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '0c71e92a-d747-4302-b17f-78c92930d2ce';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'Organization' WHERE "ID" = '0ec64524-99cd-484d-bf82-0e422d0c9903';

UPDATE __mj."EntityField" SET "Sequence" = 15, "DefaultColumnWidth" = 150 WHERE "ID" = '0f3e3c98-748b-4b54-9604-27f16e69b5b3';

UPDATE __mj."EntityField" SET "Sequence" = 14, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '152f8f83-767b-4b4f-af92-ef786126dec0';

UPDATE __mj."EntityField" SET "Sequence" = 10, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '1b312aa3-5ccc-48e6-b034-a8bf437c9a4d';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '1d142a23-e13c-4852-9dd9-a896774c3bda';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '1d7e13df-447a-49b8-9a07-1fa0cc058115';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '236794a4-9f6f-472e-9d9f-c77383cf48f5';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '255fcd46-e0e2-4b77-ab45-0ccdf6181e36';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '27375f71-8f8f-4dab-8803-96ae73ea28ce';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '28daa78c-fabd-438d-8f24-055987b58b60';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = '2a0b54f1-94f8-466c-86c2-931e200258c1';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '2acbd16a-2a78-4807-8b8d-d0920382eae6';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = '2b7f56c2-c197-45e1-9c79-af1bfde094d4';

UPDATE __mj."EntityField" SET "Sequence" = 12, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '2ff61a35-fb7c-455a-8883-6998b141b095';

UPDATE __mj."EntityField" SET "Sequence" = 11, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '311aec01-4c33-4cef-9898-bd3425834c3c';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '31733eb2-a6cb-4433-8fac-f278676855dc';

UPDATE __mj."EntityField" SET "Sequence" = 14, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '36566057-63b7-49b2-a7f2-928c0d798c02';

UPDATE __mj."EntityField" SET "Sequence" = 12, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '3a676695-4dee-4a2e-95e5-00a96de43dad';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Description" = 'URL to organization logo image', "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '428426b8-70e5-409e-ba30-8aad6dfaf08e';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'ToOrganization' WHERE "ID" = '42eba3ce-7ddb-4149-be93-e245f351b963';

UPDATE __mj."EntityField" SET "Sequence" = 11, "Length" = 4, "Precision" = 0, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '45090e40-2e5c-4359-b14d-b3d902685c11';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'int', "DefaultColumnWidth" = 50 WHERE "ID" = '45829cd8-c67d-4527-b25e-4390889eeb85';

UPDATE __mj."EntityField" SET "Sequence" = 9, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '46b9d67f-3365-47b4-bfe1-6bb932392ae3';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '4942cbcc-6d0b-44f5-be38-9d697d02b463';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'RelationshipType' WHERE "ID" = '4bffafbd-bf4e-4907-963b-95733c670b7e';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '528500f1-1bb8-4564-a46d-5d45362f3e05';

UPDATE __mj."EntityField" SET "Sequence" = 16, "Type" = 'nvarchar', "DefaultColumnWidth" = 150 WHERE "ID" = '57f78065-e9db-4d2c-a2f8-524d4f15d902';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'ContactType' WHERE "ID" = '5c42f4d1-4abd-4cc6-b5da-a164d5cba7a1';

UPDATE __mj."EntityField" SET "Sequence" = 12, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '5f0be392-8f9c-4995-bc97-344d361c9706';

UPDATE __mj."EntityField" SET "Sequence" = 20, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '5f857a6e-befc-4c29-bc2b-fd6876c269b2';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'bit', "DefaultColumnWidth" = 150 WHERE "ID" = '60d162bd-2934-4ad7-a74e-f27ef47656d7';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Length" = 4, "Precision" = 0, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '62d8a345-e8ac-4ee6-88a9-1959f6258657';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'AddressType' WHERE "ID" = '633eab3f-8828-4db0-9b19-6ad04a75cb83';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'nvarchar', "DefaultColumnWidth" = 150 WHERE "ID" = '63bb48d1-67c2-4cd9-bdd9-f86f6154f77c';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'Entity' WHERE "ID" = '63d14e61-c4be-4369-a775-7a93a14a6432';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '65acac26-5f6c-4a67-8559-bd7c0943a925';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = '665481ad-fc97-49be-a98c-ab58aa509f59';

UPDATE __mj."EntityField" SET "Sequence" = 9, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '66d63980-b9b5-47a0-ba8b-6b55977cb60c';

UPDATE __mj."EntityField" SET "Sequence" = 12, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '69b0d1a5-c5f5-4f21-9f39-4dcb1c46f76f';

UPDATE __mj."EntityField" SET "Sequence" = 13, "Description" = 'URL to profile photo or avatar image', "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '6bd597e1-05b9-46f6-80fd-5a98d35c4fdd';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'FromOrganization' WHERE "ID" = '6d46f59f-ff3f-4351-a697-e7db414a1e3e';

UPDATE __mj."EntityField" SET "Sequence" = 19, "Type" = 'nvarchar', "Length" = -1, "AllowsNull" = TRUE, "DefaultValue" = '((("FirstName")::text || '' ''::text) || ("LastName")::text)', "IsVirtual" = FALSE, "IsComputed" = TRUE WHERE "ID" = '76d49448-c586-4701-9fff-63f390ec78c0';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '77c20975-15e3-4a89-9414-3a829a5ea249';

UPDATE __mj."EntityField" SET "Sequence" = 15, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'LinkedUser' WHERE "ID" = '79f1eeab-367e-4b45-a9b8-75639f6410cb';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '7b610118-fb6d-4ce0-886f-23881c4647e3';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '7c026948-1d22-4d12-b839-a8af848811ba';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '8096a2bd-684f-44e0-b26b-424f52619220';

UPDATE __mj."EntityField" SET "Sequence" = 10, "Type" = 'nvarchar', "DefaultColumnWidth" = 150 WHERE "ID" = '80b0c5c4-915a-4e72-9978-74cb33902f08';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'bit', "DefaultColumnWidth" = 150 WHERE "ID" = '80d85088-71d2-42f1-a9a3-086ee3f96b3d';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '8221fa5a-6288-48ea-9f5c-92dbbb9020cf';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '82f2cdbc-8793-4fe4-bfca-380a8a22f41f';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = '85492901-7593-46e0-8d3d-d50ed60346d5';

UPDATE __mj."EntityField" SET "Sequence" = 13, "Type" = 'nvarchar', "DefaultColumnWidth" = 150 WHERE "ID" = '8620f795-6511-4715-a823-d3c905af3ecc';

UPDATE __mj."EntityField" SET "Sequence" = 11, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '86227274-0d90-4f5e-b43f-8b303ebe4844';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'int', "DefaultColumnWidth" = 50 WHERE "ID" = '8686f717-72ac-4ecb-b3ff-200da50df000';

UPDATE __mj."EntityField" SET "Sequence" = 17, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '86c714e8-b200-4f9f-817a-baf052aeee3d';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '86c73c1a-89cd-4326-a8bb-145e6b0b2f4a';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'FromPerson' WHERE "ID" = '8974264b-dc82-4276-b89e-c65e14f078f8';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '8c5ed1b2-107e-4195-9e05-ac25c452971d';

UPDATE __mj."EntityField" SET "Sequence" = 9, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '8c67deb3-e9ba-412d-9875-dd29a5523fce';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = '8d738e18-a0ba-45ef-88c0-d8bc29d8d877';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '8e6c198e-773e-4582-b020-7c7a9716b2c8';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '8f51e66c-379d-4e06-acf6-75f98e690782';

UPDATE __mj."EntityField" SET "Sequence" = 18, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '8f929c6b-ab7e-438c-839f-3cb4357bb69c';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '9540ede1-741a-4b6f-b9f0-8de3c3edfc31';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'int', "DefaultColumnWidth" = 50 WHERE "ID" = '971c65dd-9f0c-4b46-ab06-8d5a3e47cbc3';

UPDATE __mj."EntityField" SET "Sequence" = 17, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '97844d3b-a436-4ce7-8246-976ba9ff9a87';

UPDATE __mj."EntityField" SET "Sequence" = 10, "DefaultColumnWidth" = 150 WHERE "ID" = '99d4fe49-bc0b-4d9d-b7ec-84e04f7281ee';

UPDATE __mj."EntityField" SET "Sequence" = 10, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '9a9b834c-1d11-4a4e-98b3-904d048f89dc';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'bit', "DefaultColumnWidth" = 150 WHERE "ID" = '9aaa02e5-c378-43be-a1b3-6ef7355cdf22';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'OrganizationType' WHERE "ID" = '9e6fcd82-bcdf-443a-a87d-e16eef761068';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '9f22ee0d-ac30-4805-89ec-e2c8576615be';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = '9f465e98-0614-4987-bed8-90b8a1450685';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'bit', "DefaultColumnWidth" = 150 WHERE "ID" = '9fff0788-f1a4-4971-9b53-2fef0407880a';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'a005a7db-76ec-4ddf-8482-7951be69b165';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'a2efb1da-409f-40fa-be98-02e394a0f965';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'bit', "DefaultColumnWidth" = 150 WHERE "ID" = 'a6aaf1ab-1212-4066-9a84-2f0dae43b5be';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'acaec8f6-49f4-47c0-983d-33bb4fb29e7b';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'ToPerson' WHERE "ID" = 'ad3ecdaa-e2be-40d9-b83e-1868ab68c778';

UPDATE __mj."EntityField" SET "Sequence" = 10, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'b03f710e-9199-4986-90bf-3ece5037d79a';

UPDATE __mj."EntityField" SET "Sequence" = 4, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'b0408d09-cf61-4d1d-b951-8e0c5490bd29';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'b0c9f62f-cd73-4eeb-87a8-1f55ade79539';

UPDATE __mj."EntityField" SET "Sequence" = 13, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'b15ae830-4bcb-4aa3-847e-916885287462';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = 'b194ee44-85db-4d2a-a76f-9feb0b5f1aeb';

UPDATE __mj."EntityField" SET "Sequence" = 9, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'b3518e84-62ff-488b-963b-4e7076932a8f';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'bit', "DefaultColumnWidth" = 150 WHERE "ID" = 'b66f18b2-77da-4f8e-b9e3-44e9bc6cfc54';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'Person' WHERE "ID" = 'b6b5a623-f308-496e-8845-0cf1e92e9d00';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'b93aa266-faa5-461d-b32b-a0f26c698b2c';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = 'ba3e4fae-198f-48e4-bd9f-774d8584e259';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'bca9babd-e370-4376-89ac-dcf9340e5734';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = 'c40c2682-a2fa-4676-833b-75030293220c';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'c6515a57-dace-4684-ad9d-03297e60cde4';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = 'c66b3740-b4b9-4ba4-b53d-9cdc6a64dafb';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = 'c7ef895a-84e9-4388-8f9d-4e60a73ce67d';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'c8c255e3-d3c1-4f3d-84aa-07b30981fb3e';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'cba68064-c466-460e-ad1b-89256634a753';

UPDATE __mj."EntityField" SET "Sequence" = 18, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'cc25d06a-8f7e-433d-9658-500f225d55ec';

UPDATE __mj."EntityField" SET "Sequence" = 11, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'cd66c882-d041-46f1-8de2-3807b1bd8b5a';

UPDATE __mj."EntityField" SET "Sequence" = 7, "Type" = 'int', "DefaultValue" = NULL, "DefaultColumnWidth" = 50 WHERE "ID" = 'cf61a8c5-2f33-4756-ad71-257504e7b4e3';

UPDATE __mj."EntityField" SET "Sequence" = 11, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'cfe3572f-9b12-4d14-bba5-2f9a8a3b66f0';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'd43eca52-4b7a-434e-92ce-c3ff69824306';

UPDATE __mj."EntityField" SET "Sequence" = 5, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'Parent' WHERE "ID" = 'd78a9db0-2ed9-4d73-a408-24b0e03981c9';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'da376286-2631-4fa3-88da-1d7be44312cc';

UPDATE __mj."EntityField" SET "Sequence" = 16, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'db499ee6-8fc5-4fc7-bc36-f758d5b76bcb';

UPDATE __mj."EntityField" SET "Sequence" = 10, "DefaultColumnWidth" = 150 WHERE "ID" = 'dc5ebc38-46d2-414c-ac64-fa81b7efc19a';

UPDATE __mj."EntityField" SET "Sequence" = 8, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'e1f4b6bc-8465-429b-922c-353f6d1b547c';

UPDATE __mj."EntityField" SET "Sequence" = 15, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'e219f8e5-5247-425e-bd32-abd41f8615bd';

UPDATE __mj."EntityField" SET "Sequence" = 3, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'e6f5450e-c909-426c-8ea6-968a3a68b6ca';

UPDATE __mj."EntityField" SET "Sequence" = 12, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'e79c20c4-b9d9-433f-bd0e-5134829f1a25';

UPDATE __mj."EntityField" SET "Sequence" = 18, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'e9b40366-4907-44c0-99b1-502e35d6e345';

UPDATE __mj."EntityField" SET "Sequence" = 16, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'efd20ada-e18b-41dc-8f4f-f4ed58fe0165';

UPDATE __mj."EntityField" SET "Sequence" = 2, "Type" = 'uniqueidentifier', "DefaultValue" = NULL, "DefaultColumnWidth" = 150, "RelatedEntityNameFieldMap" = 'Address' WHERE "ID" = 'effa8dd0-9fce-4504-83a8-a1415c912621';

UPDATE __mj."EntityField" SET "Sequence" = 12, "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'f261cf20-990d-44df-b604-a603a9892a90';

UPDATE __mj."EntityField" SET "Sequence" = 10, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'f28625fd-5f8f-429c-8100-9b9c54205ab0';

UPDATE __mj."EntityField" SET "Sequence" = 9, "Type" = 'nvarchar', "DefaultValue" = NULL, "DefaultColumnWidth" = 150 WHERE "ID" = 'f6b2a29b-cfe9-410d-9732-3ae2acf44dc0';

UPDATE __mj."EntityField" SET "Sequence" = 6, "Type" = 'bit', "DefaultColumnWidth" = 150 WHERE "ID" = 'f70d2734-af27-4969-9c8b-b51259e71f8f';

UPDATE __mj."EntityField" SET "Sequence" = 9, "Type" = 'datetimeoffset', "DefaultColumnWidth" = 100 WHERE "ID" = 'fc8dc59a-e1b5-4136-9000-99643e602806';

UPDATE __mj."EntityField" SET "Sequence" = 1, "Type" = 'uniqueidentifier', "DefaultColumnWidth" = 150 WHERE "ID" = 'fefdad15-7ba5-470a-a689-147d9303ab34';
