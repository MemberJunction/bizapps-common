import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncRunDetailEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Run Details') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncrundetail-form',
    templateUrl: './mjbizappscommonactivitysyncrundetail.form.component.html'
})
export class mjBizAppsCommonActivitySyncRunDetailFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncRunDetailEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'executionContext', sectionName: 'Execution Context', isExpanded: true },
            { sectionKey: 'externalReference', sectionName: 'External Reference', isExpanded: true },
            { sectionKey: 'decisionLogic', sectionName: 'Decision Logic', isExpanded: true },
            { sectionKey: 'messageContent', sectionName: 'Message Content', isExpanded: true },
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

