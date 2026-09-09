import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncExclusionEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Exclusions') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncexclusion-form',
    templateUrl: './mjbizappscommonactivitysyncexclusion.form.component.html'
})
export class mjBizAppsCommonActivitySyncExclusionFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncExclusionEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'exclusionRules', sectionName: 'Exclusion Rules', isExpanded: true },
            { sectionKey: 'identityDetails', sectionName: 'Identity Details', isExpanded: true },
            { sectionKey: 'exclusionPolicy', sectionName: 'Exclusion Policy', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonActivitySyncRunDetails', sectionName: 'Activity Sync Run Details', isExpanded: false }
        ]);
    }
}

