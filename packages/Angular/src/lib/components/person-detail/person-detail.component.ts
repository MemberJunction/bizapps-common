import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseFormsModule, FormContext, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';
import { PersonHeaderComponent } from '../person-header/person-header.component';
import { PersonSummaryCardsComponent } from '../person-summary-cards/person-summary-cards.component';
import { PersonIdentitySectionComponent } from '../person-identity-section/person-identity-section.component';
import { PersonProfessionalSectionComponent } from '../person-professional-section/person-professional-section.component';
import { PersonAccountSectionComponent } from '../person-account-section/person-account-section.component';
import { AddressEditorComponent } from '../address-editor/address-editor.component';
import { ContactMethodListComponent } from '../contact-method-list/contact-method-list.component';
import { RelationshipListComponent } from '../relationship-list/relationship-list.component';

/**
 * PersonDetailComponent is the composed "Command Center" layout that assembles
 * all person-related atomic widgets into a complete person detail view.
 *
 * **Layout structure:**
 * - **Top:** Dark gradient header with avatar, name, title, and organization link
 * - **Below header:** Four summary metric cards (relationships, contacts, addresses, status)
 * - **Body:** Two-column grid layout:
 *   - **Left column:** Identity fields, professional fields, and address editor
 *   - **Right column:** Relationship list, contact method list, and account/status section
 *
 * This component acts as a pure composition layer, delegating all rendering and
 * editing logic to its child widgets. Navigation events from interactive children
 * (header org link, relationship links) are bubbled up through the {@link Navigate}
 * output so that a parent form or shell can handle routing.
 *
 * @example
 * ```html
 * <bizapps-person-detail
 *     [Record]="personEntity"
 *     [EditMode]="isEditing"
 *     [FormContext]="formContext"
 *     (Navigate)="onNavigate($event)">
 * </bizapps-person-detail>
 * ```
 */
@Component({
    standalone: true,
    imports: [
        CommonModule,
        BaseFormsModule,
        PersonHeaderComponent,
        PersonSummaryCardsComponent,
        PersonIdentitySectionComponent,
        PersonProfessionalSectionComponent,
        PersonAccountSectionComponent,
        AddressEditorComponent,
        ContactMethodListComponent,
        RelationshipListComponent
    ],
    selector: 'bizapps-person-detail',
    templateUrl: './person-detail.component.html',
    styleUrls: ['./person-detail.component.css']
})
export class PersonDetailComponent {
    /**
     * Change detector reference injected for manual change detection
     * after programmatic updates or async operations.
     */
    private cdr = inject(ChangeDetectorRef);

    /**
     * The Person entity record to display in the command center layout.
     * When undefined, a loading spinner is shown. Once set, all child
     * widgets receive this record for rendering their respective sections.
     */
    @Input() Record: mjBizAppsCommonPersonEntity | undefined;

    /**
     * Controls whether form fields across all child section components
     * are rendered in edit mode (editable inputs) or read-only mode
     * (display-only text). Defaults to false (read-only).
     */
    @Input() EditMode = false;

    /**
     * Optional form context passed through to child section components
     * that render `mj-form-field` elements. Provides shared state such
     * as validation errors, section filtering, and empty field visibility
     * settings.
     */
    @Input() FormContext: FormContext | undefined;

    /**
     * Emitted when a child widget triggers a navigation event, such as
     * clicking an organization link in the header or a related person
     * in the relationship list. The parent form or shell should handle
     * this event to perform the actual route navigation.
     */
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /**
     * Handles navigation events emitted by child widgets and re-emits
     * them through this component's {@link Navigate} output. This enables
     * event bubbling so that the top-level form or shell can handle all
     * navigation in a single place.
     *
     * @param event - The navigation event from a child widget, containing
     *   the target entity name, primary key, and optional new-tab flag.
     */
    OnChildNavigate(event: FormNavigationEvent): void {
        this.Navigate.emit(event);
    }
}
