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

// Import custom form components (must come AFTER generated to override via @RegisterClass priority)
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

/**
 * Bootstrap function called during MJExplorer initialization.
 * Static imports above handle all registration.
 */
export function LoadBizAppsCommonClient(): void {
    // Static imports ensure all classes are registered.
}
