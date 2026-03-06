import { Component } from '@angular/core';
import { mjBizAppsCommonPersonEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: People') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonperson-form',
    templateUrl: './mjbizappscommonperson.form.component.html'
})
export class mjBizAppsCommonPersonFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonPersonEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'personalIdentity', sectionName: 'Personal Identity', isExpanded: true },
            { sectionKey: 'professionalAndProfile', sectionName: 'Professional and Profile', isExpanded: true },
            { sectionKey: 'accountAndStatus', sectionName: 'Account and Status', isExpanded: false },
            { sectionKey: 'primaryAddress', sectionName: 'Primary Address', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonContactMethods', sectionName: 'MJ.BizApps.Common: Contact Methods', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationships', sectionName: 'MJ.BizApps.Common: Relationships', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationships1', sectionName: 'MJ.BizApps.Common: Relationships', isExpanded: false }
        ]);
    }
}

