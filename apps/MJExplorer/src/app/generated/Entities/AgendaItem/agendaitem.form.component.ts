import { Component } from '@angular/core';
import { AgendaItemEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Agenda Items') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-agendaitem-form',
    templateUrl: './agendaitem.form.component.html'
})
export class AgendaItemFormComponent extends BaseFormComponent {
    public record!: AgendaItemEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'agendaHierarchy', sectionName: 'Agenda Hierarchy', isExpanded: true },
            { sectionKey: 'itemContent', sectionName: 'Item Content', isExpanded: true },
            { sectionKey: 'presentationAttachments', sectionName: 'Presentation & Attachments', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesMotions', sectionName: 'Committees: Motions', isExpanded: false },
            { sectionKey: 'committeesAgendaItems', sectionName: 'Committees: Agenda Items', isExpanded: false },
            { sectionKey: 'committeesActionItems', sectionName: 'Committees: Action Items', isExpanded: false },
            { sectionKey: 'committeesArtifacts', sectionName: 'Committees: Artifacts', isExpanded: false }
        ]);
    }
}

