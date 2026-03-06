# Configuration Reference

This document provides a comprehensive reference for all configuration files and environment variables used in the BizApps Common repository.

---

## Environment Variables (.env)

The `.env` file lives at the repo root. `apps/MJAPI/.env` is a symlink to `../../.env`.

### Database Connection (Required)

```env
DB_HOST=localhost
DB_PORT=1433
DB_DATABASE=YourDatabase
DB_USERNAME=sa
DB_PASSWORD=yourpassword
```

### GraphQL Server

```env
GRAPHQL_PORT=4101
```

Default is 4101 to avoid conflicts with MJ core (4001).

### Authentication

BizApps Common supports two auth providers:

#### MSAL (Azure AD)

```env
AUTH_TYPE=msal
TENANT_ID=your-tenant-id
CLIENT_ID=your-client-id
CLIENT_SECRET=your-client-secret
```

#### Auth0

```env
AUTH_TYPE=auth0
AUTH0_DOMAIN=your-domain.auth0.com
AUTH0_CLIENT_ID=your-client-id
AUTH0_CLIENT_SECRET=your-client-secret
```

---

## Angular Environment (Client-Side)

Located at `apps/MJExplorer/src/environments/environment.ts`:

```typescript
export const environment = {
    GRAPHQL_URI: 'http://localhost:4101/',
    GRAPHQL_WS_URI: 'ws://localhost:4101/',
    REDIRECT_URI: 'http://localhost:4301/',
    CLIENT_ID: 'your-client-id',
    TENANT_ID: 'your-tenant-id',
    AUTH_TYPE: 'msal',
    NODE_ENV: 'development',
    APPLICATION_NAME: 'MemberJunction Explorer',
    APPLICATION_INSTANCE: 'DEV',
    // ... other settings
};
```

---

## MemberJunction Configuration (mj.config.cjs)

Controls CodeGen behavior:

```javascript
module.exports = {
    mjConfig: {
        version: '3.0',
        output: {
            entityPackageName: '@mj-biz-apps/common-entities',
            entities: './packages/Entities/src/generated',
            actions: './packages/Actions/src/generated',
            graphql: './packages/Server/src/generated',
            angular: './packages/Angular/src/lib/generated',
            sql: './SQL Scripts/generated',
            schemaJson: './Schema Files'
        },
        postBuildCommands: [
            // Build each package after generation
        ]
    }
};
```

---

## MJ Open App Manifest (mj-app.json)

Declares the app to MJ's dynamic package loader:

```json
{
    "name": "bizapps-common",
    "displayName": "BizApps Common",
    "schema": {
        "name": "__mj_BizAppsCommon",
        "createIfNotExists": true
    },
    "packages": {
        "server": [{ "name": "@mj-biz-apps/common-server", "role": "bootstrap" }],
        "client": [{ "name": "@mj-biz-apps/common-ng", "role": "bootstrap" }],
        "shared": [
            { "name": "@mj-biz-apps/common-entities", "role": "library" },
            { "name": "@mj-biz-apps/common-actions", "role": "library" }
        ]
    }
}
```

---

## Metadata Sync Configuration (.mj-sync.json)

Controls seed data synchronization:

```json
{
    "version": "1.0.0",
    "push": { "autoCreateMissingRecords": true },
    "directoryOrder": [
        "schema-info",
        "address-types",
        "contact-types",
        "organization-types",
        "relationship-types",
        "entities"
    ]
}
```

---

## Turborepo Configuration (turbo.json)

Build orchestration:

- Build tasks are cached and depend on upstream packages.
- Start tasks are persistent (long-running) and not cached.

---

## Versioning Strategy

All BizApps packages share a single version track, currently at 5.4.0. This version is independent of MemberJunction's version. MemberJunction dependencies point to the installed MJ version (currently 5.8.0). Angular is at 21.1.3.

In short: BizApps packages have their own version lifecycle. When upgrading MJ, update the MJ dependency versions across all packages but keep the BizApps version on its own cadence.

---

## Ports Reference

| Service              | Port | Configured In              |
| -------------------- | ---- | -------------------------- |
| MJAPI (GraphQL)      | 4101 | .env (`GRAPHQL_PORT`)      |
| MJExplorer (Angular) | 4301 | MJExplorer start script    |
| MJ Core API (ref)    | 4001 | MJ .env                    |
| MJ Core Explorer (ref) | 4201 | MJ start script          |

BizApps Common uses ports 4101 and 4301 specifically to avoid conflicts when running alongside a MJ core development environment on 4001 and 4201.
