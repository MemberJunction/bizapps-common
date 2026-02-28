import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseFormsModule, FormContext } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

/**
 * PersonAccountSectionComponent renders a card section containing the
 * account and status fields for a Person record. It uses MemberJunction's
 * `mj-form-field` components to render each field with appropriate types.
 *
 * **Fields displayed:**
 * - LinkedUserID (with Record link type for navigating to the linked user)
 * - Status (select dropdown with Active/Inactive/Deceased options)
 *
 * @example
 * ```html
 * <bizapps-person-account-section
 *     [Record]="personEntity"
 *     [EditMode]="isEditing"
 *     [FormContext]="formContext">
 * </bizapps-person-account-section>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, BaseFormsModule],
    selector: 'bizapps-person-account-section',
    templateUrl: './person-account-section.component.html',
    styleUrls: ['./person-account-section.component.css']
})
export class PersonAccountSectionComponent {
    /**
     * Change detector reference injected for manual change detection
     * after programmatic updates.
     */
    private cdr = inject(ChangeDetectorRef);

    /**
     * The Person entity record whose account and status fields are rendered
     * in this section. Passed directly to each `mj-form-field` component
     * as the [Record] binding.
     */
    @Input() Record: mjBizAppsCommonPersonEntity | undefined;

    /**
     * Controls whether the form fields are rendered in edit mode (editable inputs)
     * or read-only mode (display-only text). Defaults to false (read-only).
     */
    @Input() EditMode = false;

    /**
     * Optional form context passed through to `mj-form-field` components.
     * Provides shared state such as validation errors, section filtering,
     * and empty field visibility settings.
     */
    @Input() FormContext: FormContext | undefined;
}
