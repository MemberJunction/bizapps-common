import { Component } from '@angular/core';
import { mjBizAppsCommonPersonExternalIdentityEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Person External Identities') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonpersonexternalidentity-form',
    templateUrl: './mjbizappscommonpersonexternalidentity.form.component.html'
})
export class mjBizAppsCommonPersonExternalIdentityFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonPersonExternalIdentityEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'identityInformation', sectionName: 'Identity Information', isExpanded: true },
            { sectionKey: 'matchStatusDetails', sectionName: 'Match Status & Details', isExpanded: true },
            { sectionKey: 'matchingTimeline', sectionName: 'Matching Timeline', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

