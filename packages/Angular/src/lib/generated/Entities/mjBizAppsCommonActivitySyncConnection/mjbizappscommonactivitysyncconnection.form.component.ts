import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncConnectionEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Connections') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncconnection-form',
    templateUrl: './mjbizappscommonactivitysyncconnection.form.component.html'
})
export class mjBizAppsCommonActivitySyncConnectionFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncConnectionEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'connectionDetails', sectionName: 'Connection Details', isExpanded: true },
            { sectionKey: 'operationalStatus', sectionName: 'Operational Status', isExpanded: true },
            { sectionKey: 'ownershipAndSecurity', sectionName: 'Ownership and Security', isExpanded: true },
            { sectionKey: 'configuration', sectionName: 'Configuration', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivities', sectionName: 'Activities', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRules', sectionName: 'Activity Sync Rules', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncConnectionRuleSets', sectionName: 'Activity Sync Connection Rule Sets', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRuns', sectionName: 'Activity Sync Runs', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncExtensions', sectionName: 'Activity Sync Extensions', isExpanded: false }
        ]);
    }
}

