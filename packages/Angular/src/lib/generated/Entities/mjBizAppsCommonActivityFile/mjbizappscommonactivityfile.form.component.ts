import { Component } from '@angular/core';
import { mjBizAppsCommonActivityFileEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Activity Files') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonactivityfile-form',
    templateUrl: './mjbizappscommonactivityfile.form.component.html'
})
export class mjBizAppsCommonActivityFileFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonActivityFileEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true }
        ]);
    }
}

