# Getting Started -- Contributor Setup

> **Not a contributor?** If you just want to install BizApps Common into your MJ environment, see the [Open App Installation Guide](open-app.md). This page is for developers who want to work on BizApps Common itself.

This guide walks you through setting up the **BizApps Common** repository for local development. You'll clone the repo, configure a database, run migrations, and start the dev servers.

---

## Prerequisites

Before you begin, ensure you have the following installed and configured:

| Requirement | Version |
|---|---|
| MemberJunction | v5.x or higher (currently on 5.8.0) |
| Node.js | 18+ (22+ recommended) |
| NPM | 10+ |
| SQL Server | 2019+ or Azure SQL |

**Important:** MemberJunction must already be installed and running with a configured database before proceeding. This repository builds on top of an existing MJ environment.

---

## Step-by-Step Setup

### 1. Clone the Repository and Install Dependencies

```bash
git clone https://github.com/MemberJunction/bizapps-common.git
cd bizapps-common
npm install
```

This is an NPM workspace monorepo. Running `npm install` at the repository root handles all packages automatically. **Never run `npm install` inside individual package directories.**

### 2. Configure Your Environment

Create a `.env` file at the repository root (or copy from `.env.example` if available):

```bash
cp .env.example .env
```

Configure the following values in your `.env` file:

```env
# Database Connection
DB_HOST=localhost
DB_PORT=1433
DB_DATABASE=YourMJDatabase
DB_USERNAME=your_username
DB_PASSWORD=your_password

# GraphQL Server
GRAPHQL_PORT=4101

# Authentication (MSAL or Auth0 - configure one)
# See the Authentication section below for details
```

**Note:** The file `apps/MJAPI/.env` is a symlink pointing to `../../.env` at the repo root. Do not create a separate `.env` file inside `apps/MJAPI/`.

### 3. Run Database Migrations

```bash
npm run mj:migrate
```

This creates the `__mj_BizAppsCommon` schema in your database with all 11 tables required by the application.

### 4. Sync Metadata

```bash
npx mj-sync push --dir ./metadata
```

This loads seed data into your database, including:

- OrganizationTypes
- AddressTypes
- ContactTypes
- RelationshipTypes
- Entity settings and configuration

### 5. Run Code Generation

```bash
npm run mj:codegen
```

CodeGen produces the following generated artifacts:

- TypeScript entity classes (in `packages/Entities/`)
- GraphQL resolvers (in `packages/Server/src/generated/`)
- Angular form components (in `packages/Angular/src/lib/generated/`)
- SQL views and stored procedures

**Do not manually edit files in generated directories.** CodeGen will overwrite them on the next run.

### 6. Build All Packages

```bash
npm run build
```

This uses Turborepo to build all packages in the correct dependency order. You can also build individual targets:

```bash
npm run build:generated    # Build generated packages only
npm run build:api          # Build the API server only
npm run build:explorer     # Build the Angular UI only
```

### 7. Start Development Servers

Start both servers at once:

```bash
npm start
```

Or start them separately in different terminals:

```bash
# Terminal 1 - GraphQL API server
npm run start:api

# Terminal 2 - Angular UI application
npm run start:explorer
```

### Development Server Ports

| Server | Port | URL |
|---|---|---|
| MJAPI (GraphQL) | 4101 | http://localhost:4101 |
| MJExplorer (Angular) | 4301 | http://localhost:4301 |

These ports are intentionally offset from the MJ core defaults (4001/4201) to avoid conflicts when running both environments simultaneously.

---

## Loading Demo Data

To populate your database with sample records for testing:

```bash
sqlcmd -S localhost -d YourDB -i "Demos/01_BizAppsCommon_Sample_Data.sql"
```

Replace `YourDB` with your actual database name and adjust the server connection as needed for your environment.

---

## Authentication

MJExplorer supports two authentication providers: **MSAL (Azure AD)** and **Auth0**.

### Server-Side Configuration

Set the appropriate environment variables in your `.env` file for your chosen provider.

### Client-Side Configuration

Update the Angular environment file at:

```
apps/MJExplorer/src/environments/environment.ts
```

Refer to the MemberJunction documentation for detailed authentication setup instructions.

---

## Updating MemberJunction Dependencies

When a new version of MemberJunction is released, update your dependencies:

```bash
./Update_MemberJunction_Packages_To_Latest.ps1
npm install
npm run build
```

After updating, verify that your application builds and runs correctly. Check the MemberJunction release notes for any breaking changes.

---

## Troubleshooting

### `npm install` Fails

1. **Check your Node.js version.** Run `node -v` and ensure it is 18 or higher (22+ recommended).
2. **Check your NPM version.** Run `npm -v` and ensure it is 10 or higher.
3. **Clear cached data and retry:**
   ```bash
   rm -rf node_modules
   rm package-lock.json
   npm install
   ```
4. **Verify network access** to the NPM registry and any private registries your organization uses.

### Migration Fails

1. **Ensure MJ core is already migrated.** BizApps Common migrations depend on core MemberJunction tables and schemas. Run MJ core migrations first if you have not already.
2. **Check database permissions.** The database user specified in `.env` must have permissions to create schemas, tables, views, and stored procedures.
3. **Verify database connectivity.** Confirm that `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, and `DB_PASSWORD` are correct in your `.env` file.
4. **Check SQL Server version.** SQL Server 2019 or later (or Azure SQL) is required.

### Build Fails

1. **Check MemberJunction version compatibility.** Ensure all `@memberjunction/*` packages in your `package.json` files are on compatible versions. Run the update script if needed.
2. **Rebuild from clean state:**
   ```bash
   rm -rf node_modules
   npm install
   npm run build
   ```
3. **Build individual packages** to isolate the failure:
   ```bash
   cd packages/Entities && npm run build
   cd packages/Server && npm run build
   cd packages/Angular && npm run build
   ```

### Port Conflicts

If ports 4101 or 4301 are already in use:

1. **For the API server:** Change `GRAPHQL_PORT` in your `.env` file to an available port.
2. **For the Angular app:** Update the port in the MJExplorer start script configuration.
3. **Check for other running MJ instances.** The core MJ environment uses ports 4001 and 4201 by default.

### CodeGen Fails

1. **Ensure the database is accessible** and migrations have been applied.
2. **Verify your `.env` configuration** has correct database credentials.
3. **Check that MemberJunction CLI tools are installed** and accessible in your PATH.

---

## Project Structure Reference

```
bizapps-common/
  mj-app.json              # MJ Open App manifest
  .env                     # Environment configuration (repo root)
  apps/
    MJAPI/                 # GraphQL API server (port 4101)
    MJExplorer/            # Angular UI application (port 4301)
  packages/
    Entities/              # @mj-biz-apps/common-entities (generated)
    Actions/               # @mj-biz-apps/common-actions (generated)
    Server/                # @mj-biz-apps/common-server (resolvers + bootstrap)
    Angular/               # @mj-biz-apps/common-ng (Angular components + bootstrap)
```

---

## Next Steps

- Browse the GraphQL playground at http://localhost:4101 to explore the API.
- Open MJExplorer at http://localhost:4301 to interact with the UI.
- Review the entity definitions in `packages/Entities/` to understand the data model.
- Consult the [MemberJunction documentation](https://docs.memberjunction.org) for platform-level guidance.
