import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey } from '@memberjunction/core';
import { FormNavigationEvent, RecordNavigationEvent } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';

/**
 * Top-bar header component for the Organization HQ View.
 *
 * Displays the organization logo (or initial fallback), name, type, status badge,
 * founded year, and action buttons (e.g. Website). Inspired by HQ View Option B mockup.
 *
 * @example
 * ```html
 * <bizapps-org-header
 *     [Record]="orgRecord"
 *     (Navigate)="onNavigate($event)"
 *     (WebsiteClick)="onWebsiteClick($event)">
 * </bizapps-org-header>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule],
    selector: 'bizapps-org-header',
    templateUrl: './org-header.component.html',
    styleUrls: ['./org-header.component.css']
})
export class OrgHeaderComponent {
    /** Angular change-detection reference, injected for manual triggering after async ops. */
    private cdr = inject(ChangeDetectorRef);

    /**
     * The organization entity record to display in the header.
     * When set, the header renders the organization's name, type, status, and logo initial.
     */
    @Input() Record: mjBizAppsCommonOrganizationEntity | undefined;

    /**
     * Emitted when the user clicks a navigation link (e.g. parent organization link).
     * The consuming component should handle routing to the target record.
     */
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /**
     * Emitted when the user clicks the Website action button.
     * The emitted value is the organization's Website URL string.
     */
    @Output() WebsiteClick = new EventEmitter<string>();

    /**
     * Computes the first character of the organization's name for the logo fallback.
     * Returns an empty string if the record or name is not available.
     *
     * @returns The uppercase initial letter of the organization name
     */
    get LogoInitial(): string {
        const name = this.Record?.Name;
        if (!name || name.length === 0) {
            return '';
        }
        return name.charAt(0).toUpperCase();
    }

    /**
     * Extracts the four-digit year from the organization's FoundedDate.
     * Returns an empty string if FoundedDate is not set.
     *
     * @returns The founded year as a string (e.g. "2005")
     */
    get FoundedYear(): string {
        const date = this.Record?.FoundedDate;
        if (!date) {
            return '';
        }
        return new Date(date).getFullYear().toString();
    }

    /**
     * Handles the Website button click.
     * Emits the organization's Website URL via the WebsiteClick output.
     */
    OnWebsiteClick(): void {
        if (this.Record?.Website) {
            this.WebsiteClick.emit(this.Record.Website);
        }
    }

    /**
     * Handles navigation to the parent organization record.
     * Emits a RecordNavigationEvent via the Navigate output.
     *
     * @param event - The mouse event from the click, used to detect ctrl/meta key for new-tab behavior
     */
    OnNavigateToParent(event: MouseEvent): void {
        if (!this.Record?.ParentID) {
            return;
        }

        const navEvent: RecordNavigationEvent = {
            Kind: 'record',
            EntityName: 'MJ.BizApps.Common: Organizations',
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', this.Record.ParentID),
            OpenInNewTab: event.ctrlKey || event.metaKey
        };
        this.Navigate.emit(navEvent);
    }
}
