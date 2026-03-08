# Open App Installation Guide

BizApps Common is distributed as a [MemberJunction Open App](https://github.com/MemberJunction/MJ/tree/main/packages/OpenApp) -- a versioned, installable extension managed through the [MJ CLI](https://github.com/MemberJunction/MJ/tree/main/packages/MJCLI).

This document explains how Open Apps work, how to install BizApps Common, and how to manage it after installation.

---

## What is an Open App?

An Open App is MemberJunction's plugin and distribution system. It bundles everything needed -- database schema, migrations, metadata, server-side logic, and client-side UI components -- into a single installable unit.

Each Open App:

- **Owns a dedicated database schema** -- preventing collisions with MJ core or other apps
- **Ships as npm packages** -- server packages load into MJAPI, client packages load into MJExplorer
- **Uses semantic versioning** -- versions come from GitHub release tags
- **Manages its own migrations** -- Skyway (Flyway-compatible) runs SQL migrations scoped to the app's schema
- **Supports dependency chains** -- apps can depend on other Open Apps with semver ranges
- **Has a full lifecycle** -- install, upgrade, disable, enable, and remove via the `mj` CLI

---

## Prerequisites

- A running MemberJunction v5.x+ environment
- The [MJ CLI](https://github.com/MemberJunction/MJ/tree/main/packages/MJCLI) installed globally:
  ```bash
  npm install -g @memberjunction/cli
  ```
- Node.js 20+ and database credentials configured in your MJ environment

---

## Installing BizApps Common

```bash
mj app install https://github.com/MemberJunction/bizapps-common
```

To install a specific version:

```bash
mj app install https://github.com/MemberJunction/bizapps-common --version 1.0.0
```

### What Happens During Install

```
GitHub Repository (memberjunction-bizapps)
  mj-app.json  |  migrations/  |  packages/
        |
        v
MJ CLI Orchestrator
        |
        |  1. Fetch mj-app.json from GitHub (at the specified or latest tag)
        |  2. Validate manifest against Zod schema
        |  3. Check MJ version compatibility (>=5.0.0 <6.0.0)
        |  4. Resolve and install any dependency apps
        |  5. Create database schema (__mj_BizAppsCommon)
        |  6. Run Skyway migrations (create 11 tables, seed data, views)
        |  7. Add npm packages to MJAPI + MJExplorer package.json files
        |  8. Run package install (npm/pnpm/yarn -- auto-detected)
        |  9. Add @mj-biz-apps/common-server to mj.config.cjs (dynamicPackages)
        | 10. Add @mj-biz-apps/common-ng to open-app-bootstrap.generated.ts
        | 11. Record installation in MJ: Open Apps entity
        |
        v
+---------------------+     +-------------------------+
|  MJAPI (Server)      |     |  MJExplorer (Client)     |
|                      |     |                          |
|  mj.config.cjs:      |     |  open-app-bootstrap      |
|  dynamicPackages: {   |     |  .generated.ts:          |
|    server: [{         |     |                          |
|      PackageName:     |     |  import '@mj-biz-apps/   |
|       '@mj-biz-apps/  |     |   common-ng';            |
|        common-server', |     |                          |
|      StartupExport:   |     |  // Triggers             |
|       'LoadBizApps     |     |  // @RegisterClass       |
|        CommonServer'   |     |  // decorators           |
|    }]                 |     |                          |
|  }                    |     |                          |
+---------------------+     +-------------------------+
```

### After Installation

You **must** restart and rebuild for changes to take effect:

1. **Restart MJAPI** -- picks up the new server-side packages and GraphQL resolvers
2. **Rebuild MJExplorer** -- bundles the new Angular components via the updated bootstrap file

---

## The App Manifest

The `mj-app.json` at the repository root declares everything about BizApps Common:

```json
{
  "manifestVersion": 1,
  "name": "memberjunction-bizapps",
  "displayName": "BizApps Common",
  "description": "Common business entities shared across MemberJunction business applications",
  "version": "1.0.0",
  "license": "ISC",
  "icon": "fa-solid fa-building-columns",

  "publisher": {
    "name": "MemberJunction",
    "url": "https://memberjunction.com"
  },

  "repository": "https://github.com/MemberJunction/bizapps-common",
  "mjVersionRange": ">=5.0.0 <6.0.0",

  "schema": {
    "name": "__mj_BizAppsCommon",
    "createIfNotExists": true
  },

  "migrations": {
    "directory": "migrations",
    "engine": "skyway"
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
  },

  "categories": ["Business", "Foundation"],
  "tags": ["person", "organization", "address", "contact", "relationship"]
}
```

### Key Manifest Fields

| Field | Purpose |
|-------|---------|
| `name` | Unique app identifier used in CLI commands (`mj app info memberjunction-bizapps`) |
| `mjVersionRange` | Semver range -- CLI checks this before installation |
| `schema.name` | Database schema created for this app's tables |
| `packages.server` | Packages added to MJAPI; `bootstrap` role means `startupExport` is called at startup |
| `packages.client` | Packages added to MJExplorer; bootstrap import triggers `@RegisterClass` decorators |
| `packages.shared` | Packages added to both MJAPI and MJExplorer workspaces |

### Package Roles

| Role | Description | `startupExport` Required? |
|------|-------------|---------------------------|
| `bootstrap` | Entry point loaded at startup; triggers `@RegisterClass` decorators | Yes |
| `library` | Shared utilities and types | No |
| `actions` | MJ Action implementations | No |
| `module` | Angular modules | No |
| `components` | Angular components | No |

---

## Managing the App

### Check Installed Apps

```bash
mj app list
```

### View App Details

```bash
mj app info memberjunction-bizapps
```

### Upgrade

```bash
mj app upgrade memberjunction-bizapps                # Upgrade to latest
mj app upgrade memberjunction-bizapps --version 2.0.0  # Upgrade to specific version
```

The upgrade flow:
1. Validates the target version is newer than installed
2. Reuses the existing schema (Skyway only applies new migrations)
3. Updates npm packages to the new version
4. Updates the `MJ: Open Apps` record

### Disable / Enable

```bash
mj app disable memberjunction-bizapps  # Temporarily disable without removing
mj app enable memberjunction-bizapps   # Re-enable
```

Disabling comments out the server config entry and client bootstrap import. The schema and data remain intact.

### Remove

```bash
mj app remove memberjunction-bizapps              # Full removal (drops schema)
mj app remove memberjunction-bizapps --keep-data   # Remove packages but keep database
mj app remove memberjunction-bizapps --force       # Remove even if other apps depend on it
```

The remove flow:
1. Check for dependent apps (fails unless `--force`)
2. Remove config entries, client bootstrap imports, and npm packages
3. Run package install to clean up
4. Remove entity metadata for the app's schema
5. Drop the database schema (unless `--keep-data`)

---

## How Server-Side Loading Works

1. The CLI adds an entry to `mj.config.cjs`:
   ```javascript
   dynamicPackages: {
     server: [{
       PackageName: '@mj-biz-apps/common-server',
       StartupExport: 'LoadBizAppsCommonServer',
       AppName: 'memberjunction-bizapps',
       Enabled: true
     }]
   }
   ```

2. At MJAPI startup, the dynamic package loader:
   - Reads `dynamicPackages.server`
   - Calls `import('@mj-biz-apps/common-server')`
   - Calls the exported `LoadBizAppsCommonServer()` function

3. The import triggers `@RegisterClass` decorators on entity classes, action classes, and GraphQL resolvers, making them available to the MJ runtime.

---

## How Client-Side Loading Works

1. The CLI adds a static import to `open-app-bootstrap.generated.ts`:
   ```typescript
   // memberjunction-bizapps (v1.0.0)
   import '@mj-biz-apps/common-ng';
   ```

2. ESBuild includes the package in the MJExplorer bundle during build.

3. The import triggers `@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: People')` decorators, registering custom form components with MJ's ClassFactory.

4. When a user opens a Person or Organization record, MJ Explorer:
   - Looks up the form component via `ClassFactory.GetRegistration(BaseFormComponent, 'MJ.BizApps.Common: People')`
   - Instantiates BizApps Common's custom form (with Address Editor, Contact Methods, Relationships widgets)

---

## Depending on BizApps Common

If you're building your own MJ Open App that references BizApps Common entities, declare the dependency in your `mj-app.json`:

```json
{
  "dependencies": {
    "memberjunction-bizapps": {
      "version": ">=1.0.0",
      "repository": "https://github.com/MemberJunction/bizapps-common"
    }
  }
}
```

When users install your app, the MJ CLI will:
1. Perform a topological sort of the dependency graph
2. Automatically install BizApps Common first if it isn't present
3. Verify the installed version satisfies `>=1.0.0`

In your code, import the entity types directly:

```typescript
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
```

---

## Configuring Workspace Paths

If your MJ environment uses a non-standard layout, configure the `openApps` section in `mj.config.cjs`:

```javascript
module.exports = {
  // ... database config ...
  openApps: {
    serverPackagePath: 'apps/MJAPI',       // Default: 'packages/MJAPI'
    clientPackagePath: 'apps/MJExplorer',   // Default: 'packages/MJExplorer'
    packageManager: 'npm',                  // Auto-detected from lockfile
  }
};
```

---

## App Status Lifecycle

```
              install
     ────────────────────►  Installing
                                │ success
                                v
              disable       ┌────────┐       enable
         ──────────────────►│ Active │◄──────────────────
         │                  └───┬────┘                   │
         │                      │                        │
    ┌──────────┐           upgrade│              ┌──────────┐
    │ Disabled │                  v              │ Disabled │
    └──────────┘           ┌───────────┐        └──────────┘
                           │ Upgrading │
                           └─────┬─────┘
                                 │ success
                                 v
                            ┌────────┐
                            │ Active │
                            └───┬────┘
                                │ remove
                                v
                           ┌──────────┐
                           │ Removing │
                           └─────┬────┘
                                 │ success
                                 v
                           ┌──────────┐
                           │ Removed  │
                           └──────────┘
```

---

## Further Reading

- [MJ Open App Framework Documentation](https://github.com/MemberJunction/MJ/tree/main/packages/OpenApp)
- [MJ CLI Documentation](https://github.com/MemberJunction/MJ/tree/main/packages/MJCLI)
- [BizApps Common Architecture](architecture.md)
- [Entity Model Reference](entity-model.md)
