import { Component } from '@angular/core';
import { AddressLinkEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'Common: Address Links') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-addresslink-form',
    templateUrl: './addresslink.form.component.html'
})
export class AddressLinkFormComponent extends BaseFormComponent {
    public record!: AddressLinkEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'addressLinkCore', sectionName: 'Address Link Core', isExpanded: true },
            { sectionKey: 'addressLinkDetails', sectionName: 'Address Link Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

