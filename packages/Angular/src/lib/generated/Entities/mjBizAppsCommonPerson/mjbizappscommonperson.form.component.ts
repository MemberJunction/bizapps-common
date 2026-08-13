import { Component } from '@angular/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: People') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonperson-form',
    templateUrl: './mjbizappscommonperson.form.component.html'
})
export class mjBizAppsCommonPersonFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonPersonEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'personalIdentity', sectionName: 'Personal Identity', isExpanded: true },
            { sectionKey: 'professionalAndProfile', sectionName: 'Professional and Profile', isExpanded: true },
            { sectionKey: 'accountAndStatus', sectionName: 'Account and Status', isExpanded: true },
            { sectionKey: 'details', sectionName: 'Details', isExpanded: true },
            { sectionKey: 'contactAddress', sectionName: 'Contact Address', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonContactMethods', sectionName: 'MJ_BizApps_Common: Contact Methods', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationshipsToPersonID', sectionName: 'MJ_BizApps_Common: Relationships', isExpanded: false },
            { sectionKey: 'mJBizAppsTasksTaskComments', sectionName: 'Task Comments', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonRelationshipsFromPersonID', sectionName: 'MJ_BizApps_Common: Relationships', isExpanded: false },
            { sectionKey: 'mJBizAppsTasksTaskAssignments', sectionName: 'Task Assignments', isExpanded: false },
            { sectionKey: 'mJBizAppsTasksTaskActivities', sectionName: 'Task Activities', isExpanded: false },
            { sectionKey: 'mJBizAppsTasksTasks', sectionName: 'Tasks', isExpanded: false },
            { sectionKey: 'mJBizAppsTasksTaskDecisions', sectionName: 'Task Decisions', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersCustomerTaxExemptions', sectionName: 'Customer Tax Exemptions', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersStoredValueAccounts', sectionName: 'Stored Value Accounts', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersOrderLines', sectionName: 'Order Lines', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPaymentHeaders', sectionName: 'Payment Headers', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersOrderHeadersShipToPersonID', sectionName: 'Order Headers (Ship To Person)', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersOrderHeadersBillToPersonID', sectionName: 'Order Headers (Bill To Person)', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPromotionCodes', sectionName: 'Promotion Codes', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersSubscriptions', sectionName: 'Subscriptions', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPriceListAssignments', sectionName: 'Price List Assignments', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersPaymentIntents', sectionName: 'Payment Intents', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersCustomerPaymentMethods', sectionName: 'Customer Payment Methods', isExpanded: false },
            { sectionKey: 'mJBizAppsOrdersEntitlementGrants', sectionName: 'Entitlement Grants', isExpanded: false }
        ]);
    }
}

