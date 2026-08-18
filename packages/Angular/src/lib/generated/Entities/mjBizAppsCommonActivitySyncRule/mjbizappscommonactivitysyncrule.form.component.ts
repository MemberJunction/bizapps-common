import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncRuleEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

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
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true }
        ]);
    }
}

