import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

// MemberJunction Imports
import { BaseFormsModule } from '@memberjunction/ng-base-forms';
import { LinkDirectivesModule } from '@memberjunction/ng-link-directives';

// Standalone CRUD widget components (used directly in form templates)
import { AddressEditorComponent } from '../components/address-editor/address-editor.component';
import { ContactMethodListComponent } from '../components/contact-method-list/contact-method-list.component';
import { RelationshipListComponent } from '../components/relationship-list/relationship-list.component';
import { OrgHierarchyTreeComponent } from '../components/org-hierarchy-tree/org-hierarchy-tree.component';

// Custom form components
import { BizAppsPersonFormComponent } from './Person/person-form.component';
import { BizAppsOrganizationFormComponent } from './Organization/organization-form.component';

@NgModule({
    declarations: [
        BizAppsPersonFormComponent,
        BizAppsOrganizationFormComponent
    ],
    imports: [
        CommonModule,
        FormsModule,
        BaseFormsModule,
        LinkDirectivesModule,
        // Standalone CRUD widgets used in form templates
        AddressEditorComponent,
        ContactMethodListComponent,
        RelationshipListComponent,
        OrgHierarchyTreeComponent
    ],
    exports: [
        BizAppsPersonFormComponent,
        BizAppsOrganizationFormComponent
    ]
})
export class CustomFormsModule { }
