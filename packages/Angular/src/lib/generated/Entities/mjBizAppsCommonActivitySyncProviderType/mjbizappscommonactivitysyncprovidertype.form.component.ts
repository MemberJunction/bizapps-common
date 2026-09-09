import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncProviderTypeEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Provider Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncprovidertype-form',
    templateUrl: './mjbizappscommonactivitysyncprovidertype.form.component.html'
})
export class mjBizAppsCommonActivitySyncProviderTypeFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncProviderTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'providerIdentification', sectionName: 'Provider Identification', isExpanded: true },
            { sectionKey: 'providerConfiguration', sectionName: 'Provider Configuration', isExpanded: true },
            { sectionKey: 'operationalDefaults', sectionName: 'Operational Defaults', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRuleSets', sectionName: 'Activity Sync Rule Sets', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncConnections', sectionName: 'Activity Sync Connections', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncExtensions', sectionName: 'Activity Sync Extensions', isExpanded: false }
        ]);
    }
}

