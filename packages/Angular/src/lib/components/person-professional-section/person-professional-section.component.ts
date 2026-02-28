import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseFormsModule, FormContext } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

/**
 * PersonProfessionalSectionComponent renders a card section containing all
 * professional and profile fields for a Person record. It uses MemberJunction's
 * `mj-form-field` components to render each field with appropriate types and
 * link behaviors.
 *
 * **Fields displayed:**
 * - Title, CurrentJobTitle (2-column row)
 * - CurrentOrganizationID (full-width, with Record link type)
 * - Email (with Email link type), Phone (2-column row)
 * - PhotoURL (full-width, with URL link type)
 * - Bio (full-width, textarea)
 *
 * @example
 * ```html
 * <bizapps-person-professional-section
 *     [Record]="personEntity"
 *     [EditMode]="isEditing"
 *     [FormContext]="formContext">
 * </bizapps-person-professional-section>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, BaseFormsModule],
    selector: 'bizapps-person-professional-section',
    templateUrl: './person-professional-section.component.html',
    styleUrls: ['./person-professional-section.component.css']
})
export class PersonProfessionalSectionComponent {
    /**
     * Change detector reference injected for manual change detection
     * after programmatic updates.
     */
    private cdr = inject(ChangeDetectorRef);

    /**
     * The Person entity record whose professional fields are rendered in this section.
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
