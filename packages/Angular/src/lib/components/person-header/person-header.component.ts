import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey } from '@memberjunction/core';
import { FormNavigationEvent, RecordNavigationEvent } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

/**
 * PersonHeaderComponent displays a dark gradient header bar for a Person record,
 * featuring an avatar with initials, the person's display name, their current
 * job title, and an interactive link to their current organization.
 *
 * This component is designed as the top-level visual element of the Person
 * "Command Center" layout, providing at-a-glance identity information.
 *
 * @example
 * ```html
 * <bizapps-person-header
 *     [Record]="personEntity"
 *     (Navigate)="onNavigate($event)">
 * </bizapps-person-header>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule],
    selector: 'bizapps-person-header',
    templateUrl: './person-header.component.html',
    styleUrls: ['./person-header.component.css']
})
export class PersonHeaderComponent {
    /**
     * Change detector reference injected for manual change detection
     * after async operations.
     */
    private cdr = inject(ChangeDetectorRef);

    /**
     * The Person entity record to display in the header.
     * Provides the person's name, job title, and organization for rendering.
     */
    @Input() Record: mjBizAppsCommonPersonEntity | undefined;

    /**
     * Emitted when the user clicks the organization name link in the header.
     * The event payload is a {@link RecordNavigationEvent} targeting the
     * Organization entity associated with this person.
     */
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /**
     * Computes the initials to display inside the avatar circle.
     * Uses the first character of FirstName and LastName, falling back
     * to an empty string if the record is not available.
     *
     * @returns The uppercase initials string (e.g., "JD" for John Doe)
     */
    get Initials(): string {
        if (!this.Record) {
            return '';
        }
        const first = this.Record.FirstName?.charAt(0) ?? '';
        const last = this.Record.LastName?.charAt(0) ?? '';
        return (first + last).toUpperCase();
    }

    /**
     * Handles the click event on the organization link. Emits a
     * {@link RecordNavigationEvent} with the Organization entity name
     * and the person's CurrentOrganizationID as the primary key.
     *
     * @param event - The mouse event from the anchor click, used to
     *   determine whether to open in a new tab (ctrl/meta key).
     */
    onNavigateToOrg(event: MouseEvent): void {
        if (!this.Record?.CurrentOrganizationID) {
            return;
        }
        const navEvent: RecordNavigationEvent = {
            Kind: 'record',
            EntityName: 'MJ.BizApps.Common: Organizations',
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', this.Record.CurrentOrganizationID),
            OpenInNewTab: event.ctrlKey || event.metaKey
        };
        this.Navigate.emit(navEvent);
    }
}
