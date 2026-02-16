import { Component } from '@angular/core';
import { AddressEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Addresses') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-address-form',
    templateUrl: './address.form.component.html'
})
export class AddressFormComponent extends BaseFormComponent {
    public record!: AddressEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'addressLines', sectionName: 'Address Lines', isExpanded: true },
            { sectionKey: 'locationDetails', sectionName: 'Location Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonAddressLinks', sectionName: 'Common: Address Links', isExpanded: false }
        ]);
    }
}

