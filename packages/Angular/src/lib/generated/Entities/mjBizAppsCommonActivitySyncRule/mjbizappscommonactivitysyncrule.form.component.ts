import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncRuleEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Rules') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncrule-form',
    templateUrl: './mjbizappscommonactivitysyncrule.form.component.html'
})
export class mjBizAppsCommonActivitySyncRuleFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncRuleEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'syncConfiguration', sectionName: 'Sync Configuration', isExpanded: true },
            { sectionKey: 'ruleDefinition', sectionName: 'Rule Definition', isExpanded: true },
            { sectionKey: 'syncCriteria', sectionName: 'Sync Criteria', isExpanded: true },
            { sectionKey: 'syncWindow', sectionName: 'Sync Window', isExpanded: true },
            { sectionKey: 'advancedFiltering', sectionName: 'Advanced Filtering', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRunDetails', sectionName: 'Activity Sync Run Details', isExpanded: false }
        ]);
    }
}

