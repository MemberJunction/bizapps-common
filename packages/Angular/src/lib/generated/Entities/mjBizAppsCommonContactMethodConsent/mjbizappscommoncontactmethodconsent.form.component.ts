import { Component } from '@angular/core';
import { mjBizAppsCommonContactMethodConsentEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Contact Method Consents') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommoncontactmethodconsent-form',
    templateUrl: './mjbizappscommoncontactmethodconsent.form.component.html'
})
export class mjBizAppsCommonContactMethodConsentFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonContactMethodConsentEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'contactAssociation', sectionName: 'Contact Association', isExpanded: true },
            { sectionKey: 'consentDetails', sectionName: 'Consent Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonContactMethodConsentHistories', sectionName: 'Contact Method Consent Histories', isExpanded: false }
        ]);
    }
}

