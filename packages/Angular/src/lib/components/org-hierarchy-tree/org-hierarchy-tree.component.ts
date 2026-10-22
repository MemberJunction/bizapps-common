import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey, RunView } from '@memberjunction/core';
import { FormNavigationEvent, RecordNavigationEvent } from '@memberjunction/ng-base-forms';
import { UserInfoEngine } from '@memberjunction/core-entities';
import { HierarchyTreeComponent, HierarchyTreeConfig } from '@memberjunction/ng-hierarchy-tree';
import { mjBizAppsCommonOrganizationEntity } from '@mj-biz-apps/common-entities';

/**
 * Represents a single node in the organization hierarchy tree outline.
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
    /** Child organization nodes. */
    Children: OrgTreeNode[];
}

/**
 * Tree-view component that renders the parent/current/child org hierarchy.
 *
 * Supports both an interactive **Visual Org Chart Canvas** powered by `@memberjunction/ng-hierarchy-tree`
 * and a compact **Outline List** with segmented switcher and UserInfoEngine preference persistence.
 */
@Component({
    standalone: true,
    imports: [CommonModule, HierarchyTreeComponent],
    selector: 'bizapps-org-hierarchy-tree',
    templateUrl: './org-hierarchy-tree.component.html',
    styleUrls: ['./org-hierarchy-tree.component.css']
})
export class OrgHierarchyTreeComponent implements OnInit {
    private cdr = inject(ChangeDetectorRef);

    private _organizationID = '';

    /** Active view mode ('chart' for visual canvas, 'outline' for compact list) */
    public ViewMode: 'chart' | 'outline' = 'chart';

    @Input()
    set OrganizationID(value: string) {
        const prev = this._organizationID;
        this._organizationID = value;
        if (value && value !== prev) {
            this.loadHierarchy();
        }
    }
    get OrganizationID(): string { return this._organizationID; }

    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    public ParentNode: OrgTreeNode | null = null;
    public CurrentNode: OrgTreeNode | null = null;
    public ChildNodes: OrgTreeNode[] = [];
    public Loading = false;
    public TreeRoot: OrgTreeNode | null = null;

    public ngOnInit(): void {
        this.loadViewPreference();
    }

    private loadViewPreference(): void {
        const pref = UserInfoEngine.Instance.GetSetting('mj.orgHierarchy.viewMode');
        if (pref === 'outline' || pref === 'chart') {
            this.ViewMode = pref;
        }
    }

    public SetViewMode(mode: 'chart' | 'outline'): void {
        this.ViewMode = mode;
        UserInfoEngine.Instance.SetSettingDebounced('mj.orgHierarchy.viewMode', mode);
        this.cdr.detectChanges();
    }

    public get treeConfig(): HierarchyTreeConfig {
        return {
            EntityName: 'MJ_BizApps_Common: Organizations',
            ParentField: 'ParentID',
            SubtitleField: 'OrganizationType',
            DefaultIcon: 'fa-solid fa-building',
            DefaultColor: '#38bdf8',
            FocusRecordID: this._organizationID || undefined,
            Height: '440px',
            ShowSearch: true,
            ShowToolbar: true
        };
    }

    private async loadHierarchy(): Promise<void> {
        this.Loading = true;
        this.ParentNode = null;
        this.CurrentNode = null;
        this.ChildNodes = [];
        this.TreeRoot = null;
        this.cdr.detectChanges();

        try {
            const rv = new RunView();

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

            const parentID = currentOrg.ParentID;
            const batchViews = this.buildBatchQueries(parentID);

            if (batchViews.length > 0) {
                const results = await rv.RunViews(batchViews);
                this.processBatchResults(results, parentID);
            }
        } catch (err) {
            console.error('OrgHierarchyTree: Error loading hierarchy', err);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
    }

    private buildBatchQueries(parentID: string | null): Parameters<RunView['RunViews']>[0] {
        const queries: Parameters<RunView['RunViews']>[0] = [];

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
            OrderBy: 'Name ASC',
            ResultType: 'entity_object'
        });

        return queries;
    }

    private processBatchResults(
        results: Awaited<ReturnType<RunView['RunViews']>>,
        parentID: string | null
    ): void {
        let resultIndex = 0;

        if (parentID && results[resultIndex]?.Success) {
            const parentOrgs = results[resultIndex].Results as mjBizAppsCommonOrganizationEntity[];
            if (parentOrgs.length > 0) {
                this.ParentNode = this.buildTreeNode(parentOrgs[0], false);
            }
            resultIndex++;
        }

        if (results[resultIndex]?.Success) {
            const childOrgs = results[resultIndex].Results as mjBizAppsCommonOrganizationEntity[];
            this.ChildNodes = childOrgs.map(org => this.buildTreeNode(org, false));
        }
    }

    private buildTreeNode(org: mjBizAppsCommonOrganizationEntity, isCurrent: boolean): OrgTreeNode {
        return {
            ID: org.ID,
            Name: org.Name,
            OrganizationType: org.OrganizationType || '',
            IsCurrent: isCurrent,
            Children: []
        };
    }

    public OnNavigateToOrg(node: OrgTreeNode | null, event: MouseEvent): void {
        if (!node) return;
        event.stopPropagation();

        const navEvent: RecordNavigationEvent = {
            Kind: 'record',
            EntityName: 'MJ_BizApps_Common: Organizations',
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', node.ID),
            OpenInNewTab: event.ctrlKey || event.metaKey
        };
        this.Navigate.emit(navEvent);
    }
}
