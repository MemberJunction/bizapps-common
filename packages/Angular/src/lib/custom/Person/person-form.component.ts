import { Component, OnInit } from '@angular/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
// Extend the generated form to ensure it registers first (dependency ordering)
import { mjBizAppsCommonPersonFormComponent } from '../../generated/Entities/mjBizAppsCommonPerson/mjbizappscommonperson.form.component';

@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: People')
@Component({
    standalone: false,
    selector: 'bizapps-person-form',
    templateUrl: './person-form.component.html',
    styleUrls: ['./person-form.component.css']
})
export class BizAppsPersonFormComponent extends mjBizAppsCommonPersonFormComponent implements OnInit {
    public declare record: mjBizAppsCommonPersonEntity;

    override async ngOnInit(): Promise<void> {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'personalIdentity', sectionName: 'Personal Identity', isExpanded: true },
            { sectionKey: 'professional', sectionName: 'Professional & Profile', isExpanded: true },
            { sectionKey: 'addresses', sectionName: 'Addresses', isExpanded: true },
            { sectionKey: 'contactMethods', sectionName: 'Contact Methods', isExpanded: true },
            { sectionKey: 'relationships', sectionName: 'Relationships', isExpanded: true },
            { sectionKey: 'accountStatus', sectionName: 'Account & Status', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
        this.cdr.detectChanges();
    }
}
