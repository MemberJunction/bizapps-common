import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import type { EntityInfo } from '@memberjunction/core';
import type { MJUserViewEntityExtended } from '@memberjunction/core-entities';
import { NavigationService } from '@memberjunction/ng-shared';
import { EntityViewerModule, type RecordOpenedEvent } from '@memberjunction/ng-entity-viewer';
import { MJAlertComponent, MJButtonDirective, MJEmptyStateComponent } from '@memberjunction/ng-ui-components';
import { COMMON_ENTITIES } from '../data/entity-names';
import { LoadDirectorySnapshot } from '../data/directory-queries';
import { LoadLatestPeopleView, LoadLatestRelationshipsView } from '../data/directory-views';
import {
    ActiveOrganizations,
    ActivePeople,
    BuildAttentionItems,
    BuildDirectoryQueues,
    CountByDay,
    CountByLabel,
    LatestByCreated,
} from '../data/directory-stats';
import type {
    DirectoryAttentionItem,
    DirectoryBarRow,
    DirectoryDayBar,
    DirectoryOrganizationRow,
    DirectoryPersonRow,
    DirectoryQueue,
    DirectoryRelationshipRow,
} from '../data/directory-types';
import { OpenCommonRecord, OpenNewCommonRecord } from '../open-record';

/**
 * Directory home — is the party file complete, and what needs a person?
 *
 * Every figure is a cheap count over rows already loaded. No on-demand
 * aggregate. Queues sit above the trend because they are what someone acts on.
 */
@Component({
    selector: 'bizapps-common-dashboard-page',
    standalone: true,
    imports: [CommonModule, MJAlertComponent, MJButtonDirective, MJEmptyStateComponent, EntityViewerModule],
    template: `
        <div class="mjc-dash">
            <div class="mjc-hero">
                <div class="mjc-hero__identity">
                    <span class="mjc-hero__mark" aria-hidden="true">
                        <i class="fa-solid fa-address-book"></i>
                    </span>
                    <div>
                        <h1 class="mjc-hero__title">Directory</h1>
                        <p class="mjc-hero__sub">People, organizations, and the relationships between them.</p>
                    </div>
                </div>
                <div class="mjc-hero__actions">
                    <button mjButton variant="outline" size="sm" type="button" (click)="NewOrganization()">
                        <i class="fa-solid fa-building" aria-hidden="true"></i> New organization
                    </button>
                    <button mjButton variant="primary" size="sm" type="button" (click)="NewPerson()">
                        <i class="fa-solid fa-user-plus" aria-hidden="true"></i> New person
                    </button>
                </div>
            </div>

            @if (IsLoading) {
                <div class="mjc-muted">Loading the directory…</div>
            } @else {
                <div class="mjc-tiles">
                    <button type="button" class="mjc-tile" (click)="OpenPeople()">
                        <span class="mjc-tile__label"><i class="fa-solid fa-user" aria-hidden="true"></i> People</span>
                        <span class="mjc-tile__value">{{ ActivePeopleCount }}</span>
                        <span class="mjc-tile__detail">{{ PeopleDetail }}</span>
                    </button>
                    <button type="button" class="mjc-tile" (click)="OpenOrganizations()">
                        <span class="mjc-tile__label"><i class="fa-solid fa-building" aria-hidden="true"></i> Organizations</span>
                        <span class="mjc-tile__value">{{ ActiveOrganizationCount }}</span>
                        <span class="mjc-tile__detail">{{ OrganizationDetail }}</span>
                    </button>
                    <div class="mjc-tile">
                        <span class="mjc-tile__label"><i class="fa-solid fa-link" aria-hidden="true"></i> Relationships</span>
                        <span class="mjc-tile__value">{{ RelationshipCount }}</span>
                        <span class="mjc-tile__detail">Who reports to whom, who works where</span>
                    </div>
                    <div class="mjc-tile" [class.mjc-tile--alert]="GapCount > 0">
                        <span class="mjc-tile__label"><i class="fa-solid fa-clipboard-check" aria-hidden="true"></i> Gaps</span>
                        <span class="mjc-tile__value">{{ GapCount }}</span>
                        <span class="mjc-tile__detail">Missing email, org, type, or website</span>
                    </div>
                </div>

                <div class="mjc-split">
                    <section class="mjc-card">
                        <header class="mjc-card__head">
                            <i class="fa-solid fa-list-check" aria-hidden="true"></i>
                            <h2>Needs someone</h2>
                        </header>
                        <div class="mjc-card__body">
                            @for (queue of Queues; track queue.Label) {
                                <button type="button" class="mjc-queue" (click)="OpenPage(queue.PageId)">
                                    <span class="mjc-queue__icon" [attr.data-tone]="queue.Tone">
                                        <i [class]="queue.Icon" aria-hidden="true"></i>
                                    </span>
                                    <span class="mjc-queue__body">
                                        <span class="mjc-queue__label">{{ queue.Label }}</span>
                                        @if (queue.Note) {
                                            <span class="mjc-queue__note">{{ queue.Note }}</span>
                                        }
                                    </span>
                                    <b class="mjc-queue__count">{{ queue.Count }}</b>
                                    <i class="fa-solid fa-chevron-right mjc-queue__chev" aria-hidden="true"></i>
                                </button>
                            } @empty {
                                <mj-empty-state
                                    Icon="fa-solid fa-circle-check"
                                    Title="Nothing is waiting"
                                    Size="compact" />
                            }
                        </div>
                    </section>

                    <section class="mjc-card">
                        <header class="mjc-card__head">
                            <i class="fa-solid fa-chart-simple" aria-hidden="true"></i>
                            <h2>People added</h2>
                            <span class="mjc-card__meta">last 7 days</span>
                        </header>
                        <div class="mjc-card__body">
                            <div class="mjc-bars" role="img" [attr.aria-label]="'People added per day, last 7 days'">
                                @for (bar of PeoplePerDay; track bar.Label) {
                                    <div class="mjc-bars__col">
                                        <span class="mjc-bars__value">{{ bar.Value }}</span>
                                        <span class="mjc-bars__fill" [class.is-current]="bar.Current" [style.height.%]="barHeight(bar)"></span>
                                        <span class="mjc-bars__label">{{ bar.Label }}</span>
                                    </div>
                                }
                            </div>
                        </div>
                    </section>

                    <section class="mjc-card">
                        <header class="mjc-card__head">
                            <i class="fa-solid fa-layer-group" aria-hidden="true"></i>
                            <h2>Organization types</h2>
                        </header>
                        <div class="mjc-card__body">
                            @for (row of OrganizationTypeMix; track row.Label) {
                                <div class="mjc-mix">
                                    <span class="mjc-mix__label">{{ row.Label }}</span>
                                    <span class="mjc-mix__track">
                                        <span class="mjc-mix__fill" [style.width.%]="mixWidth(row)"></span>
                                    </span>
                                    <span class="mjc-mix__value">{{ row.Value }}</span>
                                </div>
                            } @empty {
                                <p class="mjc-muted">No organizations yet.</p>
                            }
                        </div>
                    </section>
                </div>

                <div class="mjc-split mjc-split--wide">
                    <section class="mjc-card">
                        <header class="mjc-card__head">
                            <i class="fa-solid fa-clock-rotate-left" aria-hidden="true"></i>
                            <h2>Latest people</h2>
                            <button type="button" class="mjc-link" (click)="OpenPeople()">All people →</button>
                        </header>
                        <div class="mjc-viewer-host">
                            @if (PersonEntity && LatestPeopleView) {
                                <mj-entity-viewer
                                    [Entity]="PersonEntity"
                                    [ViewEntity]="LatestPeopleView"
                                    [ShowRecycleBin]="false"
                                    (RecordOpened)="OnPersonOpened($event)">
                                </mj-entity-viewer>
                            } @else {
                                <p class="mjc-muted">No people yet.</p>
                            }
                        </div>
                    </section>

                    <section class="mjc-card">
                        <header class="mjc-card__head">
                            <i class="fa-solid fa-triangle-exclamation" aria-hidden="true"></i>
                            <h2>Worth a look</h2>
                        </header>
                        <div class="mjc-card__body">
                            @for (item of WorthALook; track item.RecordID) {
                                <mj-alert [Variant]="item.Tone" [Icon]="item.Icon" Role="note">
                                    <strong>{{ item.Headline }}</strong>
                                    {{ item.Detail }}
                                    <button type="button" class="mjc-link" (click)="OpenAttention(item)">Work it →</button>
                                </mj-alert>
                            } @empty {
                                <mj-empty-state
                                    Icon="fa-solid fa-circle-check"
                                    Title="Nothing is asking for attention"
                                    Size="compact" />
                            }
                        </div>
                    </section>
                </div>

                <section class="mjc-card">
                    <header class="mjc-card__head">
                        <i class="fa-solid fa-diagram-project" aria-hidden="true"></i>
                        <h2>Latest relationships</h2>
                    </header>
                    <div class="mjc-viewer-host">
                        @if (RelationshipEntity && LatestRelationshipsView) {
                            <mj-entity-viewer
                                [Entity]="RelationshipEntity"
                                [ViewEntity]="LatestRelationshipsView"
                                [ShowRecycleBin]="false"
                                (RecordOpened)="OnRelationshipOpened($event)">
                            </mj-entity-viewer>
                        } @else {
                            <p class="mjc-muted">No relationships yet.</p>
                        }
                    </div>
                </section>
            }
        </div>
    `,
    styles: [
        `
            :host {
                display: block;
                height: 100%;
                overflow: auto;
            }
            .mjc-dash {
                display: flex;
                flex-direction: column;
                gap: var(--mj-space-5);
                padding: var(--mj-space-6);
                box-sizing: border-box;
                min-width: 0;
            }
            .mjc-hero {
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: var(--mj-space-4);
                flex-wrap: wrap;
            }
            .mjc-hero__identity {
                display: flex;
                align-items: center;
                gap: var(--mj-space-3);
            }
            .mjc-hero__mark {
                width: 48px;
                height: 48px;
                border-radius: var(--mj-radius-md);
                background: var(--mj-brand-primary);
                color: var(--mj-text-inverse);
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 20px;
                flex-shrink: 0;
            }
            .mjc-hero__title {
                margin: 0;
                font-size: 1.25rem;
                font-weight: 700;
                color: var(--mj-text-primary);
            }
            .mjc-hero__sub {
                margin: 0;
                font-size: 0.8125rem;
                color: var(--mj-text-muted);
            }
            .mjc-hero__actions {
                display: flex;
                gap: var(--mj-space-2);
                flex-wrap: wrap;
            }
            .mjc-tiles {
                display: grid;
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: var(--mj-space-4);
            }
            .mjc-tile {
                display: flex;
                flex-direction: column;
                gap: var(--mj-space-1);
                align-items: flex-start;
                text-align: left;
                padding: var(--mj-space-4);
                background: var(--mj-bg-surface);
                border: 1px solid var(--mj-border-default);
                border-radius: var(--mj-radius-md);
                color: inherit;
                cursor: default;
            }
            button.mjc-tile {
                cursor: pointer;
            }
            button.mjc-tile:hover {
                border-color: var(--mj-brand-primary);
            }
            .mjc-tile--alert {
                border-color: var(--mj-status-warning-border);
                background: color-mix(in srgb, var(--mj-status-warning) 8%, var(--mj-bg-surface));
            }
            .mjc-tile__label {
                font-size: 0.75rem;
                color: var(--mj-text-secondary);
                display: flex;
                align-items: center;
                gap: var(--mj-space-2);
            }
            .mjc-tile__value {
                font-size: 1.75rem;
                font-weight: 700;
                color: var(--mj-text-primary);
                line-height: 1.1;
            }
            .mjc-tile__detail {
                font-size: 0.75rem;
                color: var(--mj-text-muted);
            }
            .mjc-split {
                display: grid;
                grid-template-columns: minmax(0, 1.3fr) minmax(0, 1fr) minmax(0, 1fr);
                gap: var(--mj-space-4);
            }
            .mjc-split--wide {
                grid-template-columns: minmax(0, 1.6fr) minmax(0, 1fr);
            }
            .mjc-card {
                background: var(--mj-bg-surface);
                border: 1px solid var(--mj-border-default);
                border-radius: var(--mj-radius-md);
                min-width: 0;
            }
            .mjc-card__head {
                display: flex;
                align-items: center;
                gap: var(--mj-space-2);
                padding: var(--mj-space-3) var(--mj-space-4);
                border-bottom: 1px solid var(--mj-border-subtle);
                color: var(--mj-text-secondary);
            }
            .mjc-card__head h2 {
                margin: 0;
                font-size: 0.9375rem;
                font-weight: 600;
                color: var(--mj-text-primary);
                flex: 1;
            }
            .mjc-card__meta {
                font-size: 0.75rem;
                color: var(--mj-text-muted);
            }
            .mjc-card__body {
                padding: var(--mj-space-4);
                display: flex;
                flex-direction: column;
                gap: var(--mj-space-3);
            }
            .mjc-queue {
                display: flex;
                align-items: center;
                gap: var(--mj-space-3);
                padding: var(--mj-space-2) 0;
                border: 0;
                border-bottom: 1px solid var(--mj-border-subtle);
                background: transparent;
                color: inherit;
                text-align: left;
                cursor: pointer;
                width: 100%;
            }
            .mjc-queue:last-child {
                border-bottom: 0;
            }
            .mjc-queue:hover .mjc-queue__label {
                color: var(--mj-brand-primary);
            }
            .mjc-queue__icon {
                width: 32px;
                height: 32px;
                border-radius: var(--mj-radius-md);
                display: flex;
                align-items: center;
                justify-content: center;
                flex: none;
                font-size: 13px;
                background: var(--mj-bg-surface-sunken);
                color: var(--mj-text-secondary);
            }
            .mjc-queue__icon[data-tone='warning'] {
                background: color-mix(in srgb, var(--mj-status-warning) 16%, var(--mj-bg-surface));
                color: var(--mj-status-warning-text);
            }
            .mjc-queue__icon[data-tone='info'] {
                background: color-mix(in srgb, var(--mj-status-info) 16%, var(--mj-bg-surface));
                color: var(--mj-status-info-text);
            }
            .mjc-queue__icon[data-tone='error'] {
                background: color-mix(in srgb, var(--mj-status-error) 16%, var(--mj-bg-surface));
                color: var(--mj-status-error-text);
            }
            .mjc-queue__body {
                flex: 1;
                min-width: 0;
            }
            .mjc-queue__label {
                display: block;
                font-weight: 600;
            }
            .mjc-queue__note {
                display: block;
                font-size: 0.75rem;
                color: var(--mj-text-muted);
            }
            .mjc-queue__count {
                font-size: 1rem;
            }
            .mjc-queue__chev {
                color: var(--mj-text-muted);
                font-size: 0.7rem;
            }
            .mjc-bars {
                display: flex;
                align-items: flex-end;
                gap: var(--mj-space-2);
                height: 140px;
            }
            .mjc-bars__col {
                flex: 1;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: flex-end;
                gap: 4px;
                height: 100%;
            }
            .mjc-bars__fill {
                width: 100%;
                min-height: 4px;
                border-radius: var(--mj-radius-sm) var(--mj-radius-sm) 0 0;
                background: color-mix(in srgb, var(--mj-brand-primary) 35%, var(--mj-bg-surface-sunken));
            }
            .mjc-bars__fill.is-current {
                background: var(--mj-brand-primary);
            }
            .mjc-bars__value,
            .mjc-bars__label {
                font-size: 0.7rem;
                color: var(--mj-text-muted);
            }
            .mjc-mix {
                display: grid;
                grid-template-columns: minmax(0, 1.2fr) minmax(0, 2fr) auto;
                gap: var(--mj-space-2);
                align-items: center;
            }
            .mjc-mix__label {
                font-size: 0.8125rem;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
            }
            .mjc-mix__track {
                height: 8px;
                background: var(--mj-bg-surface-sunken);
                border-radius: var(--mj-radius-pill, 999px);
                overflow: hidden;
            }
            .mjc-mix__fill {
                display: block;
                height: 100%;
                background: var(--mj-brand-primary);
            }
            .mjc-mix__value {
                font-size: 0.8125rem;
                font-weight: 600;
            }
            .mjc-table-wrap {
                overflow: auto;
            }
            .mjc-table {
                width: 100%;
                border-collapse: collapse;
                font-size: 0.875rem;
            }
            .mjc-table th,
            .mjc-table td {
                padding: var(--mj-space-2) var(--mj-space-4);
                text-align: left;
                border-bottom: 1px solid var(--mj-border-subtle);
            }
            .mjc-table th {
                font-size: 0.7rem;
                text-transform: uppercase;
                letter-spacing: 0.04em;
                color: var(--mj-text-muted);
                font-weight: 600;
            }
            .mjc-table tbody tr {
                cursor: pointer;
            }
            .mjc-table tbody tr:hover {
                background: var(--mj-bg-surface-hover);
            }
            .mjc-link {
                border: 0;
                background: transparent;
                color: var(--mj-text-link);
                cursor: pointer;
                font-size: 0.8125rem;
                padding: 0;
            }
            .mjc-muted {
                color: var(--mj-text-muted);
                font-size: 0.8125rem;
            }
            .mjc-viewer-host {
                height: 280px;
                min-height: 220px;
            }
            @media (max-width: 1200px) {
                .mjc-tiles {
                    grid-template-columns: repeat(2, minmax(0, 1fr));
                }
                .mjc-split {
                    grid-template-columns: repeat(2, minmax(0, 1fr));
                }
            }
            @media (max-width: 760px) {
                .mjc-dash {
                    padding: var(--mj-space-4);
                }
                .mjc-tiles,
                .mjc-split,
                .mjc-split--wide {
                    grid-template-columns: 1fr;
                }
            }
        `,
    ],
})
export class CommonDashboardPageComponent implements OnInit {
    private readonly cdr = inject(ChangeDetectorRef);
    private readonly navigation = inject(NavigationService, { optional: true });

    public IsLoading = true;
    public Queues: DirectoryQueue[] = [];
    public PeoplePerDay: DirectoryDayBar[] = [];
    public OrganizationTypeMix: DirectoryBarRow[] = [];
    public LatestPeople: DirectoryPersonRow[] = [];
    public LatestRelationships: DirectoryRelationshipRow[] = [];
    public PersonEntity: EntityInfo | null = null;
    public RelationshipEntity: EntityInfo | null = null;
    public LatestPeopleView: MJUserViewEntityExtended | null = null;
    public LatestRelationshipsView: MJUserViewEntityExtended | null = null;
    public WorthALook: DirectoryAttentionItem[] = [];
    public ActivePeopleCount = 0;
    public ActiveOrganizationCount = 0;
    public RelationshipCount = 0;
    public GapCount = 0;
    public PeopleDetail = '';
    public OrganizationDetail = '';

    public async ngOnInit(): Promise<void> {
        const [snapshot, peopleView, relView] = await Promise.all([
            LoadDirectorySnapshot(),
            LoadLatestPeopleView(),
            LoadLatestRelationshipsView(),
        ]);
        this.applySnapshot(snapshot.People, snapshot.Organizations, snapshot.Relationships);
        this.PersonEntity = peopleView.entity;
        this.LatestPeopleView = peopleView.view;
        this.RelationshipEntity = relView.entity;
        this.LatestRelationshipsView = relView.view;
        this.IsLoading = false;
        this.cdr.detectChanges();
    }

    private applySnapshot(
        people: DirectoryPersonRow[],
        orgs: DirectoryOrganizationRow[],
        relationships: DirectoryRelationshipRow[],
    ): void {
        const activePeople = ActivePeople(people);
        const activeOrgs = ActiveOrganizations(orgs);
        this.ActivePeopleCount = activePeople.length;
        this.ActiveOrganizationCount = activeOrgs.length;
        this.RelationshipCount = relationships.length;
        this.PeopleDetail = people.length === activePeople.length
            ? 'Everyone currently on file'
            : `${people.length} total, including inactive`;
        this.OrganizationDetail = orgs.length === activeOrgs.length
            ? 'Active organizations'
            : `${orgs.length} total, including inactive`;
        this.Queues = BuildDirectoryQueues(people, orgs);
        this.GapCount = this.Queues.reduce((sum, queue) => sum + queue.Count, 0);
        this.PeoplePerDay = CountByDay(people);
        this.OrganizationTypeMix = CountByLabel(
            orgs.map((org) => ({ Label: org.OrganizationType || 'Unspecified' })),
        );
        this.LatestPeople = LatestByCreated(people);
        this.LatestRelationships = LatestByCreated(relationships, 6);
        this.WorthALook = BuildAttentionItems(people, orgs);
    }

    public barHeight(bar: DirectoryDayBar): number {
        const max = Math.max(1, ...this.PeoplePerDay.map((item) => item.Value));
        return Math.max(6, (bar.Value / max) * 100);
    }

    public mixWidth(row: DirectoryBarRow): number {
        const max = Math.max(1, ...this.OrganizationTypeMix.map((item) => item.Value));
        return (row.Value / max) * 100;
    }

    public OpenPeople(): void {
        this.OpenPage('people');
    }

    public OpenOrganizations(): void {
        this.OpenPage('organizations');
    }

    public OpenPage(pageId: string): void {
        const label = pageId === 'organizations' ? 'Organizations' : 'People';
        void this.navigation?.OpenNavItemByName(label);
    }

    public NewPerson(): void {
        OpenNewCommonRecord(COMMON_ENTITIES.Person);
    }

    public NewOrganization(): void {
        OpenNewCommonRecord(COMMON_ENTITIES.Organization);
    }

    public OpenPerson(id: string): void {
        OpenCommonRecord(COMMON_ENTITIES.Person, id);
    }

    public OnPersonOpened(event: RecordOpenedEvent): void {
        const id = (event.compositeKey?.GetValueByFieldName('ID') ?? event.record?.['ID']) as string | undefined;
        this.OpenPerson(id ?? '');
    }

    public OnRelationshipOpened(event: RecordOpenedEvent): void {
        const id = (event.compositeKey?.GetValueByFieldName('ID') ?? event.record?.['ID']) as string | undefined;
        OpenCommonRecord(COMMON_ENTITIES.Relationship, id);
    }

    public OpenAttention(item: DirectoryAttentionItem): void {
        const entity = item.Kind === 'person' ? COMMON_ENTITIES.Person : COMMON_ENTITIES.Organization;
        OpenCommonRecord(entity, item.RecordID);
    }

    public OpenRelationship(rel: DirectoryRelationshipRow): void {
        const personId = rel.FromPersonID || rel.ToPersonID;
        if (personId) {
            OpenCommonRecord(COMMON_ENTITIES.Person, personId);
            return;
        }
        OpenCommonRecord(COMMON_ENTITIES.Organization, rel.FromOrganizationID || rel.ToOrganizationID);
    }

}
