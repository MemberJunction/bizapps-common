import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseFormsModule, FormContext, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';
import { OrgHeaderComponent } from '../org-header/org-header.component';
import { OrgIdentitySectionComponent } from '../org-identity-section/org-identity-section.component';
import { OrgHierarchyTreeComponent } from '../org-hierarchy-tree/org-hierarchy-tree.component';
import { AddressEditorComponent } from '../address-editor/address-editor.component';
import { ContactMethodListComponent } from '../contact-method-list/contact-method-list.component';
import { RelationshipListComponent } from '../relationship-list/relationship-list.component';

/**
 * Navigation item descriptor for the sidebar icon navigation.
 * Each item maps a unique key to a Font Awesome icon class and a human-readable tooltip title.
 */
interface NavItem {
    /** Unique identifier for the navigation section (e.g. 'overview', 'hierarchy') */
    Key: string;
    /** Font Awesome icon class string (e.g. 'fa-solid fa-building') */
    Icon: string;
    /** Human-readable tooltip/label for the navigation item */
    Title: string;
}

/**
 * Static list of sidebar navigation items for the Organization HQ View.
 * Each entry represents a logical section of the detail layout.
 */
const NAV_ITEMS: readonly NavItem[] = [
    { Key: 'overview', Icon: 'fa-solid fa-building', Title: 'Overview' },
    { Key: 'hierarchy', Icon: 'fa-solid fa-sitemap', Title: 'Hierarchy' },
    { Key: 'addresses', Icon: 'fa-solid fa-map-marker-alt', Title: 'Addresses' },
    { Key: 'contacts', Icon: 'fa-solid fa-address-card', Title: 'Contacts' },
    { Key: 'relationships', Icon: 'fa-solid fa-diagram-project', Title: 'Relationships' }
] as const;

/**
 * OrgDetailComponent is the composed "HQ View" layout that assembles all
 * organization-related atomic widgets into a complete organization detail view.
 *
 * **Layout structure:**
 * - **Left:** Dark icon sidebar navigation (56px) with scroll-to-section shortcuts
 * - **Top (main area):** Organization header with logo, name, type, and action buttons
 * - **Body (main area):** Single vertical flow with sections:
 *   - Organization identity details (full width)
 *   - Hierarchy tree (full width)
 *   - Addresses + Contact methods (side-by-side)
 *   - Relationships (full width)
 *
 * All sections share the same scroll context so the sidebar navigation
 * can smoothly scroll to any section with a highlight pulse animation.
 *
 * @example
 * ```html
 * <bizapps-org-detail
 *     [Record]="orgEntity"
 *     [EditMode]="isEditing"
 *     [FormContext]="formContext"
 *     (Navigate)="onNavigate($event)">
 * </bizapps-org-detail>
 * ```
 */
@Component({
    standalone: true,
    imports: [
        CommonModule,
        BaseFormsModule,
        OrgHeaderComponent,
        OrgIdentitySectionComponent,
        OrgHierarchyTreeComponent,
        AddressEditorComponent,
        ContactMethodListComponent,
        RelationshipListComponent
    ],
    selector: 'bizapps-org-detail',
    templateUrl: './org-detail.component.html',
    styleUrls: ['./org-detail.component.css']
})
export class OrgDetailComponent {
    /**
     * Change detector reference injected for manual change detection
     * after programmatic updates or async operations.
     */
    private cdr = inject(ChangeDetectorRef);

    /**
     * Reference to the component's host DOM element, used for
     * querying section elements within the component's own template
     * (for sidebar scroll-to-section navigation).
     */
    private hostRef = inject(ElementRef);

    /**
     * The Organization entity record to display in the HQ View layout.
     * When undefined, a loading spinner is shown. Once set, all child
     * widgets receive this record (or its ID) for rendering their respective sections.
     */
    @Input() Record: mjBizAppsCommonOrganizationEntity | undefined;

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
     * clicking a parent organization link in the header, a hierarchy tree node,
     * or a related person in the relationship list. The parent form or shell
     * should handle this event to perform the actual route navigation.
     */
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /**
     * The sidebar navigation items available in the HQ View.
     * Exposed as a public property so the template can iterate over them.
     */
    readonly NavItems: readonly NavItem[] = NAV_ITEMS;

    /**
     * Tracks which sidebar navigation item is currently active (highlighted).
     * Defaults to 'overview'.
     */
    ActiveNavSection = 'overview';

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

    /**
     * Sets the active sidebar navigation section, scrolls the corresponding
     * section element into view, and plays a brief highlight pulse animation
     * to draw the user's attention to the target section.
     *
     * @param key - The unique key of the navigation item to activate
     *   (e.g. 'overview', 'hierarchy', 'addresses', 'contacts', 'relationships')
     */
    OnNavClick(key: string): void {
        this.ActiveNavSection = key;
        const element = this.hostRef.nativeElement.querySelector(`#section-${key}`) as HTMLElement | null;
        if (element) {
            element.scrollIntoView({ behavior: 'smooth', block: 'start' });
            // Restart highlight animation by removing/re-adding the class
            element.classList.remove('hq-highlight');
            void element.offsetWidth; // force reflow
            element.classList.add('hq-highlight');
        }
    }

    /**
     * Opens the provided URL in a new browser tab. Typically called when the
     * user clicks the Website action button in the organization header.
     *
     * @param url - The fully qualified URL to open (e.g. 'https://example.com')
     */
    OnWebsiteClick(url: string): void {
        window.open(url, '_blank', 'noopener,noreferrer');
    }
}
