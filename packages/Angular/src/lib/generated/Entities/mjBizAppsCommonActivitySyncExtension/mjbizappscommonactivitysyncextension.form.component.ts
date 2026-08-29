import { Component } from '@angular/core';
import { mjBizAppsCommonActivitySyncExtensionEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Sync Extensions') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitysyncextension-form',
    templateUrl: './mjbizappscommonactivitysyncextension.form.component.html'
})
export class mjBizAppsCommonActivitySyncExtensionFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivitySyncExtensionEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'pluginConfiguration', sectionName: 'Plugin Configuration', isExpanded: true },
            { sectionKey: 'integrationSettings', sectionName: 'Integration Settings', isExpanded: true },
            { sectionKey: 'executionPolicy', sectionName: 'Execution Policy', isExpanded: true },
            { sectionKey: 'monitoring', sectionName: 'Monitoring', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

