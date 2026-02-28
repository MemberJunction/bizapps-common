import { Component } from '@angular/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
// Extend the generated form to ensure it registers first (dependency ordering)
import { mjBizAppsCommonPersonFormComponent } from '../../generated/Entities/mjBizAppsCommonPerson/mjbizappscommonperson.form.component';

/**
 * Custom Person form component that overrides the CodeGen-generated form.
 *
 * Preserves the standard MJ form layout with collapsible field panels
 * and replaces the generic related-entity data grids with richer CRUD
 * widgets for addresses, contact methods, and relationships.
 */
@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: People')
@Component({
    standalone: false,
    selector: 'bizapps-person-form',
    templateUrl: './person-form.component.html',
    styleUrls: ['./person-form.component.css']
})
export class BizAppsPersonFormComponent extends mjBizAppsCommonPersonFormComponent {
    public declare record: mjBizAppsCommonPersonEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'personalIdentity', sectionName: 'Personal Identity', isExpanded: true },
            { sectionKey: 'professionalAndProfile', sectionName: 'Professional and Profile', isExpanded: true },
            { sectionKey: 'accountAndStatus', sectionName: 'Account and Status', isExpanded: false },
            { sectionKey: 'primaryAddress', sectionName: 'Primary Address', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'addresses', sectionName: 'Addresses', isExpanded: true },
            { sectionKey: 'contactMethods', sectionName: 'Contact Methods', isExpanded: true },
            { sectionKey: 'relationships', sectionName: 'Relationships', isExpanded: true }
        ]);
    }
}
