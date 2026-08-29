import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncRunEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Runs') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncrun-form',
    templateUrl: './mjbizappscommonactivitysyncrun.form.component.html'
})
export class mjBizAppsCommonActivitySyncRunFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncRunEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'syncContext', sectionName: 'Sync Context', isExpanded: true },
            { sectionKey: 'executionTimeline', sectionName: 'Execution Timeline', isExpanded: true },
            { sectionKey: 'executionResults', sectionName: 'Execution Results', isExpanded: true },
            { sectionKey: 'executionMetrics', sectionName: 'Execution Metrics', isExpanded: true },
            { sectionKey: 'syncState', sectionName: 'Sync State', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRunDetails', sectionName: 'Activity Sync Run Details', isExpanded: false }
        ]);
    }
}

