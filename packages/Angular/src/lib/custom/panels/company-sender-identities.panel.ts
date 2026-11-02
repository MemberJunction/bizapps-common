import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { MJCompanyEntity } from '@memberjunction/core-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * Company form contribution listing the From addresses the company may send mail as.
 *
 * Additive, with no `replacesSectionKey`: MJ core generates the Company form and excludes the
 * BizApps schemas, so there is no generated section for Company Sender Identities to replace.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Companies:sender-identities',
    metadata: {
        entity: 'MJ: Companies',
        slot: 'after-related',
        sortKey: 20,
        contributionKey: 'company-sender-identities',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-company-sender-identities-panel',
    templateUrl: './company-sender-identities.panel.html',
})
export class CompanySenderIdentitiesPanel extends BizAppsFormPanel<MJCompanyEntity> {}
