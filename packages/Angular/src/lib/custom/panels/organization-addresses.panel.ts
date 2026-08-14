import { Component } from '@angular/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { BizAppsFormPanel } from './bizapps-form-panel';

/**
 * Organization form contribution that replaces the virtual Address Information
 * field panel with the address-editor widget (Address + AddressLink).
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Organizations:addresses',
    metadata: {
        entity: 'MJ_BizApps_Common: Organizations',
        slot: 'after-fields',
        sortKey: 90,
        replacesSectionKey: 'addressInformation',
        contributionKey: 'addresses',
    },
})
@Component({
    standalone: false,
    selector: 'bizapps-organization-addresses-panel',
    templateUrl: './organization-addresses.panel.html',
})
export class OrganizationAddressesPanel extends BizAppsFormPanel<mjBizAppsCommonOrganizationEntity> {}
