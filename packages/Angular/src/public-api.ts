/**
 * BizApps Common Angular Bootstrap
 *
 * Client-side bootstrap package for the BizApps Common Open App.
 * Imports all entity classes and form components to ensure @RegisterClass
 * decorators fire and components are available to MJ's class factory.
 */

// Import entity package to trigger @RegisterClass decorators for entity subclasses
import '@mj-biz-apps/common-entities';

// Import generated form components (triggers @RegisterClass for form components)
import './lib/generated/generated-forms.module';

// Import custom form panels so @RegisterClassEx contributions fire
import './lib/custom/custom-forms.module';

// Import class registrations manifest
import { CLASS_REGISTRATIONS } from './lib/generated/class-registrations-manifest';

// Re-export for consumers
export { CLASS_REGISTRATIONS } from './lib/generated/class-registrations-manifest';
export { GeneratedFormsModule } from './lib/generated/generated-forms.module';
export { CustomFormsModule } from './lib/custom/custom-forms.module';

// Reusable UI components
export { AddressEditorComponent } from './lib/components/address-editor/address-editor.component';
export { ContactMethodListComponent } from './lib/components/contact-method-list/contact-method-list.component';
export { RelationshipListComponent } from './lib/components/relationship-list/relationship-list.component';
export { OrgHierarchyTreeComponent, OrgTreeNode } from './lib/components/org-hierarchy-tree/org-hierarchy-tree.component';
export { CommonRelationshipGraphComponent } from './lib/components/relationship-graph/common-relationship-graph.component';
export { StatTileComponent, type StatTileTone } from './lib/components/stat-tile/stat-tile.component';
export { StatRowComponent } from './lib/components/stat-tile/stat-row.component';
export { PersonIdentityComponent } from './lib/components/identity-header/person-identity.component';
export { OrganizationIdentityComponent } from './lib/components/identity-header/organization-identity.component';
export { ActivityIdentityComponent } from './lib/components/identity-header/activity-identity.component';
export { ActivityTypeHierarchyPanel } from './lib/custom/panels/activity-type-hierarchy.panel';
export { ActivityHierarchyPanel } from './lib/custom/panels/activity-hierarchy.panel';
export { ActivityHeaderPanel } from './lib/custom/panels/activity-header.panel';
export { ActivityLinksPanel } from './lib/custom/panels/activity-links.panel';
export { ActivityFilesPanel } from './lib/custom/panels/activity-files.panel';
export { ActivityContentPanel } from './lib/custom/panels/activity-content.panel';

// Directory dashboard + People / Organizations lists / Graph / Activities (Explorer Custom nav)
import './lib/sections/common-sections.component';
import { LoadCommonSectionResources } from './lib/sections/common-sections.component';
export {
    LoadCommonSectionResources,
    CommonDirectoryResource,
    CommonPeopleResource,
    CommonOrganizationsResource,
    CommonRelationshipGraphResource,
    CommonActivitiesResource
} from './lib/sections/common-sections.component';
export { CommonDashboardPageComponent } from './lib/pages/common-dashboard.page';
export { CommonPeoplePageComponent } from './lib/pages/people-list.page';
export { CommonOrganizationsPageComponent } from './lib/pages/organizations-list.page';
export { CommonActivitiesPageComponent } from './lib/pages/activities-dashboard.page';

/**
 * Bootstrap function called during MJExplorer initialization.
 * Static imports above handle all registration.
 */
export function LoadBizAppsCommonClient(): void {
    LoadCommonSectionResources();
}
