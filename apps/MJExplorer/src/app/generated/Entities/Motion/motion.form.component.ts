import { Component } from '@angular/core';
import { MotionEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Motions') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-motion-form',
    templateUrl: './motion.form.component.html'
})
export class MotionFormComponent extends BaseFormComponent {
    public record!: MotionEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'motionContext', sectionName: 'Motion Context', isExpanded: true },
            { sectionKey: 'motionDetails', sectionName: 'Motion Details', isExpanded: true },
            { sectionKey: 'votingResults', sectionName: 'Voting Results', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesVotes', sectionName: 'Committees: Votes', isExpanded: false }
        ]);
    }
}

