import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

// MemberJunction Imports
import { BaseFormsModule } from '@memberjunction/ng-base-forms';

// Standalone composed detail views (used directly in form templates)
import { PersonDetailComponent } from '../components/person-detail/person-detail.component';
import { OrgDetailComponent } from '../components/org-detail/org-detail.component';

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
        // Standalone composed detail views
        PersonDetailComponent,
        OrgDetailComponent
    ],
    exports: [
        BizAppsPersonFormComponent,
        BizAppsOrganizationFormComponent
    ]
})
export class CustomFormsModule { }
