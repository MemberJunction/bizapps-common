import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { BaseFormsModule } from '@memberjunction/ng-base-forms';

import { AddressEditorComponent } from '../components/address-editor/address-editor.component';
import { ContactMethodListComponent } from '../components/contact-method-list/contact-method-list.component';
import { RelationshipListComponent } from '../components/relationship-list/relationship-list.component';
import { OrgHierarchyTreeComponent } from '../components/org-hierarchy-tree/org-hierarchy-tree.component';
import { CommonRelationshipGraphComponent } from '../components/relationship-graph/common-relationship-graph.component';

import { PersonIdentityComponent } from '../components/identity-header/person-identity.component';
import { OrganizationIdentityComponent } from '../components/identity-header/organization-identity.component';
import { ActivityIdentityComponent } from '../components/identity-header/activity-identity.component';
import { PersonHeaderPanel } from './panels/person-header.panel';
import { OrganizationHeaderPanel } from './panels/organization-header.panel';
import { ActivityHeaderPanel } from './panels/activity-header.panel';
import { PersonAddressesPanel } from './panels/person-addresses.panel';
import { PersonContactMethodsPanel } from './panels/person-contact-methods.panel';
import { PersonRelationshipsPanel } from './panels/person-relationships.panel';
import { OrganizationAddressesPanel } from './panels/organization-addresses.panel';
import { OrganizationContactMethodsPanel } from './panels/organization-contact-methods.panel';
import { OrganizationRelationshipsPanel } from './panels/organization-relationships.panel';
import { OrganizationHierarchyPanel } from './panels/organization-hierarchy.panel';
import { ActivityTypeHierarchyPanel } from './panels/activity-type-hierarchy.panel';
import { ActivityHierarchyPanel } from './panels/activity-hierarchy.panel';
import { ActivityLinksPanel } from './panels/activity-links.panel';
import { ActivityFilesPanel } from './panels/activity-files.panel';
import { ActivityContentPanel } from './panels/activity-content.panel';

const PANELS = [
    PersonHeaderPanel,
    OrganizationHeaderPanel,
    ActivityHeaderPanel,
    PersonAddressesPanel,
    PersonContactMethodsPanel,
    PersonRelationshipsPanel,
    OrganizationAddressesPanel,
    OrganizationContactMethodsPanel,
    OrganizationRelationshipsPanel,
    OrganizationHierarchyPanel,
];

/**
 * Registers People/Organization/Activity BaseFormPanel contributions.
 */
@NgModule({
    declarations: [...PANELS],
    imports: [
        CommonModule,
        BaseFormsModule,
        AddressEditorComponent,
        ContactMethodListComponent,
        RelationshipListComponent,
        OrgHierarchyTreeComponent,
        CommonRelationshipGraphComponent,
        PersonIdentityComponent,
        OrganizationIdentityComponent,
        ActivityIdentityComponent,
        ActivityTypeHierarchyPanel,
        ActivityHierarchyPanel,
        ActivityLinksPanel,
        ActivityFilesPanel,
        ActivityContentPanel,
    ],
    exports: [
        ...PANELS,
        PersonIdentityComponent,
        OrganizationIdentityComponent,
        ActivityIdentityComponent,
        ActivityTypeHierarchyPanel,
        ActivityHierarchyPanel,
        ActivityLinksPanel,
        ActivityFilesPanel,
        ActivityContentPanel,
    ],
})
export class CustomFormsModule {}
