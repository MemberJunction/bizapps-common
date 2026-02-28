import { Component } from '@angular/core';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
// Extend the generated form to ensure it registers first (dependency ordering)
import { mjBizAppsCommonOrganizationFormComponent } from '../../generated/Entities/mjBizAppsCommonOrganization/mjbizappscommonorganization.form.component';

/**
 * Custom Organization form component that overrides the CodeGen-generated form.
 *
 * Uses the {@link OrgDetailComponent} "HQ View" composed layout wrapped
 * inside `mj-record-form-container` for the standard MJ form chrome
 * (save/delete toolbar, navigation events, favorites, history).
 *
 * All field rendering, CRUD widgets, sidebar navigation, and navigation
 * events are delegated to the standalone OrgDetailComponent and its child widgets.
 */
@RegisterClass(BaseFormComponent, 'MJ.BizApps.Common: Organizations')
@Component({
    standalone: false,
    selector: 'bizapps-organization-form',
    templateUrl: './organization-form.component.html',
    styleUrls: ['./organization-form.component.css']
})
export class BizAppsOrganizationFormComponent extends mjBizAppsCommonOrganizationFormComponent {
    public declare record: mjBizAppsCommonOrganizationEntity;
}
