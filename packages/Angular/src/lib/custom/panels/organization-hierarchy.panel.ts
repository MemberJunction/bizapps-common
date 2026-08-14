import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * Organization form contribution that replaces the baked child-orgs grid
 * (`mJBizAppsCommonOrganizations`) with the hierarchy tree widget.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Organizations:related:Organizations',
    metadata: {
        entity: 'MJ_BizApps_Common: Organizations',
        slot: 'after-related',
        sortKey: 85,
        relatedEntity: 'MJ_BizApps_Common: Organizations',
        relatedJoinField: 'ParentID',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-organization-hierarchy-panel',
    templateUrl: './organization-hierarchy.panel.html',
})
export class OrganizationHierarchyPanel extends BizAppsFormPanel<mjBizAppsCommonOrganizationEntity> {}
