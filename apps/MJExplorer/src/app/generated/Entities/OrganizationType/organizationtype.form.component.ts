import { Component } from '@angular/core';
import { OrganizationTypeEntity } from 'mj_generatedentities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: Organization Types') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-organizationtype-form',
    templateUrl: './organizationtype.form.component.html'
})
export class OrganizationTypeFormComponent extends BaseFormComponent {
    public record!: OrganizationTypeEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'organizationTypeDetails', sectionName: 'Organization Type Details', isExpanded: true },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonOrganizations', sectionName: 'Common: Organizations', isExpanded: false }
        ]);
    }
}

