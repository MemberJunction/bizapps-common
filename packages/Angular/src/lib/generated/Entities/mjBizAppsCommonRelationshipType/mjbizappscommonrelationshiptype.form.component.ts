import { Component } from '@angular/core';
import { mjBizAppsCommonRelationshipTypeEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Relationship Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonrelationshiptype-form',
    templateUrl: './mjbizappscommonrelationshiptype.form.component.html'
})
export class mjBizAppsCommonRelationshipTypeFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonRelationshipTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'relationshipDefinition', sectionName: 'Relationship Definition', isExpanded: true },
            { sectionKey: 'directionalConfiguration', sectionName: 'Directional Configuration', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonRelationships', sectionName: 'Common: Relationships', isExpanded: false }
        ]);
    }
}

