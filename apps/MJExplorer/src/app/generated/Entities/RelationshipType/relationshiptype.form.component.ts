import { Component } from '@angular/core';
import { RelationshipTypeEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Relationship Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-relationshiptype-form',
    templateUrl: './relationshiptype.form.component.html'
})
export class RelationshipTypeFormComponent extends BaseFormComponent {
    public record!: RelationshipTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'relationshipTypeDefinition', sectionName: 'Relationship Type Definition', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonRelationships', sectionName: 'Common: Relationships', isExpanded: false }
        ]);
    }
}

