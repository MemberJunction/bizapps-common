import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Metadata, RunView } from '@memberjunction/core';
import {
    mjBizAppsCommonContactMethodEntity,
    mjBizAppsCommonContactTypeEntity
} from '@mj-biz-apps/common-entities';

interface ContactFormData {
    TypeID: string;
    Value: string;
    Label: string;
    IsPrimary: boolean;
}

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

    @Input()
    set PersonID(value: string | null) {
        const prev = this._personID;
        this._personID = value;
        if (value && value !== prev) {
            this.loadData();
        }
    }
    get PersonID(): string | null { return this._personID; }

    @Input()
    set OrganizationID(value: string | null) {
        const prev = this._organizationID;
        this._organizationID = value;
        if (value && value !== prev) {
            this.loadData();
        }
    }
    get OrganizationID(): string | null { return this._organizationID; }

    ContactMethods: mjBizAppsCommonContactMethodEntity[] = [];
    ContactTypes: mjBizAppsCommonContactTypeEntity[] = [];
    EditingId: string | null = null;
    ShowAddForm = false;
    Loading = false;
    Saving = false;

    EditForm: ContactFormData = this.createEmptyForm();
    AddForm: ContactFormData = this.createEmptyForm();

    // Map of ContactType name (lowercase) to icon color CSS class
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

    // Contact types that are links (open in new tab rather than copy)
    private linkTypeNames = new Set(['linkedin', 'twitter', 'twitter / x', 'website']);

    private createEmptyForm(): ContactFormData {
        return { TypeID: '', Value: '', Label: '', IsPrimary: false };
    }

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

    private getTypeRank(typeID: string): number {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        return ct?.DisplayRank ?? 999;
    }

    getContactTypeIcon(typeID: string): string {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        return ct?.IconClass || 'fa-solid fa-circle-info';
    }

    getIconColorClass(typeID: string): string {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        if (!ct) return 'icon-default';
        const key = ct.Name.toLowerCase();
        return this.iconColorMap[key] || 'icon-default';
    }

    getContactMeta(cm: mjBizAppsCommonContactMethodEntity): string {
        const parts: string[] = [];
        if (cm.Label) parts.push(cm.Label);
        if (cm.ContactType) parts.push(cm.ContactType);
        return parts.join(' · ') || cm.ContactType;
    }

    getPlaceholder(typeID: string): string {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        if (!ct) return 'Enter value...';
        const name = ct.Name.toLowerCase();
        if (name.includes('email')) return 'Enter email address...';
        if (name.includes('phone') || name.includes('mobile')) return 'Enter phone number...';
        if (name.includes('linkedin') || name.includes('twitter') || name.includes('website')) return 'Enter URL...';
        return 'Enter value...';
    }

    isLinkType(typeID: string): boolean {
        const ct = this.ContactTypes.find(t => t.ID === typeID);
        if (!ct) return false;
        return this.linkTypeNames.has(ct.Name.toLowerCase());
    }

    onCopyValue(value: string): void {
        navigator.clipboard.writeText(value).catch(() => {
            // Fallback: silently fail
        });
    }

    onOpenLink(value: string): void {
        let url = value;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://' + url;
        }
        window.open(url, '_blank');
    }

    onShowAdd(): void {
        this.AddForm = this.createEmptyForm();
        if (this.ContactTypes.length > 0) {
            this.AddForm.TypeID = this.ContactTypes[0].ID;
        }
        this.ShowAddForm = true;
        this.cdr.detectChanges();
    }

    onCancelAdd(): void {
        this.ShowAddForm = false;
        this.cdr.detectChanges();
    }

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

    onCancelEdit(): void {
        this.EditingId = null;
        this.cdr.detectChanges();
    }

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

    private async clearPrimariesForType(typeID: string): Promise<void> {
        const sameType = this.ContactMethods.filter(c => c.ContactTypeID === typeID && c.IsPrimary);
        for (const c of sameType) {
            c.IsPrimary = false;
            await c.Save();
        }
    }
}
