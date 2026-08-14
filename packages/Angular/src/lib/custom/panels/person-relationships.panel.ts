import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * People form contribution that replaces both FromPersonID and ToPersonID
 * relationship grids with a single directional relationship widget.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:People:related:Relationships',
    metadata: {
        entity: 'MJ_BizApps_Common: People',
        slot: 'after-related',
        sortKey: 70,
        relatedEntity: 'MJ_BizApps_Common: Relationships',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-person-relationships-panel',
    templateUrl: './person-relationships.panel.html',
})
export class PersonRelationshipsPanel extends BizAppsFormPanel<mjBizAppsCommonPersonEntity> {}
