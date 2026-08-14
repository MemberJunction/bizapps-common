import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * Organization form contribution that replaces both FromOrganizationID and
 * ToOrganizationID relationship grids with a single directional widget.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Organizations:related:Relationships',
    metadata: {
        entity: 'MJ_BizApps_Common: Organizations',
        slot: 'after-related',
        sortKey: 70,
        relatedEntity: 'MJ_BizApps_Common: Relationships',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-organization-relationships-panel',
    templateUrl: './organization-relationships.panel.html',
})
export class OrganizationRelationshipsPanel extends BizAppsFormPanel<mjBizAppsCommonOrganizationEntity> {}
