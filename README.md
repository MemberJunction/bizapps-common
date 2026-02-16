# BizApps Common

Common business application entities (Person, Organization, Address, ContactMethod, Relationship) built as a reusable foundation on the [MemberJunction](https://github.com/MemberJunction/MJ) platform.

## The Problem

Business applications repeatedly implement the same foundational entities -- people, organizations, addresses, contact information, and relationships. Each implementation creates maintenance burden and prevents data sharing across applications.

## What This Provides

| Entity | Description |
|---|---|
| **Person** | Individual people with demographics, optionally linked to MJ system users |
| **Organization** | Companies, associations, government bodies with hierarchy support |
| **Address** | Polymorphic address records linkable to any entity |
| **ContactMethod** | Additional contact information (phone, email, social media, etc.) |
| **Relationship** | Typed, directional links between people and organizations |

## Schema Overview

All tables live in the `__mj_BizAppsCommon` SQL schema (11 tables):

**Core Entities** -- Person, Organization, Address, ContactMethod, Relationship
**Type Tables** -- OrganizationType, AddressType, ContactType, RelationshipType
**Linking** -- AddressLink (polymorphic address linker)

## Prerequisites

- **MemberJunction** v4.x or higher
- **Node.js** 22+
- **SQL Server** 2019+ or Azure SQL
- A configured MJ environment with database access

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy or edit `.env` with your database connection settings. See MemberJunction docs for required environment variables (DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD, auth provider settings).

### 3. Run Migrations

```bash
npm run mj:migrate
```

This creates the `__mj_BizAppsCommon` schema and all tables.

### 4. Sync Metadata

```bash
npx mj-sync push --dir ./metadata
```

This loads seed data for organization types, address types, contact types, and relationship types.

### 5. Run Code Generation

```bash
npm run mj:codegen
```

Generates TypeScript entity classes, GraphQL resolvers, and Angular components.

### 6. Build & Run

```bash
npm run build
npm start
```

## Directory Structure

```
.
├── apps/
│   ├── MJAPI/                 # GraphQL API server
│   └── MJExplorer/            # Angular UI
├── Demos/                     # Demo datasets (sample SQL data)
├── metadata/                  # Seed data (types and lookup values)
├── migrations/                # Flyway database migrations
├── packages/
│   ├── GeneratedEntities/     # Auto-generated entity classes
│   └── GeneratedActions/      # Auto-generated action classes
├── SQL Scripts/               # SQL views and stored procedures
├── mj.config.cjs              # MemberJunction configuration
└── turbo.json                 # Turbo build configuration
```

## Seed Data

Managed via the `metadata/` folder using `mj-sync`. Includes:

- **Organization Types**: Company, Non-Profit, Association, Government
- **Address Types**: Home, Work, Mailing, Billing
- **Contact Types**: Phone, Mobile, Email, LinkedIn, Website
- **Relationship Types**: Employment, Family, Professional relationships with directionality

## Using in Your Application

Once installed, you can reference and extend these entities in your own MemberJunction applications:

```typescript
import { PersonEntity, OrganizationEntity } from '@memberjunction/generatedentities';

// Create a person record
const md = new Metadata();
const person = await md.GetEntityObject<PersonEntity>('Person', contextUser);
person.FirstName = 'John';
person.LastName = 'Doe';
person.Email = 'john@example.com';
await person.Save();
```

## Development

### After Database Changes

```bash
npm run mj:migrate     # Run new migrations
npm run mj:codegen     # Regenerate TypeScript/GraphQL/Angular code
npm run build          # Rebuild all packages
```

### Updating MemberJunction Packages

```bash
./Update_MemberJunction_Packages_To_Latest.ps1
npm install
npm run build
```

## License

ISC
