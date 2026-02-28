import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseFormsModule, FormContext } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';

/**
 * Panel card component for displaying and editing core organization detail fields.
 *
 * Renders a styled section card with a header ("Organization Details") and rows
 * of `mj-form-field` components for the organization's identity fields. Designed
 * for the left column of the Organization HQ View layout.
 *
 * Uses the MemberJunction `mj-form-field` component (provided by BaseFormsModule)
 * to render each field with automatic label, type handling, and edit-mode support.
 *
 * @example
 * ```html
 * <bizapps-org-identity-section
 *     [Record]="orgRecord"
 *     [EditMode]="isEditing"
 *     [FormContext]="formCtx">
 * </bizapps-org-identity-section>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, BaseFormsModule],
    selector: 'bizapps-org-identity-section',
    templateUrl: './org-identity-section.component.html',
    styleUrls: ['./org-identity-section.component.css']
})
export class OrgIdentitySectionComponent {
    /** Angular change-detection reference, injected for manual triggering after async ops. */
    private cdr = inject(ChangeDetectorRef);

    /**
     * The organization entity record whose fields are displayed in this section.
     * All `mj-form-field` components bind to this record for value display and editing.
     */
    @Input() Record: mjBizAppsCommonOrganizationEntity | undefined;

    /**
     * Whether the section fields are in edit mode.
     * When `true`, `mj-form-field` renders editable inputs; when `false`, read-only values.
     *
     * @default false
     */
    @Input() EditMode = false;

    /**
     * The form context passed through to each `mj-form-field`.
     * Provides search filtering, validation state, and display preferences.
     */
    @Input() FormContext: FormContext | undefined;
}
