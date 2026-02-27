import { Component } from '@angular/core';
import { mjBizAppsCommonRelationshipEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';

@RegisterClass(BaseFormComponent, 'Common: Relationships') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonrelationship-form',
    templateUrl: './mjbizappscommonrelationship.form.component.html'
})
export class mjBizAppsCommonRelationshipFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonRelationshipEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'relationshipDetails', sectionName: 'Relationship Details', isExpanded: true },
            { sectionKey: 'participants', sectionName: 'Participants', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false }
        ]);
    }
}

