import { Component } from '@angular/core';
import { PersonEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: People') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-person-form',
    templateUrl: './person.form.component.html'
})
export class PersonFormComponent extends BaseFormComponent {
    public record!: PersonEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'nameDetails', sectionName: 'Name Details', isExpanded: true },
            { sectionKey: 'professionalProfile', sectionName: 'Professional Profile', isExpanded: true },
            { sectionKey: 'contactDemographics', sectionName: 'Contact & Demographics', isExpanded: false },
            { sectionKey: 'accountLinkage', sectionName: 'Account Linkage', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesAgendaItems', sectionName: 'Committees: Agenda Items', isExpanded: false },
            { sectionKey: 'committeesAttendances', sectionName: 'Committees: Attendances', isExpanded: false },
            { sectionKey: 'commonContactMethods', sectionName: 'Common: Contact Methods', isExpanded: false },
            { sectionKey: 'commonRelationships', sectionName: 'Common: Relationships', isExpanded: false },
            { sectionKey: 'committeesActionItems', sectionName: 'Committees: Action Items', isExpanded: false },
            { sectionKey: 'committeesMemberships', sectionName: 'Committees: Memberships', isExpanded: false },
            { sectionKey: 'commonRelationships1', sectionName: 'Common: Relationships', isExpanded: false },
            { sectionKey: 'committeesActionItems1', sectionName: 'Committees: Action Items', isExpanded: false },
            { sectionKey: 'committeesArtifacts', sectionName: 'Committees: Artifacts', isExpanded: false }
        ]);
    }
}

