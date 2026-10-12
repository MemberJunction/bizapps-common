import { Component } from '@angular/core';
import { mjBizAppsCommonEnrichmentProviderRateEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Enrichment Provider Rates') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonenrichmentproviderrate-form',
    templateUrl: './mjbizappscommonenrichmentproviderrate.form.component.html'
})
export class mjBizAppsCommonEnrichmentProviderRateFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonEnrichmentProviderRateEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'providerConfiguration', sectionName: 'Provider Configuration', isExpanded: true },
            { sectionKey: 'rateAndBilling', sectionName: 'Rate and Billing', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

