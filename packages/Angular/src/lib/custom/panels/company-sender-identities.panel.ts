import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { MJCompanyEntity } from '@memberjunction/core-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * Company form contribution listing the From addresses the company may send mail as.
 *
 * No `replacesSectionKey`: MJ core's generated Company form bakes no section for this BizApps
 * entity. But the relationship row (MJ: Companies -> Company Sender Identities, DisplayInForm = 1)
 * still makes MJ mount a stock related-entity grid at runtime unless a panel claims it, so the
 * panel claims it with `relatedEntity` + `relatedJoinField`, as the Contact Methods panels do.
 * No `contributionKey` either: MJ would then use it as the left-nav rail key, and only the key it
 * derives from `relatedEntity` ('companySenderIdentities') matches the template's SectionKey.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Companies:sender-identities',
    metadata: {
        entity: 'MJ: Companies',
        slot: 'after-related',
        sortKey: 20,
        relatedEntity: 'MJ_BizApps_Common: Company Sender Identities',
        relatedJoinField: 'CompanyID',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-company-sender-identities-panel',
    templateUrl: './company-sender-identities.panel.html',
})
export class CompanySenderIdentitiesPanel extends BizAppsFormPanel<MJCompanyEntity> {}
