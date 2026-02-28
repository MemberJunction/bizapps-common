import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Metadata, RunView } from '@memberjunction/core';
import {
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
}

/**
 * Displays and manages contact methods (email, phone, social, etc.) for a
 * Person or Organization record.
 *
 * Contact methods are loaded from the `MJ.BizApps.Common: Contact Methods`
 * entity, filtered by either {@link PersonID} or {@link OrganizationID}.
 * The component provides inline add, edit, delete, set-primary, copy-to-clipboard,
 * and open-link functionality.
 *
 * Primary management is scoped per contact type -- setting a contact as primary
 * only demotes other primaries of the **same** type.
 *
 * @example
 * ```html
 * <!-- For a Person -->
 * <bizapps-contact-method-list
 *     [PersonID]="person.ID">
 * </bizapps-contact-method-list>
 *
 * <!-- For an Organization -->
 * <bizapps-contact-method-list
 *     [OrganizationID]="org.ID">
 * </bizapps-contact-method-list>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, FormsModule],
    selector: 'bizapps-contact-method-list',
    templateUrl: './contact-method-list.component.html',
    styleUrls: ['./contact-method-list.component.css']
})
export class ContactMethodListComponent {
    private cdr = inject(ChangeDetectorRef);

    private _personID: string | null = null;
    private _organizationID: string | null = null;

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
     * Loaded from `MJ.BizApps.Common: Contact Types`, sorted by `DisplayRank ASC`.
     */
    ContactTypes: mjBizAppsCommonContactTypeEntity[] = [];

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
        return { TypeID: '', Value: '', Label: '', IsPrimary: false };
    }

    /**
     * Loads contact methods and contact types from the server.
     * Resets editing state before loading.
     */
    private async loadData(): Promise<void> {
        this.Loading = true;
        this.EditingId = null;
        this.ShowAddForm = false;
        this.cdr.detectChanges();

        try {
            const rv = new RunView();

            // Build filter
            let filter = '';
            if (this._personID) {
                filter = `PersonID='${this._personID}'`;
            } else if (this._organizationID) {
                filter = `OrganizationID='${this._organizationID}'`;
            } else {
                return;
            }

            const [methodsResult, typesResult] = await rv.RunViews([
                {
                    EntityName: 'MJ.BizApps.Common: Contact Methods',
                    ExtraFilter: filter,
                    ResultType: 'entity_object'
                },
                {
                    EntityName: 'MJ.BizApps.Common: Contact Types',
                    ExtraFilter: 'IsActive=1',
                    OrderBy: 'DisplayRank ASC',
                    ResultType: 'entity_object'
                }
            ]);

            this.ContactMethods = methodsResult.Success
                ? methodsResult.Results as mjBizAppsCommonContactMethodEntity[]
                : [];
            this.ContactTypes = typesResult.Success
                ? typesResult.Results as mjBizAppsCommonContactTypeEntity[]
                : [];

            // Sort: primary first, then by type rank
            this.ContactMethods.sort((a, b) => {
                if (a.IsPrimary && !b.IsPrimary) return -1;
                if (!a.IsPrimary && b.IsPrimary) return 1;
                return this.getTypeRank(a.ContactTypeID) - this.getTypeRank(b.ContactTypeID);
            });

            // Set default type for add form
            if (this.ContactTypes.length > 0) {
                this.AddForm.TypeID = this.ContactTypes[0].ID;
            }
        } catch (err) {
            console.error('ContactMethodList: Error loading data', err);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
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
     * @param value - The URL string to open
     */
    onOpenLink(value: string): void {
        let url = value;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://' + url;
        }
        window.open(url, '_blank');
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
     * Persists the new contact method from the add form.
     *
     * When the "Primary" flag is set, other primaries of the same contact
     * type are demoted first. The contact list is reloaded after saving.
     */
    async onSaveAdd(): Promise<void> {
        if (!this.AddForm.Value) return;

        this.Saving = true;
        this.cdr.detectChanges();

        try {
            const md = new Metadata();
            const cm = await md.GetEntityObject<mjBizAppsCommonContactMethodEntity>('MJ.BizApps.Common: Contact Methods');
            cm.NewRecord();
            cm.ContactTypeID = this.AddForm.TypeID;
            cm.Value = this.AddForm.Value;
            cm.Label = this.AddForm.Label || null;
            cm.IsPrimary = this.AddForm.IsPrimary;

            if (this._personID) {
                cm.PersonID = this._personID;
            } else if (this._organizationID) {
                cm.OrganizationID = this._organizationID;
            }

            // If setting primary, clear other primaries of same type
            if (this.AddForm.IsPrimary) {
                await this.clearPrimariesForType(this.AddForm.TypeID);
            }

            await cm.Save();
            await this.loadData();
        } catch (err) {
            console.error('ContactMethodList: Error adding contact', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Opens the inline edit form for an existing contact method, populating
     * the form fields from the current entity data.
     *
     * Closes the add form if it is currently open.
     *
     * @param cm - The contact method entity to edit
     */
    onEdit(cm: mjBizAppsCommonContactMethodEntity): void {
        this.EditForm = {
            TypeID: cm.ContactTypeID,
            Value: cm.Value,
            Label: cm.Label || '',
            IsPrimary: cm.IsPrimary
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
     * Persists the edited contact method from the edit form.
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
            await cm.Save();

            await this.loadData();
        } catch (err) {
            console.error('ContactMethodList: Error saving contact', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
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
            await cm.Save();

            await this.loadData();
        } catch (err) {
            console.error('ContactMethodList: Error setting primary', err);
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
            await cm.Delete();
            await this.loadData();
        } catch (err) {
            console.error('ContactMethodList: Error deleting contact', err);
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
            await c.Save();
        }
    }
}
