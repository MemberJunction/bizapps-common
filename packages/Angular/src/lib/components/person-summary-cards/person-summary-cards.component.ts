import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RunView } from '@memberjunction/core';
import { mjBizAppsCommonPersonEntity } from '@mj-biz-apps/common-entities';

/**
 * PersonSummaryCardsComponent renders a row of four metric cards that provide
 * an at-a-glance overview of a Person's key contact information:
 *
 * 1. **Email** - The person's primary email address
 * 2. **Phone** - The person's primary phone number
 * 3. **Address** - Count of linked addresses
 * 4. **Relationships** - Count of associated relationships
 *
 * Address and relationship counts are loaded lazily via RunView when the
 * Record input changes, avoiding unnecessary database calls on initial render.
 *
 * @example
 * ```html
 * <bizapps-person-summary-cards [Record]="personEntity">
 * </bizapps-person-summary-cards>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule],
    selector: 'bizapps-person-summary-cards',
    templateUrl: './person-summary-cards.component.html',
    styleUrls: ['./person-summary-cards.component.css']
})
export class PersonSummaryCardsComponent {
    /**
     * Change detector reference injected for manual change detection
     * after asynchronous data loading completes.
     */
    private cdr = inject(ChangeDetectorRef);

    /**
     * Backing field for the Record input property.
     */
    private _record: mjBizAppsCommonPersonEntity | undefined;

    /**
     * The Person entity record whose summary data is displayed in the cards.
     * When this value changes, address and relationship counts are refreshed
     * from the database via lazy loading.
     */
    @Input()
    set Record(value: mjBizAppsCommonPersonEntity | undefined) {
        const prev = this._record;
        this._record = value;
        if (value && value !== prev) {
            this.loadCounts();
        }
    }
    get Record(): mjBizAppsCommonPersonEntity | undefined {
        return this._record;
    }

    /**
     * Number of addresses linked to this person, loaded from the
     * Address Links entity filtered by the person's entity and ID.
     */
    private addressCount = 0;

    /**
     * Number of relationships associated with this person, loaded from
     * the Relationships entity filtered by person ID on either side.
     */
    private relationshipCount = 0;

    /**
     * Whether the component is currently loading count data from the database.
     */
    private loading = false;

    /**
     * Returns a formatted display string for the address count.
     * Shows "Loading..." during async data fetch, otherwise the numeric count.
     *
     * @returns A human-readable string representing the address count
     */
    get AddressCountDisplay(): string {
        if (this.loading) {
            return 'Loading...';
        }
        return this.addressCount.toString();
    }

    /**
     * Returns a formatted display string for the relationship count.
     * Shows "Loading..." during async data fetch, otherwise the numeric count.
     *
     * @returns A human-readable string representing the relationship count
     */
    get RelationshipCountDisplay(): string {
        if (this.loading) {
            return 'Loading...';
        }
        return this.relationshipCount.toString();
    }

    /**
     * Loads address and relationship counts in parallel using RunViews.
     * Uses the 'simple' result type with a minimal field set for performance,
     * then counts the returned rows.
     *
     * This method is called automatically when the Record input changes.
     */
    private async loadCounts(): Promise<void> {
        if (!this._record?.ID) {
            return;
        }

        this.loading = true;
        this.cdr.detectChanges();

        try {
            const rv = new RunView();
            const personID = this._record.ID;

            const [addressResult, relationshipResult] = await rv.RunViews([
                {
                    EntityName: 'MJ.BizApps.Common: Address Links',
                    ExtraFilter: `RecordID='${personID}'`,
                    ResultType: 'simple',
                    Fields: ['ID']
                },
                {
                    EntityName: 'MJ.BizApps.Common: Relationships',
                    ExtraFilter: `FromPersonID='${personID}' OR ToPersonID='${personID}'`,
                    ResultType: 'simple',
                    Fields: ['ID']
                }
            ]);

            this.addressCount = addressResult.Success
                ? (addressResult.Results?.length ?? 0)
                : 0;
            this.relationshipCount = relationshipResult.Success
                ? (relationshipResult.Results?.length ?? 0)
                : 0;
        } catch (err) {
            console.error('PersonSummaryCards: Error loading counts', err);
            this.addressCount = 0;
            this.relationshipCount = 0;
        } finally {
            this.loading = false;
            this.cdr.detectChanges();
        }
    }
}
