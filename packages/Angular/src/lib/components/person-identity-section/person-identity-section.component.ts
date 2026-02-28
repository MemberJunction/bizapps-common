import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseFormsModule, FormContext } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

/**
 * PersonIdentitySectionComponent renders a card section containing all personal
 * identity fields for a Person record. It uses MemberJunction's `mj-form-field`
 * components to render each field, supporting both read-only and edit modes.
 *
 * **Fields displayed:**
 * - FirstName, LastName (2-column row)
 * - MiddleName, PreferredName (2-column row)
 * - Prefix, Suffix, Gender (3-column row for short fields)
 * - DateOfBirth, DisplayName (2-column row)
 *
 * @example
 * ```html
 * <bizapps-person-identity-section
 *     [Record]="personEntity"
 *     [EditMode]="isEditing"
 *     [FormContext]="formContext">
 * </bizapps-person-identity-section>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, BaseFormsModule],
    selector: 'bizapps-person-identity-section',
    templateUrl: './person-identity-section.component.html',
    styleUrls: ['./person-identity-section.component.css']
})
export class PersonIdentitySectionComponent {
    /**
     * Change detector reference injected for manual change detection
     * after programmatic updates.
     */
    private cdr = inject(ChangeDetectorRef);

    /**
     * The Person entity record whose identity fields are rendered in this section.
     * Passed directly to each `mj-form-field` component as the [Record] binding.
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
