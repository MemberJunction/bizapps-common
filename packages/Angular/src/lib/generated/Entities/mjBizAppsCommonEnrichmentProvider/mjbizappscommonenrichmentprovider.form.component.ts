import { Component } from '@angular/core';
import { mjBizAppsCommonEnrichmentProviderEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Enrichment Providers') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonenrichmentprovider-form',
    templateUrl: './mjbizappscommonenrichmentprovider.form.component.html'
})
export class mjBizAppsCommonEnrichmentProviderFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonEnrichmentProviderEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'providerDetails', sectionName: 'Provider Details', isExpanded: true },
            { sectionKey: 'configurationAndIntegration', sectionName: 'Configuration and Integration', isExpanded: true },
            { sectionKey: 'performanceAndLimits', sectionName: 'Performance and Limits', isExpanded: true },
            { sectionKey: 'pricingAndEconomics', sectionName: 'Pricing and Economics', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'mJBizAppsCommonEnrichmentProviderRates', sectionName: 'Enrichment Provider Rates', isExpanded: false }
        ]);
    }
}

