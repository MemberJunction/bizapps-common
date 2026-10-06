import { Component } from '@angular/core';
import { mjBizAppsCommonSeniorityLevelEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Seniority Levels') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonsenioritylevel-form',
    templateUrl: './mjbizappscommonsenioritylevel.form.component.html'
})
export class mjBizAppsCommonSeniorityLevelFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonSeniorityLevelEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'seniorityDetails', sectionName: 'Seniority Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonPeople', sectionName: 'People', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationships', sectionName: 'Relationships', isExpanded: false }
        ]);
    }
}

