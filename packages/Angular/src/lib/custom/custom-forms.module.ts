import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

// MemberJunction Imports
import { BaseFormsModule } from '@memberjunction/ng-base-forms';
import { EntityViewerModule } from '@memberjunction/ng-entity-viewer';
import { LinkDirectivesModule } from '@memberjunction/ng-link-directives';
import { LayoutModule } from '@progress/kendo-angular-layout';

// Standalone widget components (imported directly as standalone)
import { AddressEditorComponent } from '../components/address-editor/address-editor.component';
import { ContactMethodListComponent } from '../components/contact-method-list/contact-method-list.component';
import { RelationshipListComponent } from '../components/relationship-list/relationship-list.component';

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
        LayoutModule,
        BaseFormsModule,
        EntityViewerModule,
        LinkDirectivesModule,
        // Standalone widget components
        AddressEditorComponent,
        ContactMethodListComponent,
        RelationshipListComponent
    ],
    exports: [
        BizAppsPersonFormComponent,
        BizAppsOrganizationFormComponent
    ]
})
export class CustomFormsModule { }
