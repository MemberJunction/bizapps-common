/**********************************************************************************
* GENERATED FILE - This file is automatically managed by the MJ CodeGen tool, 
* 
* DO NOT MODIFY THIS FILE - any changes you make will be wiped out the next time the file is
* generated
* 
**********************************************************************************/
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

// MemberJunction Imports
import { BaseFormsModule } from '@memberjunction/ng-base-forms';
import { EntityViewerModule } from '@memberjunction/ng-entity-viewer';
import { LinkDirectivesModule } from '@memberjunction/ng-link-directives';

// Import Generated Components
import { mjBizAppsCommonAddressLinkFormComponent } from "./Entities/mjBizAppsCommonAddressLink/mjbizappscommonaddresslink.form.component";
import { mjBizAppsCommonAddressTypeFormComponent } from "./Entities/mjBizAppsCommonAddressType/mjbizappscommonaddresstype.form.component";
import { mjBizAppsCommonAddressFormComponent } from "./Entities/mjBizAppsCommonAddress/mjbizappscommonaddress.form.component";
import { mjBizAppsCommonContactMethodFormComponent } from "./Entities/mjBizAppsCommonContactMethod/mjbizappscommoncontactmethod.form.component";
import { mjBizAppsCommonContactTypeFormComponent } from "./Entities/mjBizAppsCommonContactType/mjbizappscommoncontacttype.form.component";
import { mjBizAppsCommonOrganizationTypeFormComponent } from "./Entities/mjBizAppsCommonOrganizationType/mjbizappscommonorganizationtype.form.component";
import { mjBizAppsCommonOrganizationFormComponent } from "./Entities/mjBizAppsCommonOrganization/mjbizappscommonorganization.form.component";
import { mjBizAppsCommonPersonFormComponent } from "./Entities/mjBizAppsCommonPerson/mjbizappscommonperson.form.component";
import { mjBizAppsCommonRelationshipTypeFormComponent } from "./Entities/mjBizAppsCommonRelationshipType/mjbizappscommonrelationshiptype.form.component";
import { mjBizAppsCommonRelationshipFormComponent } from "./Entities/mjBizAppsCommonRelationship/mjbizappscommonrelationship.form.component";
   

@NgModule({
declarations: [
    mjBizAppsCommonAddressLinkFormComponent,
    mjBizAppsCommonAddressTypeFormComponent,
    mjBizAppsCommonAddressFormComponent,
    mjBizAppsCommonContactMethodFormComponent,
    mjBizAppsCommonContactTypeFormComponent,
    mjBizAppsCommonOrganizationTypeFormComponent,
    mjBizAppsCommonOrganizationFormComponent,
    mjBizAppsCommonPersonFormComponent,
    mjBizAppsCommonRelationshipTypeFormComponent,
    mjBizAppsCommonRelationshipFormComponent],
imports: [
    CommonModule,
    FormsModule,
    BaseFormsModule,
    EntityViewerModule,
    LinkDirectivesModule
],
exports: [
]
})
export class GeneratedForms_SubModule_0 { }
    


@NgModule({
declarations: [
],
imports: [
    GeneratedForms_SubModule_0
]
})
export class GeneratedFormsModule { }
    
// Note: LoadXXXGeneratedForms() functions have been removed. Tree-shaking prevention
// is now handled by the pre-built class registration manifest system.
// See packages/CodeGenLib/CLASS_MANIFEST_GUIDE.md for details.
    