import { Component } from '@angular/core';
import { RelationshipEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'Common: Relationships') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-relationship-form',
    templateUrl: './relationship.form.component.html'
})
export class RelationshipFormComponent extends BaseFormComponent {
    public record!: RelationshipEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'relationshipDetails', sectionName: 'Relationship Details', isExpanded: true },
            { sectionKey: 'participants', sectionName: 'Participants', isExpanded: true },
            { sectionKey: 'durationNotes', sectionName: 'Duration & Notes', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

