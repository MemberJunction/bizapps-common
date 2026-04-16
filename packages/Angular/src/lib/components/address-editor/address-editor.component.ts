import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Metadata, RunView } from '@memberjunction/core';
import { GraphQLDataProvider, GraphQLActionClient } from '@memberjunction/graphql-dataprovider';
import { ActionParam, ActionEngineBase } from '@memberjunction/actions-base';
import {
    mjBizAppsCommonAddressEntity,
    mjBizAppsCommonAddressLinkEntity,
    mjBizAppsCommonAddressTypeEntity
} from '@mj-biz-apps/common-entities';

/**
 * Represents a single address row in the editor, pairing the physical
 * address record with its entity-specific link record.
 *
 * MemberJunction uses a two-table pattern for addresses:
 * - **Address** holds the street/city/state data (reusable across entities).
 * - **AddressLink** binds an Address to a specific entity record and carries
 *   the address type and primary flag.
 */
interface AddressItem {
    /** The AddressLink entity that ties the address to the parent record. */
    Link: mjBizAppsCommonAddressLinkEntity;

    /** The Address entity containing the physical location data. */
    Address: mjBizAppsCommonAddressEntity;
}

/**
 * Form model used for both creating and editing an address.
 *
 * All fields map directly to the corresponding Address and AddressLink
 * entity properties so that two-way binding in the template works cleanly.
 */
interface AddressEditForm {
    /** The selected AddressType record ID. */
    TypeID: string;

    /** Whether this address should be marked as the primary address for the parent record. */
    IsPrimary: boolean;

    /** Street address line 1 (required). */
    Line1: string;

    /** Street address line 2 (apartment, suite, etc.). Optional. */
    Line2: string;

    /** City name (required). */
    City: string;

    /** State or province abbreviation (e.g., `'CA'`, `'ON'`). */
    StateProvince: string;

    /** Postal or ZIP code. */
    PostalCode: string;

    /** ISO country code (e.g., `'US'`, `'CA'`). Defaults to `'US'`. */
    Country: string;
}

/**
 * Manages CRUD operations for addresses linked to any MemberJunction entity record.
 *
 * This component implements the MJ two-table address pattern:
 * - **Address** stores the physical location data (line 1, city, country, etc.).
 * - **AddressLink** binds an address to a specific entity and record, and carries
 *   the address type (Home, Work, etc.) and the primary flag.
 *
 * The component automatically loads addresses and address types when both
 * {@link EntityName} and {@link RecordID} inputs are set, and provides
 * inline add/edit/delete functionality with primary-address management.
 *
 * @example
 * ```html
 * <bizapps-address-editor
 *     EntityName="MJ.BizApps.Common: People"
 *     [RecordID]="personId">
 * </bizapps-address-editor>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, FormsModule],
    selector: 'bizapps-address-editor',
    templateUrl: './address-editor.component.html',
    styleUrls: ['./address-editor.component.css']
})
export class AddressEditorComponent {
    private cdr = inject(ChangeDetectorRef);

    constructor() {
        // Fire-and-forget to prewarm the ActionEngine cache so postal code lookup is fast
        ActionEngineBase.Instance.Config(false);
    }

    /** ISO 3166-1 alpha-2 country codes for the country dropdown. */
    readonly Countries: { Code: string; Name: string }[] = [
        { Code: 'US', Name: 'United States' }, { Code: 'CA', Name: 'Canada' }, { Code: 'GB', Name: 'United Kingdom' },
        { Code: 'AU', Name: 'Australia' }, { Code: 'DE', Name: 'Germany' }, { Code: 'FR', Name: 'France' },
        { Code: 'ES', Name: 'Spain' }, { Code: 'IT', Name: 'Italy' }, { Code: 'NL', Name: 'Netherlands' },
        { Code: 'BE', Name: 'Belgium' }, { Code: 'AT', Name: 'Austria' }, { Code: 'CH', Name: 'Switzerland' },
        { Code: 'SE', Name: 'Sweden' }, { Code: 'NO', Name: 'Norway' }, { Code: 'DK', Name: 'Denmark' },
        { Code: 'FI', Name: 'Finland' }, { Code: 'IE', Name: 'Ireland' }, { Code: 'PT', Name: 'Portugal' },
        { Code: 'PL', Name: 'Poland' }, { Code: 'CZ', Name: 'Czech Republic' }, { Code: 'GR', Name: 'Greece' },
        { Code: 'HU', Name: 'Hungary' }, { Code: 'RO', Name: 'Romania' }, { Code: 'BG', Name: 'Bulgaria' },
        { Code: 'HR', Name: 'Croatia' }, { Code: 'SK', Name: 'Slovakia' }, { Code: 'SI', Name: 'Slovenia' },
        { Code: 'LT', Name: 'Lithuania' }, { Code: 'LV', Name: 'Latvia' }, { Code: 'EE', Name: 'Estonia' },
        { Code: 'LU', Name: 'Luxembourg' }, { Code: 'MT', Name: 'Malta' }, { Code: 'CY', Name: 'Cyprus' },
        { Code: 'IS', Name: 'Iceland' }, { Code: 'JP', Name: 'Japan' }, { Code: 'KR', Name: 'South Korea' },
        { Code: 'CN', Name: 'China' }, { Code: 'TW', Name: 'Taiwan' }, { Code: 'HK', Name: 'Hong Kong' },
        { Code: 'SG', Name: 'Singapore' }, { Code: 'IN', Name: 'India' }, { Code: 'PK', Name: 'Pakistan' },
        { Code: 'BD', Name: 'Bangladesh' }, { Code: 'PH', Name: 'Philippines' }, { Code: 'TH', Name: 'Thailand' },
        { Code: 'VN', Name: 'Vietnam' }, { Code: 'MY', Name: 'Malaysia' }, { Code: 'ID', Name: 'Indonesia' },
        { Code: 'NZ', Name: 'New Zealand' }, { Code: 'MX', Name: 'Mexico' }, { Code: 'BR', Name: 'Brazil' },
        { Code: 'AR', Name: 'Argentina' }, { Code: 'CL', Name: 'Chile' }, { Code: 'CO', Name: 'Colombia' },
        { Code: 'PE', Name: 'Peru' }, { Code: 'VE', Name: 'Venezuela' }, { Code: 'EC', Name: 'Ecuador' },
        { Code: 'UY', Name: 'Uruguay' }, { Code: 'PY', Name: 'Paraguay' }, { Code: 'BO', Name: 'Bolivia' },
        { Code: 'CR', Name: 'Costa Rica' }, { Code: 'PA', Name: 'Panama' }, { Code: 'DO', Name: 'Dominican Republic' },
        { Code: 'GT', Name: 'Guatemala' }, { Code: 'HN', Name: 'Honduras' }, { Code: 'SV', Name: 'El Salvador' },
        { Code: 'NI', Name: 'Nicaragua' }, { Code: 'CU', Name: 'Cuba' }, { Code: 'JM', Name: 'Jamaica' },
        { Code: 'TT', Name: 'Trinidad and Tobago' }, { Code: 'PR', Name: 'Puerto Rico' },
        { Code: 'ZA', Name: 'South Africa' }, { Code: 'NG', Name: 'Nigeria' }, { Code: 'KE', Name: 'Kenya' },
        { Code: 'EG', Name: 'Egypt' }, { Code: 'MA', Name: 'Morocco' }, { Code: 'GH', Name: 'Ghana' },
        { Code: 'TZ', Name: 'Tanzania' }, { Code: 'ET', Name: 'Ethiopia' }, { Code: 'UG', Name: 'Uganda' },
        { Code: 'IL', Name: 'Israel' }, { Code: 'AE', Name: 'United Arab Emirates' }, { Code: 'SA', Name: 'Saudi Arabia' },
        { Code: 'QA', Name: 'Qatar' }, { Code: 'KW', Name: 'Kuwait' }, { Code: 'BH', Name: 'Bahrain' },
        { Code: 'OM', Name: 'Oman' }, { Code: 'JO', Name: 'Jordan' }, { Code: 'LB', Name: 'Lebanon' },
        { Code: 'TR', Name: 'Turkey' }, { Code: 'RU', Name: 'Russia' }, { Code: 'UA', Name: 'Ukraine' },
    ];

    /**
     * Controls whether add, edit, delete, and set-primary actions are available.
     * When `false`, the component renders in read-only display mode.
     * Typically bound to the parent form's `EditMode` property.
     */
    @Input() EditMode = false;

    /** Emitted after any mutation (save, delete, set-primary) so the parent can refresh derived data. */
    @Output() DataChanged = new EventEmitter<void>();

    private _entityName = '';
    private _recordID = '';

    /**
     * The MemberJunction entity name (schema-qualified) of the parent record
     * whose addresses are being managed.
     *
     * Setting this property triggers a data reload when {@link RecordID} is
     * also available, unless the value has not changed.
     *
     * @example `'BAC: People'`
     */
    @Input()
    set EntityName(value: string) {
        const prev = this._entityName;
        this._entityName = value;
        if (value && value !== prev && this._recordID) {
            this.loadData();
        }
    }
    get EntityName(): string { return this._entityName; }

    /**
     * The primary key (ID) of the parent record whose addresses are being managed.
     *
     * Setting this property triggers a data reload when {@link EntityName} is
     * also available, unless the value has not changed.
     *
     * @example `'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'`
     */
    @Input()
    set RecordID(value: string) {
        const prev = this._recordID;
        this._recordID = value;
        if (value && value !== prev && this._entityName) {
            this.loadData();
        }
    }
    get RecordID(): string { return this._recordID; }

    /**
     * The list of address items currently displayed, each pairing an
     * AddressLink with its corresponding Address entity. Sorted with
     * primary addresses first.
     */
    AddressItems: AddressItem[] = [];

    /**
     * All active address types available for selection in the type dropdown.
     * Loaded from the `MJ.BizApps.Common: Address Types` entity, sorted by
     * `DefaultRank ASC`.
     */
    AddressTypes: mjBizAppsCommonAddressTypeEntity[] = [];

    /**
     * Tracks the current editing state:
     * - `null` -- not editing (display mode)
     * - `-1` -- adding a new address
     * - `>= 0` -- editing the address at that array index
     */
    EditingIndex: number | null = null;

    /**
     * The form model bound to the inline add/edit panel via two-way binding.
     * Reset to defaults when adding, or populated from the existing record
     * when editing.
     */
    EditForm: AddressEditForm = this.createEmptyForm();

    /**
     * Indicates whether the component is performing the initial data load.
     * The template shows a loading spinner while this is `true`.
     */
    Loading = false;

    /**
     * Indicates whether a save, delete, or set-primary operation is in progress.
     * Used to disable action buttons and show spinner feedback while `true`.
     */
    Saving = false;

    /** The resolved MJ EntityID for the current {@link EntityName}. */
    private resolvedEntityID = '';

    /** Cached action ID for the Postal Code Lookup action. */
    private postalCodeLookupActionID: string | null = null;

    /** Whether a postal code lookup is currently in progress. */
    LookingUpPostalCode = false;

    /** Whether the last postal code lookup returned no results. */
    PostalCodeNotFound = false;

    /** The postal code value when the form was opened, used to detect changes. */
    private originalPostalCode = '';

    /** Creates a blank {@link AddressEditForm} with sensible defaults. */
    private createEmptyForm(): AddressEditForm {
        return {
            TypeID: '',
            IsPrimary: false,
            Line1: '',
            Line2: '',
            City: '',
            StateProvince: '',
            PostalCode: '',
            Country: 'US'
        };
    }

    /**
     * Looks up city and state from a postal code using the Postal Code Lookup
     * MJ Action (backed by Google Geocoding API). Called on blur of the postal
     * code input field.
     *
     * For new addresses: triggers when City or State are empty.
     * For edits: triggers when the postal code changed from the original value.
     */
    async onPostalCodeBlur(): Promise<void> {
        const postalCode = this.EditForm.PostalCode?.trim();
        if (!postalCode || postalCode.length < 3) return;

        const postalCodeChanged = postalCode !== this.originalPostalCode.trim();
        const cityOrStateEmpty = !this.EditForm.City || !this.EditForm.StateProvince;

        // Skip if postal code hasn't changed and city/state are already filled
        if (!postalCodeChanged && !cityOrStateEmpty) return;

        this.LookingUpPostalCode = true;
        this.PostalCodeNotFound = false;
        this.cdr.detectChanges();

        try {
            const actionID = await this.getPostalCodeLookupActionID();
            if (!actionID) return;

            const provider = Metadata.Provider as GraphQLDataProvider;
            const actionClient = new GraphQLActionClient(provider);
            const params: ActionParam[] = [
                { Name: 'PostalCode', Value: postalCode, Type: 'Input' },
                { Name: 'Country', Value: this.EditForm.Country || 'US', Type: 'Both' },
            ];

            const result = await actionClient.RunAction(actionID, params);
            if (result.Success && result.Message) {
                // The action returns JSON-stringified address in Message
                const address = JSON.parse(result.Message);
                const city: string = address.City || '';
                const state: string = address.State || '';

                if (!city && !state) {
                    // Google resolved the country but not a specific city/state for this postal code
                    this.PostalCodeNotFound = true;
                } else if (postalCodeChanged) {
                    if (city) this.EditForm.City = city;
                    if (state) this.EditForm.StateProvince = state;
                    this.originalPostalCode = postalCode;
                } else {
                    if (!this.EditForm.City && city) this.EditForm.City = city;
                    if (!this.EditForm.StateProvince && state) this.EditForm.StateProvince = state;
                }
            } else {
                this.PostalCodeNotFound = true;
            }
        } catch (err) {
            console.error('AddressEditor: Postal code lookup failed', err);
            this.PostalCodeNotFound = true;
        } finally {
            this.LookingUpPostalCode = false;
            this.cdr.detectChanges();
        }
    }

    /** Resolves and caches the Action ID for "Postal Code Lookup" using ActionEngineBase metadata. */
    private async getPostalCodeLookupActionID(): Promise<string | null> {
        if (this.postalCodeLookupActionID) return this.postalCodeLookupActionID;

        await ActionEngineBase.Instance.Config(false);
        const action = ActionEngineBase.Instance.GetActionByName('Postal Code Lookup');
        this.postalCodeLookupActionID = action?.ID ?? null;
        return this.postalCodeLookupActionID;
    }

    /**
     * Loads address links, their associated addresses, and available address
     * types from the server. Resets editing state before loading.
     */
    private async loadData(): Promise<void> {
        this.Loading = true;
        this.EditingIndex = null;
        this.cdr.detectChanges();

        try {
            const md = new Metadata();

            // Resolve EntityName -> EntityID
            const entity = md.Entities.find(e => e.Name === this._entityName);
            if (!entity) {
                console.error(`AddressEditor: Entity "${this._entityName}" not found`);
                return;
            }
            this.resolvedEntityID = entity.ID;

            const rv = new RunView();

            // Load address links and address types in parallel
            const [linksResult, typesResult] = await rv.RunViews([
                {
                    EntityName: 'BAC: Address Links',
                    ExtraFilter: `EntityID='${this.resolvedEntityID}' AND RecordID='${this._recordID}'`,
                    ResultType: 'entity_object'
                },
                {
                    EntityName: 'BAC: Address Types',
                    ExtraFilter: 'IsActive=1',
                    OrderBy: 'DefaultRank ASC',
                    ResultType: 'entity_object'
                }
            ]);

            const links = linksResult.Success ? linksResult.Results as mjBizAppsCommonAddressLinkEntity[] : [];
            this.AddressTypes = typesResult.Success ? typesResult.Results as mjBizAppsCommonAddressTypeEntity[] : [];

            // Load all referenced addresses in one batch if we have links
            if (links.length > 0) {
                const addressIDs = links.map(l => `'${l.AddressID}'`).join(',');
                const addressResult = await rv.RunView<mjBizAppsCommonAddressEntity>({
                    EntityName: 'BAC: Addresses',
                    ExtraFilter: `ID IN (${addressIDs})`,
                    ResultType: 'entity_object'
                });

                const addressMap = new Map<string, mjBizAppsCommonAddressEntity>();
                if (addressResult.Success) {
                    for (const addr of addressResult.Results) {
                        addressMap.set(addr.ID, addr);
                    }
                }

                this.AddressItems = links
                    .filter(link => addressMap.has(link.AddressID))
                    .map(link => ({
                        Link: link,
                        Address: addressMap.get(link.AddressID)!
                    }));

                // Sort: primary first, then by rank/type
                this.AddressItems.sort((a, b) => {
                    if (a.Link.IsPrimary && !b.Link.IsPrimary) return -1;
                    if (!a.Link.IsPrimary && b.Link.IsPrimary) return 1;
                    return 0;
                });
            } else {
                this.AddressItems = [];
            }

            // Set default type for add form
            if (this.AddressTypes.length > 0) {
                this.EditForm.TypeID = this.AddressTypes[0].ID;
            }
        } catch (err) {
            console.error('AddressEditor: Error loading data', err);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Resolves the Font Awesome icon class for a given address type.
     *
     * Falls back to `'fa-solid fa-location-dot'` when the type is not found
     * or has no icon configured.
     *
     * @param typeID - The AddressType record ID to look up
     * @returns The CSS class string for the icon (e.g., `'fa-solid fa-home'`)
     */
    getAddressTypeIcon(typeID: string): string {
        const addrType = this.AddressTypes.find(t => t.ID === typeID);
        return addrType?.IconClass || 'fa-solid fa-location-dot';
    }

    /**
     * Formats the first line of an address display string.
     *
     * Combines Line1 and Line2 (if present) with a comma separator.
     *
     * @param address - The Address entity to format
     * @returns A formatted string such as `'123 Main St, Suite 200'`
     */
    formatAddressLine1(address: mjBizAppsCommonAddressEntity): string {
        const parts = [address.Line1];
        if (address.Line2) parts.push(address.Line2);
        return parts.join(', ');
    }

    /**
     * Formats the second line of an address display string.
     *
     * Combines City, StateProvince, PostalCode, and Country into a standard
     * comma-separated format.
     *
     * @param address - The Address entity to format
     * @returns A formatted string such as `'San Francisco, CA, 94105, US'`
     */
    formatAddressLine2(address: mjBizAppsCommonAddressEntity): string {
        const parts: string[] = [];
        if (address.City) parts.push(address.City);
        if (address.StateProvince) parts.push(address.StateProvince);
        if (address.PostalCode) parts.push(address.PostalCode);

        let line = parts.join(', ');
        if (address.Country) line += ', ' + address.Country;
        return line;
    }

    /**
     * Opens the inline add form for creating a new address.
     *
     * Resets the edit form to defaults, pre-selects the first available
     * address type, and auto-checks the "Primary" flag when no addresses
     * exist yet.
     */
    onAdd(): void {
        this.EditForm = this.createEmptyForm();
        if (this.AddressTypes.length > 0) {
            this.EditForm.TypeID = this.AddressTypes[0].ID;
        }
        // Default to primary if no addresses exist
        if (this.AddressItems.length === 0) {
            this.EditForm.IsPrimary = true;
        }
        this.originalPostalCode = '';
        this.EditingIndex = -1;
        this.cdr.detectChanges();
    }

    /**
     * Opens the inline edit form for an existing address, populating the
     * form fields from the current address and link data.
     *
     * @param index - The zero-based index of the address item in {@link AddressItems}
     */
    onEdit(index: number): void {
        const item = this.AddressItems[index];
        this.EditForm = {
            TypeID: item.Link.AddressTypeID,
            IsPrimary: item.Link.IsPrimary,
            Line1: item.Address.Line1,
            Line2: item.Address.Line2 || '',
            City: item.Address.City,
            StateProvince: item.Address.StateProvince || '',
            PostalCode: item.Address.PostalCode || '',
            Country: item.Address.Country
        };
        this.originalPostalCode = this.EditForm.PostalCode;
        this.EditingIndex = index;
        this.cdr.detectChanges();
    }

    /**
     * Cancels the current add or edit operation and returns to display mode.
     */
    onCancelEdit(): void {
        this.EditingIndex = null;
        this.cdr.detectChanges();
    }

    /**
     * Persists the current form data, handling both new address creation and
     * existing address updates.
     *
     * When the "Primary" flag is set, all other addresses for the same
     * parent record are demoted. After saving, the address list is reloaded.
     */
    async onSave(): Promise<void> {
        if (!this.EditForm.Line1 || !this.EditForm.City) return;

        this.Saving = true;
        this.cdr.detectChanges();

        try {
            const md = new Metadata();

            if (this.EditingIndex !== null && this.EditingIndex >= 0) {
                // Editing existing
                await this.saveExisting(md);
            } else {
                // Adding new
                await this.saveNew(md);
            }

            // If setting as primary, clear other primaries
            if (this.EditForm.IsPrimary) {
                await this.clearOtherPrimaries();
            }

            // Reload data
            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            console.error('AddressEditor: Error saving', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /** Updates an existing Address and its AddressLink with form data. */
    private async saveExisting(md: Metadata): Promise<void> {
        const item = this.AddressItems[this.EditingIndex!];

        // Update address
        item.Address.Line1 = this.EditForm.Line1;
        item.Address.Line2 = this.EditForm.Line2 || null;
        item.Address.City = this.EditForm.City;
        item.Address.StateProvince = this.EditForm.StateProvince || null;
        item.Address.PostalCode = this.EditForm.PostalCode || null;
        item.Address.Country = this.EditForm.Country;
        await item.Address.Save();

        // Update link
        item.Link.AddressTypeID = this.EditForm.TypeID;
        item.Link.IsPrimary = this.EditForm.IsPrimary;
        await item.Link.Save();
    }

    /** Creates a new Address record and its associated AddressLink. */
    private async saveNew(md: Metadata): Promise<void> {
        // Create new Address
        const address = await md.GetEntityObject<mjBizAppsCommonAddressEntity>('BAC: Addresses');
        address.NewRecord();
        address.Line1 = this.EditForm.Line1;
        address.Line2 = this.EditForm.Line2 || null;
        address.City = this.EditForm.City;
        address.StateProvince = this.EditForm.StateProvince || null;
        address.PostalCode = this.EditForm.PostalCode || null;
        address.Country = this.EditForm.Country;
        const addrSaved = await address.Save();
        if (!addrSaved) {
            console.error('AddressEditor: Failed to save address');
            return;
        }

        // Create AddressLink
        const link = await md.GetEntityObject<mjBizAppsCommonAddressLinkEntity>('BAC: Address Links');
        link.NewRecord();
        link.AddressID = address.ID;
        link.EntityID = this.resolvedEntityID;
        link.RecordID = this._recordID;
        link.AddressTypeID = this.EditForm.TypeID;
        link.IsPrimary = this.EditForm.IsPrimary;
        const linkSaved = await link.Save();
        if (!linkSaved) {
            console.error('AddressEditor: Failed to save address link');
        }
    }

    /** Removes the primary flag from all other address links for this record. */
    private async clearOtherPrimaries(): Promise<void> {
        const currentEditingLinkID = this.EditingIndex !== null && this.EditingIndex >= 0
            ? this.AddressItems[this.EditingIndex].Link.ID
            : null;

        for (const item of this.AddressItems) {
            if (item.Link.IsPrimary && item.Link.ID !== currentEditingLinkID) {
                item.Link.IsPrimary = false;
                await item.Link.Save();
            }
        }
    }

    /**
     * Promotes the address at the given index to primary, demoting all others.
     *
     * After the update, the address list is reloaded so that sort order
     * reflects the new primary designation.
     *
     * @param index - The zero-based index of the address item in {@link AddressItems}
     */
    async onSetPrimary(index: number): Promise<void> {
        this.Saving = true;
        this.cdr.detectChanges();

        try {
            // Clear all primaries
            for (const item of this.AddressItems) {
                if (item.Link.IsPrimary) {
                    item.Link.IsPrimary = false;
                    await item.Link.Save();
                }
            }

            // Set new primary
            this.AddressItems[index].Link.IsPrimary = true;
            await this.AddressItems[index].Link.Save();

            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            console.error('AddressEditor: Error setting primary', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Deletes the address at the given index, removing both the AddressLink
     * and the orphaned Address record.
     *
     * After deletion, the address list is reloaded.
     *
     * @param index - The zero-based index of the address item in {@link AddressItems}
     */
    async onDelete(index: number): Promise<void> {
        const item = this.AddressItems[index];

        this.Saving = true;
        this.cdr.detectChanges();

        try {
            // Delete the link
            await item.Link.Delete();

            // Also delete the address record (it's orphaned now)
            await item.Address.Delete();

            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            console.error('AddressEditor: Error deleting address', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }
}
