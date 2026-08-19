import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';

/**
 * Activity form hero banner. Composes ActivityIdentityComponent at slot `before-fields`.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Activities:header',
    metadata: {
        entity: 'MJ_BizApps_Common: Activities',
        slot: 'before-fields',
        sortKey: 100,
        contributionKey: 'header',
        replacesSectionKey: 'activityDetails',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-activity-header-panel',
    template: `
        <bizapps-activity-identity
            [Record]="Record"
            [EditMode]="EditMode"
            [FormContext]="FormContext"
            (Navigate)="FormComponent.OnFormNavigate($event)">
        </bizapps-activity-identity>
    `,
})
export class ActivityHeaderPanel extends BaseFormPanel<mjBizAppsCommonActivityEntity> {}
