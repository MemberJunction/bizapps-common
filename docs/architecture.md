# BizApps Common -- Architecture Documentation

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Package Dependency Graph](#2-package-dependency-graph)
3. [The Open App Pattern](#3-the-open-app-pattern)
4. [Data Flow](#4-data-flow)
5. [Code Generation Pipeline](#5-code-generation-pipeline)
6. [Two-Table Address Pattern](#6-two-table-address-pattern)
7. [Relationship Directionality](#7-relationship-directionality)
8. [Registration and Class Factory](#8-registration-and-class-factory)
9. [Build Pipeline](#9-build-pipeline)

---

## 1. High-Level Architecture

BizApps Common is a **MemberJunction Open App** -- a pluggable module that extends the MemberJunction platform with common business entities: Person, Organization, Address, ContactMethod, and Relationship. It is not a standalone application; it is a shared library consumed by other MJ-based business applications (e.g., Committees, Events).

```
+---------------------------------------------------------------+
|                   Consuming Applications                      |
|  (Committees, Events, Membership, etc.)                       |
+---------------------------------------------------------------+
        |                    |                    |
        v                    v                    v
+---------------------------------------------------------------+
|                     BizApps Common                            |
|  Person | Organization | Address | ContactMethod | Relationship|
+---------------------------------------------------------------+
        |                    |                    |
        v                    v                    v
+---------------------------------------------------------------+
|                   MemberJunction Platform                     |
|  Core | Server | Angular | CodeGen | AI | GraphQL | Metadata  |
+---------------------------------------------------------------+
        |
        v
+-------------------+
|    SQL Server     |
+-------------------+
```

The MJ platform provides:
- **Metadata engine** that describes all entities, fields, relationships, and permissions
- **Class factory** for runtime type resolution
- **GraphQL API layer** (Apollo Server) for data access
- **Angular component framework** for auto-generated and custom UIs
- **CodeGen system** that generates TypeScript classes from database schema

BizApps Common plugs into this platform via the **Open App** pattern, declaring itself through an `mj-app.json` manifest at the repository root.

### Runtime Environments

The repository ships two runnable applications for local development and testing:

| Application  | Port | Purpose                                      |
|-------------|------|----------------------------------------------|
| MJAPI       | 4101 | GraphQL API server (Node.js + Apollo Server) |
| MJExplorer  | 4301 | Angular UI application (ESBuild + Vite)      |

These ports are intentionally offset from MJ's defaults (4001/4201) to allow side-by-side development.

---

## 2. Package Dependency Graph

The repository contains four library packages and two application packages. The build order is strictly determined by inter-package dependencies:

```
                    +------------------+
                    |    Entities      |
                    | common-entities  |
                    +--------+---------+
                             |
                    +--------+---------+
                    |    Actions       |
                    | common-actions   |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
     +--------v---------+         +--------v---------+
     |     Server        |         |     Angular       |
     |  common-server    |         |   common-ng       |
     +--------+----------+         +--------+----------+
              |                             |
     +--------v----------+         +--------v----------+
     |      MJAPI         |         |    MJExplorer      |
     |   (apps/MJAPI)     |         |  (apps/MJExplorer) |
     +--------------------+         +--------------------+
```

### Package Details

| Package | NPM Name | Compiler | Dependencies |
|---------|-----------|----------|-------------|
| Entities | `@mj-biz-apps/common-entities` | `tsc` | `@memberjunction/core`, `@memberjunction/global`, `zod` |
| Actions | `@mj-biz-apps/common-actions` | `tsc` | `@memberjunction/actions-base`, `@memberjunction/core`, common-entities (implicit via MJ) |
| Server | `@mj-biz-apps/common-server` | `tsc` | common-entities, common-actions, `@memberjunction/server` |
| Angular | `@mj-biz-apps/common-ng` | `ngc` | common-entities, `@memberjunction/ng-base-forms`, `@angular/core` |

**Key constraint**: Entities must build first because every other package imports entity classes. Actions builds next. Server and Angular can build in parallel once Entities and Actions are ready.

---

## 3. The Open App Pattern

### The mj-app.json Manifest

Every MJ Open App declares itself through an `mj-app.json` file at the repository root. This manifest tells the MJ platform how to discover, load, and initialize the app.

```json
{
  "name": "bizapps-common",
  "displayName": "BizApps Common",
  "mjVersionRange": ">=5.0.0 <6.0.0",
  "schema": {
    "name": "__mj_BizAppsCommon",
    "createIfNotExists": true
  },
  "migrations": {
    "directory": "migrations",
    "engine": "skyway"
  },
  "metadata": {
    "directory": "metadata"
  },
  "packages": {
    "server": [
      {
        "name": "@mj-biz-apps/common-server",
        "role": "bootstrap",
        "startupExport": "LoadBizAppsCommonServer"
      }
    ],
    "client": [
      {
        "name": "@mj-biz-apps/common-ng",
        "role": "bootstrap",
        "startupExport": "LoadBizAppsCommonClient"
      }
    ],
    "shared": [
      { "name": "@mj-biz-apps/common-entities", "role": "library" },
      { "name": "@mj-biz-apps/common-actions", "role": "library" }
    ]
  }
}
```

### Package Roles

- **`bootstrap`** -- The package exports a startup function that MJ's `DynamicPackageLoader` calls during initialization. Importing the module triggers all `@RegisterClass` decorators.
- **`library`** -- The package provides classes (entity subclasses, action subclasses) but does not need an explicit startup call. It is loaded transitively through bootstrap package imports.

### Bootstrap Entry Points

**Server side** -- `LoadBizAppsCommonServer()` in `packages/Server/src/index.ts`:

```typescript
// Static imports trigger @RegisterClass decorators
import '@mj-biz-apps/common-entities';
import '@mj-biz-apps/common-actions';
import './generated/generated.js';

export function LoadBizAppsCommonServer(): void {
    // The static imports above do all the work.
    // This function exists as the startupExport entry point.
}
```

**Client side** -- `LoadBizAppsCommonClient()` in `packages/Angular/src/public-api.ts`:

```typescript
import '@mj-biz-apps/common-entities';
import './lib/generated/generated-forms.module';
import './lib/custom/custom-forms.module';  // Must come AFTER generated

export function LoadBizAppsCommonClient(): void {
    // Static imports ensure all classes are registered.
}
```

The critical detail: **import order matters on the client**. Generated form components must register before custom ones, because custom components override generated ones by registering with the same entity name at a higher priority.

### Database Schema Isolation

The manifest declares a dedicated SQL Server schema (`__mj_BizAppsCommon`) for this app's tables. This keeps BizApps Common tables separate from MJ core tables (`__mj` schema) and from other Open Apps.

---

## 4. Data Flow

### Request Lifecycle

```
Browser (Angular)
    |
    |  HTTP/WebSocket
    v
+---------------------------+
|  MJExplorer (port 4301)   |
|  Angular Components       |
|  - Generated form comps   |
|  - Custom form comps      |
|  - CRUD widget comps      |
+---------------------------+
    |
    |  GraphQL queries/mutations
    |  (via GraphQLDataProvider)
    v
+---------------------------+
|  MJAPI (port 4101)        |
|  Apollo Server            |
|  - Generated resolvers    |
|  - TypeGraphQL types      |
+---------------------------+
    |
    |  MJ Core (Metadata,
    |  RunView, BaseEntity)
    v
+---------------------------+
|  SQLServerDataProvider    |
|  - Parameterized SQL      |
|  - Views for reads        |
|  - SP calls for writes    |
+---------------------------+
    |
    v
+---------------------------+
|  SQL Server Database      |
|  __mj_BizAppsCommon.*     |
+---------------------------+
```

### Key Abstractions

1. **Entity Objects** (`BaseEntity` subclasses) -- The primary data abstraction. Generated classes like `mjBizAppsCommonPersonEntity` provide strongly-typed property access, validation (via Zod schemas), and save/delete operations. Entity objects are never instantiated directly; they are obtained through the `Metadata` class.

2. **RunView** -- The standard way to query data. Returns either raw objects (`simple`) or hydrated entity objects (`entity_object`). Multiple independent queries can be batched with `RunViews` (plural).

3. **GraphQL Resolvers** -- Auto-generated TypeGraphQL resolvers expose each entity as a GraphQL type with standard CRUD operations. The generated file (`packages/Server/src/generated/generated.ts`) contains ObjectTypes, InputTypes, and Resolver classes for all 10 entities.

4. **GraphQLDataProvider** -- Client-side adapter that translates `RunView` and entity save/delete calls into GraphQL operations.

---

## 5. Code Generation Pipeline

CodeGen is MJ's code generation system. It reads the database schema and MJ metadata tables, then generates TypeScript classes, GraphQL types, Angular components, and SQL objects.

### What Gets Generated

```
CodeGen reads DB
    |
    +---> packages/Entities/src/generated/entity_subclasses.ts
    |     - Zod schemas for validation
    |     - TypeScript entity classes extending BaseEntity
    |     - @RegisterClass decorators for class factory
    |
    +---> packages/Actions/src/generated/ (if actions exist)
    |     - Action subclasses
    |
    +---> packages/Server/src/generated/generated.ts
    |     - TypeGraphQL ObjectTypes (GraphQL schema)
    |     - TypeGraphQL InputTypes (for mutations)
    |     - TypeGraphQL Resolvers (query/mutation handlers)
    |
    +---> packages/Server/src/generated/class-registrations-manifest.ts
    |     - Anti-tree-shaking manifest for server
    |
    +---> packages/Angular/src/lib/generated/
    |     +---> Entities/<EntityName>/<entity>.form.component.ts
    |     |     - One Angular form component per entity
    |     +---> generated-forms.module.ts
    |     |     - NgModule declaring all generated form components
    |     +---> class-registrations-manifest.ts
    |           - Anti-tree-shaking manifest for client
    |
    +---> SQL Scripts/
    |     - Generated views (vw* prefix)
    |     - Generated stored procedures (sp* prefix)
    |
    +---> apps/MJAPI/schema.graphql
          - Full GraphQL schema definition
```

### Generated Entity Class Structure

Each entity gets a Zod schema and a TypeScript class:

```typescript
// Zod schema provides runtime validation
export const mjBizAppsCommonAddressLinkSchema = z.object({
    ID: z.string(),
    AddressID: z.string(),
    EntityID: z.string(),
    RecordID: z.string(),
    AddressTypeID: z.string(),
    IsPrimary: z.boolean(),
    // ... view-joined fields like Address, Entity, AddressType
});

// Entity class provides typed property access and CRUD
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: Address Links')
export class mjBizAppsCommonAddressLinkEntity extends BaseEntity<...> {
    // Typed getters/setters for each field
    // Save, Delete, Validate methods inherited from BaseEntity
}
```

### Anti-Tree-Shaking Manifests

Modern bundlers (ESBuild, Webpack) remove unused imports via tree-shaking. Since `@RegisterClass` decorators have side effects (they register classes in a global factory), the bundler might strip them. The `class-registrations-manifest.ts` files solve this by creating explicit references:

```typescript
import { mjBizAppsCommonPersonEntity, ... } from '@mj-biz-apps/common-entities';

export const CLASS_REGISTRATIONS: any[] = [
    mjBizAppsCommonPersonEntity,
    // ... all 10 entity classes
];
```

This array creates a static code path the bundler cannot eliminate.

### Rules for Generated Code

- **NEVER edit files in `src/generated/` directories** -- CodeGen will overwrite them
- Run `npm run mj:codegen` from the repo root after any database schema change
- Run `npm run mj:migrate` before CodeGen if there are new migration files

---

## 6. Two-Table Address Pattern

Addresses use a **polymorphic link table** pattern that allows any entity in the system to have addresses without requiring a foreign key column on every entity table.

### Schema

```
+-------------------+          +-------------------+
|     Address       |          |    AddressLink     |
+-------------------+          +-------------------+
| ID           (PK) |<--------| AddressID     (FK) |
| Line1             |          | EntityID      (FK) |---> MJ Entity table
| Line2             |          | RecordID           |---> PK of linked record
| City              |          | AddressTypeID (FK) |---> AddressType
| StateProvince     |          | IsPrimary          |
| PostalCode        |          | Rank               |
| Country           |          +-------------------+
+-------------------+
```

### How It Works

1. **Address** holds the physical location data (street, city, state, postal code, country). An Address record is reusable -- the same physical address could theoretically be linked to multiple entities.

2. **AddressLink** is the polymorphic join table. It connects an Address to any entity record in the system using an `(EntityID, RecordID)` pair:
   - `EntityID` references the MJ Entities metadata table, identifying *which* entity type (Person, Organization, etc.)
   - `RecordID` holds the primary key value of the specific record within that entity

3. **AddressType** (via `AddressTypeID`) classifies the link (Home, Work, Mailing, Billing, etc.)

4. **IsPrimary** flag marks one address as the primary for each linked record. Only one AddressLink per `(EntityID, RecordID)` pair should have `IsPrimary = true`.

### Angular Component

The `AddressEditorComponent` (standalone component at `packages/Angular/src/lib/components/address-editor/`) manages the full lifecycle:

```typescript
@Component({
    standalone: true,
    selector: 'bizapps-address-editor',
    imports: [CommonModule, FormsModule],
    // ...
})
export class AddressEditorComponent {
    @Input() EntityName: string;   // e.g., 'MJ.BizApps.Common: People'
    @Input() RecordID: string;     // PK of the parent record
    @Output() DataChanged = new EventEmitter<void>();
}
```

It loads all AddressLink records for the given `(EntityID, RecordID)` pair, joins them with their Address records, and presents an inline editor for CRUD operations. When data changes, it emits `DataChanged` so the parent form can refresh computed fields (e.g., `PrimaryAddressLine1`).

---

## 7. Relationship Directionality

Relationships between entities (Person-to-Person, Person-to-Organization, Organization-to-Organization) use a **directional model** with forward and reverse labels.

### Schema

```
+---------------------+          +------------------------+
|   RelationshipType  |          |     Relationship       |
+---------------------+          +------------------------+
| ID             (PK) |<--------| RelationshipTypeID (FK)|
| Name                |          | FromEntityID      (FK) |
| IsDirectional       |          | FromRecordID           |
| ForwardLabel        |          | ToEntityID        (FK) |
| ReverseLabel        |          | ToRecordID             |
| Category            |          | StartDate              |
+---------------------+          | EndDate                |
                                 +------------------------+
```

### Directional vs Non-Directional

- **Directional** (`IsDirectional = true`): The From/To sides have different meanings.
  - Example: "Employed by" (Person -> Organization) vs "Employer of" (Organization -> Person)
  - `ForwardLabel = 'Employed by'`, `ReverseLabel = 'Employer of'`

- **Non-Directional** (`IsDirectional = false`): Both sides have equivalent meaning.
  - Example: "Sibling of" (Person <-> Person)
  - `ForwardLabel = 'Sibling of'`, `ReverseLabel = 'Sibling of'` (same)

### Label Resolution in the UI

The `RelationshipListComponent` determines which label to display based on whether the current entity is the "From" or "To" side:

```
If current record matches FromRecordID:
    Show ForwardLabel    (e.g., "Employed by")
    Target = To side     (the Organization)
Else (current record matches ToRecordID):
    Show ReverseLabel    (e.g., "Employer of")
    Target = From side   (the Person)
```

The component builds `RelationshipDisplayItem` view models that resolve:
- `DirectionLabel` -- The appropriate forward or reverse label
- `TargetName` -- Display name of the other party
- `TargetEntityName` -- MJ entity name for navigation
- `TargetID` -- Primary key of the other party
- `DateDisplay` -- Formatted date range (e.g., "Jan 2020 - Present")

Relationships are further grouped by `Category` (from `RelationshipType`) into `CategoryGroup` objects for a grouped-timeline layout in the UI.

---

## 8. Registration and Class Factory

MJ uses a **class factory** pattern to decouple class creation from class definition. This is the mechanism that allows custom form components to override generated ones, and allows consuming applications to extend entity behavior.

### @RegisterClass Decorator

Every entity subclass and form component is decorated with `@RegisterClass`:

```typescript
// Entity registration (in generated entity_subclasses.ts)
@RegisterClass(BaseEntity, 'MJ.BizApps.Common: People')
export class mjBizAppsCommonPersonEntity extends BaseEntity<...> { ... }

// Generated form registration (in generated form component)
@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: People')
export class mjBizAppsCommonPersonFormComponent extends BaseFormComponent { ... }

// Custom form registration (overrides the generated one)
@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: People')
export class BizAppsPersonFormComponent extends mjBizAppsCommonPersonFormComponent { ... }
```

### How Registration Works

1. When a module is imported, the `@RegisterClass` decorator fires immediately (as a side effect of module evaluation).
2. It registers the class in MJ's global class factory under the given `(BaseClass, key)` pair.
3. If multiple classes register under the same key, the **last one registered wins** (later imports override earlier ones).
4. This is why import order matters: generated forms are imported first, then custom forms override them.

### How the Class Factory Is Used

When MJ needs to render a form for an entity, it asks the class factory:

```typescript
// MJ internally does something like:
const formClass = ClassFactory.getClass(BaseFormComponent, 'MJ.BizApps.Common: People');
// Returns BizAppsPersonFormComponent (the custom one), not the generated one
```

Similarly, when creating entity objects:

```typescript
const md = new Metadata();
const person = await md.GetEntityObject<mjBizAppsCommonPersonEntity>('MJ.BizApps.Common: People');
// Returns an instance of mjBizAppsCommonPersonEntity
```

### Custom Form Override Pattern

The custom form components in `packages/Angular/src/lib/custom/` follow a specific pattern:

1. **Extend the generated form** -- This ensures the generated form module is imported first (establishing the dependency).
2. **Register with the same entity name** -- The custom registration overwrites the generated one in the factory.
3. **Add richer UI** -- Replace generic data grids with specialized CRUD widgets (AddressEditor, ContactMethodList, RelationshipList).

```typescript
@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: People')
@Component({ standalone: false, selector: 'bizapps-person-form', ... })
export class BizAppsPersonFormComponent extends mjBizAppsCommonPersonFormComponent {
    // Adds custom sections for addresses, contacts, relationships
}
```

---

## 9. Build Pipeline

### Turborepo Orchestration

The repository uses [Turborepo](https://turbo.build/) to orchestrate builds across the NPM workspace. The `turbo.json` configuration is minimal:

```json
{
  "tasks": {
    "build": {
      "outputs": ["build/**", "dist/**"],
      "dependsOn": ["^build"],
      "cache": true
    }
  }
}
```

The `"dependsOn": ["^build"]` directive tells Turbo to build each package's dependencies before building the package itself. This respects the dependency graph automatically.

### Build Order (Resolved by Turborepo)

```
Phase 1:  Entities  (tsc + tsc-alias)
Phase 2:  Actions   (tsc + tsc-alias)
Phase 3:  Server    (tsc + tsc-alias)  |  Angular  (ngc)    [parallel]
Phase 4:  MJAPI     (tsc)              |  MJExplorer (esbuild/vite)  [parallel]
```

### Compiler by Package

| Package | Compiler | Output |
|---------|----------|--------|
| Entities | `tsc && tsc-alias` | `dist/` |
| Actions | `tsc && tsc-alias` | `dist/` |
| Server | `tsc && tsc-alias` | `dist/` |
| Angular | `ngc` (Angular Compiler) | `dist/` |
| MJAPI | `tsc` (via Turbo) | `dist/` |
| MJExplorer | ESBuild + Vite (Angular builder) | `dist/` |

### Common Build Commands

```bash
# Build everything (recommended)
npm run build

# Build only generated packages (Entities + Actions)
npm run build:generated

# Build only library packages (all four)
npm run build:packages

# Build a single package for quick iteration
cd packages/Angular && npm run build

# Start both apps
npm run start

# Run migrations then codegen then build (full setup)
npm run mj:migrate && npm run mj:codegen && npm run build
```

### NPM Workspace Rules

This is an NPM workspace monorepo. Dependencies are managed at the root level:
- Define dependencies in each package's own `package.json`
- Run `npm install` at the **repository root** (never inside individual package directories)
- Cross-package references use workspace resolution automatically

---

## Appendix: Entity Inventory

The following entities are defined in the `__mj_BizAppsCommon` schema:

| Entity | Description |
|--------|------------|
| Person | Individual people with name, email, title, status |
| Organization | Companies, nonprofits, departments with hierarchy support |
| OrganizationType | Classification of organizations (Company, Nonprofit, etc.) |
| Address | Physical location data (street, city, state, postal, country) |
| AddressLink | Polymorphic join linking addresses to any entity record |
| AddressType | Classification of address links (Home, Work, Mailing, etc.) |
| ContactMethod | Communication channels (phone, email, social) for people/orgs |
| ContactType | Classification of contact methods (Phone, Email, LinkedIn, etc.) |
| Relationship | Directional or non-directional link between two entity records |
| RelationshipType | Classification with forward/reverse labels and directionality |

### Custom Angular Components

Beyond the 10 generated form components, the repository includes these hand-written components:

| Component | Type | Location |
|-----------|------|----------|
| `BizAppsPersonFormComponent` | Custom form (overrides generated) | `packages/Angular/src/lib/custom/Person/` |
| `BizAppsOrganizationFormComponent` | Custom form (overrides generated) | `packages/Angular/src/lib/custom/Organization/` |
| `AddressEditorComponent` | Standalone CRUD widget | `packages/Angular/src/lib/components/address-editor/` |
| `ContactMethodListComponent` | Standalone CRUD widget | `packages/Angular/src/lib/components/contact-method-list/` |
| `RelationshipListComponent` | Standalone CRUD widget | `packages/Angular/src/lib/components/relationship-list/` |
| `OrgHierarchyTreeComponent` | Standalone widget | `packages/Angular/src/lib/components/org-hierarchy-tree/` |
