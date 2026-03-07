import { Component } from '@angular/core';
import { mjBizAppsCommonOrganizationEntity } from '@memberjunction-bizapps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: Organizations') // Tell MemberJunction about this class
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
            { sectionKey: 'organizationIdentity', sectionName: 'Organization Identity', isExpanded: true },
            { sectionKey: 'hierarchyAndStructure', sectionName: 'Hierarchy and Structure', isExpanded: true },
            { sectionKey: 'contactInformation', sectionName: 'Contact Information', isExpanded: false },
            { sectionKey: 'primaryAddress', sectionName: 'Primary Address', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonOrganizations', sectionName: 'MJ.BizApps.Common: Organizations', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationships', sectionName: 'MJ.BizApps.Common: Relationships', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonContactMethods', sectionName: 'MJ.BizApps.Common: Contact Methods', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationships1', sectionName: 'MJ.BizApps.Common: Relationships', isExpanded: false }
        ]);
    }
}

