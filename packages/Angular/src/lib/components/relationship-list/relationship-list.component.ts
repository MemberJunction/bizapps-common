import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CompositeKey, Metadata, RunView } from '@memberjunction/core';
import { FormNavigationEvent, RecordNavigationEvent } from '@memberjunction/ng-base-forms';
import {
    mjBizAppsCommonRelationshipEntity,
    mjBizAppsCommonRelationshipTypeEntity,
    mjBizAppsCommonPersonEntity,
    mjBizAppsCommonOrganizationEntity
} from '@mj-biz-apps/common-entities';

interface RelationshipDisplayItem {
    Relationship: mjBizAppsCommonRelationshipEntity;
    DirectionLabel: string;  // ForwardLabel or ReverseLabel
    TargetName: string;      // Name of the "other" entity
    TargetEntityName: string; // MJ entity name for navigation (e.g., 'MJ.BizApps.Common: People')
    TargetID: string;        // ID of the target record
    DateDisplay: string;
}

interface CategoryGroup {
    Category: string;        // e.g., 'PersonToOrganization'
    Label: string;           // e.g., 'Employment'
    Icon: string;            // Font Awesome class
    IconClass: string;       // CSS class for icon background
    Items: RelationshipDisplayItem[];
}

interface SearchResult {
    ID: string;
    Name: string;
    Detail: string;
}

interface AddFormData {
    TypeID: string;
    TargetSearch: string;
    TargetID: string;
    TargetName: string;
    Title: string;
    StartDate: string;
    EndDate: string;
}

interface EditFormData {
    TypeID: string;
    Title: string;
    StartDate: string;
    EndDate: string;
    Status: 'Active' | 'Inactive' | 'Ended';
}

// Category display configuration
const CATEGORY_CONFIG: Record<string, { label: string; icon: string; iconClass: string }> = {
    'PersonToOrganization': { label: 'Employment', icon: 'fa-solid fa-briefcase', iconClass: 'cat-employment' },
    'PersonToPerson': { label: 'Personal', icon: 'fa-solid fa-heart', iconClass: 'cat-personal' },
    'OrganizationToOrganization': { label: 'Business', icon: 'fa-solid fa-building', iconClass: 'cat-business' }
};

@Component({
    standalone: true,
    imports: [CommonModule, FormsModule],
    selector: 'bizapps-relationship-list',
    templateUrl: './relationship-list.component.html',
    styleUrls: ['./relationship-list.component.css']
})
export class RelationshipListComponent {
    private cdr = inject(ChangeDetectorRef);

    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

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

    GroupedRelationships: CategoryGroup[] = [];
    RelationshipTypes: mjBizAppsCommonRelationshipTypeEntity[] = [];
    Loading = false;
    Saving = false;
    ShowAddForm = false;
    EditingId: string | null = null;

    AddForm: AddFormData = this.createEmptyAddForm();
    EditForm: EditFormData = this.createEmptyEditForm();
    TargetSearchResults: SearchResult[] = [];

    private relationshipTypeMap = new Map<string, mjBizAppsCommonRelationshipTypeEntity>();
    private searchDebounceTimer: ReturnType<typeof setTimeout> | null = null;

    private createEmptyAddForm(): AddFormData {
        return { TypeID: '', TargetSearch: '', TargetID: '', TargetName: '', Title: '', StartDate: '', EndDate: '' };
    }

    private createEmptyEditForm(): EditFormData {
        return { TypeID: '', Title: '', StartDate: '', EndDate: '', Status: 'Active' };
    }

    private async loadData(): Promise<void> {
        this.Loading = true;
        this.EditingId = null;
        this.ShowAddForm = false;
        this.cdr.detectChanges();

        try {
            const rv = new RunView();

            // Build filter for relationships
            let filter = '';
            if (this._personID) {
                filter = `FromPersonID='${this._personID}' OR ToPersonID='${this._personID}'`;
            } else if (this._organizationID) {
                filter = `FromOrganizationID='${this._organizationID}' OR ToOrganizationID='${this._organizationID}'`;
            } else {
                return;
            }

            const [relsResult, typesResult] = await rv.RunViews([
                {
                    EntityName: 'MJ.BizApps.Common: Relationships',
                    ExtraFilter: filter,
                    OrderBy: 'Status ASC, StartDate DESC',
                    ResultType: 'entity_object'
                },
                {
                    EntityName: 'MJ.BizApps.Common: Relationship Types',
                    ExtraFilter: 'IsActive=1',
                    ResultType: 'entity_object'
                }
            ]);

            const relationships = relsResult.Success
                ? relsResult.Results as mjBizAppsCommonRelationshipEntity[]
                : [];
            this.RelationshipTypes = typesResult.Success
                ? typesResult.Results as mjBizAppsCommonRelationshipTypeEntity[]
                : [];

            // Build type lookup map
            this.relationshipTypeMap.clear();
            for (const rt of this.RelationshipTypes) {
                this.relationshipTypeMap.set(rt.ID, rt);
            }

            // Group relationships by category
            this.GroupedRelationships = this.buildGroups(relationships);
        } catch (err) {
            console.error('RelationshipList: Error loading data', err);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
    }

    private buildGroups(relationships: mjBizAppsCommonRelationshipEntity[]): CategoryGroup[] {
        const groupMap = new Map<string, CategoryGroup>();

        for (const rel of relationships) {
            const relType = this.relationshipTypeMap.get(rel.RelationshipTypeID);
            if (!relType) continue;

            const category = relType.Category;
            if (!groupMap.has(category)) {
                const config = CATEGORY_CONFIG[category] || { label: category, icon: 'fa-solid fa-link', iconClass: 'cat-default' };
                groupMap.set(category, {
                    Category: category,
                    Label: config.label,
                    Icon: config.icon,
                    IconClass: config.iconClass,
                    Items: []
                });
            }

            const displayItem = this.buildDisplayItem(rel, relType);
            groupMap.get(category)!.Items.push(displayItem);
        }

        // Sort groups by a fixed order
        const order = ['PersonToOrganization', 'OrganizationToOrganization', 'PersonToPerson'];
        return order
            .filter(cat => groupMap.has(cat))
            .map(cat => groupMap.get(cat)!);
    }

    private buildDisplayItem(
        rel: mjBizAppsCommonRelationshipEntity,
        relType: mjBizAppsCommonRelationshipTypeEntity
    ): RelationshipDisplayItem {
        // Determine direction: is the current entity on the "From" or "To" side?
        const isFromSide = this.isCurrentEntityOnFromSide(rel);

        let directionLabel: string;
        let targetName: string;
        let targetEntityName: string;
        let targetID: string;

        if (!relType.IsDirectional) {
            // Symmetric relationship (e.g., Spouse) — always use ForwardLabel
            directionLabel = relType.ForwardLabel || relType.Name;
            targetName = this.getOtherSideName(rel, isFromSide);
            const target = this.getOtherSideTarget(rel, isFromSide);
            targetEntityName = target.entityName;
            targetID = target.id;
        } else if (isFromSide) {
            // Current entity is "From" → use ForwardLabel, show "To" target
            directionLabel = relType.ForwardLabel || relType.Name;
            targetName = this.getToSideName(rel);
            const target = this.getToSideTarget(rel);
            targetEntityName = target.entityName;
            targetID = target.id;
        } else {
            // Current entity is "To" → use ReverseLabel, show "From" target
            directionLabel = relType.ReverseLabel || relType.Name;
            targetName = this.getFromSideName(rel);
            const target = this.getFromSideTarget(rel);
            targetEntityName = target.entityName;
            targetID = target.id;
        }

        return {
            Relationship: rel,
            DirectionLabel: directionLabel + ' ',
            TargetName: targetName,
            TargetEntityName: targetEntityName,
            TargetID: targetID,
            DateDisplay: this.formatDateRange(rel.StartDate, rel.EndDate, rel.Status)
        };
    }

    private isCurrentEntityOnFromSide(rel: mjBizAppsCommonRelationshipEntity): boolean {
        if (this._personID) {
            return rel.FromPersonID === this._personID;
        }
        if (this._organizationID) {
            return rel.FromOrganizationID === this._organizationID;
        }
        return true;
    }

    private getToSideName(rel: mjBizAppsCommonRelationshipEntity): string {
        return rel.ToPerson || rel.ToOrganization || 'Unknown';
    }

    private getFromSideName(rel: mjBizAppsCommonRelationshipEntity): string {
        return rel.FromPerson || rel.FromOrganization || 'Unknown';
    }

    private getOtherSideName(rel: mjBizAppsCommonRelationshipEntity, isFromSide: boolean): string {
        return isFromSide ? this.getToSideName(rel) : this.getFromSideName(rel);
    }

    private getToSideTarget(rel: mjBizAppsCommonRelationshipEntity): { entityName: string; id: string } {
        if (rel.ToPersonID) return { entityName: 'MJ.BizApps.Common: People', id: rel.ToPersonID };
        if (rel.ToOrganizationID) return { entityName: 'MJ.BizApps.Common: Organizations', id: rel.ToOrganizationID };
        return { entityName: '', id: '' };
    }

    private getFromSideTarget(rel: mjBizAppsCommonRelationshipEntity): { entityName: string; id: string } {
        if (rel.FromPersonID) return { entityName: 'MJ.BizApps.Common: People', id: rel.FromPersonID };
        if (rel.FromOrganizationID) return { entityName: 'MJ.BizApps.Common: Organizations', id: rel.FromOrganizationID };
        return { entityName: '', id: '' };
    }

    private getOtherSideTarget(rel: mjBizAppsCommonRelationshipEntity, isFromSide: boolean): { entityName: string; id: string } {
        return isFromSide ? this.getToSideTarget(rel) : this.getFromSideTarget(rel);
    }

    onNavigateToTarget(item: RelationshipDisplayItem, event: MouseEvent): void {
        if (!item.TargetEntityName || !item.TargetID) return;
        event.stopPropagation();

        const navEvent: RecordNavigationEvent = {
            Kind: 'record',
            EntityName: item.TargetEntityName,
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', item.TargetID),
            OpenInNewTab: event.ctrlKey || event.metaKey
        };
        this.Navigate.emit(navEvent);
    }

    private formatDateRange(start: Date | null, end: Date | null, status: string): string {
        if (!start && !end) return '';

        const formatDate = (d: Date): string => {
            const date = new Date(d);
            return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
        };

        const startStr = start ? formatDate(start) : '';
        const endStr = end ? formatDate(end) : (status === 'Active' ? 'Present' : '');

        if (startStr && endStr) return `${startStr} - ${endStr}`;
        if (startStr) return `${startStr} -`;
        return '';
    }

    // --- Add Form ---

    onShowAdd(): void {
        this.AddForm = this.createEmptyAddForm();
        this.TargetSearchResults = [];
        this.ShowAddForm = true;
        this.EditingId = null;
        this.cdr.detectChanges();
    }

    onCancelAdd(): void {
        this.ShowAddForm = false;
        this.TargetSearchResults = [];
        this.cdr.detectChanges();
    }

    onAddTypeChange(): void {
        // Clear target when type changes (category may differ)
        this.AddForm.TargetID = '';
        this.AddForm.TargetName = '';
        this.AddForm.TargetSearch = '';
        this.TargetSearchResults = [];
        this.cdr.detectChanges();
    }

    getAddCategory(): string {
        if (!this.AddForm.TypeID) return '—';
        const rt = this.relationshipTypeMap.get(this.AddForm.TypeID);
        return rt?.Category || '—';
    }

    getAddTargetLabel(): string {
        const category = this.getAddCategory();
        if (category === 'PersonToOrganization') return 'Organization';
        if (category === 'OrganizationToOrganization') return 'Organization';
        if (category === 'PersonToPerson') return 'Person';
        return 'Target';
    }

    onTargetSearch(): void {
        if (this.searchDebounceTimer) {
            clearTimeout(this.searchDebounceTimer);
        }
        this.searchDebounceTimer = setTimeout(() => {
            this.performTargetSearch();
        }, 300);
    }

    private async performTargetSearch(): Promise<void> {
        const query = this.AddForm.TargetSearch?.trim();
        if (!query || query.length < 2) {
            this.TargetSearchResults = [];
            this.cdr.detectChanges();
            return;
        }

        const category = this.getAddCategory();
        const escapedQuery = query.replace(/'/g, "''");
        const rv = new RunView();

        try {
            if (category === 'PersonToPerson') {
                const result = await rv.RunView<mjBizAppsCommonPersonEntity>({
                    EntityName: 'MJ.BizApps.Common: People',
                    ExtraFilter: `(FirstName LIKE '%${escapedQuery}%' OR LastName LIKE '%${escapedQuery}%' OR DisplayName LIKE '%${escapedQuery}%')`,
                    MaxRows: 10,
                    ResultType: 'entity_object'
                });
                this.TargetSearchResults = result.Success
                    ? result.Results.map(p => ({
                        ID: p.ID,
                        Name: p.DisplayName || `${p.FirstName} ${p.LastName}`,
                        Detail: p.Title || ''
                    }))
                    : [];
            } else {
                const result = await rv.RunView<mjBizAppsCommonOrganizationEntity>({
                    EntityName: 'MJ.BizApps.Common: Organizations',
                    ExtraFilter: `Name LIKE '%${escapedQuery}%'`,
                    MaxRows: 10,
                    ResultType: 'entity_object'
                });
                this.TargetSearchResults = result.Success
                    ? result.Results.map(o => ({
                        ID: o.ID,
                        Name: o.Name,
                        Detail: o.OrganizationType || ''
                    }))
                    : [];
            }
        } catch (err) {
            console.error('RelationshipList: Search error', err);
            this.TargetSearchResults = [];
        }
        this.cdr.detectChanges();
    }

    onSelectTarget(result: SearchResult): void {
        this.AddForm.TargetID = result.ID;
        this.AddForm.TargetName = result.Name;
        this.AddForm.TargetSearch = '';
        this.TargetSearchResults = [];
        this.cdr.detectChanges();
    }

    onClearTarget(): void {
        this.AddForm.TargetID = '';
        this.AddForm.TargetName = '';
        this.cdr.detectChanges();
    }

    async onSaveAdd(): Promise<void> {
        if (!this.AddForm.TypeID || !this.AddForm.TargetID) return;

        this.Saving = true;
        this.cdr.detectChanges();

        try {
            const md = new Metadata();
            const rel = await md.GetEntityObject<mjBizAppsCommonRelationshipEntity>('MJ.BizApps.Common: Relationships');
            rel.NewRecord();
            rel.RelationshipTypeID = this.AddForm.TypeID;
            rel.Title = this.AddForm.Title || null;
            rel.Status = 'Active';

            if (this.AddForm.StartDate) {
                rel.StartDate = new Date(this.AddForm.StartDate);
            }
            if (this.AddForm.EndDate) {
                rel.EndDate = new Date(this.AddForm.EndDate);
            }

            // Set From/To based on which side we're on and category
            const rt = this.relationshipTypeMap.get(this.AddForm.TypeID);
            if (!rt) return;

            if (this._personID) {
                rel.FromPersonID = this._personID;
                if (rt.Category === 'PersonToOrganization') {
                    rel.ToOrganizationID = this.AddForm.TargetID;
                } else if (rt.Category === 'PersonToPerson') {
                    rel.ToPersonID = this.AddForm.TargetID;
                }
            } else if (this._organizationID) {
                rel.FromOrganizationID = this._organizationID;
                rel.ToOrganizationID = this.AddForm.TargetID;
            }

            await rel.Save();
            await this.loadData();
        } catch (err) {
            console.error('RelationshipList: Error adding relationship', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    // --- Edit ---

    onEdit(rel: mjBizAppsCommonRelationshipEntity): void {
        this.EditForm = {
            TypeID: rel.RelationshipTypeID,
            Title: rel.Title || '',
            StartDate: rel.StartDate ? this.formatDateForInput(rel.StartDate) : '',
            EndDate: rel.EndDate ? this.formatDateForInput(rel.EndDate) : '',
            Status: rel.Status as 'Active' | 'Inactive' | 'Ended'
        };
        this.EditingId = rel.ID;
        this.ShowAddForm = false;
        this.cdr.detectChanges();
    }

    onCancelEdit(): void {
        this.EditingId = null;
        this.cdr.detectChanges();
    }

    onEditTypeChange(): void {
        this.cdr.detectChanges();
    }

    getEditCategory(): string {
        if (!this.EditForm.TypeID) return '—';
        const rt = this.relationshipTypeMap.get(this.EditForm.TypeID);
        return rt?.Category || '—';
    }

    async onSaveEdit(): Promise<void> {
        if (!this.EditingId) return;

        this.Saving = true;
        this.cdr.detectChanges();

        try {
            // Find the relationship entity in our loaded data
            let rel: mjBizAppsCommonRelationshipEntity | undefined;
            for (const group of this.GroupedRelationships) {
                const found = group.Items.find(i => i.Relationship.ID === this.EditingId);
                if (found) {
                    rel = found.Relationship;
                    break;
                }
            }
            if (!rel) return;

            rel.RelationshipTypeID = this.EditForm.TypeID;
            rel.Title = this.EditForm.Title || null;
            rel.Status = this.EditForm.Status;
            rel.StartDate = this.EditForm.StartDate ? new Date(this.EditForm.StartDate) : null;
            rel.EndDate = this.EditForm.EndDate ? new Date(this.EditForm.EndDate) : null;

            await rel.Save();
            await this.loadData();
        } catch (err) {
            console.error('RelationshipList: Error saving edit', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    async onEndRelationship(rel: mjBizAppsCommonRelationshipEntity): Promise<void> {
        this.Saving = true;
        this.cdr.detectChanges();

        try {
            rel.Status = 'Ended';
            rel.EndDate = new Date();
            await rel.Save();
            await this.loadData();
        } catch (err) {
            console.error('RelationshipList: Error ending relationship', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    async onDelete(rel: mjBizAppsCommonRelationshipEntity): Promise<void> {
        this.Saving = true;
        this.cdr.detectChanges();

        try {
            await rel.Delete();
            await this.loadData();
        } catch (err) {
            console.error('RelationshipList: Error deleting relationship', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    private formatDateForInput(date: Date): string {
        const d = new Date(date);
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
}
