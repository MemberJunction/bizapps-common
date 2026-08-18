import { Component } from '@angular/core';
import { mjBizAppsCommonActivityTypeEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitytype-form',
    templateUrl: './mjbizappscommonactivitytype.form.component.html'
})
export class mjBizAppsCommonActivityTypeFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivityTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true },
            { sectionKey: 'mJBizAppsCommonActivities', sectionName: 'Activities', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRules', sectionName: 'Activity Sync Rules', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivityTypes', sectionName: 'Activity Types', isExpanded: false }
        ]);
    }
}

