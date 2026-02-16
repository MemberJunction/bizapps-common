import { Component } from '@angular/core';
import { ArtifactTypeEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Artifact Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-artifacttype-form',
    templateUrl: './artifacttype.form.component.html'
})
export class ArtifactTypeFormComponent extends BaseFormComponent {
    public record!: ArtifactTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'artifactTypeDetails', sectionName: 'Artifact Type Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesArtifacts', sectionName: 'Committees: Artifacts', isExpanded: false }
        ]);
    }
}

