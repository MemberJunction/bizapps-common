import { Component } from '@angular/core';
import { CommitteeEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Committees') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-committee-form',
    templateUrl: './committee.form.component.html'
})
export class CommitteeFormComponent extends BaseFormComponent {
    public record!: CommitteeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'committeeOverview', sectionName: 'Committee Overview', isExpanded: true },
            { sectionKey: 'classificationHierarchy', sectionName: 'Classification & Hierarchy', isExpanded: true },
            { sectionKey: 'lifecycleStatus', sectionName: 'Lifecycle & Status', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesActionItems', sectionName: 'Committees: Action Items', isExpanded: false },
            { sectionKey: 'committeesArtifacts', sectionName: 'Committees: Artifacts', isExpanded: false },
            { sectionKey: 'committeesCommittees', sectionName: 'Committees: Committees', isExpanded: false },
            { sectionKey: 'committeesMeetings', sectionName: 'Committees: Meetings', isExpanded: false },
            { sectionKey: 'committeesMemberships', sectionName: 'Committees: Memberships', isExpanded: false },
            { sectionKey: 'committeesTerms', sectionName: 'Committees: Terms', isExpanded: false }
        ]);
    }
}

