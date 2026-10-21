import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IMetadataProvider, IRunViewProvider, LogError, Metadata, RunView, type RelatedRecordCollection } from '@memberjunction/core';
import { EscapeSQLString, UUIDsEqual } from '@memberjunction/global';
import { SharedGenericModule } from '@memberjunction/ng-shared-generic';
import {
    CONTACT_CONSENT_STATUSES,
    ContactConsentStatus,
    mjBizAppsCommonConsentPurposeEntity,
    mjBizAppsCommonContactConsentEntity,
    mjBizAppsCommonContactConsentHistoryEntity,
    mjBizAppsCommonContactMethodEntity,
    mjBizAppsCommonContactTypeEntity
} from '@mj-biz-apps/common-entities';

/**
 * Form model for both adding and editing a contact method.
 *
 * Fields correspond directly to {@link mjBizAppsCommonContactMethodEntity}
 * properties, enabling clean two-way binding in the template.
 */
interface ContactFormData {
    /** The selected ContactType record ID. */
    TypeID: string;

    /** The contact value (email address, phone number, URL, etc.). */
    Value: string;

    /**
     * An optional human-readable label for this contact method
     * (e.g., `'Work'`, `'Direct Line'`).
     */
    Label: string;

    /** Whether this contact method should be flagged as the primary for its type. */
    IsPrimary: boolean;

    /**
     * The installation-wide consents to record, keyed by Consent Purpose ID, plus the general
     * (any purpose) answer under {@link GENERAL_CONSENT_KEY}. Only shown for types that map to a
     * channel (email, phone); a change on save writes a `ContactConsentHistory` row with source
     * "Staff". Per-organization consents are managed on the Contact Consents records themselves.
     */
    Consents: Record<string, ContactConsentStatus>;
}

/** One line of the consent history panel: a change on one of the method's consents. */
interface ConsentHistoryLine {
    ID: string;
    Purpose: string;
    Organization: string | null;
    ConsentStatusAt: Date;
    NewConsentStatus: ContactConsentStatus;
    ConsentSource: string;
}

/** The form key for a method's general consent: the row with no purpose, which answers for anything. */
export const GENERAL_CONSENT_KEY = 'general';

/** True when two purpose IDs name the same purpose, treating null (general) as a value. */
function samePurpose(a: string | null | undefined, b: string | null | undefined): boolean {
    if (!a || !b) return !a && !b;
    return UUIDsEqual(a, b);
}

/** True when a metadata provider also serves views, as every MJ provider does. */
function isRunViewProvider(p: IMetadataProvider): p is IMetadataProvider & IRunViewProvider {
    return typeof (p as Partial<IRunViewProvider>).RunView === 'function';
}

/**
 * Displays and manages contact methods (email, phone, social, etc.) for a
 * Person or Organization record, with each method's consents.
 *
 * Contact methods are loaded from the `MJ_BizApps_Common: Contact Methods`
 * entity, filtered by either {@link PersonID}, {@link OrganizationID}, or
 * bound directly via a strongly-typed {@link Collection} (`RelatedRecordCollection`).
 * The component provides inline add, edit, delete, set-primary, copy-to-clipboard,
 * and open-link functionality.
 *
 * Consent hangs off each method as `MJ_BizApps_Common: Contact Consents` rows, one per purpose
 * and optional organization. Every channel type (email, phone) shows a badge per consent, with
 * the method's consent history on hover, and the edit row offers a dropdown per active purpose.
 *
 * Primary management is scoped per contact type -- setting a contact as primary
 * only demotes other primaries of the **same** type.
 *
 * @example
 * ```html
 * <!-- Bound to RelatedRecordCollection on a Person -->
 * <bizapps-contact-method-list
 *     [Collection]="person.ContactMethods"
 *     [EditMode]="true">
 * </bizapps-contact-method-list>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, FormsModule, SharedGenericModule],
    selector: 'bizapps-contact-method-list',
    templateUrl: './contact-method-list.component.html',
    styleUrls: ['./contact-method-list.component.css']
})
export class ContactMethodListComponent {
    private cdr = inject(ChangeDetectorRef);

    /**
     * Controls whether add, edit, delete, and set-primary actions are available.
     * When `false`, the component renders in read-only display mode.
     * Copy and open-link actions remain available regardless of this setting.
     */
    @Input() EditMode = false;

    /**
     * The metadata provider to read and write through. Defaults to the global provider, which is
     * right for a single-server Explorer; a host on several providers passes its own.
     */
    @Input() Provider?: IMetadataProvider;

    /** The provider this component reads and writes with. */
    public get ProviderToUse(): IMetadataProvider {
        return this.Provider ?? Metadata.Provider;
    }

    /** The same provider for RunView, when it serves views; otherwise RunView's own default. */
    private get runViewToUse(): IRunViewProvider | null {
        const p = this.ProviderToUse;
        return isRunViewProvider(p) ? p : null;
    }

    /** Emitted after any mutation (save, delete, set-primary) so the parent can refresh derived data. */
    @Output() DataChanged = new EventEmitter<void>();

    private _collection?: RelatedRecordCollection<mjBizAppsCommonContactMethodEntity>;
    private _personID: string | null = null;
    private _organizationID: string | null = null;

    /**
     * Optional strongly-typed RelatedRecordCollection from the parent Person or Organization entity.
     * When provided, contact methods are managed directly in the collection and persist atomically
     * when the parent entity is saved.
     */
    @Input()
    set Collection(value: RelatedRecordCollection<mjBizAppsCommonContactMethodEntity> | undefined) {
        this._collection = value;
        if (value) {
            this.loadData();
        }
    }
    get Collection(): RelatedRecordCollection<mjBizAppsCommonContactMethodEntity> | undefined {
        return this._collection;
    }

    /**
     * The Person record ID whose contact methods should be displayed.
     *
     * Mutually exclusive with {@link OrganizationID}. Setting this triggers
     * a data reload unless the value has not changed.
     *
     * @example `'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'`
     */
    @Input()
    set PersonID(value: string | null) {
        const prev = this._personID;
        this._personID = value;
        if (value && value !== prev) {
            this.loadData();
        }
    }
    get PersonID(): string | null { return this._personID; }

    /**
     * The Organization record ID whose contact methods should be displayed.
     *
     * Mutually exclusive with {@link PersonID}. Setting this triggers
     * a data reload unless the value has not changed.
     *
     * @example `'B2C3D4E5-F6A7-8901-BCDE-F12345678901'`
     */
    @Input()
    set OrganizationID(value: string | null) {
        const prev = this._organizationID;
        this._organizationID = value;
        if (value && value !== prev) {
            this.loadData();
        }
    }
    get OrganizationID(): string | null { return this._organizationID; }

    /**
     * The loaded contact method entities for the current Person or Organization,
     * sorted with primaries first, then by contact type display rank.
     */
    ContactMethods: mjBizAppsCommonContactMethodEntity[] = [];

    /**
     * All active contact types available for selection in type dropdowns.
     * Loaded from `MJ_BizApps_Common: Contact Types`, sorted by `DisplayRank ASC`.
     */
    ContactTypes: mjBizAppsCommonContactTypeEntity[] = [];

    /** The active consent purposes, by display rank: one dropdown each on the add and edit rows. */
    ConsentPurposes: mjBizAppsCommonConsentPurposeEntity[] = [];

    /** The consent choices offered per purpose, in the order the CHECK constraint lists them. */
    ConsentStatuses = CONTACT_CONSENT_STATUSES;

    /** The form key of the general (any purpose) consent, for the template. */
    GeneralKey = GENERAL_CONSENT_KEY;

    /** Each loaded method's consent rows (every purpose and organization), keyed by contact method ID. */
    private consentsByMethod = new Map<string, mjBizAppsCommonContactConsentEntity[]>();

    /**
     * The ID of the contact method currently being edited, or `null` when
     * not in edit mode.
     */
    EditingId: string | null = null;

    /**
     * Controls visibility of the inline add form. When `true`, the add form
     * is displayed at the bottom of the contact list.
     */
    ShowAddForm = false;

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

    /**
     * The form model bound to the inline edit panel via two-way binding.
     * Populated from the existing contact method record when editing begins.
     */
    EditForm: ContactFormData = this.createEmptyForm();

    /**
     * The form model bound to the inline add panel via two-way binding.
     * Reset to defaults each time the add form is opened.
     */
    AddForm: ContactFormData = this.createEmptyForm();

    /** The contact method whose consent history is open under its badges, or `null`. */
    ConsentHistoryFor: string | null = null;

    /** The history lines shown for {@link ConsentHistoryFor}, newest first, across the method's consents. */
    ConsentHistory: ConsentHistoryLine[] = [];

    /** True while the history for {@link ConsentHistoryFor} is being read. */
    ConsentHistoryLoading = false;

    /** History already read this session, by contact method ID; dropped for a row when it is saved. */
    private consentHistoryCache = new Map<string, ConsentHistoryLine[]>();

    /** Maps lowercase contact type names to CSS icon-color classes. */
    private iconColorMap: Record<string, string> = {
        'email': 'icon-email',
        'mobile phone': 'icon-mobile',
        'work phone': 'icon-phone',
        'home phone': 'icon-phone',
        'phone': 'icon-phone',
        'linkedin': 'icon-linkedin',
        'twitter': 'icon-twitter',
        'twitter / x': 'icon-twitter',
        'website': 'icon-web',
        'fax': 'icon-fax'
    };

    /** Contact type names (lowercase) that represent clickable URLs rather than copyable values. */
    private linkTypeNames = new Set(['linkedin', 'twitter', 'twitter / x', 'website']);

    /** Creates a blank {@link ContactFormData} with empty defaults. */
    private createEmptyForm(): ContactFormData {
        return { TypeID: '', Value: '', Label: '', IsPrimary: false, Consents: {} };
    }

    /**
     * Loads contact methods, contact types, consent purposes and the methods' consents.
     * Resets editing state before loading.
     */
    private async loadData(): Promise<void> {
        this.Loading = true;
        this.EditingId = null;
        this.ShowAddForm = false;
        this.cdr.detectChanges();

        try {
            await this.loadLookups();

            if (this._collection) {
                if (!this._collection.IsLoaded) {
                    await this._collection.Load();
                }
                this.ContactMethods = [...this._collection.Items];
            } else {
                this.ContactMethods = await this.loadStandaloneMethods();
            }

            this.sortContactMethods();
            await this.loadConsents();

            if (this.ContactTypes.length > 0 && !this.AddForm.TypeID) {
                this.AddForm.TypeID = this.ContactTypes[0].ID;
            }
        } catch (err) {
            LogError(`ContactMethodList: Error loading data: ${String(err)}`);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
    }

    /** Reads contact types and consent purposes once, in one round trip. */
    private async loadLookups(): Promise<void> {
        if (this.ContactTypes.length > 0 && this.ConsentPurposes.length > 0) {
            return;
        }
        const rv = new RunView(this.runViewToUse);
        const [types, purposes] = await rv.RunViews([
            {
                EntityName: 'MJ_BizApps_Common: Contact Types',
                ExtraFilter: 'IsActive=1',
                OrderBy: 'DisplayRank ASC',
                ResultType: 'entity_object'
            },
            {
                EntityName: 'MJ_BizApps_Common: Consent Purposes',
                ExtraFilter: 'IsActive=1',
                OrderBy: 'DisplayRank ASC',
                ResultType: 'entity_object'
            }
        ]);
        if (types.Success) {
            this.ContactTypes = types.Results as mjBizAppsCommonContactTypeEntity[];
        }
        if (purposes.Success) {
            this.ConsentPurposes = purposes.Results as mjBizAppsCommonConsentPurposeEntity[];
        }
    }

    /** Reads the person's or organization's contact methods when no collection was bound. */
    private async loadStandaloneMethods(): Promise<mjBizAppsCommonContactMethodEntity[]> {
        let filter = '';
        if (this._personID) {
            filter = `PersonID='${EscapeSQLString(this._personID)}'`;
        } else if (this._organizationID) {
            filter = `OrganizationID='${EscapeSQLString(this._organizationID)}'`;
        } else {
            return [];
        }
        const rv = new RunView(this.runViewToUse);
        const result = await rv.RunView<mjBizAppsCommonContactMethodEntity>({
            EntityName: 'MJ_BizApps_Common: Contact Methods',
            ExtraFilter: filter,
            ResultType: 'entity_object'
        });
        return result.Success ? result.Results : [];
    }

    /** Reads every consent row of the loaded (saved) methods in one query and groups them by method. */
    private async loadConsents(): Promise<void> {
        this.consentsByMethod.clear();
        const ids = this.ContactMethods.filter((cm) => cm.IsSaved).map((cm) => `'${EscapeSQLString(cm.ID)}'`);
        if (ids.length === 0) {
            return;
        }
        const rv = new RunView(this.runViewToUse);
        const result = await rv.RunView<mjBizAppsCommonContactConsentEntity>({
            EntityName: 'MJ_BizApps_Common: Contact Consents',
            ExtraFilter: `ContactMethodID IN (${ids.join(',')})`,
            ResultType: 'entity_object'
        });
        if (!result.Success) {
            LogError(`ContactMethodList: Error loading consents: ${result.ErrorMessage}`);
            return;
        }
        for (const consent of result.Results) {
            const list = this.consentsByMethod.get(consent.ContactMethodID) ?? [];
            list.push(consent);
            this.consentsByMethod.set(consent.ContactMethodID, list);
        }
    }

    private sortContactMethods(): void {
        this.ContactMethods.sort((a, b) => {
            if (a.IsPrimary && !b.IsPrimary) return -1;
            if (!a.IsPrimary && b.IsPrimary) return 1;
            return this.getTypeRank(a.ContactTypeID) - this.getTypeRank(b.ContactTypeID);
        });
    }

    /** Returns the DisplayRank for a contact type, defaulting to 999 if not found. */
    private getTypeRank(typeID: string): number {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        return ct?.DisplayRank ?? 999;
    }

    /**
     * Resolves the Font Awesome icon class for a given contact type.
     *
     * Falls back to `'fa-solid fa-circle-info'` when the type is not found
     * or has no icon configured.
     *
     * @param typeID - The ContactType record ID to look up
     * @returns The CSS class string for the icon (e.g., `'fa-solid fa-envelope'`)
     */
    getContactTypeIcon(typeID: string): string {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        return ct?.IconClass || 'fa-solid fa-circle-info';
    }

    /**
     * Returns a CSS class name that applies a theme color to the contact
     * type icon based on the type name.
     *
     * Falls back to `'icon-default'` for unrecognized type names.
     *
     * @param typeID - The ContactType record ID to look up
     * @returns A CSS class string such as `'icon-email'` or `'icon-linkedin'`
     */
    getIconColorClass(typeID: string): string {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        if (!ct) return 'icon-default';
        const key = ct.Name.toLowerCase();
        return this.iconColorMap[key] || 'icon-default';
    }

    /**
     * Builds a display-friendly metadata string for a contact method row,
     * combining the optional label and the contact type name.
     *
     * @param cm - The contact method entity to format
     * @returns A string such as `'Work · Email'` or just `'Email'`
     */
    getContactMeta(cm: mjBizAppsCommonContactMethodEntity): string {
        const parts: string[] = [];
        if (cm.Label) parts.push(cm.Label);
        if (cm.ContactType) parts.push(cm.ContactType);
        return parts.join(' · ') || cm.ContactType;
    }

    /**
     * Returns a context-appropriate placeholder string for the value input
     * field based on the selected contact type.
     *
     * @param typeID - The ContactType record ID to look up
     * @returns A placeholder string such as `'Enter email address...'`
     */
    getPlaceholder(typeID: string): string {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        if (!ct) return 'Enter value...';
        const name = ct.Name.toLowerCase();
        if (name.includes('email')) return 'Enter email address...';
        if (name.includes('phone') || name.includes('mobile')) return 'Enter phone number...';
        if (name.includes('linkedin') || name.includes('twitter') || name.includes('website')) return 'Enter URL...';
        return 'Enter value...';
    }

    /**
     * Determines whether a contact type represents a URL that should be
     * opened in a new browser tab rather than copied to the clipboard.
     *
     * @param typeID - The ContactType record ID to check
     * @returns `true` for LinkedIn, Twitter/X, and Website types; `false` otherwise
     */
    isLinkType(typeID: string): boolean {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        if (!ct) return false;
        return this.linkTypeNames.has(ct.Name.toLowerCase());
    }

    /**
     * Whether a contact type carries consent: it maps to one of MJ's communication channels
     * (Email, Phone, SMS). LinkedIn, Website and the like do not, so they show no badges.
     *
     * @param typeID - The ContactType record ID to check
     */
    isConsentType(typeID: string): boolean {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        return !!ct?.CommunicationBaseMessageTypeID;
    }

    /** The consent rows a method has, in purpose display order, installation-wide rows before scoped ones. */
    getConsents(cm: mjBizAppsCommonContactMethodEntity): mjBizAppsCommonContactConsentEntity[] {
        const rows = this.consentsByMethod.get(cm.ID) ?? [];
        return [...rows].sort((a, b) => {
            const rank = this.getPurposeRank(a.ConsentPurposeID) - this.getPurposeRank(b.ConsentPurposeID);
            if (rank !== 0) return rank;
            return (a.OrganizationID ? 1 : 0) - (b.OrganizationID ? 1 : 0);
        });
    }

    /** Returns the DisplayRank for a consent purpose; the general row (no purpose) sorts first. */
    private getPurposeRank(purposeID: string | null): number {
        if (!purposeID) return -1;
        const p = this.ConsentPurposes.find(x => UUIDsEqual(x.ID, purposeID));
        return p?.DisplayRank ?? 999;
    }

    /** The badge text for a consent row: its purpose (or General), and the organization when it is scoped to one. */
    getConsentBadgeText(consent: mjBizAppsCommonContactConsentEntity): string {
        const purpose = consent.ConsentPurpose ?? 'General';
        return consent.Organization ? `${purpose} · ${consent.Organization}` : purpose;
    }

    /** The badge colour class for a consent status. */
    getConsentBadgeClass(status: ContactConsentStatus): string {
        switch (status) {
            case 'OptedIn': return 'consent-in';
            case 'OptedOut': return 'consent-out';
            default: return 'consent-unknown';
        }
    }

    /** The Font Awesome icon for a consent status. */
    getConsentIcon(status: ContactConsentStatus): string {
        switch (status) {
            case 'OptedIn': return 'fa-solid fa-check';
            case 'OptedOut': return 'fa-solid fa-ban';
            default: return 'fa-regular fa-circle-question';
        }
    }

    /** The label shown for a consent status, on badges, in history rows and in the dropdowns. */
    getConsentLabel(status: ContactConsentStatus): string {
        switch (status) {
            case 'OptedIn': return 'Opted in';
            case 'OptedOut': return 'Opted out';
            default: return 'Not specified';
        }
    }

    /**
     * Opens the consent history under a row's badges, reading it on first hover and reusing it
     * afterwards until that row is saved again.
     *
     * @param cm - The contact method whose badges are being hovered
     */
    async onShowConsentHistory(cm: mjBizAppsCommonContactMethodEntity): Promise<void> {
        this.ConsentHistoryFor = cm.ID;
        const cached = this.consentHistoryCache.get(cm.ID);
        if (cached) {
            this.ConsentHistory = cached;
            this.cdr.detectChanges();
            return;
        }
        this.ConsentHistory = [];
        this.ConsentHistoryLoading = true;
        this.cdr.detectChanges();
        const lines = await this.loadConsentHistory(cm);
        this.consentHistoryCache.set(cm.ID, lines);
        if (this.ConsentHistoryFor === cm.ID) {
            this.ConsentHistory = lines;
        }
        this.ConsentHistoryLoading = false;
        this.cdr.detectChanges();
    }

    /** Closes the consent history. */
    onHideConsentHistory(): void {
        this.ConsentHistoryFor = null;
        this.cdr.detectChanges();
    }

    /** Reads the history of every consent a method has, newest change first, labelled with its purpose. */
    private async loadConsentHistory(cm: mjBizAppsCommonContactMethodEntity): Promise<ConsentHistoryLine[]> {
        const consents = this.consentsByMethod.get(cm.ID) ?? [];
        if (consents.length === 0) {
            return [];
        }
        const ids = consents.map((c) => `'${EscapeSQLString(c.ID)}'`).join(',');
        const rv = new RunView(this.runViewToUse);
        const result = await rv.RunView<mjBizAppsCommonContactConsentHistoryEntity>({
            EntityName: 'MJ_BizApps_Common: Contact Consent Histories',
            ExtraFilter: `ContactConsentID IN (${ids})`,
            OrderBy: 'ConsentStatusAt DESC',
            ResultType: 'entity_object'
        });
        if (!result.Success) {
            LogError(`ContactMethodList: Error loading consent history: ${result.ErrorMessage}`);
            return [];
        }
        return result.Results.map((h) => {
            const consent = consents.find((c) => UUIDsEqual(c.ID, h.ContactConsentID));
            return {
                ID: h.ID,
                Purpose: consent?.ConsentPurpose ?? 'General',
                Organization: consent?.Organization ?? null,
                ConsentStatusAt: h.ConsentStatusAt,
                NewConsentStatus: h.NewConsentStatus,
                ConsentSource: h.ConsentSource
            };
        });
    }

    /**
     * Copies the given string value to the system clipboard.
     *
     * Silently ignores clipboard write failures (e.g., when the Clipboard
     * API is not available).
     *
     * @param value - The text to copy to the clipboard
     */
    onCopyValue(value: string): void {
        navigator.clipboard.writeText(value).catch(() => {
            // Fallback: silently fail
        });
    }

    /**
     * Opens the given URL in a new browser tab.
     *
     * Automatically prepends `'https://'` when the value does not already
     * include a protocol prefix.
     *
     * Opened with `noopener,noreferrer`: contact-method values are shared data
     * that any user with write access to the record can set, and without
     * `noopener` the opened page receives `window.opener` and can navigate this
     * Explorer tab (reverse tabnabbing).
     *
     * @param value - The URL string to open
     */
    onOpenLink(value: string): void {
        let url = value;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://' + url;
        }
        window.open(url, '_blank', 'noopener,noreferrer');
    }

    /**
     * Opens the inline add form for creating a new contact method.
     *
     * Resets the add form to defaults and pre-selects the first available
     * contact type.
     */
    onShowAdd(): void {
        this.AddForm = this.createEmptyForm();
        if (this.ContactTypes.length > 0) {
            this.AddForm.TypeID = this.ContactTypes[0].ID;
        }
        this.AddForm.Consents[GENERAL_CONSENT_KEY] = 'NotSpecified';
        for (const p of this.ConsentPurposes) {
            this.AddForm.Consents[p.ID] = 'NotSpecified';
        }
        this.ShowAddForm = true;
        this.cdr.detectChanges();
    }

    /**
     * Closes the inline add form without saving.
     */
    onCancelAdd(): void {
        this.ShowAddForm = false;
        this.cdr.detectChanges();
    }

    /**
     * Persists the new contact method from the add form, with any consents chosen for it.
     *
     * When the "Primary" flag is set, other primaries of the same contact
     * type are demoted first. The contact list is reloaded after saving.
     */
    async onSaveAdd(): Promise<void> {
        if (!this.AddForm.Value) return;

        this.Saving = true;
        this.cdr.detectChanges();

        try {
            const cm = this._collection
                ? await this._collection.Create()
                : await this.ProviderToUse.GetEntityObject<mjBizAppsCommonContactMethodEntity>('MJ_BizApps_Common: Contact Methods');
            if (!this._collection) {
                cm.NewRecord();
                if (this._personID) {
                    cm.PersonID = this._personID;
                } else if (this._organizationID) {
                    cm.OrganizationID = this._organizationID;
                }
            }
            cm.ContactTypeID = this.AddForm.TypeID;
            cm.Value = this.AddForm.Value;
            cm.Label = this.AddForm.Label || null;
            cm.IsPrimary = this.AddForm.IsPrimary;
            await this.applyConsentsFromForm(cm, this.AddForm);

            if (this.AddForm.IsPrimary) {
                await this.clearPrimariesForType(this.AddForm.TypeID);
            }

            if (this._collection) {
                this.ContactMethods = [...this._collection.Items];
                this.sortContactMethods();
                this.ShowAddForm = false;
                this.DataChanged.emit();
                return;
            }

            if (!(await cm.Save())) {
                LogError(`ContactMethodList: Error adding contact: ${cm.LatestResult?.CompleteMessage ?? 'unknown error'}`);
            }
            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            LogError(`ContactMethodList: Error adding contact: ${String(err)}`);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Opens the inline edit form for an existing contact method, populating
     * the form fields from the current entity data and its installation-wide consents.
     *
     * Closes the add form if it is currently open.
     *
     * @param cm - The contact method entity to edit
     */
    onEdit(cm: mjBizAppsCommonContactMethodEntity): void {
        const consents: Record<string, ContactConsentStatus> = {};
        consents[GENERAL_CONSENT_KEY] = this.findUnscopedConsent(cm, null)?.ConsentStatus ?? 'NotSpecified';
        for (const p of this.ConsentPurposes) {
            const row = this.findUnscopedConsent(cm, p.ID);
            consents[p.ID] = row?.ConsentStatus ?? 'NotSpecified';
        }
        this.EditForm = {
            TypeID: cm.ContactTypeID,
            Value: cm.Value,
            Label: cm.Label || '',
            IsPrimary: cm.IsPrimary,
            Consents: consents
        };
        this.EditingId = cm.ID;
        this.ShowAddForm = false;
        this.cdr.detectChanges();
    }

    /**
     * Cancels the current edit operation and returns to display mode.
     */
    onCancelEdit(): void {
        this.EditingId = null;
        this.cdr.detectChanges();
    }

    /**
     * Persists the edited contact method from the edit form, with its consents.
     *
     * When the "Primary" flag is newly set, other primaries of the same
     * contact type are demoted first. The contact list is reloaded after saving.
     */
    async onSaveEdit(): Promise<void> {
        if (!this.EditForm.Value || !this.EditingId) return;

        this.Saving = true;
        this.cdr.detectChanges();

        try {
            const cm = this.ContactMethods.find(c => c.ID === this.EditingId);
            if (!cm) return;

            // If setting primary, clear other primaries of same type
            if (this.EditForm.IsPrimary && !cm.IsPrimary) {
                await this.clearPrimariesForType(this.EditForm.TypeID);
            }

            cm.ContactTypeID = this.EditForm.TypeID;
            cm.Value = this.EditForm.Value;
            cm.Label = this.EditForm.Label || null;
            cm.IsPrimary = this.EditForm.IsPrimary;
            await this.applyConsentsFromForm(cm, this.EditForm);
            this.consentHistoryCache.delete(cm.ID);

            if (this._collection) {
                this.ContactMethods = [...this._collection.Items];
                this.sortContactMethods();
                this.EditingId = null;
                this.DataChanged.emit();
                return;
            }

            if (!(await cm.Save())) {
                LogError(`ContactMethodList: Error saving contact: ${cm.LatestResult?.CompleteMessage ?? 'unknown error'}`);
            }
            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            LogError(`ContactMethodList: Error saving contact: ${String(err)}`);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /** The method's installation-wide consent row for a purpose (null = the general row), from the loaded rows, or null. */
    private findUnscopedConsent(cm: mjBizAppsCommonContactMethodEntity, purposeID: string | null): mjBizAppsCommonContactConsentEntity | null {
        const rows = this.consentsByMethod.get(cm.ID) ?? [];
        return rows.find((r) => r.OrganizationID == null && samePurpose(r.ConsentPurposeID, purposeID)) ?? null;
    }

    /**
     * Writes the form's per-purpose choices onto the method's `Consents` collection, so they save
     * with the method: an existing installation-wide row is updated when its status changed, and
     * a new row is created when a purpose was given a status for the first time. The consent
     * entity's own Save adds the history row for each change.
     */
    private async applyConsentsFromForm(cm: mjBizAppsCommonContactMethodEntity, form: ContactFormData): Promise<void> {
        if (!this.isConsentType(form.TypeID)) {
            return;
        }
        if (cm.IsSaved && !cm.Consents.IsLoaded) {
            await cm.Consents.Load();
        }
        const keys: Array<{ key: string; purposeID: string | null }> = [
            { key: GENERAL_CONSENT_KEY, purposeID: null },
            ...this.ConsentPurposes.map((p) => ({ key: p.ID, purposeID: p.ID })),
        ];
        for (const { key, purposeID } of keys) {
            const wanted = form.Consents[key] ?? 'NotSpecified';
            const existing = cm.Consents.Items.find((r) => r.OrganizationID == null && samePurpose(r.ConsentPurposeID, purposeID));
            if (existing) {
                if (existing.ConsentStatus !== wanted) {
                    existing.ConsentStatus = wanted;
                }
            } else if (wanted !== 'NotSpecified') {
                const row = await cm.Consents.Create();
                row.ConsentPurposeID = purposeID;
                row.OrganizationID = null;
                row.ConsentStatus = wanted;
            }
        }
    }

    /**
     * Promotes the given contact method to primary for its contact type,
     * demoting all other primaries of the same type.
     *
     * After the update, the contact list is reloaded.
     *
     * @param cm - The contact method entity to promote
     */
    async onSetPrimary(cm: mjBizAppsCommonContactMethodEntity): Promise<void> {
        this.Saving = true;
        this.cdr.detectChanges();

        try {
            // Clear other primaries of same type
            await this.clearPrimariesForType(cm.ContactTypeID);

            cm.IsPrimary = true;

            if (this._collection) {
                this.ContactMethods = [...this._collection.Items];
                this.sortContactMethods();
                this.DataChanged.emit();
                return;
            }

            if (!(await cm.Save())) {
                LogError(`ContactMethodList: Error setting primary: ${cm.LatestResult?.CompleteMessage ?? 'unknown error'}`);
            }
            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            LogError(`ContactMethodList: Error setting primary: ${String(err)}`);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Permanently deletes the given contact method record.
     *
     * After deletion, the contact list is reloaded.
     *
     * @param cm - The contact method entity to delete
     */
    async onDelete(cm: mjBizAppsCommonContactMethodEntity): Promise<void> {
        this.Saving = true;
        this.cdr.detectChanges();

        try {
            if (this._collection) {
                this._collection.Remove(cm);
                this.ContactMethods = [...this._collection.Items];
                this.sortContactMethods();
                this.DataChanged.emit();
                return;
            }

            if (!(await cm.Delete())) {
                LogError(`ContactMethodList: Error deleting contact: ${cm.LatestResult?.CompleteMessage ?? 'unknown error'}`);
            }
            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            LogError(`ContactMethodList: Error deleting contact: ${String(err)}`);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /** Removes the primary flag from all contact methods of the given type. */
    private async clearPrimariesForType(typeID: string): Promise<void> {
        const sameType = this.ContactMethods.filter(c => c.ContactTypeID === typeID && c.IsPrimary);
        for (const c of sameType) {
            c.IsPrimary = false;
            if (!this._collection) {
                await c.Save();
            }
        }
    }
}
