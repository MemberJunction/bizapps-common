import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey, RunView } from '@memberjunction/core';
import { FormNavigationEvent, RecordNavigationEvent } from '@memberjunction/ng-base-forms';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';

/**
 * Represents a single node in the organization hierarchy tree.
 * Each node holds basic display information and a flag indicating
 * whether it is the currently-viewed organization.
 */
export interface OrgTreeNode {
    /** The unique identifier of the organization record. */
    ID: string;
    /** The display name of the organization. */
    Name: string;
    /** The organization type label (e.g. "Corporation", "Non-Profit"). */
    OrganizationType: string;
    /** Whether this node represents the currently-viewed organization. */
    IsCurrent: boolean;
    /** Child organization nodes. Currently used for structural completeness. */
    Children: OrgTreeNode[];
}

/**
 * Tree-view component that renders the parent/current/child org hierarchy.
 *
 * Self-loads its data from the MemberJunction entity system when `OrganizationID`
 * is set. Displays the parent organization (if any), the current organization
 * highlighted, and all direct child organizations. Clicking a parent or child
 * node emits a navigation event.
 *
 * Indentation levels are controlled by CSS classes rather than nested DOM
 * elements, which works cleanly with Angular's `@if`/`@for` block syntax.
 *
 * @example
 * ```html
 * <bizapps-org-hierarchy-tree
 *     [OrganizationID]="orgRecord.ID"
 *     (Navigate)="onNavigate($event)">
 * </bizapps-org-hierarchy-tree>
 * ```
 */
@Component({
    standalone: true,
    imports: [CommonModule],
    selector: 'bizapps-org-hierarchy-tree',
    templateUrl: './org-hierarchy-tree.component.html',
    styleUrls: ['./org-hierarchy-tree.component.css']
})
export class OrgHierarchyTreeComponent {
    /** Angular change-detection reference, injected for manual triggering after async ops. */
    private cdr = inject(ChangeDetectorRef);

    /** Backing field for the OrganizationID input property. */
    private _organizationID = '';

    /**
     * The ID of the current organization whose hierarchy should be displayed.
     * Setting this value triggers an asynchronous data reload of parent and child orgs.
     */
    @Input()
    set OrganizationID(value: string) {
        const prev = this._organizationID;
        this._organizationID = value;
        if (value && value !== prev) {
            this.loadHierarchy();
        }
    }
    /** Returns the current organization ID. */
    get OrganizationID(): string { return this._organizationID; }

    /**
     * Emitted when the user clicks a parent or child organization node.
     * The event payload is a {@link RecordNavigationEvent} targeting the clicked org record.
     */
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    /**
     * The parent organization tree node, or `null` if the current org has no parent.
     */
    ParentNode: OrgTreeNode | null = null;

    /**
     * The tree node representing the currently-viewed organization.
     */
    CurrentNode: OrgTreeNode | null = null;

    /**
     * Array of direct child organization tree nodes.
     */
    ChildNodes: OrgTreeNode[] = [];

    /**
     * Whether the component is currently loading hierarchy data.
     */
    Loading = false;

    /**
     * The root tree node (set to CurrentNode after loading). Used in the template
     * to determine whether the hierarchy has been loaded at all.
     */
    TreeRoot: OrgTreeNode | null = null;

    /**
     * Loads the organization hierarchy: current org, optional parent, and children.
     *
     * Uses RunView to batch-query the parent (if ParentID exists) and all direct
     * children (where ParentID matches the current org). Builds OrgTreeNode
     * instances from the loaded entity objects.
     */
    private async loadHierarchy(): Promise<void> {
        this.Loading = true;
        this.ParentNode = null;
        this.CurrentNode = null;
        this.ChildNodes = [];
        this.TreeRoot = null;
        this.cdr.detectChanges();

        try {
            const rv = new RunView();

            // First, load the current organization
            const currentResult = await rv.RunView<mjBizAppsCommonOrganizationEntity>({
                EntityName: 'MJ_BizApps_Common: Organizations',
                ExtraFilter: `ID='${this._organizationID}'`,
                ResultType: 'entity_object'
            });

            if (!currentResult.Success || currentResult.Results.length === 0) {
                return;
            }

            const currentOrg = currentResult.Results[0];
            this.CurrentNode = this.buildTreeNode(currentOrg, true);
            this.TreeRoot = this.CurrentNode;

            // Load parent and children in parallel
            const parentID = currentOrg.ParentID;
            const batchViews = this.buildBatchQueries(parentID);

            if (batchViews.length > 0) {
                const batchResults = await rv.RunViews(batchViews);
                this.processBatchResults(batchResults, parentID);
            }
        } catch (err) {
            console.error('OrgHierarchyTree: Error loading hierarchy', err);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
    }

    /**
     * Builds the array of RunView parameter objects for batch loading.
     * Includes a parent org query (if parentID exists) and a children query.
     *
     * @param parentID - The parent organization ID, or null if none
     * @returns Array of RunView parameter objects for batch execution
     */
    private buildBatchQueries(parentID: string | null): { EntityName: string; ExtraFilter: string; ResultType: 'entity_object' }[] {
        const queries: { EntityName: string; ExtraFilter: string; ResultType: 'entity_object' }[] = [];

        if (parentID) {
            queries.push({
                EntityName: 'MJ_BizApps_Common: Organizations',
                ExtraFilter: `ID='${parentID}'`,
                ResultType: 'entity_object'
            });
        }

        queries.push({
            EntityName: 'MJ_BizApps_Common: Organizations',
            ExtraFilter: `ParentID='${this._organizationID}'`,
            ResultType: 'entity_object'
        });

        return queries;
    }

    /**
     * Processes the batch RunView results into parent and child tree nodes.
     *
     * @param batchResults - The results array from RunViews
     * @param parentID - The parent organization ID, used to determine result indexing
     */
    private processBatchResults(batchResults: { Success: boolean; Results: mjBizAppsCommonOrganizationEntity[] }[], parentID: string | null): void {
        let childResultIndex = 0;

        if (parentID && batchResults.length > 0) {
            const parentResult = batchResults[0];
            if (parentResult.Success && parentResult.Results.length > 0) {
                this.ParentNode = this.buildTreeNode(parentResult.Results[0], false);
            }
            childResultIndex = 1;
        }

        if (batchResults.length > childResultIndex) {
            const childResult = batchResults[childResultIndex];
            if (childResult.Success) {
                this.ChildNodes = childResult.Results.map(org => this.buildTreeNode(org, false));
            }
        }
    }

    /**
     * Constructs an OrgTreeNode from a loaded organization entity object.
     *
     * @param org - The organization entity instance
     * @param isCurrent - Whether this node represents the currently-viewed org
     * @returns A new OrgTreeNode populated from the entity fields
     */
    private buildTreeNode(org: mjBizAppsCommonOrganizationEntity, isCurrent: boolean): OrgTreeNode {
        return {
            ID: org.ID,
            Name: org.Name,
            OrganizationType: org.OrganizationType || '',
            IsCurrent: isCurrent,
            Children: []
        };
    }

    /**
     * Handles click on a tree node (parent or child) and emits a navigation event.
     *
     * @param node - The OrgTreeNode that was clicked
     * @param event - The mouse event, used to detect ctrl/meta key for new-tab behavior
     */
    OnNavigateToOrg(node: OrgTreeNode, event: MouseEvent): void {
        if (node.IsCurrent) {
            return;
        }

        const navEvent: RecordNavigationEvent = {
            Kind: 'record',
            EntityName: 'MJ_BizApps_Common: Organizations',
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', node.ID),
            OpenInNewTab: event.ctrlKey || event.metaKey
        };
        this.Navigate.emit(navEvent);
    }
}
