import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
/**
 * Organization form hero. Last-wins identity is `header`.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Organizations:header',
    metadata: {
        entity: 'MJ_BizApps_Common: Organizations',
        slot: 'before-fields',
        sortKey: 100,
        contributionKey: 'header',
        replacesSectionKey: 'organizationIdentity',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-organization-header-panel',
    template: `
        <bizapps-organization-identity
            [Record]="Record"
            [EditMode]="EditMode"
            [FormContext]="FormContext"
            (Navigate)="FormComponent.OnFormNavigate($event)">
        </bizapps-organization-identity>
    `,
})
export class OrganizationHeaderPanel extends BaseFormPanel<mjBizAppsCommonOrganizationEntity> {}
