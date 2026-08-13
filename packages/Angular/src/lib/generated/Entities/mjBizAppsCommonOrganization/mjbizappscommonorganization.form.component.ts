import { Component } from '@angular/core';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Organizations') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonorganization-form',
    templateUrl: './mjbizappscommonorganization.form.component.html'
})
export class mjBizAppsCommonOrganizationFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonOrganizationEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'organizationIdentity', sectionName: 'Organization Identity', isExpanded: true },
            { sectionKey: 'hierarchyAndStructure', sectionName: 'Hierarchy and Structure', isExpanded: true },
            { sectionKey: 'contactInformation', sectionName: 'Contact Information', isExpanded: true },
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true },
            { sectionKey: 'addressInformation', sectionName: 'Address Information', isExpanded: true },
            { sectionKey: 'organizationalMetrics', sectionName: 'Organizational Metrics', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonOrganizations', sectionName: 'MJ_BizApps_Common: Organizations', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationshipsToOrganizationID', sectionName: 'MJ_BizApps_Common: Relationships', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonContactMethods', sectionName: 'MJ_BizApps_Common: Contact Methods', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationshipsFromOrganizationID', sectionName: 'MJ_BizApps_Common: Relationships', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersOrderHeadersBillToOrganizationID', sectionName: 'Order Headers (Bill To Organization)', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersOrderHeadersShipToOrganizationID', sectionName: 'Order Headers (Ship To Organization)', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersCustomerPaymentMethods', sectionName: 'Customer Payment Methods', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPaymentHeaders', sectionName: 'Payment Headers', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersStoredValueAccounts', sectionName: 'Stored Value Accounts', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersEntitlementGrants', sectionName: 'Entitlement Grants', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPriceListAssignments', sectionName: 'Price List Assignments', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersSubscriptions', sectionName: 'Subscriptions', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPromotionCodes', sectionName: 'Promotion Codes', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPaymentIntents', sectionName: 'Payment Intents', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersCustomerTaxExemptions', sectionName: 'Customer Tax Exemptions', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersOrderLines', sectionName: 'Order Lines', isExpanded: false }
        ]);
    }
}

