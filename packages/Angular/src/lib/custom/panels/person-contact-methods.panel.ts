import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * People form contribution that replaces the baked Contact Methods grid.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:People:related:ContactMethods',
    metadata: {
        entity: 'MJ_BizApps_Common: People',
        slot: 'after-related',
        sortKey: 80,
        relatedEntity: 'MJ_BizApps_Common: Contact Methods',
        relatedJoinField: 'PersonID',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-person-contact-methods-panel',
    templateUrl: './person-contact-methods.panel.html',
})
export class PersonContactMethodsPanel extends BizAppsFormPanel<mjBizAppsCommonPersonEntity> {}
