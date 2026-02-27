import { Component } from '@angular/core';
import { mjBizAppsCommonPersonEntity } from '@memberjunction/bizapps-common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
import {  } from "@memberjunction/ng-entity-viewer"

@RegisterClass(BaseFormComponent, 'Common: People') // Tell MemberJunction about this class
@Component({
    standalone: false,
    selector: 'gen-mjbizappscommonperson-form',
    templateUrl: './mjbizappscommonperson.form.component.html'
})
export class mjBizAppsCommonPersonFormComponent extends BaseFormComponent {
    public record!: mjBizAppsCommonPersonEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'identityProfile', sectionName: 'Identity & Profile', isExpanded: true },
            { sectionKey: 'contactProfessional', sectionName: 'Contact & Professional', isExpanded: true },
            { sectionKey: 'accountManagement', sectionName: 'Account Management', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'commonContactMethods', sectionName: 'Common: Contact Methods', isExpanded: false },
            { sectionKey: 'commonRelationships', sectionName: 'Common: Relationships', isExpanded: false },
            { sectionKey: 'commonRelationships1', sectionName: 'Common: Relationships', isExpanded: false }
        ]);
    }
}

