import { Component } from '@angular/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { RegisterClass } from '@memberjunction/global';
import { BaseFormComponent } from '@memberjunction/ng-base-forms';
// Extend the generated form to ensure it registers first (dependency ordering)
import { mjBizAppsCommonPersonFormComponent } from '../../generated/Entities/mjBizAppsCommonPerson/mjbizappscommonperson.form.component';

/**
 * Custom Person form component that overrides the CodeGen-generated form.
 *
 * Uses the {@link PersonDetailComponent} "Command Center" composed layout
 * wrapped inside `mj-record-form-container` for the standard MJ form chrome
 * (save/delete toolbar, navigation events, favorites, history).
 *
 * All field rendering, CRUD widgets, and navigation are delegated to
 * the standalone PersonDetailComponent and its child widgets.
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
}
