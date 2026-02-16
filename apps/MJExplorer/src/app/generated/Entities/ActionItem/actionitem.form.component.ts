import { Component } from '@angular/core';
import { ActionItemEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Action Items') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-actionitem-form',
    templateUrl: './actionitem.form.component.html'
})
export class ActionItemFormComponent extends BaseFormComponent {
    public record!: ActionItemEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'assignmentContext', sectionName: 'Assignment & Context', isExpanded: true },
            { sectionKey: 'actionItemDetails', sectionName: 'Action Item Details', isExpanded: true },
            { sectionKey: 'scheduleCompletion', sectionName: 'Schedule & Completion', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesArtifacts', sectionName: 'Committees: Artifacts', isExpanded: false }
        ]);
    }
}

