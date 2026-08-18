import { Component } from '@angular/core';
import { mjBizAppsCommonActivityLinkEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Links') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivitylink-form',
    templateUrl: './mjbizappscommonactivitylink.form.component.html'
})
export class mjBizAppsCommonActivityLinkFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivityLinkEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true }
        ]);
    }
}

