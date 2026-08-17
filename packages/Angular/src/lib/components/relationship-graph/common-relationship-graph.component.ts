import {
    ChangeDetectionStrategy,
    ChangeDetectorRef,
    Component,
    Input,
    Output,
    EventEmitter,
    OnInit,
    OnChanges,
    SimpleChanges,
    inject
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { RunView, CompositeKey } from '@memberjunction/core';
import { UserInfoEngine } from '@memberjunction/core-entities';
import type { FormNavigationEvent } from '@memberjunction/ng-base-forms';
import {
    GraphViewComponent,
    type GraphNode,
    type GraphEdge,
    type GraphLayoutMode,
    type GraphCategoryConfig,
    type HopExpandedEventArgs,
    type NodeSelectedEventArgs,
    type NodeNavigatedEventArgs,
    type LayoutChangedEventArgs,
    type ViewportTransformEventArgs
} from '@memberjunction/ng-graph-view';
import { COMMON_ENTITIES } from '../../data/entity-names';
import type { DirectoryRelationshipRow } from '../../data/directory-types';

/**
 * `<bizapps-relationship-graph>` — Entity-aware relationship graph viewer for BizApps Common.
 *
 * Visualizes interconnections between People, Organizations, and linked roles.
 * Performs smart, bounded queries to load local neighborhoods without overwhelming the database.
 */
@Component({
    selector: 'bizapps-relationship-graph',
    standalone: true,
    imports: [CommonModule, GraphViewComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <div class="bizapps-rel-graph-container" [style.height]="Height">
            @if (IsLoading) {
                <div class="bizapps-rel-graph-loading">
                    <i class="fa-solid fa-spinner fa-spin" style="font-size: 24px; color: var(--mj-brand-primary, #38bdf8);"></i>
                    <span>Loading relationship graph...</span>
                </div>
            } @else if (Nodes.length === 0) {
                <div class="bizapps-rel-graph-empty">
                    <i class="fa-solid fa-circle-nodes" style="font-size: 32px; color: var(--mj-text-muted, #64748b);"></i>
                    <p>No mapped relationships found for this record.</p>
                </div>
            } @else {
                <mj-graph-view
                    [Nodes]="Nodes"
                    [Edges]="Edges"
                    [Categories]="GraphCategories"
                    [FocalNodeId]="FocalNodeID"
                    [LayoutMode]="LayoutMode"
                    (LayoutChanged)="OnLayoutChanged($event)"
                    (ViewportTransform)="OnViewportTransform($event)"
                    (HopExpanded)="OnHopExpanded($event)"
                    (NodeSelected)="OnNodeSelected($event)"
                    (NodeNavigated)="OnNodeNavigated($event)">
                </mj-graph-view>
            }
        </div>
    `,
    styles: [`
        :host {
            display: block;
            width: 100%;
            height: 100%;
        }

        .bizapps-rel-graph-container {
            width: 100%;
            height: 100%;
            min-height: 480px;
            position: relative;
        }

        .bizapps-rel-graph-loading,
        .bizapps-rel-graph-empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 12px;
            height: 100%;
            min-height: 360px;
            background: var(--mj-bg-surface-sunken, #0b1220);
            border-radius: 12px;
            border: 1px solid var(--mj-border-default, #223254);
            color: var(--mj-text-secondary, #94a3b8);
            font-size: 13px;
        }
    `]
})
export class CommonRelationshipGraphComponent implements OnInit, OnChanges {
    private cdr = inject(ChangeDetectorRef);

    @Input() public PersonID?: string;
    @Input() public OrganizationID?: string;
    @Input() public Height = '100%';

    @Output() public Navigate = new EventEmitter<FormNavigationEvent>();

    public Nodes: GraphNode[] = [];
    public Edges: GraphEdge[] = [];
    public FocalNodeID?: string;
    public LayoutMode: GraphLayoutMode = 'force';
    public IsLoading = false;

    public readonly GraphCategories: GraphCategoryConfig[] = [
        { Category: 'person', Label: 'Person', Color: '#10b981', IconClass: 'fa-solid fa-user' },
        { Category: 'organization', Label: 'Organization', Color: '#38bdf8', IconClass: 'fa-solid fa-building' }
    ];

    private static graphCache = new Map<string, { nodes: GraphNode[]; edges: GraphEdge[] }>();

    private get PrefsKey(): string {
        return this.PersonID
            ? 'mj.bizapps.common.person.graphPrefs'
            : 'mj.bizapps.common.organization.graphPrefs';
    }

    public ngOnInit(): void {
        this.LoadPrefs();
        this.LoadGraphData();
    }

    private LoadPrefs(): void {
        const raw = UserInfoEngine.Instance.GetSetting(this.PrefsKey);
        if (raw) {
            try {
                const parsed = JSON.parse(raw);
                if (parsed.LayoutMode === 'force' || parsed.LayoutMode === 'circular') {
                    this.LayoutMode = parsed.LayoutMode;
                }
            } catch (e) {
                // Keep default
            }
        }
    }

    public OnLayoutChanged(event: LayoutChangedEventArgs): void {
        this.LayoutMode = event.NewMode;
        this.SavePrefs();
    }

    public OnViewportTransform(event: ViewportTransformEventArgs): void {
        this.SavePrefs(event.Transform);
    }

    private SavePrefs(transform?: { Scale: number; PanX: number; PanY: number }): void {
        const prefs = {
            LayoutMode: this.LayoutMode,
            ...(transform ? { Scale: transform.Scale, PanX: transform.PanX, PanY: transform.PanY } : {})
        };
        UserInfoEngine.Instance.SetSettingDebounced(this.PrefsKey, JSON.stringify(prefs));
    }

    public ngOnChanges(changes: SimpleChanges): void {
        if (changes['PersonID'] || changes['OrganizationID']) {
            this.LoadGraphData();
        }
    }

    public async LoadGraphData(): Promise<void> {
        const cacheKey = this.PersonID ? `person:${this.PersonID}` : (this.OrganizationID ? `org:${this.OrganizationID}` : '');
        if (cacheKey && CommonRelationshipGraphComponent.graphCache.has(cacheKey)) {
            const cached = CommonRelationshipGraphComponent.graphCache.get(cacheKey)!;
            this.Nodes = [...cached.nodes];
            this.Edges = [...cached.edges];
            this.FocalNodeID = cacheKey;
            this.cdr.markForCheck();
            return;
        }

        this.IsLoading = true;
        this.cdr.markForCheck();

        try {
            const rv = new RunView();
            let filter = '';

            if (this.PersonID) {
                this.FocalNodeID = `person:${this.PersonID}`;
                filter = `FromPersonID = '${this.PersonID}' OR ToPersonID = '${this.PersonID}'`;
            } else if (this.OrganizationID) {
                this.FocalNodeID = `org:${this.OrganizationID}`;
                filter = `FromOrganizationID = '${this.OrganizationID}' OR ToOrganizationID = '${this.OrganizationID}'`;
            }

            const result = await rv.RunView<DirectoryRelationshipRow>({
                EntityName: COMMON_ENTITIES.Relationship,
                ExtraFilter: filter || undefined,
                Fields: ['ID', 'FromPersonID', 'ToPersonID', 'FromOrganizationID', 'ToOrganizationID', 'FromPerson', 'ToPerson', 'FromOrganization', 'ToOrganization', 'RelationshipType', 'Title'],
                OrderBy: '__mj_CreatedAt DESC',
                MaxRows: 60,
                ResultType: 'simple'
            });

            if (result.Success && result.Results) {
                this.BuildGraphFromRelationships(result.Results);
                if (cacheKey) {
                    CommonRelationshipGraphComponent.graphCache.set(cacheKey, {
                        nodes: [...this.Nodes],
                        edges: [...this.Edges]
                    });
                }
            }
        } catch (e) {
            console.error('Failed to load relationship graph:', e);
        } finally {
            this.IsLoading = false;
            this.cdr.markForCheck();
        }
    }

    private BuildGraphFromRelationships(rows: DirectoryRelationshipRow[]): void {
        const nodeMap = new Map<string, GraphNode>();
        const edges: GraphEdge[] = [];

        // Determine focal label from rows if available
        let focalLabel = this.PersonID ? 'Person' : 'Organization';
        if (this.PersonID) {
            const match = rows.find(r => r.FromPersonID === this.PersonID || r.ToPersonID === this.PersonID);
            if (match) {
                focalLabel = (match.FromPersonID === this.PersonID ? match.FromPerson : match.ToPerson) || 'Person';
            }
        } else if (this.OrganizationID) {
            const match = rows.find(r => r.FromOrganizationID === this.OrganizationID || r.ToOrganizationID === this.OrganizationID);
            if (match) {
                focalLabel = (match.FromOrganizationID === this.OrganizationID ? match.FromOrganization : match.ToOrganization) || 'Organization';
            }
        }

        // Ensure focal node exists if specified
        if (this.PersonID && !nodeMap.has(this.FocalNodeID!)) {
            nodeMap.set(this.FocalNodeID!, {
                ID: this.FocalNodeID!,
                Label: focalLabel,
                Category: 'person',
                Radius: 30,
                HopDistance: 0,
                Data: { EntityName: COMMON_ENTITIES.Person, ID: this.PersonID }
            });
        } else if (this.OrganizationID && !nodeMap.has(this.FocalNodeID!)) {
            nodeMap.set(this.FocalNodeID!, {
                ID: this.FocalNodeID!,
                Label: focalLabel,
                Category: 'organization',
                Radius: 30,
                HopDistance: 0,
                Data: { EntityName: COMMON_ENTITIES.Organization, ID: this.OrganizationID }
            });
        }

        for (const r of rows) {
            let sourceId = '';
            let targetId = '';

            // From Entity
            if (r.FromPersonID) {
                sourceId = `person:${r.FromPersonID}`;
                if (!nodeMap.has(sourceId)) {
                    nodeMap.set(sourceId, {
                        ID: sourceId,
                        Label: r.FromPerson || 'Person',
                        Category: 'person',
                        Data: { EntityName: COMMON_ENTITIES.Person, ID: r.FromPersonID }
                    });
                }
            } else if (r.FromOrganizationID) {
                sourceId = `org:${r.FromOrganizationID}`;
                if (!nodeMap.has(sourceId)) {
                    nodeMap.set(sourceId, {
                        ID: sourceId,
                        Label: r.FromOrganization || 'Organization',
                        Category: 'organization',
                        Data: { EntityName: COMMON_ENTITIES.Organization, ID: r.FromOrganizationID }
                    });
                }
            }

            // To Entity
            if (r.ToPersonID) {
                targetId = `person:${r.ToPersonID}`;
                if (!nodeMap.has(targetId)) {
                    nodeMap.set(targetId, {
                        ID: targetId,
                        Label: r.ToPerson || 'Person',
                        Category: 'person',
                        Data: { EntityName: COMMON_ENTITIES.Person, ID: r.ToPersonID }
                    });
                }
            } else if (r.ToOrganizationID) {
                targetId = `org:${r.ToOrganizationID}`;
                if (!nodeMap.has(targetId)) {
                    nodeMap.set(targetId, {
                        ID: targetId,
                        Label: r.ToOrganization || 'Organization',
                        Category: 'organization',
                        Data: { EntityName: COMMON_ENTITIES.Organization, ID: r.ToOrganizationID }
                    });
                }
            }

            if (sourceId && targetId) {
                edges.push({
                    ID: r.ID,
                    SourceID: sourceId,
                    TargetID: targetId,
                    Label: r.RelationshipType || r.Title || 'Related',
                    Direction: 'directed',
                    Data: { EntityName: COMMON_ENTITIES.Relationship, ID: r.ID }
                });
            }
        }

        this.Nodes = Array.from(nodeMap.values());
        this.Edges = edges;
    }

    public async OnHopExpanded(event: HopExpandedEventArgs): Promise<void> {
        const rawId = event.Node.ID.split(':')[1];
        const isPerson = event.Node.Category === 'person';
        if (!rawId) return;

        try {
            const rv = new RunView();
            const filter = isPerson
                ? `FromPersonID = '${rawId}' OR ToPersonID = '${rawId}'`
                : `FromOrganizationID = '${rawId}' OR ToOrganizationID = '${rawId}'`;

            const result = await rv.RunView<DirectoryRelationshipRow>({
                EntityName: COMMON_ENTITIES.Relationship,
                ExtraFilter: filter,
                OrderBy: '__mj_CreatedAt DESC',
                MaxRows: 30,
                ResultType: 'simple'
            });

            if (result.Success && result.Results) {
                this.AppendIncrementalRelationships(result.Results, event.CurrentDepth);
            }
        } catch (e) {
            console.error('Failed to expand graph hops:', e);
        }
    }

    private AppendIncrementalRelationships(rows: DirectoryRelationshipRow[], depth: number): void {
        const nodeMap = new Map<string, GraphNode>(this.Nodes.map(n => [n.ID, n]));
        const edgeMap = new Map<string, GraphEdge>(this.Edges.map(e => [e.ID, e]));

        for (const r of rows) {
            let sourceId = '';
            let targetId = '';

            if (r.FromPersonID) {
                sourceId = `person:${r.FromPersonID}`;
                if (!nodeMap.has(sourceId)) {
                    nodeMap.set(sourceId, {
                        ID: sourceId,
                        Label: r.FromPerson || 'Person',
                        Category: 'person',
                        HopDistance: depth,
                        Data: { EntityName: COMMON_ENTITIES.Person, ID: r.FromPersonID }
                    });
                }
            } else if (r.FromOrganizationID) {
                sourceId = `org:${r.FromOrganizationID}`;
                if (!nodeMap.has(sourceId)) {
                    nodeMap.set(sourceId, {
                        ID: sourceId,
                        Label: r.FromOrganization || 'Organization',
                        Category: 'organization',
                        HopDistance: depth,
                        Data: { EntityName: COMMON_ENTITIES.Organization, ID: r.FromOrganizationID }
                    });
                }
            }

            if (r.ToPersonID) {
                targetId = `person:${r.ToPersonID}`;
                if (!nodeMap.has(targetId)) {
                    nodeMap.set(targetId, {
                        ID: targetId,
                        Label: r.ToPerson || 'Person',
                        Category: 'person',
                        HopDistance: depth,
                        Data: { EntityName: COMMON_ENTITIES.Person, ID: r.ToPersonID }
                    });
                }
            } else if (r.ToOrganizationID) {
                targetId = `org:${r.ToOrganizationID}`;
                if (!nodeMap.has(targetId)) {
                    nodeMap.set(targetId, {
                        ID: targetId,
                        Label: r.ToOrganization || 'Organization',
                        Category: 'organization',
                        HopDistance: depth,
                        Data: { EntityName: COMMON_ENTITIES.Organization, ID: r.ToOrganizationID }
                    });
                }
            }

            if (sourceId && targetId && !edgeMap.has(r.ID)) {
                edgeMap.set(r.ID, {
                    ID: r.ID,
                    SourceID: sourceId,
                    TargetID: targetId,
                    Label: r.RelationshipType || r.Title || 'Related',
                    Direction: 'directed',
                    Data: { EntityName: COMMON_ENTITIES.Relationship, ID: r.ID }
                });
            }
        }

        this.Nodes = Array.from(nodeMap.values());
        this.Edges = Array.from(edgeMap.values());
        this.cdr.markForCheck();
    }

    public OnNodeSelected(_event: NodeSelectedEventArgs): void {
        // Telemetry or UI hook if needed
    }

    public OnNodeNavigated(event: NodeNavigatedEventArgs): void {
        const entityName = event.EntityName || (event.Node?.Category === 'person' ? COMMON_ENTITIES.Person : COMMON_ENTITIES.Organization);
        const pk = CompositeKey.FromID(event.RecordID);
        this.Navigate.emit({
            Kind: 'record',
            EntityName: entityName,
            PrimaryKey: pk,
            OpenInNewTab: false
        });
    }
}
