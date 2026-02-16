import { Component } from '@angular/core';
import { ArtifactEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Committees: Artifacts') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-artifact-form',
    templateUrl: './artifact.form.component.html'
})
export class ArtifactFormComponent extends BaseFormComponent {
    public record!: ArtifactEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'relatedContext', sectionName: 'Related Context', isExpanded: true },
            { sectionKey: 'artifactDetails', sectionName: 'Artifact Details', isExpanded: true },
            { sectionKey: 'storageAccess', sectionName: 'Storage & Access', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'committeesMinutes', sectionName: 'Committees: Minutes', isExpanded: false }
        ]);
    }
}

