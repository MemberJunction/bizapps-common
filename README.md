<p align="center">
  <img src="https://raw.githubusercontent.com/MemberJunction/MJ/main/logo.png" alt="MemberJunction" width="120" />
</p>

<h1 align="center">BizApps Common</h1>

<p align="center">
  <strong>Foundational business entities for the <a href="https://github.com/MemberJunction/MJ">MemberJunction</a> platform</strong>
</p>

<p align="center">
  <a href="#installation">Install</a> &middot;
  <a href="#entity-model">Entity Model</a> &middot;
  <a href="#angular-components">Components</a> &middot;
  <a href="docs/">Documentation</a>
</p>

<p align="center">
  <img alt="MJ Version" src="https://img.shields.io/badge/MemberJunction-5.8.0-blue?style=flat-square" />
  <img alt="Angular" src="https://img.shields.io/badge/Angular-21-DD0031?style=flat-square&logo=angular&logoColor=white" />
  <img alt="TypeScript" src="https://img.shields.io/badge/TypeScript-5.9-3178C6?style=flat-square&logo=typescript&logoColor=white" />
  <img alt="License" src="https://img.shields.io/badge/License-ISC-green?style=flat-square" />
  <img alt="Node" src="https://img.shields.io/badge/Node-18%2B-339933?style=flat-square&logo=node.js&logoColor=white" />
</p>

---

Business applications repeatedly implement the same foundational entities -- people, organizations, addresses, contact information, and relationships. BizApps Common solves this by providing a production-ready, schema-complete, fully-typed set of reusable business entities as a **MemberJunction Open App**.

Other MJ applications (Committees, Events, Membership, etc.) depend on these shared entities rather than building their own, eliminating duplication and enabling cross-application data sharing.

---

## Installation

BizApps Common is a [MemberJunction Open App](https://github.com/MemberJunction/MJ/tree/main/packages/OpenApp). Install it into any MJ environment using the [MJ CLI](https://github.com/MemberJunction/MJ/tree/main/packages/MJCLI):

```bash
mj app install https://github.com/MemberJunction/bizapps-common
```

This single command:

1. Fetches the `mj-app.json` manifest from this repository
2. Validates MJ version compatibility (`>=5.0.0 <6.0.0`)
3. Creates the `__mj_BizAppsCommon` database schema
4. Runs Skyway migrations to create all 11 tables
5. Installs npm packages into your MJAPI and MJExplorer workspaces
6. Configures server bootstrap (`@mj-biz-apps/common-server`) in `mj.config.cjs`
7. Adds client bootstrap (`@mj-biz-apps/common-ng`) to `open-app-bootstrap.generated.ts`

After installation, restart MJAPI and rebuild MJExplorer to activate.

### Manage the App

```bash
mj app list                    # See installed apps
mj app info bizapps-common     # Show details and version
mj app upgrade bizapps-common  # Upgrade to latest release
mj app disable bizapps-common  # Temporarily disable
mj app enable bizapps-common   # Re-enable
mj app remove bizapps-common   # Uninstall (--keep-data to preserve schema)
```

See [Open App Installation Guide](docs/open-app.md) for full details on how the Open App lifecycle works.

---

## What You Get

### 11 Database Tables

All tables live in the `__mj_BizAppsCommon` SQL schema, deployed via migrations.

| Category | Tables | Purpose |
|----------|--------|---------|
| **Core Entities** | Person, Organization, Address, ContactMethod, Relationship | The business objects themselves |
| **Type Lookups** | OrganizationType, AddressType, ContactType, RelationshipType | Configurable categorization |
| **Linking** | AddressLink | Polymorphic address attachment to any entity |

### 4 TypeScript Packages

| Package | NPM Name | Role |
|---------|----------|------|
| **Entities** | `@mj-biz-apps/common-entities` | Strongly-typed entity classes with Zod validation |
| **Actions** | `@mj-biz-apps/common-actions` | Server-side action handlers (e.g., postal code lookup) |
| **Server** | `@mj-biz-apps/common-server` | GraphQL resolvers and server bootstrap |
| **Angular** | `@mj-biz-apps/common-ng` | UI components, form overrides, CRUD widgets |

### 4 Reusable Angular Components

Production-ready, standalone Angular widgets that handle their own data loading, editing, and saving:

| Component | Selector | Features |
|-----------|----------|----------|
| **Address Editor** | `<bizapps-address-editor>` | Two-table CRUD, postal code autocomplete via Google Geocoding, primary management, inline editing |
| **Contact Method List** | `<bizapps-contact-method-list>` | Type-based icons, copy-to-clipboard, primary-per-type, open links |
| **Relationship List** | `<bizapps-relationship-list>` | Grouped timeline, directional labels, typeahead search, date ranges |
| **Org Hierarchy Tree** | `<bizapps-org-hierarchy-tree>` | Parent/child tree, click-to-navigate, batch loading |

### Custom Form Layouts

Polished form overrides for Person and Organization records with sectioned layouts and embedded CRUD widgets.

---

## Entity Model

```
                        ┌──────────────────┐
                        │  OrganizationType │
                        └────────┬─────────┘
                                 │
┌──────────┐            ┌────────┴─────────┐           ┌──────────────┐
│  Person  │◄──────────►│  Organization    │◄─────────►│ Organization │
│          │            │                  │  (parent)  │  (children)  │
└────┬─────┘            └────────┬─────────┘           └──────────────┘
     │                           │
     │    ┌──────────────────────┐│
     ├───►│   ContactMethod     │◄┘
     │    │  (PersonID or       │
     │    │   OrganizationID)   │──────► ContactType
     │    └──────────────────────┘
     │
     │    ┌──────────────────────┐       ┌─────────────┐
     ├───►│   AddressLink       │──────►│   Address    │
     │    │  (EntityID+RecordID)│       └─────────────┘
     │    │                     │──────► AddressType
     │    └──────────────────────┘
     │
     │    ┌──────────────────────┐
     ├───►│   Relationship      │──────► RelationshipType
     │    │  (From/To Person    │         (ForwardLabel,
     └───►│   or Organization)  │          ReverseLabel,
          └──────────────────────┘          IsDirectional)
```

### Key Design Patterns

**Polymorphic Address Linking** -- Addresses are standalone records joined to any entity via `AddressLink(EntityID, RecordID)`. This means any entity in the system can have addresses without schema changes.

**Directional Relationships** -- Each RelationshipType defines `ForwardLabel` and `ReverseLabel` (e.g., "is employee of" / "employs"). The UI automatically selects the correct label based on perspective.

**Contact Method Flexibility** -- ContactMethods attach to either a Person or Organization via nullable FKs. Primary flags are scoped per ContactType, so a person can have a primary email AND a primary phone.

See [Entity Model Reference](docs/entity-model.md) for the complete schema documentation.

---

## Using BizApps Common in Your Code

### Referencing Entities

```typescript
import { Metadata } from '@memberjunction/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

const md = new Metadata();
const person = await md.GetEntityObject<mjBizAppsCommonPersonEntity>(
    'MJ.BizApps.Common: People'
);
person.FirstName = 'Jane';
person.LastName = 'Smith';
person.Email = 'jane@example.com';
await person.Save();
```

### Querying Data

```typescript
import { RunView } from '@memberjunction/core';

const rv = new RunView();
const result = await rv.RunView<mjBizAppsCommonPersonEntity>({
    EntityName: 'MJ.BizApps.Common: People',
    ExtraFilter: "LastName = 'Smith'",
    OrderBy: 'FirstName ASC',
    ResultType: 'entity_object'
});

if (result.Success) {
    for (const person of result.Results) {
        console.log(`${person.FirstName} ${person.LastName}`);
    }
}
```

### Embedding Widgets in Your Angular Components

```html
<bizapps-address-editor
    [EntityName]="'MJ.BizApps.Common: People'"
    [RecordID]="person.ID"
    [EditMode]="true"
    (DataChanged)="onRefresh()">
</bizapps-address-editor>

<bizapps-contact-method-list
    [PersonID]="person.ID"
    [EditMode]="true"
    (DataChanged)="onRefresh()">
</bizapps-contact-method-list>

<bizapps-relationship-list
    [PersonID]="person.ID"
    [EntityName]="'MJ.BizApps.Common: People'"
    [EditMode]="true"
    (Navigate)="onNavigate($event)">
</bizapps-relationship-list>
```

---

## Seed Data

Deployed via migrations. Fully customizable per deployment.

| Type Table | Included Records |
|------------|-----------------|
| **OrganizationType** | Company, Non-Profit, Association, Government, Educational Institution, Healthcare |
| **AddressType** | Home, Work, Mailing, Billing, Shipping, Legal |
| **ContactType** | Phone, Mobile, Email, LinkedIn, Website, Fax, Twitter/X |
| **RelationshipType** | Spouse, Parent/Child, Sibling, Friend, Employee, Board Member, Member, Volunteer, Customer, Consultant, Subsidiary, Partner, Vendor, Affiliate |

---

## Building an App That Depends on BizApps Common

If you're building your own MJ Open App that references these entities (e.g., a Committees app that links members to Person records), declare the dependency in your `mj-app.json`:

```json
{
  "dependencies": {
    "bizapps-common": {
      "version": ">=1.0.0",
      "repository": "https://github.com/MemberJunction/bizapps-common"
    }
  }
}
```

When users install your app, the MJ CLI will automatically install BizApps Common first if it isn't already present.

---

## Contributing (Developer Setup)

To work on BizApps Common itself (not just use it), clone the repo and set up a local development environment:

```bash
git clone https://github.com/MemberJunction/bizapps-common.git
cd bizapps-common
npm install
```

### Configure Environment

Create a `.env` file at the repo root:

```env
DB_HOST=localhost
DB_PORT=1433
DB_DATABASE=YourDatabase
DB_USERNAME=sa
DB_PASSWORD=yourpassword
GRAPHQL_PORT=4101
```

### Deploy and Build

```bash
npm run mj:migrate                    # Create schema and tables
npx mj-sync push --dir ./metadata    # Load seed data
npm run mj:codegen                    # Generate TypeScript/GraphQL/Angular code
npm run build                         # Build all packages (Turborepo)
```

### Run Development Servers

```bash
npm run start:api      # GraphQL server at localhost:4101
npm run start:explorer # Angular app at localhost:4301
```

See [Development Guide](docs/development.md) for the full workflow including build commands, code generation, debugging, and conventions.

---

## Repository Structure

```
bizapps-common/
├── mj-app.json                    # MJ Open App manifest
├── apps/
│   ├── MJAPI/                     # GraphQL API server (port 4101)
│   └── MJExplorer/                # Angular UI application (port 4301)
├── packages/
│   ├── Entities/                   # @mj-biz-apps/common-entities
│   ├── Actions/                    # @mj-biz-apps/common-actions
│   ├── Server/                     # @mj-biz-apps/common-server
│   └── Angular/                    # @mj-biz-apps/common-ng
├── migrations/                     # Skyway SQL migrations
├── metadata/                       # Seed data (synced via mj-sync)
├── Demos/                          # Sample SQL data
└── docs/                           # Documentation
```

### Build Dependency Graph

```
Entities ──► Actions ──► Server ──► MJAPI
    │                      │
    └──────► Angular ──────┴──► MJExplorer
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Open App Installation](docs/open-app.md) | How the MJ Open App lifecycle works -- install, upgrade, remove |
| [Getting Started (Contributors)](docs/getting-started.md) | Full local dev setup with prerequisites and troubleshooting |
| [Architecture](docs/architecture.md) | System architecture, Open App pattern, data flow, and design decisions |
| [Entity Model](docs/entity-model.md) | Complete schema reference, ER diagram, relationships, and access patterns |
| [Angular Components](docs/angular-components.md) | Component API reference, usage examples, and styling guide |
| [Development Guide](docs/development.md) | Build system, code generation, TypeScript conventions, and Git workflow |
| [API & Server](docs/api-server.md) | GraphQL API, server bootstrap, actions system, and deployment |
| [Configuration](docs/configuration.md) | Environment variables, manifest files, and port reference |

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Platform** | [MemberJunction](https://github.com/MemberJunction/MJ) | 5.8.0 |
| **Runtime** | Node.js | 18+ |
| **Language** | TypeScript | 5.9 |
| **Database** | SQL Server / Azure SQL | 2019+ |
| **API** | GraphQL (Apollo Server) | -- |
| **UI Framework** | Angular | 21 |
| **Build** | Turborepo | 2.7 |
| **Validation** | Zod | 3.24 |
| **Auth** | MSAL / Auth0 | -- |

---

## License

ISC

---

<p align="center">
  Built on <a href="https://github.com/MemberJunction/MJ">MemberJunction</a> -- the open-source metadata-driven application platform.
</p>
