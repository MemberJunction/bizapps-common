import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { BaseFormsModule } from '@memberjunction/ng-base-forms';

import { AddressEditorComponent } from '../components/address-editor/address-editor.component';
import { ContactMethodListComponent } from '../components/contact-method-list/contact-method-list.component';
import { RelationshipListComponent } from '../components/relationship-list/relationship-list.component';
import { OrgHierarchyTreeComponent } from '../components/org-hierarchy-tree/org-hierarchy-tree.component';

import { PersonIdentityComponent } from '../components/identity-header/person-identity.component';
import { OrganizationIdentityComponent } from '../components/identity-header/organization-identity.component';
import { PersonHeaderPanel } from './panels/person-header.panel';
import { OrganizationHeaderPanel } from './panels/organization-header.panel';
import { PersonAddressesPanel } from './panels/person-addresses.panel';
import { PersonContactMethodsPanel } from './panels/person-contact-methods.panel';
import { PersonRelationshipsPanel } from './panels/person-relationships.panel';
import { OrganizationAddressesPanel } from './panels/organization-addresses.panel';
import { OrganizationContactMethodsPanel } from './panels/organization-contact-methods.panel';
import { OrganizationRelationshipsPanel } from './panels/organization-relationships.panel';
import { OrganizationHierarchyPanel } from './panels/organization-hierarchy.panel';

const PANELS = [
    PersonHeaderPanel,
    OrganizationHeaderPanel,
    PersonAddressesPanel,
    PersonContactMethodsPanel,
    PersonRelationshipsPanel,
    OrganizationAddressesPanel,
    OrganizationContactMethodsPanel,
    OrganizationRelationshipsPanel,
    OrganizationHierarchyPanel,
];

/**
 * Registers People/Organization BaseFormPanel contributions. Importing this
 * module fires @RegisterClassEx so generated forms pick up the widgets.
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
        PersonIdentityComponent,
        OrganizationIdentityComponent,
    ],
    exports: [...PANELS],
})
export class CustomFormsModule {}
