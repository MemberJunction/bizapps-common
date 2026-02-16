import { Component } from '@angular/core';
import { OrganizationEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Organizations') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-organization-form',
    templateUrl: './organization.form.component.html'
})
export class OrganizationFormComponent extends BaseFormComponent {
    public record!: OrganizationEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'generalInformation', sectionName: 'General Information', isExpanded: true },
            { sectionKey: 'organizationalStructure', sectionName: 'Organizational Structure', isExpanded: true },
            { sectionKey: 'contactOnlinePresence', sectionName: 'Contact & Online Presence', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonOrganizations', sectionName: 'Common: Organizations', isExpanded: false },
            { sectionKey: 'commonContactMethods', sectionName: 'Common: Contact Methods', isExpanded: false },
            { sectionKey: 'committeesCommittees', sectionName: 'Committees: Committees', isExpanded: false },
            { sectionKey: 'commonRelationships', sectionName: 'Common: Relationships', isExpanded: false },
            { sectionKey: 'commonRelationships1', sectionName: 'Common: Relationships', isExpanded: false }
        ]);
    }
}

