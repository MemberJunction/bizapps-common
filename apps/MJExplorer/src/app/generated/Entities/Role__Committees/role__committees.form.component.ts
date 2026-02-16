import { Component } from '@angular/core';
import { Role__CommitteesEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Roles__Committees') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-role__committees-form',
    templateUrl: './role__committees.form.component.html'
})
export class Role__CommitteesFormComponent extends BaseFormComponent {
    public record!: Role__CommitteesEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'roleDetails', sectionName: 'Role Details', isExpanded: true },
            { sectionKey: 'roleSettings', sectionName: 'Role Settings', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'memberships', sectionName: 'Memberships', isExpanded: false }
        ]);
    }
}

