import { Component } from '@angular/core';
import { mjBizAppsCommonOrganizationEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Organizations') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonorganization-form',
    templateUrl: './mjbizappscommonorganization.form.component.html'
})
export class mjBizAppsCommonOrganizationFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonOrganizationEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'organizationDetails', sectionName: 'Organization Details', isExpanded: true },
            { sectionKey: 'hierarchyAndStructure', sectionName: 'Hierarchy and Structure', isExpanded: true },
            { sectionKey: 'contactAndOnlinePresence', sectionName: 'Contact and Online Presence', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonOrganizations', sectionName: 'Common: Organizations', isExpanded: false },
            { sectionKey: 'commonContactMethods', sectionName: 'Common: Contact Methods', isExpanded: false },
            { sectionKey: 'commonRelationships', sectionName: 'Common: Relationships', isExpanded: false },
            { sectionKey: 'commonRelationships1', sectionName: 'Common: Relationships', isExpanded: false }
        ]);
    }
}

