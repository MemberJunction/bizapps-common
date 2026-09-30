import { Component } from '@angular/core';
import { mjBizAppsCommonPersonJobFunctionEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Person Job Functions') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonpersonjobfunction-form',
    templateUrl: './mjbizappscommonpersonjobfunction.form.component.html'
})
export class mjBizAppsCommonPersonJobFunctionFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonPersonJobFunctionEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true }
        ]);
    }
}

