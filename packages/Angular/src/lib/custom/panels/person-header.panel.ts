import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
/**
 * People form hero. Last-wins identity is `header` so a vertical (Orders)
 * can replace this panel and still compose {@link PersonIdentityComponent}.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:People:header',
    metadata: {
        entity: 'MJ_BizApps_Common: People',
        slot: 'before-fields',
        sortKey: 100,
        contributionKey: 'header',
        replacesSectionKey: 'personalIdentity',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-person-header-panel',
    template: `
        <bizapps-person-identity
            [Record]="Record"
            [EditMode]="EditMode"
            [FormContext]="FormContext"
            (Navigate)="FormComponent.OnFormNavigate($event)">
        </bizapps-person-identity>
    `,
})
export class PersonHeaderPanel extends BaseFormPanel<mjBizAppsCommonPersonEntity> {}
