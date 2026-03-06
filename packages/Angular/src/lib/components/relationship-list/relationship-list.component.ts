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
} from '@memberjunction/bizapps-common-entities';

/**
 * View model for a single relationship row, enriched with display-friendly
 * fields that account for the directionality of the relationship.
 *
 * Because relationships are stored with From/To sides, this model resolves
 * which label and target to show based on whether the current entity is the
 * "From" or "To" party.
 */
interface RelationshipDisplayItem {
    /** The underlying Relationship entity record. */
    Relationship: mjBizAppsCommonRelationshipEntity;

    /**
     * The human-readable label describing the relationship direction
     * (e.g., `'Employed by'` or `'Employer of'`).
     */
    DirectionLabel: string;

    /** Display name of the "other" entity in the relationship (e.g., `'Acme Corp'`). */
    TargetName: string;

    /**
     * The MemberJunction entity name for the target, used for navigation
     * (e.g., `'MJ.BizApps.Common: People'` or `'MJ.BizApps.Common: Organizations'`).
     */
    TargetEntityName: string;

    /** The primary key ID of the target record, used for navigation. */
    TargetID: string;

    /**
     * A formatted date range string for display
     * (e.g., `'Jan 2020 - Present'` or `'Mar 2018 - Dec 2023'`).
     */
    DateDisplay: string;
}

/**
 * Groups relationship display items by category for the grouped-timeline
 * layout in the template.
 */
interface CategoryGroup {
    /**
     * The raw category key from the RelationshipType
     * (e.g., `'PersonToOrganization'`, `'PersonToPerson'`).
     */
    Category: string;

    /** Human-readable group heading (e.g., `'Employment'`, `'Personal'`). */
    Label: string;

    /** Font Awesome icon class for the group header. */
    Icon: string;

    /** CSS class applied to the icon background for color theming. */
    IconClass: string;

    /** The relationship display items belonging to this category. */
    Items: RelationshipDisplayItem[];
}

/**
 * Represents a single result from the target entity search typeahead,
 * used when adding a new relationship.
 */
interface SearchResult {
    /** The primary key ID of the matched Person or Organization. */
    ID: string;

    /** The display name of the matched record. */
    Name: string;

    /** Additional detail shown below the name (e.g., Title for people, Type for orgs). */
    Detail: string;
}

/**
 * Form model for the "Add Relationship" panel.
 *
 * Fields map to the relationship entity properties plus search/selection
 * state for the target entity typeahead.
 */
interface AddFormData {
    /** The selected RelationshipType record ID. */
    TypeID: string;

    /** The current text in the target search input (for typeahead). */
    TargetSearch: string;

    /** The selected target entity's record ID (set after selection). */
    TargetID: string;

    /** The display name of the selected target entity. */
    TargetName: string;

    /** Optional title or role description for the relationship (e.g., `'CEO'`). */
    Title: string;

    /** ISO date string (`YYYY-MM-DD`) for the relationship start date. */
    StartDate: string;

    /** ISO date string (`YYYY-MM-DD`) for the relationship end date. */
    EndDate: string;
}

/**
 * Form model for the "Edit Relationship" inline panel.
 *
 * The target entity cannot be changed during editing -- only metadata
 * fields (type, title, dates, status) are editable.
 */
interface EditFormData {
    /** The selected RelationshipType record ID. */
    TypeID: string;

    /** Optional title or role description for the relationship. */
    Title: string;

    /** ISO date string (`YYYY-MM-DD`) for the relationship start date. */
    StartDate: string;

    /** ISO date string (`YYYY-MM-DD`) for the relationship end date. */
    EndDate: string;

    /** The current status of the relationship. */
    Status: 'Active' | 'Inactive' | 'Ended';
}

/**
 * Display configuration for each relationship category, mapping category
 * keys to their human-readable labels, Font Awesome icons, and CSS classes.
 *
 * Used by the template to render group headers with consistent iconography
 * and color theming.
 */
const CATEGORY_CONFIG: Record<string, { label: string; icon: string; iconClass: string }> = {
    'PersonToOrganization': { label: 'Employment', icon: 'fa-solid fa-briefcase', iconClass: 'cat-employment' },
    'PersonToPerson': { label: 'Personal', icon: 'fa-solid fa-heart', iconClass: 'cat-personal' },
    'OrganizationToOrganization': { label: 'Business', icon: 'fa-solid fa-building', iconClass: 'cat-business' }
};

/**
 * Displays and manages relationships for a Person or Organization record,
 * grouped by category (Employment, Personal, Business) in a timeline layout.
 *
 * Relationships are bidirectional: each record has From and To sides with
 * optional Person and Organization foreign keys. The component automatically
 * resolves direction labels and target names based on which side the current
 * entity occupies.
 *
 * Supports adding new relationships with a typeahead target search, inline
 * editing of relationship metadata, ending active relationships, and deletion.
 *
 * @example
 * ```html
 * <!-- For a Person -->
 * <bizapps-relationship-list
 *     [PersonID]="person.ID"
 *     (Navigate)="onNavigate($event)">
 * </bizapps-relationship-list>
 *
 * <!-- For an Organization -->
 * <bizapps-relationship-list
 *     [OrganizationID]="org.ID"
 *     (Navigate)="onNavigate($event)">
 * </bizapps-relationship-list>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule, FormsModule],
    selector: 'bizapps-relationship-list',
    templateUrl: './relationship-list.component.html',
    styleUrls: ['./relationship-list.component.css']
})
export class RelationshipListComponent {
    private cdr = inject(ChangeDetectorRef);

    /**
     * Emitted when the user clicks a relationship target name to navigate
     * to that Person or Organization record.
     *
     * The event payload is a {@link FormNavigationEvent} (specifically a
     * {@link RecordNavigationEvent}) containing the target entity name,
     * composite key, and whether to open in a new tab.
     *
     * @fires Navigate When the user clicks a target entity link
     *
     * @example
     * ```html
     * <bizapps-relationship-list
     *     [PersonID]="person.ID"
     *     (Navigate)="onNavigate($event)">
     * </bizapps-relationship-list>
     * ```
     */
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /**
     * Controls whether add, edit, delete, and end-relationship actions are available.
     * When `false`, the component renders in read-only display mode.
     * Navigation links to related entities remain available regardless of this setting.
     */
    @Input() EditMode = false;

    /** Emitted after any mutation (save, delete, end-relationship) so the parent can refresh derived data. */
    @Output() DataChanged = new EventEmitter<void>();

    private _personID: string | null = null;
    private _organizationID: string | null = null;

    /**
     * The Person record ID whose relationships should be displayed.
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
     * The Organization record ID whose relationships should be displayed.
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
     * Relationships grouped by category (Employment, Personal, Business),
     * each containing an array of display items. This is the primary data
     * structure consumed by the template for rendering the grouped timeline.
     */
    GroupedRelationships: CategoryGroup[] = [];

    /**
     * All active relationship types available for selection in type dropdowns.
     * Loaded from `MJ.BizApps.Common: Relationship Types`, filtered to `IsActive=1`.
     */
    RelationshipTypes: mjBizAppsCommonRelationshipTypeEntity[] = [];

    /**
     * Indicates whether the component is performing the initial data load.
     * The template shows a loading spinner while this is `true`.
     */
    Loading = false;

    /**
     * Indicates whether a save, delete, or end-relationship operation is in progress.
     * Used to disable action buttons and show spinner feedback while `true`.
     */
    Saving = false;

    /**
     * Controls visibility of the "Add Relationship" form panel. When `true`,
     * the add form is displayed below the existing relationship groups.
     */
    ShowAddForm = false;

    /**
     * The ID of the relationship currently being edited inline, or `null`
     * when not in edit mode.
     */
    EditingId: string | null = null;

    /**
     * The form model bound to the "Add Relationship" panel via two-way
     * binding. Reset to defaults each time the add form is opened.
     */
    AddForm: AddFormData = this.createEmptyAddForm();

    /**
     * The form model bound to the inline edit panel via two-way binding.
     * Populated from the existing relationship record when editing begins.
     */
    EditForm: EditFormData = this.createEmptyEditForm();

    /**
     * Search results from the target entity typeahead, displayed as a
     * dropdown below the search input in the add form.
     */
    TargetSearchResults: SearchResult[] = [];

    /** Lookup map from RelationshipType ID to entity for quick access. */
    private relationshipTypeMap = new Map<string, mjBizAppsCommonRelationshipTypeEntity>();

    /** Handle for the debounce timer used in target search. */
    private searchDebounceTimer: ReturnType<typeof setTimeout> | null = null;

    /** Creates a blank {@link AddFormData} with empty defaults. */
    private createEmptyAddForm(): AddFormData {
        return { TypeID: '', TargetSearch: '', TargetID: '', TargetName: '', Title: '', StartDate: '', EndDate: '' };
    }

    /** Creates a blank {@link EditFormData} with default status of Active. */
    private createEmptyEditForm(): EditFormData {
        return { TypeID: '', Title: '', StartDate: '', EndDate: '', Status: 'Active' };
    }

    /**
     * Loads relationships and relationship types from the server,
     * then groups them by category. Resets editing state before loading.
     */
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

    /** Organizes relationships into category groups with display-friendly items. */
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

    /** Constructs a display item from a relationship and its type, resolving direction. */
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
            // Symmetric relationship (e.g., Spouse) -- always use ForwardLabel
            directionLabel = relType.ForwardLabel || relType.Name;
            targetName = this.getOtherSideName(rel, isFromSide);
            const target = this.getOtherSideTarget(rel, isFromSide);
            targetEntityName = target.entityName;
            targetID = target.id;
        } else if (isFromSide) {
            // Current entity is "From" -> use ForwardLabel, show "To" target
            directionLabel = relType.ForwardLabel || relType.Name;
            targetName = this.getToSideName(rel);
            const target = this.getToSideTarget(rel);
            targetEntityName = target.entityName;
            targetID = target.id;
        } else {
            // Current entity is "To" -> use ReverseLabel, show "From" target
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

    /** Checks whether the current entity (Person or Org) is on the "From" side. */
    private isCurrentEntityOnFromSide(rel: mjBizAppsCommonRelationshipEntity): boolean {
        if (this._personID) {
            return rel.FromPersonID === this._personID;
        }
        if (this._organizationID) {
            return rel.FromOrganizationID === this._organizationID;
        }
        return true;
    }

    /** Returns the display name of the "To" side entity. */
    private getToSideName(rel: mjBizAppsCommonRelationshipEntity): string {
        return rel.ToPerson || rel.ToOrganization || 'Unknown';
    }

    /** Returns the display name of the "From" side entity. */
    private getFromSideName(rel: mjBizAppsCommonRelationshipEntity): string {
        return rel.FromPerson || rel.FromOrganization || 'Unknown';
    }

    /** Returns the display name of whichever side is NOT the current entity. */
    private getOtherSideName(rel: mjBizAppsCommonRelationshipEntity, isFromSide: boolean): string {
        return isFromSide ? this.getToSideName(rel) : this.getFromSideName(rel);
    }

    /** Returns the entity name and ID for the "To" side. */
    private getToSideTarget(rel: mjBizAppsCommonRelationshipEntity): { entityName: string; id: string } {
        if (rel.ToPersonID) return { entityName: 'MJ.BizApps.Common: People', id: rel.ToPersonID };
        if (rel.ToOrganizationID) return { entityName: 'MJ.BizApps.Common: Organizations', id: rel.ToOrganizationID };
        return { entityName: '', id: '' };
    }

    /** Returns the entity name and ID for the "From" side. */
    private getFromSideTarget(rel: mjBizAppsCommonRelationshipEntity): { entityName: string; id: string } {
        if (rel.FromPersonID) return { entityName: 'MJ.BizApps.Common: People', id: rel.FromPersonID };
        if (rel.FromOrganizationID) return { entityName: 'MJ.BizApps.Common: Organizations', id: rel.FromOrganizationID };
        return { entityName: '', id: '' };
    }

    /** Returns the entity name and ID for whichever side is NOT the current entity. */
    private getOtherSideTarget(rel: mjBizAppsCommonRelationshipEntity, isFromSide: boolean): { entityName: string; id: string } {
        return isFromSide ? this.getToSideTarget(rel) : this.getFromSideTarget(rel);
    }

    /**
     * Emits a {@link Navigate} event to navigate to the target entity record
     * of a relationship row.
     *
     * Supports Ctrl+Click / Cmd+Click to open in a new tab.
     *
     * @param item - The relationship display item whose target should be navigated to
     * @param event - The mouse event, used to detect modifier keys for new-tab behavior
     *
     * @fires Navigate With a {@link RecordNavigationEvent} payload
     */
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

    /** Formats a date range into a compact display string. */
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

    /**
     * Opens the "Add Relationship" form panel.
     *
     * Resets the add form to defaults, clears any previous search results,
     * and closes any active inline edit.
     */
    onShowAdd(): void {
        this.AddForm = this.createEmptyAddForm();
        this.TargetSearchResults = [];
        this.ShowAddForm = true;
        this.EditingId = null;
        this.cdr.detectChanges();
    }

    /**
     * Closes the "Add Relationship" form panel without saving, and clears
     * the target search results.
     */
    onCancelAdd(): void {
        this.ShowAddForm = false;
        this.TargetSearchResults = [];
        this.cdr.detectChanges();
    }

    /**
     * Handles a change to the relationship type in the add form.
     *
     * Clears the currently selected target because the category (and
     * therefore the target entity type) may have changed.
     */
    onAddTypeChange(): void {
        // Clear target when type changes (category may differ)
        this.AddForm.TargetID = '';
        this.AddForm.TargetName = '';
        this.AddForm.TargetSearch = '';
        this.TargetSearchResults = [];
        this.cdr.detectChanges();
    }

    /**
     * Returns the category key of the currently selected relationship type
     * in the add form (e.g., `'PersonToOrganization'`).
     *
     * @returns The category string, or `'--'` if no type is selected
     */
    getAddCategory(): string {
        if (!this.AddForm.TypeID) return '—';
        const rt = this.relationshipTypeMap.get(this.AddForm.TypeID);
        return rt?.Category || '—';
    }

    /**
     * Returns a user-facing label for the target entity search field based
     * on the current add form's relationship category.
     *
     * @returns `'Organization'`, `'Person'`, or `'Target'` depending on category
     */
    getAddTargetLabel(): string {
        const category = this.getAddCategory();
        if (category === 'PersonToOrganization') return 'Organization';
        if (category === 'OrganizationToOrganization') return 'Organization';
        if (category === 'PersonToPerson') return 'Person';
        return 'Target';
    }

    /**
     * Debounces the target search input and triggers a server-side search
     * after a 300ms pause in typing.
     *
     * Called on each keystroke in the target search field.
     */
    onTargetSearch(): void {
        if (this.searchDebounceTimer) {
            clearTimeout(this.searchDebounceTimer);
        }
        this.searchDebounceTimer = setTimeout(() => {
            this.performTargetSearch();
        }, 300);
    }

    /** Executes the debounced target search against Person or Organization entities. */
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

    /**
     * Selects a target entity from the search results dropdown, populating
     * the add form's target fields and clearing the search input.
     *
     * @param result - The selected search result to use as the relationship target
     */
    onSelectTarget(result: SearchResult): void {
        this.AddForm.TargetID = result.ID;
        this.AddForm.TargetName = result.Name;
        this.AddForm.TargetSearch = '';
        this.TargetSearchResults = [];
        this.cdr.detectChanges();
    }

    /**
     * Clears the currently selected target entity from the add form,
     * allowing the user to search for a different target.
     */
    onClearTarget(): void {
        this.AddForm.TargetID = '';
        this.AddForm.TargetName = '';
        this.cdr.detectChanges();
    }

    /**
     * Persists the new relationship from the add form.
     *
     * Determines which From/To fields to populate based on the current
     * entity type (Person or Organization) and the relationship category.
     * After saving, the relationship list is reloaded.
     */
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
            this.DataChanged.emit();
        } catch (err) {
            console.error('RelationshipList: Error adding relationship', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    // --- Edit ---

    /**
     * Opens the inline edit form for an existing relationship, populating
     * the form fields from the current entity data.
     *
     * Closes the add form if it is currently open.
     *
     * @param rel - The relationship entity to edit
     */
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

    /**
     * Cancels the current edit operation and returns to display mode.
     */
    onCancelEdit(): void {
        this.EditingId = null;
        this.cdr.detectChanges();
    }

    /**
     * Handles a change to the relationship type in the edit form.
     *
     * Triggers change detection so the category display updates.
     */
    onEditTypeChange(): void {
        this.cdr.detectChanges();
    }

    /**
     * Returns the category key of the currently selected relationship type
     * in the edit form (e.g., `'PersonToOrganization'`).
     *
     * @returns The category string, or `'--'` if no type is selected
     */
    getEditCategory(): string {
        if (!this.EditForm.TypeID) return '—';
        const rt = this.relationshipTypeMap.get(this.EditForm.TypeID);
        return rt?.Category || '—';
    }

    /**
     * Persists the edited relationship from the inline edit form.
     *
     * Locates the relationship entity within the grouped data, applies
     * the form values, saves, and reloads the list.
     */
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
            this.DataChanged.emit();
        } catch (err) {
            console.error('RelationshipList: Error saving edit', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Ends an active relationship by setting its status to `'Ended'` and
     * its end date to today. After saving, the relationship list is reloaded.
     *
     * @param rel - The active relationship entity to end
     */
    async onEndRelationship(rel: mjBizAppsCommonRelationshipEntity): Promise<void> {
        this.Saving = true;
        this.cdr.detectChanges();

        try {
            rel.Status = 'Ended';
            rel.EndDate = new Date();
            await rel.Save();
            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            console.error('RelationshipList: Error ending relationship', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Permanently deletes the given relationship record.
     *
     * After deletion, the relationship list is reloaded.
     *
     * @param rel - The relationship entity to delete
     */
    async onDelete(rel: mjBizAppsCommonRelationshipEntity): Promise<void> {
        this.Saving = true;
        this.cdr.detectChanges();

        try {
            await rel.Delete();
            await this.loadData();
            this.DataChanged.emit();
        } catch (err) {
            console.error('RelationshipList: Error deleting relationship', err);
        } finally {
            this.Saving = false;
            this.cdr.detectChanges();
        }
    }

    /** Converts a Date to an ISO date string (`YYYY-MM-DD`) for HTML date inputs. */
    private formatDateForInput(date: Date): string {
        const d = new Date(date);
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
}
