import { Component } from '@angular/core';
import { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activities') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivity-form',
    templateUrl: './mjbizappscommonactivity.form.component.html'
})
export class mjBizAppsCommonActivityFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivityEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'activityDetails', sectionName: 'Activity Details', isExpanded: true },
            { sectionKey: 'timeline', sectionName: 'Timeline', isExpanded: true },
            { sectionKey: 'securityAndAccess', sectionName: 'Security and Access', isExpanded: true },
            { sectionKey: 'relationships', sectionName: 'Relationships', isExpanded: true },
            { sectionKey: 'location', sectionName: 'Location', isExpanded: true },
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivities', sectionName: 'Activities', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivityFiles', sectionName: 'Activity Files', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivityLinks', sectionName: 'Activity Links', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRunDetails', sectionName: 'Activity Sync Run Details', isExpanded: false }
        ]);
    }
}

