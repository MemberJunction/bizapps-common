import { Component, Input, Output, EventEmitter, inject, ChangeDetectorRef, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey, Metadata, RunView } from '@memberjunction/core';
import { BaseFormsModule, FormNavigationEvent, RecordNavigationEvent } from '@memberjunction/ng-base-forms';
import { UserInfoEngine } from '@memberjunction/core-entities';
import { HierarchyTreeComponent, HierarchyTreeConfig } from '@memberjunction/ng-hierarchy-tree';
import { CommonEngine, type CommonOrganizationSummary } from '@mj-biz-apps/common-entities';
import { EscapeFilterValue } from '../../data/directory-stats';

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
    imports: [CommonModule, BaseFormsModule, HierarchyTreeComponent],
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
            const rv = RunView.FromMetadataProvider(Metadata.Provider);
            const escapedOrgID = EscapeFilterValue(this._organizationID);
            const hierarchyFields = ['ID', 'Name', 'OrganizationType', 'ParentID'];

            // Batch current organization and its direct children in a single RunViews round trip
            const [currentResult, childrenResult] = await rv.RunViews([
                {
                    EntityName: 'MJ_BizApps_Common: Organizations',
                    ExtraFilter: `ID='${escapedOrgID}'`,
                    Fields: hierarchyFields,
                    MaxRows: 1,
                    ResultType: 'simple'
                },
                {
                    EntityName: 'MJ_BizApps_Common: Organizations',
                    ExtraFilter: `ParentID='${escapedOrgID}'`,
                    Fields: hierarchyFields,
                    OrderBy: 'Name ASC',
                    ResultType: 'simple'
                }
            ]);

            if (!currentResult?.Success || currentResult.Results.length === 0) {
                return;
            }

            const currentOrg = currentResult.Results[0] as Pick<CommonOrganizationSummary, 'ID' | 'Name' | 'OrganizationType' | 'ParentID'>;
            this.CurrentNode = this.buildTreeNode(currentOrg, true);
            this.TreeRoot = this.CurrentNode;

            if (childrenResult?.Success) {
                const childOrgs = childrenResult.Results as Array<Pick<CommonOrganizationSummary, 'ID' | 'Name' | 'OrganizationType' | 'ParentID'>>;
                this.ChildNodes = childOrgs.map(org => this.buildTreeNode(org, false));
            }

            if (currentOrg.ParentID) {
                const parentOrg = await CommonEngine.Instance.GetOrganizationByID(currentOrg.ParentID, {
                    provider: Metadata.Provider,
                    contextUser: Metadata.Provider.CurrentUser,
                });
                if (parentOrg) {
                    this.ParentNode = this.buildTreeNode(parentOrg, false);
                }
            }
        } catch (err) {
            console.error('OrgHierarchyTree: Error loading hierarchy', err);
        } finally {
            this.Loading = false;
            this.cdr.detectChanges();
        }
    }

    private buildTreeNode(
        org: Pick<CommonOrganizationSummary, 'ID' | 'Name' | 'OrganizationType'>,
        isCurrent: boolean
    ): OrgTreeNode {
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
