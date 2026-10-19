import { Component } from '@angular/core';
import { mjBizAppsCommonContactConsentEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Contact Consents') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommoncontactconsent-form',
    templateUrl: './mjbizappscommoncontactconsent.form.component.html'
})
export class mjBizAppsCommonContactConsentFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonContactConsentEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'consentDetails', sectionName: 'Consent Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonContactConsentHistories', sectionName: 'Contact Consent Histories', isExpanded: false }
        ]);
    }
}

