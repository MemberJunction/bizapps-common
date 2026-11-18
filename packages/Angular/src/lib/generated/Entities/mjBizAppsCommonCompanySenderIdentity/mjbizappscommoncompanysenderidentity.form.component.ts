import { Component } from '@angular/core';
import { mjBizAppsCommonCompanySenderIdentityEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Company Sender Identities') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommoncompanysenderidentity-form',
    templateUrl: './mjbizappscommoncompanysenderidentity.form.component.html'
})
export class mjBizAppsCommonCompanySenderIdentityFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonCompanySenderIdentityEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'identityDetails', sectionName: 'Identity Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

