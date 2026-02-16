import { Component } from '@angular/core';
import { ContactMethodEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'Common: Contact Methods') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-contactmethod-form',
    templateUrl: './contactmethod.form.component.html'
})
export class ContactMethodFormComponent extends BaseFormComponent {
    public record!: ContactMethodEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'association', sectionName: 'Association', isExpanded: true },
            { sectionKey: 'contactDetails', sectionName: 'Contact Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

