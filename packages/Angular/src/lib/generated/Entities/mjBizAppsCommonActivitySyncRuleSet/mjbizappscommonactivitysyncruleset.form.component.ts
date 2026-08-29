import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncRuleSetEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Rule Sets') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncruleset-form',
    templateUrl: './mjbizappscommonactivitysyncruleset.form.component.html'
})
export class mjBizAppsCommonActivitySyncRuleSetFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncRuleSetEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'ruleSetInformation', sectionName: 'Rule Set Information', isExpanded: true },
            { sectionKey: 'providerConfiguration', sectionName: 'Provider Configuration', isExpanded: true },
            { sectionKey: 'ruleSetConfiguration', sectionName: 'Rule Set Configuration', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRules', sectionName: 'Activity Sync Rules', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncExclusions', sectionName: 'Activity Sync Exclusions', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncConnectionRuleSets', sectionName: 'Activity Sync Connection Rule Sets', isExpanded: false }
        ]);
    }
}

