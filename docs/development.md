# BizApps Common - Development Workflow Guide

## Build System

### Turborepo
- Config: `turbo.json` at repo root
- `npm run build` builds all packages in dependency order
- Build outputs cached in `build/` and `dist/` directories
- Build dependency graph: Entities -> Actions -> Server -> Angular -> MJAPI -> MJExplorer

### Build Commands
```bash
npm run build              # Build everything (Turborepo)
npm run build:generated    # Build Entities + Actions only
npm run build:packages     # Build all @mj-biz-apps/* packages
npm run build:api          # Build MJAPI
npm run build:explorer     # Build MJExplorer
```

### Building Individual Packages
```bash
cd packages/Entities && npm run build    # tsc && tsc-alias
cd packages/Actions && npm run build     # tsc && tsc-alias
cd packages/Server && npm run build      # tsc && tsc-alias
cd packages/Angular && npm run build     # ngc (Angular Compiler)
```

## NPM Workspace Rules
- This is an NPM workspace monorepo
- ALWAYS run `npm install` at the repo root, NEVER inside individual packages
- To add a dependency: edit the package's `package.json`, then `npm install` at root

## Code Generation
```bash
npm run mj:codegen
```
- Reads database schema and MJ metadata
- Generates files in `src/generated/` directories:
  - `packages/Entities/src/generated/` - Entity TypeScript classes with Zod schemas
  - `packages/Actions/src/generated/` - Action TypeScript classes
  - `packages/Server/src/generated/` - GraphQL resolvers, class registrations
  - `packages/Angular/src/lib/generated/` - Angular form components and module
  - `SQL Scripts/generated/` - Views and stored procedures
  - `Schema Files/` - JSON schema exports
- NEVER manually edit generated files - CodeGen will overwrite them
- Config: `mj.config.cjs`

## Database Migrations
```bash
npm run mj:migrate
```
- Uses Skyway (Flyway-compatible) migration engine
- Migrations live in `/migrations/` directory
- Naming convention: `V{timestamp}__{description}.sql` for versioned, `B{timestamp}__{description}.sql` for baseline
- Rules:
  - Never include `__mj_CreatedAt`/`__mj_UpdatedAt` columns - CodeGen handles them
  - Never create indexes for FK columns - CodeGen creates them automatically

## Metadata Sync
```bash
npx mj-sync push --dir ./metadata
```
- Syncs seed data from JSON files to database
- Config: `.mj-sync.json` specifies directory order and options
- Directories processed in order: schema-info -> address-types -> contact-types -> organization-types -> relationship-types -> entities

## Development Servers
```bash
npm run start:api            # Port 4101
npm run start:explorer       # Port 4301
```
- MJExplorer uses Angular's dev server with Vite HMR
- MJAPI runs Node.js with dotenv

## Updating MemberJunction
```bash
./Update_MemberJunction_Packages_To_Latest.ps1
npm install
npm run build
```

## Debugging (VSCode)
Launch configurations available:
- **MJAPI**: Node.js debugger with source maps
- **MJExplorer**: Chrome debugger (port 4301)
- **MJExplorer (attach)**: Attach to existing Chrome on port 9222
- **Full Stack**: Compound config running both

Source maps scoped to local packages only (excluding node_modules).

## After Database Changes Workflow
1. Write migration SQL in `/migrations/`
2. `npm run mj:migrate` - apply migration
3. `npm run mj:codegen` - regenerate code
4. `npm run build` - rebuild everything
5. Test with `npm start`

## TypeScript Conventions
- Strict mode, explicit typing, NO `any` types ever
- PascalCase: classes, interfaces, public members
- camelCase: private/protected members, locals, parameters
- Static imports only (no dynamic `require()`/`import()`)
- Functional decomposition: max 30-40 lines per function
- ESM modules (`type: "module"` in `package.json`)

## Angular Conventions
- Modern template syntax: `@if`/`@for`/`@switch` (not `*ngIf`/`*ngFor`)
- `inject()` function for DI (not constructor injection)
- `ChangeDetectorRef.detectChanges()` after async operations
- `@Input()` getter/setter pattern for reactivity
- Font Awesome for icons
- No custom spinners - use `<mj-loading>` component

## Entity Data Access Patterns
```typescript
// CORRECT - Use Metadata system
const md = new Metadata();
const person = await md.GetEntityObject<PersonEntity>('MJ.BizApps.Common: People');

// CORRECT - RunView for queries
const rv = new RunView();
const result = await rv.RunView<PersonEntity>({
    EntityName: 'MJ.BizApps.Common: People',
    ExtraFilter: "LastName='Smith'",
    ResultType: 'entity_object'
});

// CORRECT - Batch queries
const [people, orgs] = await rv.RunViews([...]);

// WRONG - Never instantiate directly
const person = new PersonEntity(); // NO!

// WRONG - Never use spread on entities
const data = { ...person }; // NO! Use person.GetAll()
```

## Git Workflow
- Work in feature branches, not main
- Feature branches must track same-named remote: `git push -u origin my-feature`
- Never commit without explicit approval
- Never force push to main
