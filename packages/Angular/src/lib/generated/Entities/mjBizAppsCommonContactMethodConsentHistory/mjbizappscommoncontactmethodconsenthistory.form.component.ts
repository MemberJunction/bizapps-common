import { Component } from '@angular/core';
import { mjBizAppsCommonContactMethodConsentHistoryEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Contact Method Consent Histories') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommoncontactmethodconsenthistory-form',
    templateUrl: './mjbizappscommoncontactmethodconsenthistory.form.component.html'
})
export class mjBizAppsCommonContactMethodConsentHistoryFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonContactMethodConsentHistoryEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'consentHistoryDetails', sectionName: 'Consent History Details', isExpanded: true },
            { sectionKey: 'auditInformation', sectionName: 'Audit Information', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

