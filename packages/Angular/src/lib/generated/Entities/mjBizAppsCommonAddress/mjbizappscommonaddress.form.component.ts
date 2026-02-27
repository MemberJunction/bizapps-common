import { Component } from '@angular/core';
import { mjBizAppsCommonAddressEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Addresses') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonaddress-form',
    templateUrl: './mjbizappscommonaddress.form.component.html'
})
export class mjBizAppsCommonAddressFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonAddressEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'streetAddress', sectionName: 'Street Address', isExpanded: true },
            { sectionKey: 'localityAndRegion', sectionName: 'Locality and Region', isExpanded: true },
            { sectionKey: 'geographicLocation', sectionName: 'Geographic Location', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonAddressLinks', sectionName: 'Common: Address Links', isExpanded: false }
        ]);
    }
}

