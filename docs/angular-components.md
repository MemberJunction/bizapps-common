# Angular Component Documentation -- @mj-biz-apps/common-ng

## Package Overview

| Property       | Value                          |
|----------------|--------------------------------|
| Package        | `@mj-biz-apps/common-ng`      |
| Version        | 5.4.0                         |
| Angular        | 21.1.3                        |
| Build          | ngc (Angular Compiler)        |
| Entry          | `src/public-api.ts`           |
| Bootstrap      | `LoadBizAppsCommonClient()`   |

---

## Component Categories

### 1. Reusable CRUD Widget Components (Standalone)

These are standalone components that can be embedded in any form. They handle their own data loading, editing, and saving.

---

#### AddressEditorComponent

- **Selector**: `<bizapps-address-editor>`
- **File**: `packages/Angular/src/lib/components/address-editor/address-editor.component.ts`

##### Inputs

| Input        | Type      | Description                                  |
|--------------|-----------|----------------------------------------------|
| `EntityName` | `string`  | e.g. `'MJ.BizApps.Common: People'`          |
| `RecordID`   | `string`  | The parent record's ID                       |
| `EditMode`   | `boolean` | Show/hide edit controls                      |

##### Outputs

| Output        | Type           | Description                          |
|---------------|----------------|--------------------------------------|
| `DataChanged` | `EventEmitter` | Emits when addresses are modified    |

##### Features

- Two-table CRUD: creates/updates both Address and AddressLink records.
- Compact table layout with type icons, badges, and primary star.
- Inline edit panel slides down within the table.
- Postal code autocomplete via Google Geocoding API (calls "Postal Code Lookup" MJ Action via `GraphQLActionClient`).
- Full ISO 3166-1 country dropdown (90+ countries).
- Set primary address (unsets previous primary).
- Loading spinner and "not found" indicator for postal lookup.
- `ActionEngineBase` cache prewarming on construction.

##### Data Pattern

Loads AddressLinks filtered by `(EntityID, RecordID)`, then batch-loads associated Address records. AddressTypes are loaded for the dropdown.

---

#### ContactMethodListComponent

- **Selector**: `<bizapps-contact-method-list>`
- **File**: `packages/Angular/src/lib/components/contact-method-list/contact-method-list.component.ts`

##### Inputs

| Input            | Type             | Description                                      |
|------------------|------------------|--------------------------------------------------|
| `PersonID`       | `string \| null` | ID of the parent Person (exactly one should be set) |
| `OrganizationID` | `string \| null` | ID of the parent Organization                    |
| `EditMode`       | `boolean`        | Show/hide edit controls                          |

##### Outputs

| Output        | Type           | Description                               |
|---------------|----------------|-------------------------------------------|
| `DataChanged` | `EventEmitter` | Emits when contact methods are modified   |

##### Features

- Single-table CRUD on the ContactMethod entity.
- Flat list with colored type icons (36px circles).
- Primary-per-type management (scoped by `ContactTypeID`).
- Copy-to-clipboard with brief feedback.
- Open links (`mailto:`, `tel:`, `https://`).
- Inline edit and add panels.
- Type-based icon and color mapping.

---

#### RelationshipListComponent

- **Selector**: `<bizapps-relationship-list>`
- **File**: `packages/Angular/src/lib/components/relationship-list/relationship-list.component.ts`

##### Inputs

| Input            | Type             | Description                              |
|------------------|------------------|------------------------------------------|
| `PersonID`       | `string \| null` | ID of the parent Person                  |
| `OrganizationID` | `string \| null` | ID of the parent Organization            |
| `EntityName`     | `string`         | e.g. `'MJ.BizApps.Common: People'`      |
| `EditMode`       | `boolean`        | Show/hide edit controls                  |

##### Outputs

| Output        | Type                          | Description                              |
|---------------|-------------------------------|------------------------------------------|
| `DataChanged` | `EventEmitter`                | Emits when relationships are modified    |
| `Navigate`    | `EventEmitter<FormNavigationEvent>` | Emits when user clicks a related record |

##### Features

- Grouped timeline layout by `RelationshipType.Category`.
- Smart directionality: shows `ForwardLabel` or `ReverseLabel` based on which side is the current entity.
- Category grouping: Employment, Personal, Professional, Organizational.
- Typeahead search for target person/organization.
- Date range support (`StartDate`/`EndDate`).
- Status badges (Active/Inactive/Ended based on dates).
- Navigation to related records via the `Navigate` output.

---

#### OrgHierarchyTreeComponent

- **Selector**: `<bizapps-org-hierarchy-tree>`
- **File**: `packages/Angular/src/lib/components/org-hierarchy-tree/` (if present)

##### Inputs

| Input            | Type     | Description                      |
|------------------|----------|----------------------------------|
| `OrganizationID` | `string` | ID of the current organization   |

##### Outputs

| Output     | Type                          | Description                              |
|------------|-------------------------------|------------------------------------------|
| `Navigate` | `EventEmitter<FormNavigationEvent>` | Emits when user clicks an org node |

##### Features

- Shows parent, current org, and children in a tree view.
- Batch loads related orgs via `RunView`.
- Click to navigate; Ctrl/Meta-click opens in a new tab.
- CSS-based indentation.

---

### 2. Custom Form Components (Module-declared)

These override the CodeGen-generated form components for Person and Organization. They are declared in `CustomFormsModule` (not standalone).

---

#### BizAppsPersonFormComponent

- **Selector**: `bizapps-person-form`
- **Registered for**: `MJ.BizApps.Common: People`
- **Extends**: `mjBizAppsCommonPersonFormComponent` (generated)
- **File**: `packages/Angular/src/lib/custom/Person/person-form.component.ts`

##### Form Sections

| Section                        | Default State | Contents                                       |
|--------------------------------|---------------|-------------------------------------------------|
| Personal Identity              | Expanded      | Name fields, prefix, suffix                    |
| Professional and Profile       | Expanded      | Title, company, bio                            |
| Account and Status             | Collapsed     | User link, active flag                         |
| Primary Address                | Collapsed     | Main address fields on Person record           |
| System Metadata                | Collapsed     | Created/updated timestamps                     |
| Addresses                      | Expanded      | `AddressEditorComponent` widget                |
| Contact Methods                | Expanded      | `ContactMethodListComponent` widget            |
| Relationships                  | Expanded      | `RelationshipListComponent` widget             |

##### Key Behavior

`OnWidgetDataChanged()` reloads the entity record when a widget saves data, provided there are no pending form edits.

---

#### BizAppsOrganizationFormComponent

- **Selector**: `bizapps-organization-form`
- **Registered for**: `MJ.BizApps.Common: Organizations`
- **Extends**: `mjBizAppsCommonOrganizationFormComponent` (generated)
- **File**: `packages/Angular/src/lib/custom/Organization/organization-form.component.ts`

##### Form Sections

| Section                        | Default State | Contents                                       |
|--------------------------------|---------------|-------------------------------------------------|
| Organization Identity          | Expanded      | Name and identifying fields                    |
| Hierarchy and Structure        | Expanded      | Parent org, structure details                  |
| Contact Information            | Collapsed     | Org-level contact info                         |
| Primary Address                | Collapsed     | Main address fields on Organization record     |
| System Metadata                | Collapsed     | Created/updated timestamps                     |
| Organization Hierarchy         | Expanded      | `OrgHierarchyTreeComponent` widget             |
| Addresses                      | Expanded      | `AddressEditorComponent` widget                |
| Contact Methods                | Expanded      | `ContactMethodListComponent` widget            |
| Relationships                  | Expanded      | `RelationshipListComponent` widget             |

---

### 3. Generated Form Components (CodeGen)

Located in `src/lib/generated/Entities/`. One form component per entity (10 total). These provide the base field layout that custom forms extend. Bundled in `GeneratedFormsModule`.

**Important**: Do NOT manually edit files in the generated directory. CodeGen will overwrite them.

---

## Usage Examples

### Embedding Widgets in a Form Template

```html
<!-- Address editor for a Person record -->
<bizapps-address-editor
    [EntityName]="'MJ.BizApps.Common: People'"
    [RecordID]="record.ID"
    [EditMode]="EditMode"
    (DataChanged)="OnWidgetDataChanged()">
</bizapps-address-editor>

<!-- Contact methods for a Person -->
<bizapps-contact-method-list
    [PersonID]="record.ID"
    [EditMode]="EditMode"
    (DataChanged)="OnWidgetDataChanged()">
</bizapps-contact-method-list>

<!-- Relationships for a Person -->
<bizapps-relationship-list
    [PersonID]="record.ID"
    [EntityName]="'MJ.BizApps.Common: People'"
    [EditMode]="EditMode"
    (DataChanged)="OnWidgetDataChanged()"
    (Navigate)="OnNavigate($event)">
</bizapps-relationship-list>
```

### Embedding Widgets in an Organization Form Template

```html
<!-- Organization hierarchy tree -->
<bizapps-org-hierarchy-tree
    [OrganizationID]="record.ID"
    (Navigate)="OnNavigate($event)">
</bizapps-org-hierarchy-tree>

<!-- Address editor for an Organization record -->
<bizapps-address-editor
    [EntityName]="'MJ.BizApps.Common: Organizations'"
    [RecordID]="record.ID"
    [EditMode]="EditMode"
    (DataChanged)="OnWidgetDataChanged()">
</bizapps-address-editor>

<!-- Contact methods for an Organization -->
<bizapps-contact-method-list
    [OrganizationID]="record.ID"
    [EditMode]="EditMode"
    (DataChanged)="OnWidgetDataChanged()">
</bizapps-contact-method-list>

<!-- Relationships for an Organization -->
<bizapps-relationship-list
    [OrganizationID]="record.ID"
    [EntityName]="'MJ.BizApps.Common: Organizations'"
    [EditMode]="EditMode"
    (DataChanged)="OnWidgetDataChanged()"
    (Navigate)="OnNavigate($event)">
</bizapps-relationship-list>
```

---

## Styling

- Each widget has its own scoped CSS (`ViewEncapsulation.Emulated`).
- Font Awesome icons are used throughout.
- Consistent design tokens:
  - Borders: `#e0e0e0`
  - Hover backgrounds: `#fafafa`
  - Primary blue: `#1976d2`
  - Green for primary items: `#f1f8e9`
- Badges use uppercase text, small font size, and rounded corners.

---

## Module Structure

| Module               | Type           | Description                                                    |
|----------------------|----------------|----------------------------------------------------------------|
| `GeneratedFormsModule` | Auto-generated | Contains all CodeGen-generated form components. DO NOT edit.  |
| `CustomFormsModule`    | Manual         | Contains custom form overrides. Imports all standalone widgets. |

Standalone widget components (`AddressEditorComponent`, `ContactMethodListComponent`, `RelationshipListComponent`, `OrgHierarchyTreeComponent`) are not declared in any module -- they are imported directly where needed.
