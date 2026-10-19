import { Component } from '@angular/core';
import { mjBizAppsCommonConsentPurposeEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Consent Purposes') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonconsentpurpose-form',
    templateUrl: './mjbizappscommonconsentpurpose.form.component.html'
})
export class mjBizAppsCommonConsentPurposeFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonConsentPurposeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'consentPurposeDetails', sectionName: 'Consent Purpose Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonContactConsents', sectionName: 'Contact Consents', isExpanded: false }
        ]);
    }
}

