# BizApps Common Entity Model

This document describes the data model for the BizApps Common shared library. All tables reside in the `__mj_BizAppsCommon` SQL schema and are available to any MemberJunction application that depends on this package.

---

## Core Entities (5)

### Person

People records with demographics and optional linkage to the MJ system user table.

| Field | Type | Notes |
|-------|------|-------|
| FirstName | nvarchar | Required |
| LastName | nvarchar | Required |
| MiddleName | nvarchar | Optional |
| Prefix | nvarchar | e.g., Mr., Dr., Hon. |
| Suffix | nvarchar | e.g., Jr., III, Esq. |
| Email | nvarchar | Convenience field; also tracked via ContactMethod |
| DateOfBirth | date | Optional |
| Gender | nvarchar | Optional |
| Title | nvarchar | Denormalized professional info (e.g., "VP Engineering") |
| Company | nvarchar | Denormalized professional info (e.g., "Acme Corp") |
| LinkedUserID | uniqueidentifier | Optional FK to MJ core Users table |
| Bio | nvarchar(max) | Free-form biography |
| Notes | nvarchar(max) | Internal notes |
| IsActive | bit | Soft-delete flag |

### Organization

Companies, non-profits, associations, government bodies, and other institutional entities.

| Field | Type | Notes |
|-------|------|-------|
| Name | nvarchar | Required |
| Description | nvarchar(max) | Optional |
| OrganizationTypeID | uniqueidentifier | FK to OrganizationType |
| ParentOrganizationID | uniqueidentifier | Self-referencing FK for hierarchy (nullable) |
| Website | nvarchar | Convenience field |
| Phone | nvarchar | Convenience field |
| Email | nvarchar | Convenience field |
| DateFounded | date | Optional |
| IsActive | bit | Soft-delete flag |

### Address

Standalone, reusable address records. Addresses are linked to entities through AddressLink rather than belonging directly to a single entity.

| Field | Type | Notes |
|-------|------|-------|
| Line1 | nvarchar | Street address line 1 |
| Line2 | nvarchar | Street address line 2 (optional) |
| City | nvarchar | Required |
| StateProvince | nvarchar | State, province, or region |
| PostalCode | nvarchar | ZIP or postal code |
| Country | nvarchar | ISO 3166-1 alpha-2 code (e.g., "US", "CA") |
| Latitude | decimal | Geocoded latitude (optional) |
| Longitude | decimal | Geocoded longitude (optional) |
| IsVerified | bit | Whether the address has been validated |

### ContactMethod

Additional contact information for people or organizations. Each record belongs to exactly one Person or one Organization (never both, never neither).

| Field | Type | Notes |
|-------|------|-------|
| PersonID | uniqueidentifier | FK to Person (nullable) |
| OrganizationID | uniqueidentifier | FK to Organization (nullable) |
| ContactTypeID | uniqueidentifier | FK to ContactType |
| Value | nvarchar | The actual phone number, email, URL, etc. |
| Label | nvarchar | User-defined label (e.g., "Work Cell", "Personal Email") |
| IsPrimary | bit | Primary flag per contact type |
| IsActive | bit | Soft-delete flag |

**Constraint**: Exactly one of PersonID or OrganizationID must be set.

### Relationship

Typed, directional links between people and/or organizations.

| Field | Type | Notes |
|-------|------|-------|
| RelationshipTypeID | uniqueidentifier | FK to RelationshipType |
| FromPersonID | uniqueidentifier | Source person (nullable) |
| FromOrganizationID | uniqueidentifier | Source organization (nullable) |
| ToPersonID | uniqueidentifier | Target person (nullable) |
| ToOrganizationID | uniqueidentifier | Target organization (nullable) |
| Title | nvarchar | Role or position context (e.g., "CEO", "Board Chair") |
| StartDate | date | When the relationship began |
| EndDate | date | When the relationship ended (nullable) |
| IsActive | bit | Soft-delete flag |

The "from" side is the source and the "to" side is the target. For non-directional relationship types (e.g., Spouse), both directions are logically equivalent.

---

## Type / Lookup Tables (4)

### OrganizationType

Classifies organizations.

| Field | Type | Notes |
|-------|------|-------|
| Name | nvarchar | Required, unique |
| Description | nvarchar | Optional |
| IsActive | bit | Soft-delete flag |

**Seed data**: Company, Non-Profit, Association, Government, Educational Institution, Healthcare

### AddressType

Classifies the purpose of an address link.

| Field | Type | Notes |
|-------|------|-------|
| Name | nvarchar | Required, unique |
| Description | nvarchar | Optional |
| IconClass | nvarchar | Font Awesome icon class for UI rendering |
| DefaultRank | int | Default display order |
| IsActive | bit | Soft-delete flag |

**Seed data**: Home, Work, Mailing, Billing, Shipping, Legal

### ContactType

Classifies contact methods.

| Field | Type | Notes |
|-------|------|-------|
| Name | nvarchar | Required, unique |
| Description | nvarchar | Optional |
| IconClass | nvarchar | Font Awesome icon class for UI rendering |
| IsActive | bit | Soft-delete flag |

**Seed data**: Phone, Mobile, Email, LinkedIn, Website, Fax, Twitter/X

### RelationshipType

Defines the nature of a relationship and how it should be displayed.

| Field | Type | Notes |
|-------|------|-------|
| Name | nvarchar | Required, unique |
| Description | nvarchar | Optional |
| Category | nvarchar | One of: PersonToPerson, PersonToOrganization, OrganizationToOrganization |
| IsDirectional | bit | true for asymmetric relationships (e.g., Employee->Employer) |
| ForwardLabel | nvarchar | Label from source to target (e.g., "is employed by") |
| ReverseLabel | nvarchar | Label from target to source (e.g., "employs") |
| IsActive | bit | Soft-delete flag |

**Seed data**:
- PersonToPerson: Spouse, Parent/Child, Sibling, Friend
- PersonToOrganization: Employee, Board Member, Member, Volunteer, Customer, Consultant
- OrganizationToOrganization: Subsidiary, Partner, Vendor, Affiliate

---

## Linking Table (1)

### AddressLink

Polymorphic address linker enabling any MJ entity to have addresses without schema changes.

| Field | Type | Notes |
|-------|------|-------|
| AddressID | uniqueidentifier | FK to Address |
| EntityID | uniqueidentifier | FK to MJ core Entities table (identifies which entity type) |
| RecordID | nvarchar | The specific record's primary key value |
| AddressTypeID | uniqueidentifier | FK to AddressType |
| IsPrimary | bit | Whether this is the primary address of its type |

**Design rationale**:

- A single Address record can be shared across multiple entities (e.g., a person and their company share the same physical address).
- Any new entity added to the system can have addresses without schema changes -- just create AddressLink rows pointing to the new entity.
- Query pattern: `WHERE EntityID = '<entity-guid>' AND RecordID = '<record-guid>'`

---

## Entity Relationship Diagram

```
+-------------------+        +--------------------+
|  OrganizationType |        |    ContactType     |
+-------------------+        +--------------------+
| Name              |        | Name               |
| Description       |        | Description        |
| IsActive          |        | IconClass          |
+--------+----------+        | IsActive           |
         |                   +----------+---------+
         | 1                            | 1
         |                              |
         | *                            | *
+--------+----------+        +----------+---------+
|   Organization    |        |   ContactMethod    |
+-------------------+        +--------------------+
| Name              |        | Value              |
| Description       |<--+    | Label              |
| OrganizationTypeID|   |    | IsPrimary          |
| ParentOrgID ------+---+    | PersonID ----------+--->+
| Website           |   *    | OrganizationID ----+--->|
| Phone, Email      |        | ContactTypeID      |    |
| DateFounded       |        | IsActive           |    |
| IsActive          |        +--------------------+    |
+--------+----------+                                   |
         |                                              |
         | *                                            |
         |         +--------------------+               |
         |         |   Relationship     |               |
         |         +--------------------+               |
         |         | RelationshipTypeID |               |
         +-------->| FromOrgID         |               |
         +-------->| ToOrgID           |               |
         |         | FromPersonID  ----+------+         |
         |         | ToPersonID    ----+------+         |
         |         | Title             |      |         |
         |         | StartDate,EndDate |      |         |
         |         | IsActive          |      |         |
         |         +---------+---------+      |         |
         |                   |                |         |
         |                   | *              |         |
         |         +---------+---------+      |         |
         |         | RelationshipType  |      |         |
         |         +-------------------+      |         |
         |         | Name              |      |         |
         |         | Category          |      |         |
         |         | IsDirectional     |      |         |
         |         | ForwardLabel      |      |         |
         |         | ReverseLabel      |      |         |
         |         | IsActive          |      |         |
         |         +-------------------+      |         |
         |                                    |         |
+--------+----------+                  +------+---------+
|     AddressLink   |                  |     Person     |
+-------------------+                  +----------------+
| AddressID --------+--->+            | FirstName      |
| EntityID          |    |            | LastName       |
| RecordID          |    |            | Email          |
| AddressTypeID ----+->+ |            | DateOfBirth    |
| IsPrimary         |  | |            | Gender         |
+-------------------+  | |            | Title, Company |
                       | |            | LinkedUserID   |
              +--------+-+            | Bio, Notes     |
              |        |              | IsActive       |
   +----------+--+  +--+----------+  +----------------+
   | AddressType |  |   Address   |
   +-------------+  +-------------+
   | Name        |  | Line1       |
   | Description |  | Line2       |
   | IconClass   |  | City        |
   | DefaultRank |  | StateProvince|
   | IsActive    |  | PostalCode  |
   +-------------+  | Country     |
                     | Lat, Lng    |
                     | IsVerified  |
                     +-------------+
```

**Key relationships**:

- Organization -> OrganizationType (many-to-one)
- Organization -> Organization (self-referencing hierarchy via ParentOrganizationID)
- ContactMethod -> Person OR Organization (polymorphic, exactly one)
- ContactMethod -> ContactType (many-to-one)
- Relationship -> RelationshipType (many-to-one)
- Relationship -> Person/Organization (polymorphic from/to endpoints)
- AddressLink -> Address (many-to-one)
- AddressLink -> AddressType (many-to-one)
- AddressLink -> any MJ entity (polymorphic via EntityID + RecordID)

---

## Naming Convention

All entity names are prefixed with the app schema namespace to prevent collisions with other MJ applications:

```
MJ.BizApps.Common: People
MJ.BizApps.Common: Organizations
MJ.BizApps.Common: Addresses
MJ.BizApps.Common: Contact Methods
MJ.BizApps.Common: Relationships
MJ.BizApps.Common: Organization Types
MJ.BizApps.Common: Address Types
MJ.BizApps.Common: Contact Types
MJ.BizApps.Common: Relationship Types
MJ.BizApps.Common: Address Links
```

When using the MJ metadata API, always reference entities by their full namespaced name.

---

## Views

CodeGen generates enriched SQL views for each entity. These views join lookup tables so that consuming code gets denormalized, display-ready fields without extra queries:

- **vwPeopleExtended** -- Person fields plus any denormalized lookups
- **vwOrganizationsExtended** -- Organization fields plus OrganizationType name, parent organization name
- **vwContactMethodsExtended** -- ContactMethod fields plus ContactType name, linked Person/Organization name
- **vwRelationshipsExtended** -- Relationship fields plus RelationshipType name, from/to entity names
- **vwAddressLinksExtended** -- AddressLink fields plus Address details, AddressType name

Use the denormalized view fields directly instead of making separate lookup queries. This is a significant performance optimization.

---

## TypeScript Entity Classes

CodeGen generates a TypeScript class for each entity. These classes extend `BaseEntity` and include Zod schemas for runtime validation.

Generated class names follow the pattern `mjBizAppsCommon<EntityName>Entity`:

| Entity | Generated Class |
|--------|----------------|
| Person | `mjBizAppsCommonPersonEntity` |
| Organization | `mjBizAppsCommonOrganizationEntity` |
| Address | `mjBizAppsCommonAddressEntity` |
| ContactMethod | `mjBizAppsCommonContactMethodEntity` |
| Relationship | `mjBizAppsCommonRelationshipEntity` |
| OrganizationType | `mjBizAppsCommonOrganizationTypeEntity` |
| AddressType | `mjBizAppsCommonAddressTypeEntity` |
| ContactType | `mjBizAppsCommonContactTypeEntity` |
| RelationshipType | `mjBizAppsCommonRelationshipTypeEntity` |
| AddressLink | `mjBizAppsCommonAddressLinkEntity` |

These classes are exported from the `@mj-biz-apps/common-entities` package.

---

## Code Examples

### Creating a New Person

```typescript
import { Metadata } from '@memberjunction/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

const md = new Metadata();
const person = await md.GetEntityObject<mjBizAppsCommonPersonEntity>(
  'MJ.BizApps.Common: People'
);

person.FirstName = 'Jane';
person.LastName = 'Doe';
person.Email = 'jane.doe@example.com';
person.Title = 'Director of Engineering';
person.Company = 'Acme Corp';
person.IsActive = true;

const saved = await person.Save();
if (!saved) {
  console.error('Failed to save person:', person.LatestResult?.Message);
}
```

### Creating a Person (Server-Side with Context User)

On the server, always pass `contextUser` to ensure proper authorization and audit trails:

```typescript
import { Metadata } from '@memberjunction/core';
import { UserInfo } from '@memberjunction/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

async function createPerson(contextUser: UserInfo) {
  const md = new Metadata();
  const person = await md.GetEntityObject<mjBizAppsCommonPersonEntity>(
    'MJ.BizApps.Common: People',
    contextUser
  );

  person.FirstName = 'Jane';
  person.LastName = 'Doe';
  person.Email = 'jane.doe@example.com';
  person.IsActive = true;

  const saved = await person.Save();
  if (!saved) {
    throw new Error(`Failed to save person: ${person.LatestResult?.Message}`);
  }
  return person;
}
```

### Querying with RunView

```typescript
import { RunView } from '@memberjunction/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

const rv = new RunView();
const result = await rv.RunView<mjBizAppsCommonPersonEntity>({
  EntityName: 'MJ.BizApps.Common: People',
  ExtraFilter: `LastName = 'Doe' AND IsActive = 1`,
  OrderBy: 'FirstName ASC',
  ResultType: 'entity_object',
});

if (result.Success) {
  for (const person of result.Results) {
    console.log(`${person.FirstName} ${person.LastName} - ${person.Email}`);
  }
} else {
  console.error('Query failed:', result.ErrorMessage);
}
```

### Read-Only Query with Specific Fields

When you only need to display data and do not need to save changes, use `ResultType: 'simple'` with `Fields` for better performance:

```typescript
const rv = new RunView();
const result = await rv.RunView({
  EntityName: 'MJ.BizApps.Common: Organizations',
  ExtraFilter: `IsActive = 1`,
  OrderBy: 'Name ASC',
  Fields: ['ID', 'Name', 'OrganizationType', 'Website'],
  ResultType: 'simple',
});

if (result.Success) {
  for (const row of result.Results) {
    console.log(`${row.Name} (${row.OrganizationType})`);
  }
}
```

### Batch Queries with RunViews

Use `RunViews` (plural) to execute multiple independent queries in a single round trip:

```typescript
import { RunView } from '@memberjunction/core';
import {
  mjBizAppsCommonPersonEntity,
  mjBizAppsCommonOrganizationEntity,
} from '@mj-biz-apps/common-entities';

const rv = new RunView();
const [peopleResult, orgsResult] = await rv.RunViews([
  {
    EntityName: 'MJ.BizApps.Common: People',
    ExtraFilter: `IsActive = 1`,
    ResultType: 'entity_object',
  },
  {
    EntityName: 'MJ.BizApps.Common: Organizations',
    ExtraFilter: `IsActive = 1`,
    ResultType: 'entity_object',
  },
]);

if (peopleResult.Success && orgsResult.Success) {
  const people = peopleResult.Results as mjBizAppsCommonPersonEntity[];
  const orgs = orgsResult.Results as mjBizAppsCommonOrganizationEntity[];
  console.log(`Loaded ${people.length} people and ${orgs.length} organizations`);
}
```

### Loading and Updating an Existing Record

```typescript
import { Metadata } from '@memberjunction/core';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';

const md = new Metadata();
const org = await md.GetEntityObject<mjBizAppsCommonOrganizationEntity>(
  'MJ.BizApps.Common: Organizations'
);

// Load an existing record by primary key
const loaded = await org.Load(existingOrgId);
if (!loaded) {
  throw new Error('Organization not found');
}

// Update fields
org.Website = 'https://new-website.example.com';
org.Phone = '+1-555-0199';

const saved = await org.Save();
if (!saved) {
  console.error('Update failed:', org.LatestResult?.Message);
}
```

### Adding a Contact Method to a Person

```typescript
const md = new Metadata();
const contact = await md.GetEntityObject<mjBizAppsCommonContactMethodEntity>(
  'MJ.BizApps.Common: Contact Methods'
);

contact.PersonID = person.ID;
contact.ContactTypeID = mobileContactTypeId;
contact.Value = '+1-555-0142';
contact.Label = 'Work Cell';
contact.IsPrimary = true;
contact.IsActive = true;

await contact.Save();
```

### Creating a Relationship Between a Person and an Organization

```typescript
const md = new Metadata();
const rel = await md.GetEntityObject<mjBizAppsCommonRelationshipEntity>(
  'MJ.BizApps.Common: Relationships'
);

rel.RelationshipTypeID = employeeRelTypeId;
rel.FromPersonID = person.ID;
rel.ToOrganizationID = organization.ID;
rel.Title = 'Senior Engineer';
rel.StartDate = new Date('2024-03-01');
rel.IsActive = true;

await rel.Save();
```

### Linking an Address to an Entity via AddressLink

```typescript
const md = new Metadata();

// First, create or load the address
const address = await md.GetEntityObject<mjBizAppsCommonAddressEntity>(
  'MJ.BizApps.Common: Addresses'
);
address.Line1 = '123 Main Street';
address.City = 'Springfield';
address.StateProvince = 'IL';
address.PostalCode = '62701';
address.Country = 'US';
await address.Save();

// Then link it to a person (or any entity)
const link = await md.GetEntityObject<mjBizAppsCommonAddressLinkEntity>(
  'MJ.BizApps.Common: Address Links'
);
link.AddressID = address.ID;
link.EntityID = personEntityId;       // The MJ entity definition ID for People
link.RecordID = person.ID;            // The specific person's ID
link.AddressTypeID = homeAddressTypeId;
link.IsPrimary = true;

await link.Save();
```

---

## Important Reminders

1. **Never instantiate entity classes directly** -- always use `Metadata.GetEntityObject<T>()`.
2. **Never use the spread operator on entity objects** -- use `entity.GetAll()` instead.
3. **Always pass `contextUser` on the server side** when calling `GetEntityObject()` or `RunView()`.
4. **Check `result.Success`** after `RunView` calls -- they do not throw exceptions on failure.
5. **Use `RunViews` (plural)** for batch queries instead of calling `RunView` in a loop.
6. **Use denormalized view fields** from the generated views instead of making separate lookup queries.
7. **Never manually edit generated code** in `packages/Entities/` or `packages/Server/src/generated/` -- run `npm run mj:codegen` instead.
