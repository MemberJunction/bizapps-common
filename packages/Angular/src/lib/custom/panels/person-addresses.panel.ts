import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * People form contribution that replaces the virtual Contact Address field
 * panel with the address-editor widget (Address + AddressLink).
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:People:addresses',
    metadata: {
        entity: 'MJ_BizApps_Common: People',
        slot: 'after-related', // its own rail tab — after-fields would fold it into Details (MJ #4311 slot default)
        sortKey: 90,
        replacesSectionKey: 'contactAddress',
        contributionKey: 'addresses',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-person-addresses-panel',
    templateUrl: './person-addresses.panel.html',
})
export class PersonAddressesPanel extends BizAppsFormPanel<mjBizAppsCommonPersonEntity> {}
