import { Component } from '@angular/core';
import { AddressTypeEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Address Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-addresstype-form',
    templateUrl: './addresstype.form.component.html'
})
export class AddressTypeFormComponent extends BaseFormComponent {
    public record!: AddressTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'identifier', sectionName: 'Identifier', isExpanded: true },
            { sectionKey: 'addressTypeDetails', sectionName: 'Address Type Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonAddressLinks', sectionName: 'Common: Address Links', isExpanded: false }
        ]);
    }
}

