import { Component } from '@angular/core';
import { TypeEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-type-form',
    templateUrl: './type.form.component.html'
})
export class TypeFormComponent extends BaseFormComponent {
    public record!: TypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'committeeTypeDetails', sectionName: 'Committee Type Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesCommittees', sectionName: 'Committees: Committees', isExpanded: false }
        ]);
    }
}

