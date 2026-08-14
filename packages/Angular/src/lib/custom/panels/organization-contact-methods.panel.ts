import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * Organization form contribution that replaces the baked Contact Methods grid.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Organizations:related:ContactMethods',
    metadata: {
        entity: 'MJ_BizApps_Common: Organizations',
        slot: 'after-related',
        sortKey: 80,
        relatedEntity: 'MJ_BizApps_Common: Contact Methods',
        relatedJoinField: 'OrganizationID',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-organization-contact-methods-panel',
    templateUrl: './organization-contact-methods.panel.html',
})
export class OrganizationContactMethodsPanel extends BizAppsFormPanel<mjBizAppsCommonOrganizationEntity> {}
