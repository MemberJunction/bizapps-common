import { Component } from '@angular/core';
import { mjBizAppsCommonPersonEducationEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Person Educations') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonpersoneducation-form',
    templateUrl: './mjbizappscommonpersoneducation.form.component.html'
})
export class mjBizAppsCommonPersonEducationFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonPersonEducationEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'educationDetails', sectionName: 'Education Details', isExpanded: true },
            { sectionKey: 'timeline', sectionName: 'Timeline', isExpanded: true },
            { sectionKey: 'sourceAndVerification', sectionName: 'Source and Verification', isExpanded: true },
            { sectionKey: 'additionalInformation', sectionName: 'Additional Information', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

