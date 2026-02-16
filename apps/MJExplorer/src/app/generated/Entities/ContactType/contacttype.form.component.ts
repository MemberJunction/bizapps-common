import { Component } from '@angular/core';
import { ContactTypeEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Contact Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-contacttype-form',
    templateUrl: './contacttype.form.component.html'
})
export class ContactTypeFormComponent extends BaseFormComponent {
    public record!: ContactTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'contactTypeDetails', sectionName: 'Contact Type Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonContactMethods', sectionName: 'Common: Contact Methods', isExpanded: false }
        ]);
    }
}

