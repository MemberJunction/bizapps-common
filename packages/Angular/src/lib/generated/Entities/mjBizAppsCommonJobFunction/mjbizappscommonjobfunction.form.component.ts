import { Component } from '@angular/core';
import { mjBizAppsCommonJobFunctionEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Job Functions') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonjobfunction-form',
    templateUrl: './mjbizappscommonjobfunction.form.component.html'
})
export class mjBizAppsCommonJobFunctionFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonJobFunctionEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'jobFunctionDetails', sectionName: 'Job Function Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonPersonJobFunctions', sectionName: 'Person Job Functions', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationships', sectionName: 'Relationships', isExpanded: false }
        ]);
    }
}

