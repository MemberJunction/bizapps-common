import { Component } from '@angular/core';
import { TermEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Terms') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-term-form',
    templateUrl: './term.form.component.html'
})
export class TermFormComponent extends BaseFormComponent {
    public record!: TermEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'committeeAssociation', sectionName: 'Committee Association', isExpanded: true },
            { sectionKey: 'termDetails', sectionName: 'Term Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesMemberships', sectionName: 'Committees: Memberships', isExpanded: false }
        ]);
    }
}

