import { Component } from '@angular/core';
import { VoteEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'Committees: Votes') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-vote-form',
    templateUrl: './vote.form.component.html'
})
export class VoteFormComponent extends BaseFormComponent {
    public record!: VoteEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'voteContext', sectionName: 'Vote Context', isExpanded: true },
            { sectionKey: 'voteDetails', sectionName: 'Vote Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

