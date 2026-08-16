import {
    ChangeDetectionStrategy,
    ChangeDetectorRef,
    Component,
    Input,
    OnInit,
    OnChanges,
    SimpleChanges,
    inject
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { RunView } from '@memberjunction/core';
import {
    GraphViewComponent,
    type GraphNode,
    type GraphEdge,
    type HopExpandedEventArgs,
    type NodeSelectedEventArgs
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
                    [SelectedNodeId]="FocalNodeID"
                    [LayoutMode]="'force'"
                    (HopExpanded)="OnHopExpanded($event)"
                    (NodeSelected)="OnNodeSelected($event)">
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

    public Nodes: GraphNode[] = [];
    public Edges: GraphEdge[] = [];
    public FocalNodeID?: string;
    public IsLoading = false;

    public ngOnInit(): void {
        this.LoadGraphData();
    }

    public ngOnChanges(changes: SimpleChanges): void {
        if (changes['PersonID'] || changes['OrganizationID']) {
            this.LoadGraphData();
        }
    }

    public async LoadGraphData(): Promise<void> {
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
                OrderBy: '__mj_CreatedAt DESC',
                MaxRows: 60,
                ResultType: 'simple'
            });

            if (result.Success && result.Results) {
                this.BuildGraphFromRelationships(result.Results);
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

        // Ensure focal node exists if specified
        if (this.PersonID && !nodeMap.has(this.FocalNodeID!)) {
            nodeMap.set(this.FocalNodeID!, {
                ID: this.FocalNodeID!,
                Label: 'Current Person',
                Category: 'person',
                Radius: 30,
                HopDistance: 0,
                Data: { EntityName: COMMON_ENTITIES.Person, ID: this.PersonID }
            });
        } else if (this.OrganizationID && !nodeMap.has(this.FocalNodeID!)) {
            nodeMap.set(this.FocalNodeID!, {
                ID: this.FocalNodeID!,
                Label: 'Current Organization',
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
}
