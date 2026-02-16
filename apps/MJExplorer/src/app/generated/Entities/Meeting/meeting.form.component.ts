import { Component } from '@angular/core';
import { MeetingEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Meetings') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-meeting-form',
    templateUrl: './meeting.form.component.html'
})
export class MeetingFormComponent extends BaseFormComponent {
    public record!: MeetingEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'meetingOverview', sectionName: 'Meeting Overview', isExpanded: true },
            { sectionKey: 'scheduleTiming', sectionName: 'Schedule & Timing', isExpanded: true },
            { sectionKey: 'venueAccess', sectionName: 'Venue & Access', isExpanded: false },
            { sectionKey: 'recordingTranscript', sectionName: 'Recording & Transcript', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesAttendances', sectionName: 'Committees: Attendances', isExpanded: false },
            { sectionKey: 'committeesMinutes', sectionName: 'Committees: Minutes', isExpanded: false },
            { sectionKey: 'committeesAgendaItems', sectionName: 'Committees: Agenda Items', isExpanded: false },
            { sectionKey: 'committeesMotions', sectionName: 'Committees: Motions', isExpanded: false },
            { sectionKey: 'committeesActionItems', sectionName: 'Committees: Action Items', isExpanded: false },
            { sectionKey: 'committeesArtifacts', sectionName: 'Committees: Artifacts', isExpanded: false }
        ]);
    }
}

