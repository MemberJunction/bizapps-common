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
import { MJTabStripModule } from "@memberjunction/ng-tabstrip";
import { ContainerDirectivesModule } from "@memberjunction/ng-container-directives";
import { LayoutModule } from '@progress/kendo-angular-layout';

// Import Generated Components
import { ActionItemFormComponent } from "./Entities/ActionItem/actionitem.form.component";
import { AgendaItemFormComponent } from "./Entities/AgendaItem/agendaitem.form.component";
import { ArtifactTypeFormComponent } from "./Entities/ArtifactType/artifacttype.form.component";
import { ArtifactFormComponent } from "./Entities/Artifact/artifact.form.component";
import { AttendanceFormComponent } from "./Entities/Attendance/attendance.form.component";
import { CommitteeFormComponent } from "./Entities/Committee/committee.form.component";
import { MeetingFormComponent } from "./Entities/Meeting/meeting.form.component";
import { MembershipFormComponent } from "./Entities/Membership/membership.form.component";
import { MinuteFormComponent } from "./Entities/Minute/minute.form.component";
import { MotionFormComponent } from "./Entities/Motion/motion.form.component";
import { RoleFormComponent } from "./Entities/Role/role.form.component";
import { TermFormComponent } from "./Entities/Term/term.form.component";
import { TypeFormComponent } from "./Entities/Type/type.form.component";
import { VoteFormComponent } from "./Entities/Vote/vote.form.component";
import { AddressLinkFormComponent } from "./Entities/AddressLink/addresslink.form.component";
import { AddressTypeFormComponent } from "./Entities/AddressType/addresstype.form.component";
import { AddressFormComponent } from "./Entities/Address/address.form.component";
import { ContactMethodFormComponent } from "./Entities/ContactMethod/contactmethod.form.component";
import { ContactTypeFormComponent } from "./Entities/ContactType/contacttype.form.component";
import { OrganizationTypeFormComponent } from "./Entities/OrganizationType/organizationtype.form.component";
import { OrganizationFormComponent } from "./Entities/Organization/organization.form.component";
import { PersonFormComponent } from "./Entities/Person/person.form.component";
import { RelationshipTypeFormComponent } from "./Entities/RelationshipType/relationshiptype.form.component";
import { RelationshipFormComponent } from "./Entities/Relationship/relationship.form.component";
   

@NgModule({
declarations: [
    ActionItemFormComponent,
    AgendaItemFormComponent,
    ArtifactTypeFormComponent,
    ArtifactFormComponent,
    AttendanceFormComponent,
    CommitteeFormComponent,
    MeetingFormComponent,
    MembershipFormComponent,
    MinuteFormComponent,
    MotionFormComponent,
    RoleFormComponent,
    TermFormComponent,
    TypeFormComponent,
    VoteFormComponent,
    AddressLinkFormComponent,
    AddressTypeFormComponent,
    AddressFormComponent,
    ContactMethodFormComponent,
    ContactTypeFormComponent,
    OrganizationTypeFormComponent],
imports: [
    CommonModule,
    FormsModule,
    LayoutModule,
    BaseFormsModule,
    EntityViewerModule,
    LinkDirectivesModule,
    MJTabStripModule,
    ContainerDirectivesModule
],
exports: [
]
})
export class GeneratedForms_SubModule_0 { }
    


@NgModule({
declarations: [
    OrganizationFormComponent,
    PersonFormComponent,
    RelationshipTypeFormComponent,
    RelationshipFormComponent],
imports: [
    CommonModule,
    FormsModule,
    LayoutModule,
    BaseFormsModule,
    EntityViewerModule,
    LinkDirectivesModule,
    MJTabStripModule,
    ContainerDirectivesModule
],
exports: [
]
})
export class GeneratedForms_SubModule_1 { }
    


@NgModule({
declarations: [
],
imports: [
    GeneratedForms_SubModule_0,
    GeneratedForms_SubModule_1
]
})
export class GeneratedFormsModule { }
    
// Note: LoadXXXGeneratedForms() functions have been removed. Tree-shaking prevention
// is now handled by the pre-built class registration manifest system.
// See packages/CodeGenLib/CLASS_MANIFEST_GUIDE.md for details.
    