import { Component, OnInit } from '@angular/core';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
// Extend the generated form to ensure it registers first (dependency ordering)
import { mjBizAppsCommonOrganizationFormComponent } from '../../generated/Entities/mjBizAppsCommonOrganization/mjbizappscommonorganization.form.component';

@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: Organizations')
@Component({
    standalone: false,
    selector: 'bizapps-organization-form',
    templateUrl: './organization-form.component.html',
    styleUrls: ['./organization-form.component.css']
})
export class BizAppsOrganizationFormComponent extends mjBizAppsCommonOrganizationFormComponent implements OnInit {
    public declare record: mjBizAppsCommonOrganizationEntity;

    override async ngOnInit(): Promise<void> {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'orgIdentity', sectionName: 'Organization Identity', isExpanded: true },
            { sectionKey: 'hierarchy', sectionName: 'Hierarchy & Structure', isExpanded: true },
            { sectionKey: 'contactInfo', sectionName: 'Contact Information', isExpanded: true },
            { sectionKey: 'addresses', sectionName: 'Addresses', isExpanded: true },
            { sectionKey: 'contactMethods', sectionName: 'Contact Methods', isExpanded: true },
            { sectionKey: 'relationships', sectionName: 'Relationships', isExpanded: true },
            { sectionKey: 'childOrganizations', sectionName: 'Child Organizations', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
        this.cdr.detectChanges();
    }
}
