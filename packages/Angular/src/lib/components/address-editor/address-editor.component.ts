import { Component, Input, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Metadata, RunView } from '@memberjunction/core';
import {
    mjBizAppsCommonAddressEntity,
    mjBizAppsCommonAddressLinkEntity,
    mjBizAppsCommonAddressTypeEntity
} from '@mj-biz-apps/common-entities';

interface AddressItem {
    Link: mjBizAppsCommonAddressLinkEntity;
    Address: mjBizAppsCommonAddressEntity;
}

interface AddressEditForm {
    TypeID: string;
    IsPrimary: boolean;
    Line1: string;
    Line2: string;
    City: string;
    StateProvince: string;
    PostalCode: string;
    Country: string;
}

@Component({
    standalone: true,
    imports: [CommonModule, FormsModule],
    selector: 'bizapps-address-editor',
    templateUrl: './address-editor.component.html',
    styleUrls: ['./address-editor.component.css']
})
export class AddressEditorComponent {
    private cdr = inject(ChangeDetectorRef);

    private _entityName = '';
    private _recordID = '';

    @Input()
    set EntityName(value: string) {
        const prev = this._entityName;
        this._entityName = value;
        if (value && value !== prev && this._recordID) {
            this.loadData();
        }
    }
    get EntityName(): string { return this._entityName; }

    @Input()
    set RecordID(value: string) {
        const prev = this._recordID;
        this._recordID = value;
        if (value && value !== prev && this._entityName) {
            this.loadData();
        }
    }
    get RecordID(): string { return this._recordID; }

    AddressItems: AddressItem[] = [];
    AddressTypes: mjBizAppsCommonAddressTypeEntity[] = [];
    EditingIndex: number | null = null; // null=not editing, -1=adding new, >=0=editing that index
    EditForm: AddressEditForm = this.createEmptyForm();
    Loading = false;
    Saving = false;

    private resolvedEntityID = '';

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

    private async loadData(): Promise<void> {
        this.Loading = true;
        this.EditingIndex = null;
        this.cdr.detectChanges();

        try {
            const md = new Metadata();

            // Resolve EntityName → EntityID
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
                    EntityName: 'MJ.BizApps.Common: Address Links',
                    ExtraFilter: `EntityID='${this.resolvedEntityID}' AND RecordID='${this._recordID}'`,
                    ResultType: 'entity_object'
                },
                {
                    EntityName: 'MJ.BizApps.Common: Address Types',
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
                    EntityName: 'MJ.BizApps.Common: Addresses',
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

    getAddressTypeIcon(typeID: string): string {
        const addrType = this.AddressTypes.find(t => t.ID === typeID);
        return addrType?.IconClass || 'fa-solid fa-location-dot';
    }

    formatAddressLine1(address: mjBizAppsCommonAddressEntity): string {
        const parts = [address.Line1];
        if (address.Line2) parts.push(address.Line2);
        return parts.join(', ');
    }

    formatAddressLine2(address: mjBizAppsCommonAddressEntity): string {
        const parts: string[] = [];
        if (address.City) parts.push(address.City);
        if (address.StateProvince) parts.push(address.StateProvince);
        if (address.PostalCode) parts.push(address.PostalCode);

        let line = parts.join(', ');
        if (address.Country) line += ', ' + address.Country;
        return line;
    }

    onAdd(): void {
        this.EditForm = this.createEmptyForm();
        if (this.AddressTypes.length > 0) {
            this.EditForm.TypeID = this.AddressTypes[0].ID;
        }
        // Default to primary if no addresses exist
        if (this.AddressItems.length === 0) {
            this.EditForm.IsPrimary = true;
        }
        this.EditingIndex = -1;
        this.cdr.detectChanges();
    }

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
        this.EditingIndex = index;
        this.cdr.detectChanges();
    }

    onCancelEdit(): void {
        this.EditingIndex = null;
        this.cdr.detectChanges();
    }

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
        } catch (err) {
            console.error('AddressEditor: Error saving', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

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

    private async saveNew(md: Metadata): Promise<void> {
        // Create new Address
        const address = await md.GetEntityObject<mjBizAppsCommonAddressEntity>('MJ.BizApps.Common: Addresses');
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
        const link = await md.GetEntityObject<mjBizAppsCommonAddressLinkEntity>('MJ.BizApps.Common: Address Links');
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
        } catch (err) {
            console.error('AddressEditor: Error setting primary', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

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
        } catch (err) {
            console.error('AddressEditor: Error deleting address', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }
}
