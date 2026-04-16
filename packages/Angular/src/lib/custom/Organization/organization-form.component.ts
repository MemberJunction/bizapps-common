import { Component } from '@angular/core';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
// Extend the generated form to ensure it registers first (dependency ordering)
import { mjBizAppsCommonOrganizationFormComponent } from '../../generated/Entities/mjBizAppsCommonOrganization/mjbizappscommonorganization.form.component';

/**
 * Custom Organization form component that overrides the CodeGen-generated form.
 *
 * Preserves the standard MJ form layout with collapsible field panels
 * and replaces the generic related-entity data grids with richer CRUD
 * widgets for hierarchy tree, addresses, contact methods, and relationships.
 */
@RegisterClass(BaseFormComponent, 'MJ_BizApps_Common: Organizations')
@Component({
    standalone: false,
    selector: 'bizapps-organization-form',
    templateUrl: './organization-form.component.html',
    styleUrls: ['./organization-form.component.css']
})
export class BizAppsOrganizationFormComponent extends mjBizAppsCommonOrganizationFormComponent {
    public declare record: mjBizAppsCommonOrganizationEntity;

    override async ngOnInit() {
        await super.ngOnInit();
        this.initSections([
            { sectionKey: 'organizationIdentity', sectionName: 'Organization Identity', isExpanded: true },
            { sectionKey: 'hierarchyAndStructure', sectionName: 'Hierarchy and Structure', isExpanded: true },
            { sectionKey: 'contactInformation', sectionName: 'Contact Information', isExpanded: false },
            { sectionKey: 'primaryAddress', sectionName: 'Primary Address', isExpanded: false },
            { sectionKey: 'systemMetadata', sectionName: 'System Metadata', isExpanded: false },
            { sectionKey: 'organizationHierarchy', sectionName: 'Organization Hierarchy', isExpanded: true },
            { sectionKey: 'addresses', sectionName: 'Addresses', isExpanded: true },
            { sectionKey: 'contactMethods', sectionName: 'Contact Methods', isExpanded: true },
            { sectionKey: 'relationships', sectionName: 'Relationships', isExpanded: true }
        ]);
    }

    /**
     * Called when a CRUD widget (address, contact method, relationship) mutates
     * related data. Reloads the record from the database to refresh virtual
     * fields (PrimaryAddress*, PrimaryEmail, ActivePersonCount, etc.)
     * only when the form has no pending edits.
     */
    async OnWidgetDataChanged(): Promise<void> {
        if (!this.record.Dirty) {
            await this.record.InnerLoad(this.record.PrimaryKey);
            this.cdr.detectChanges();
        }
    }
}
