import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * People form contribution that replaces the default Person Job Functions related-entity
 * grid with an interactive job-functions manager supporting sequences, primary badge,
 * quick add, reordering, and removal.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:People:job-functions',
    metadata: {
        entity: 'MJ_BizApps_Common: People',
        slot: 'after-related',
        sortKey: 15,
        replacesSectionKey: 'mJBizAppsCommonPersonJobFunctions',
        relatedEntity: 'MJ_BizApps_Common: Person Job Functions',
        relatedJoinField: 'PersonID',
        contributionKey: 'person-job-functions',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-person-job-functions-panel',
    templateUrl: './person-job-functions.panel.html',
})
export class PersonJobFunctionsPanel extends BizAppsFormPanel<mjBizAppsCommonPersonEntity> {}
