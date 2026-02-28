# @mj-biz-apps/common-ng

Angular bootstrap and reusable UI component library for the **BizApps Common** MemberJunction Open App. Provides form components, data widgets, and composed detail views for People, Organizations, and their related data (addresses, contact methods, relationships).

## Installation

```bash
npm install @mj-biz-apps/common-ng
```

**Peer dependencies:** `@angular/core >=21`, `@angular/common >=21`

## Quick Start

Import and call the bootstrap function during application initialization to register all entity classes and form components with MemberJunction's class factory:

```typescript
import { LoadBizAppsCommonClient } from '@mj-biz-apps/common-ng';

// Call during app bootstrap (e.g., in APP_INITIALIZER or main.ts)
LoadBizAppsCommonClient();
```

For NgModule-based applications, import the form modules:

```typescript
import { GeneratedFormsModule, CustomFormsModule } from '@mj-biz-apps/common-ng';

@NgModule({
    imports: [GeneratedFormsModule, CustomFormsModule]
})
export class AppModule {}
```

---

## Architecture

The package follows a three-tier component architecture:

```
Form Components (NgModule-declared, @RegisterClass)
  └── Composed Detail Views (standalone)
        └── Atomic Widgets (standalone)
```

1. **Atomic Widgets** — Small, focused, reusable standalone components that handle one concern (e.g., a header bar, a section of form fields, or a CRUD list).
2. **Composed Detail Views** — Standalone components that assemble multiple atomic widgets into a complete layout for a specific entity (Person Command Center, Organization HQ View).
3. **Form Components** — NgModule-declared components registered with MJ's class factory via `@RegisterClass`. They wrap a composed detail view inside `mj-record-form-container` to get the standard MJ form chrome (save/delete toolbar, navigation, favorites, history).

---

## Components

### Atomic Widgets — Person

| Component | Selector | Description |
|---|---|---|
| `PersonHeaderComponent` | `<bizapps-person-header>` | Dark gradient header with avatar initials, name, job title, and organization navigation link |
| `PersonSummaryCardsComponent` | `<bizapps-person-summary-cards>` | Four metric cards showing email, phone, address count, and relationship count (lazy-loaded) |
| `PersonIdentitySectionComponent` | `<bizapps-person-identity-section>` | Section card with identity fields: name, preferred name, prefix/suffix/gender, date of birth |
| `PersonProfessionalSectionComponent` | `<bizapps-person-professional-section>` | Section card with professional fields: title, job title, organization link, email, phone, bio |
| `PersonAccountSectionComponent` | `<bizapps-person-account-section>` | Section card with account fields: linked user and status |

### Atomic Widgets — Organization

| Component | Selector | Description |
|---|---|---|
| `OrgHeaderComponent` | `<bizapps-org-header>` | Top bar with logo initial, name, type badge, status, founded year, and website action |
| `OrgIdentitySectionComponent` | `<bizapps-org-identity-section>` | Panel card with all organization detail fields: name, legal name, type, status, contacts, parent, description |
| `OrgHierarchyTreeComponent` | `<bizapps-org-hierarchy-tree>` | Self-loading tree view showing parent, current, and child organizations with navigation |

### Atomic Widgets — CRUD Data

| Component | Selector | Description |
|---|---|---|
| `AddressEditorComponent` | `<bizapps-address-editor>` | Full CRUD for addresses via the AddressLink polymorphic pattern. Compact table layout with inline editing, primary badge, and type management |
| `ContactMethodListComponent` | `<bizapps-contact-method-list>` | Full CRUD for contact methods (email, phone, social, etc.) with icon-coded types, copy-to-clipboard, and primary designation |
| `RelationshipListComponent` | `<bizapps-relationship-list>` | Grouped relationship viewer organized by category (Employment, Personal, Business) with directional label logic and navigation events |

### Composed Detail Views

| Component | Selector | Description |
|---|---|---|
| `PersonDetailComponent` | `<bizapps-person-detail>` | **Command Center** layout — dark header, summary cards, two-column body with all person sections and CRUD widgets |
| `OrgDetailComponent` | `<bizapps-org-detail>` | **HQ View** layout — dark icon sidebar, header bar, two-column body with identity, hierarchy tree, and CRUD widgets |

### Form Components

| Component | Selector | Registered Entity |
|---|---|---|
| `BizAppsPersonFormComponent` | `<bizapps-person-form>` | `MJ.BizApps.Common: People` |
| `BizAppsOrganizationFormComponent` | `<bizapps-organization-form>` | `MJ.BizApps.Common: Organizations` |

---

## Usage Examples

### Standalone Widgets

All atomic widgets and composed detail views are **standalone components** that can be imported directly into any Angular component or module:

```html
<!-- Person Command Center (all-in-one) -->
<bizapps-person-detail
    [Record]="personEntity"
    [EditMode]="isEditing"
    [FormContext]="formContext"
    (Navigate)="onNavigate($event)">
</bizapps-person-detail>

<!-- Organization HQ View (all-in-one) -->
<bizapps-org-detail
    [Record]="orgEntity"
    [EditMode]="isEditing"
    [FormContext]="formContext"
    (Navigate)="onNavigate($event)">
</bizapps-org-detail>
```

### Individual Widgets

Use atomic widgets independently when you only need part of the layout:

```html
<!-- Address editor for any entity that supports the AddressLink pattern -->
<bizapps-address-editor
    EntityName="MJ.BizApps.Common: People"
    [RecordID]="personId">
</bizapps-address-editor>

<!-- Contact methods for a person -->
<bizapps-contact-method-list
    [PersonID]="personId">
</bizapps-contact-method-list>

<!-- Contact methods for an organization -->
<bizapps-contact-method-list
    [OrganizationID]="orgId">
</bizapps-contact-method-list>

<!-- Relationships for a person -->
<bizapps-relationship-list
    [PersonID]="personId"
    (Navigate)="onNavigate($event)">
</bizapps-relationship-list>

<!-- Organization hierarchy tree (self-loading) -->
<bizapps-org-hierarchy-tree
    [OrganizationID]="orgId"
    (Navigate)="onNavigate($event)">
</bizapps-org-hierarchy-tree>

<!-- Person header only -->
<bizapps-person-header
    [Record]="personEntity"
    (Navigate)="onNavigate($event)">
</bizapps-person-header>
```

---

## Inputs & Outputs Reference

### Common Inputs (Section Widgets)

| Input | Type | Default | Description |
|---|---|---|---|
| `Record` | Entity object | `undefined` | The MJ entity record to display |
| `EditMode` | `boolean` | `false` | Whether fields are editable or read-only |
| `FormContext` | `FormContext` | `undefined` | Shared form state (validation, visibility settings) |

### Common Outputs

| Output | Type | Description |
|---|---|---|
| `Navigate` | `EventEmitter<FormNavigationEvent>` | Emitted when a navigation link is clicked (org link, relationship target, hierarchy node). The parent handles actual routing. |

### AddressEditor Inputs

| Input | Type | Description |
|---|---|---|
| `EntityName` | `string` | MJ entity name (e.g. `'MJ.BizApps.Common: People'`) |
| `RecordID` | `string` | ID of the parent record |

### ContactMethodList Inputs

| Input | Type | Description |
|---|---|---|
| `PersonID` | `string \| null` | Person record ID (set one) |
| `OrganizationID` | `string \| null` | Organization record ID (set one) |

### RelationshipList Inputs

| Input | Type | Description |
|---|---|---|
| `PersonID` | `string \| null` | Person record ID (set one) |
| `OrganizationID` | `string \| null` | Organization record ID (set one) |

### OrgHierarchyTree Inputs

| Input | Type | Description |
|---|---|---|
| `OrganizationID` | `string \| null` | Organization ID to build the tree around |

### OrgHeader Outputs

| Output | Type | Description |
|---|---|---|
| `Navigate` | `EventEmitter<FormNavigationEvent>` | Parent org navigation |
| `WebsiteClick` | `EventEmitter<string>` | Emitted with the website URL when the button is clicked |

---

## Data Access Patterns

All components use MemberJunction's `RunView` / `RunViews` for data access:

- **AddressEditor**: Two-table pattern via `Address` + `AddressLink` entities. Batch-loads addresses, types, and links.
- **ContactMethodList**: Single-table CRUD on `ContactMethod` entity, with `ContactType` lookup for icons.
- **RelationshipList**: Loads `Relationship` entities with directional label logic (ForwardLabel/ReverseLabel) and groups by `RelationshipType.Category`.
- **OrgHierarchyTree**: Self-loading tree that batch-queries parent, current, and child organizations in a single `RunViews` call.
- **PersonSummaryCards**: Lazy-loads address and relationship counts via `RunViews` with `ResultType: 'simple'`.

---

## Exports

The package re-exports everything needed for consumption:

```typescript
// Bootstrap
export { LoadBizAppsCommonClient } from '@mj-biz-apps/common-ng';
export { CLASS_REGISTRATIONS } from '@mj-biz-apps/common-ng';

// Modules
export { GeneratedFormsModule } from '@mj-biz-apps/common-ng';
export { CustomFormsModule } from '@mj-biz-apps/common-ng';

// All 13 standalone components
export { PersonHeaderComponent } from '@mj-biz-apps/common-ng';
export { PersonSummaryCardsComponent } from '@mj-biz-apps/common-ng';
export { PersonIdentitySectionComponent } from '@mj-biz-apps/common-ng';
export { PersonProfessionalSectionComponent } from '@mj-biz-apps/common-ng';
export { PersonAccountSectionComponent } from '@mj-biz-apps/common-ng';
export { PersonDetailComponent } from '@mj-biz-apps/common-ng';
export { OrgHeaderComponent } from '@mj-biz-apps/common-ng';
export { OrgIdentitySectionComponent } from '@mj-biz-apps/common-ng';
export { OrgHierarchyTreeComponent, OrgTreeNode } from '@mj-biz-apps/common-ng';
export { OrgDetailComponent } from '@mj-biz-apps/common-ng';
export { AddressEditorComponent } from '@mj-biz-apps/common-ng';
export { ContactMethodListComponent } from '@mj-biz-apps/common-ng';
export { RelationshipListComponent } from '@mj-biz-apps/common-ng';
```

---

## Build

```bash
cd packages/Angular
npm run build    # Runs ngc (Angular compiler)
```

The output is written to `dist/` and consumed via the `main` and `types` fields in `package.json`.

---

## Design Decisions

- **Standalone components** for all widgets ensures maximum reusability. Each component declares its own dependencies and can be imported anywhere without requiring a shared NgModule.
- **NgModule-declared form components** are required because MJ's `@RegisterClass(BaseFormComponent, ...)` pattern expects components to be declared in a module for the class factory to resolve them.
- **No routing** in any component. Navigation events are emitted as outputs; the containing application handles routing.
- **`@if`/`@for` block syntax** used throughout (Angular 21 modern template syntax).
- **`inject()` function** used for DI instead of constructor injection.
- **PascalCase** for all public members, **camelCase** for private/protected, per MJ conventions.
