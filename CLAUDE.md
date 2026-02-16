# GENERAL RULE
Don't say "You're absolutely right" each time I correct you. Mix it up, that's so boring!

# BizApps Common Development Guide

This is a **shared library repository** built on top of the [MemberJunction](https://github.com/MemberJunction/MJ) platform. It provides common business entities (Person, Organization, Address, ContactMethod, Relationship) that can be consumed by other MemberJunction applications.

## Repository Structure

```
bizapps-common/
  apps/
    MJAPI/         - GraphQL API server (port 4101)
    MJExplorer/    - Angular UI application (port 4301)
  packages/
    GeneratedEntities/  - CodeGen-generated entity subclasses
    GeneratedActions/   - CodeGen-generated action subclasses
```

---

## CRITICAL RULES - VIOLATIONS ARE UNACCEPTABLE

### 1. NO COMMITS WITHOUT EXPLICIT APPROVAL
- **NEVER run `git commit` without the user explicitly asking you to**
- **Each commit requires ONE-TIME explicit approval** - don't assume ongoing permission
- **NEVER ask to commit** - wait for the user to request it
- **ONLY commit what is staged** - never modify or add to staged changes
- **NEVER commit work-in-progress** that isn't staged by the user

### 2. NO `any` TYPES - EVER
- **NEVER use `any` types in TypeScript code**
- **ALWAYS ask the user** if you think you need to use `any`
- This includes: No `as any`, No `: any`, No `<any>`, No `unknown` as a lazy alternative
- **Why**: MemberJunction has strong typing throughout - there's always a proper type available

### 3. NO MODIFICATIONS TO MERGED PRs
- **NEVER update title/description of merged PRs** without explicit approval each time

### 4. ANGULAR COMPONENT & MODULE STRATEGY
MemberJunction supports both standalone and NgModule-declared components. Choose the right approach for each situation:

#### When to Use Standalone Components (Preferred for New Components)
- **New leaf components** (dialogs, panels, small widgets) that don't need to share a module
- **Lazy-loaded route components** - standalone enables direct `loadComponent()` without wrapper modules
- **Simple, self-contained components** with clear dependency lists

#### When to Use NgModules
- **Feature modules** grouping many related components
- **Shared modules** providing common functionality to multiple consumers
- **Existing module-declared components** - don't migrate just for the sake of it

#### Rules for Both Approaches
- **Standalone components**: declare all dependencies in the component's `imports` array
- **NgModule components**: must use `standalone: false` explicitly (Angular 21 defaults to standalone)
- **Never mix within a single component** - a component is either standalone or module-declared
- When adding to an existing package, **follow the pattern already used in that package**

#### Modern Template Syntax (Required for New Code)
- **Use `@if`/`@for`/`@switch`** block syntax instead of `*ngIf`/`*ngFor`/`*ngSwitch`
- **Use `inject()` function** instead of constructor injection for new components

### 5. NO RE-EXPORTS BETWEEN PACKAGES
- **NEVER re-export types, classes, or interfaces from other packages**
- **ALWAYS** import directly from the source package that defines them

### 6. USE BaseSingleton FOR ALL SINGLETONS
- **NEVER use manual `static _instance` singleton patterns** - always extend `BaseSingleton<T>` from `@memberjunction/global`
- See MJ documentation for the pattern

---

## IMPORTANT
- Before starting a new line of work always check the local branch we're on and see if it is (a) separate from the default branch in the remote repo - we always want to work in local feature branches and (b) if we aren't in such a feature branch that is named for the work being requested and empty, cut a new one but ask first and then switch to it

**VERY IMPORTANT** We want you to be a high performance agent. Therefore whenever you need to spin up tasks - if they do not require interaction with the user and if they are not interdependent in any way, ALWAYS spin up multiple parallel tasks to work together for faster responses. **NEVER** process tasks sequentially if they are candidates for parallelization

## Git Branch Tracking Rules

### Feature Branches MUST Track Same-Named Remote Branches
When creating or working with feature branches, **ALWAYS** ensure the local branch tracks a remote branch **with the same name**. Never track `main` or other permanent branches.

```bash
# CORRECT
git checkout -b my-feature-branch
git push -u origin my-feature-branch

# WRONG - Branch created from main will track origin/main by default!
git checkout main
git checkout -b my-feature-branch
# Now my-feature-branch tracks origin/main - DANGEROUS!
```

### Before Every Push
1. Run `git branch -vv` to verify tracking
2. Ensure your branch tracks `origin/<same-branch-name>`
3. If tracking is wrong, fix it before pushing

---

## Build Commands
- Build all packages: `npm run build` (from repo root, uses Turborepo)
- Build generated packages: `npm run build:generated`
- Build API only: `npm run build:api`
- Build Explorer only: `npm run build:explorer`
- Start API server: `npm run start:api` (port 4101)
- Start Explorer UI: `npm run start:explorer` (port 4301)
- Build specific package: `cd packages/PackageName && npm run build`
- **IMPORTANT**: When building individual packages for testing/compilation, always use `npm run build` in the specific package directory

### Build Pipeline
- MJExplorer uses the Angular `application` builder powered by ESBuild and Vite
- Dev server uses Vite with HMR for fast iteration
- Source maps are configured for full debugging support including local packages

### NPM Workspace Management
- This is an NPM workspace monorepo
- **IMPORTANT**: To add dependencies to a specific package:
  - Define dependencies in the individual package's package.json
  - Run `npm install` at the repository root (NOT within the package directory)
  - Never run `npm install` inside individual package directories

## Development Workflow
- **CRITICAL**: After making code changes, always compile the affected package by running `npm run build` in that package's directory to check for TypeScript errors
- Fix all compilation errors before proceeding with additional changes
- **Tasks**: whenever you need to spin up tasks - if they do not require interaction with the user and if they are not interdependent in any way, ALWAYS spin up multiple parallel tasks to work together for faster responses

## Ports
- MJAPI GraphQL server: **4101** (configured via `GRAPHQL_PORT` in `.env`)
- MJExplorer Angular app: **4301** (configured in MJExplorer start script)
- These avoid conflicts with other MJ dev environments (MJ uses 4001/4201)

## Environment Configuration
- The repo root `.env` file contains all configuration (DB, auth, AI keys, etc.)
- `apps/MJAPI/.env` is a **symlink** to `../../.env` - do not create a separate file there
- Angular environment files are in `apps/MJExplorer/src/environments/`

---

## Code Style Guide
- Use TypeScript strict mode and explicit typing
- Always use MemberJunction generated `BaseEntity` sub-classes for all data work for strong typing
- No explicit `any` types - see CRITICAL RULES section above
- Prefer union types over enums for better package exports
- Prefer object shorthand syntax
- Follow existing naming conventions:
  - PascalCase for classes and interfaces
  - **PascalCase for public class members** (properties, methods, `@Input()`, `@Output()`)
  - **camelCase for private/protected class members**
  - camelCase for local variables and function parameters
  - Use descriptive names and avoid abbreviations
- Imports: group imports by type (external, internal, relative)
- Error handling: use try/catch blocks and provide meaningful error messages
- Keep functions focused and concise
- **NEVER use dynamic require() or import() statements** - always use static imports at the top of files unless explicitly requested

### Functional Decomposition Is Mandatory
- **NEVER** write long, monolithic functions that do multiple things
- **ALWAYS** decompose complex operations into smaller, well-named helper functions
- **MAXIMUM** function length should be ~30-40 lines (excluding comments)
- If a function is getting long, STOP and refactor it immediately

---

## MemberJunction Entity and Data Access Patterns

### Entity Object Creation
**Never directly instantiate BaseEntity subclasses** - always use the Metadata system:

```typescript
// WRONG - bypasses MJ class system
const entity = new PersonEntity();

// CORRECT - uses MJ metadata system
const md = new Metadata();
const entity = await md.GetEntityObject<PersonEntity>('Person');
```

### BaseEntity Spread Operator Limitation
**CRITICAL**: Never use the spread operator (`...`) directly on BaseEntity-derived classes. Use `GetAll()` instead:

```typescript
// WRONG
const data = { ...myEntity, extraField: 'value' };

// CORRECT
const data = { ...myEntity.GetAll(), extraField: 'value' };
```

### Server-Side Context User Requirements
When working on server-side code, **ALWAYS** pass `contextUser` to `GetEntityObject` and `RunView` methods:

```typescript
// WRONG - missing contextUser on server
const entity = await md.GetEntityObject<SomeEntity>('Entity Name');

// CORRECT - includes contextUser for server-side operations
const entity = await md.GetEntityObject<SomeEntity>('Entity Name', contextUser);
```

### Loading Records with RunView
```typescript
const rv = new RunView();
const results = await rv.RunView<PersonEntity>({
    EntityName: 'Person',
    ExtraFilter: `LastName='Smith'`,
    OrderBy: 'FirstName ASC',
    ResultType: 'entity_object'  // Returns actual entity objects
});
```

### RunView Error Handling
**Important**: RunView does NOT throw exceptions. Check `Success` property:

```typescript
const result = await rv.RunView<SomeEntity>({...});
if (result.Success) {
    const items = result.Results || [];
} else {
    console.error('Failed:', result.ErrorMessage);
}
```

### ResultType: entity_object vs simple
- Use `entity_object` when you need to **mutate and save** records
- Use `simple` with `Fields` parameter when you only need to **read/display** data
- **DO NOT** use `Fields` parameter with `entity_object` - it is automatically ignored

### Batch Queries with RunViews
Use `RunViews` (plural) for multiple independent queries:

```typescript
const rv = new RunView();
const [people, orgs] = await rv.RunViews([
    { EntityName: 'Person', ExtraFilter: '', ResultType: 'entity_object' },
    { EntityName: 'Organization', ExtraFilter: '', ResultType: 'entity_object' }
]);
```

---

## Angular Development Best Practices

### Change Detection
- Add `ChangeDetectorRef` and use `cdr.detectChanges()` after programmatic changes
- Replace `setTimeout` with `Promise.resolve().then()` for microtask timing

### Input Properties - Use Getter/Setters
```typescript
// GOOD - Precise control with getter/setter
private _myInput: string | null = null;

@Input()
set myInput(value: string | null) {
    const prev = this._myInput;
    this._myInput = value;
    if (value && value !== prev) this.onMyInputChanged(value);
}
get myInput(): string | null { return this._myInput; }
```

### Loading Indicators
- **ALWAYS** use the `<mj-loading>` component from `@memberjunction/ng-shared-generic`
- **NEVER** create custom spinners

### Dialog Button Placement
- **Confirm/Submit buttons go on the LEFT**, Cancel buttons on the RIGHT

### Icon Libraries
- **Primary**: Font Awesome (already included)

---

## CodeGen

This repo uses MemberJunction's CodeGen system to generate entity and action subclasses. The generated code lives in:
- `packages/GeneratedEntities/` - Entity TypeScript classes with Zod schemas
- `packages/GeneratedActions/` - Action TypeScript classes

**Key rules:**
- Never manually edit files in generated directories - CodeGen will overwrite them
- Always run CodeGen after database schema changes
- Run `npm run mj:codegen` from repo root to regenerate

## Database Migrations
- Run `npm run mj:migrate` from repo root
- See MJ documentation for migration file format and conventions
- Never include `__mj_CreatedAt`/`__mj_UpdatedAt` columns in CREATE TABLE - CodeGen handles them
- Never create indexes for foreign key columns - CodeGen creates them automatically

---

## Debugging

### VSCode Launch Configurations
- **MJAPI**: Node.js debugger with source maps for local packages
- **MJExplorer**: Chrome debugger (port 4301) with source maps
- **MJExplorer (attach)**: Attach to existing Chrome on port 9222
- **Full Stack**: Compound configuration running both MJAPI + MJExplorer

### Source Map Scoping
Source maps are scoped to local packages only (`apps/MJAPI/**`, `packages/GeneratedEntities/**`, `packages/GeneratedActions/**`). Third-party packages and node_modules are excluded to avoid noise.

---

## Performance Best Practices

### Batch Database Operations
- Use `RunViews` (plural) instead of multiple `RunView` calls
- Group related queries together in a single batch operation

### Avoid Per-Item Queries in Loops
- **NEVER** make RunView calls inside loops
- Load all data once, then process client-side

### Use View Fields Instead of Lookups
- Most MJ views include denormalized fields from related entities
- Use the denormalized field directly instead of a separate lookup query

---

## GitHub Repository
- Repository: https://github.com/MemberJunction/bizapps-common
- Default branch: `main`
- PRs target `main`

## Purpose

This repository provides foundational business entities that can be consumed by other MemberJunction applications (like Committees, Events, etc.). Applications can:

1. Reference the BizApps entities directly in their own migrations/schemas
2. Link their application-specific entities to Person, Organization, etc.
3. Extend the core entities with additional fields or relationships

**Example**: The Committees application links Committee Members to BizApps Person records.
