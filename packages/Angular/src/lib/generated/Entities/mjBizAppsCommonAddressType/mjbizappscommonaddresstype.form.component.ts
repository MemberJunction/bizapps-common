import { Component } from '@angular/core';
import { mjBizAppsCommonAddressTypeEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Address Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonaddresstype-form',
    templateUrl: './mjbizappscommonaddresstype.form.component.html'
})
export class mjBizAppsCommonAddressTypeFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonAddressTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'addressTypeDetails', sectionName: 'Address Type Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonAddressLinks', sectionName: 'Common: Address Links', isExpanded: false }
        ]);
    }
}

