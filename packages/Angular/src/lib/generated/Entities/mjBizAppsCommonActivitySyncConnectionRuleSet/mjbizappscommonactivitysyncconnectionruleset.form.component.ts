import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncConnectionRuleSetEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Connection Rule Sets') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncconnectionruleset-form',
    templateUrl: './mjbizappscommonactivitysyncconnectionruleset.form.component.html'
})
export class mjBizAppsCommonActivitySyncConnectionRuleSetFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncConnectionRuleSetEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'relationships', sectionName: 'Relationships', isExpanded: true },
            { sectionKey: 'configuration', sectionName: 'Configuration', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

