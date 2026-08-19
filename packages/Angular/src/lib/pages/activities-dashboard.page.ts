import { Component, OnInit, ChangeDetectionStrategy, ChangeDetectorRef, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RunView } from '@memberjunction/core';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import { OpenCommonRecord, OpenNewCommonRecord } from '../open-record';
import { COMMON_ENTITIES } from '../data/entity-names';

export interface ActivityDashboardRow {
    ID: string;
    Title: string;
    Description: string | null;
    StartedAt: string;
    EndedAt: string | null;
    Direction: 'Inbound' | 'Internal' | 'Outbound';
    Status: string;
    Outcome: string | null;
    Location: string | null;
    ActivityTypeID: string;
    ActivityType: string;
    Source: string;
    SourceSystem: string | null;
    LoggedByUser: string | null;
    __mj_CreatedAt: string;
}

export interface ActivityKPIs {
    TotalThisWeek: number;
    CallsCount: number;
    MeetingsCount: number;
    ScheduledCount: number;
}

@Component({
    selector: 'bizapps-common-activities-page',
    standalone: true,
    imports: [CommonModule, FormsModule, MJButtonDirective],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <div class="mja-dash">
            <!-- Header & KPI Bar -->
            <header class="mja-head">
                <div class="mja-head__top">
                    <div class="mja-head__identity">
                        <div class="mja-head__avatar">
                            <i class="fa-solid fa-bolt" aria-hidden="true"></i>
                        </div>
                        <div class="mja-head__titles">
                            <h1 class="mja-head__title">Activities &amp; Interactions</h1>
                            <p class="mja-head__sub">Customer communications, meetings, calls, and email threads across all accounts.</p>
                        </div>
                    </div>

                    <div class="mja-head__actions">
                        <button mjButton variant="primary" size="sm" type="button" (click)="NewActivity()">
                            <i class="fa-solid fa-plus" aria-hidden="true"></i> New Activity
                        </button>
                    </div>
                </div>

                <!-- KPI Figures -->
                <div class="mja-kpis">
                    <div class="mja-kpi">
                        <span class="mja-kpi__label">Total Activities</span>
                        <span class="mja-kpi__val">{{ Activities.length }}</span>
                    </div>
                    <div class="mja-kpi">
                        <span class="mja-kpi__label">Calls Logged</span>
                        <span class="mja-kpi__val mja-val--green">{{ KPIs.CallsCount }}</span>
                    </div>
                    <div class="mja-kpi">
                        <span class="mja-kpi__label">Meetings</span>
                        <span class="mja-kpi__val mja-val--blue">{{ KPIs.MeetingsCount }}</span>
                    </div>
                    <div class="mja-kpi">
                        <span class="mja-kpi__label">Scheduled</span>
                        <span class="mja-kpi__val mja-val--amber">{{ KPIs.ScheduledCount }}</span>
                    </div>
                </div>

                <!-- Filters & Search Toolbar -->
                <div class="mja-toolbar">
                    <div class="mja-chips">
                        @for (chip of TypeFilterOptions; track chip.id) {
                            <button
                                type="button"
                                class="mja-chip"
                                [class.mja-chip--active]="ActiveTypeFilter === chip.id"
                                (click)="SetTypeFilter(chip.id)">
                                <i [class]="chip.icon"></i> {{ chip.label }}
                            </button>
                        }
                    </div>

                    <div class="mja-search-box">
                        <input
                            class="mj-input mja-search-input"
                            type="search"
                            placeholder="Search activities by title, description, or outcome…"
                            [(ngModel)]="SearchQuery"
                            (ngModelChange)="OnSearchChanged()" />
                    </div>
                </div>
            </header>

            <!-- Activity Stream -->
            <main class="mja-main">
                @if (IsLoading) {
                    <div class="mja-loading">
                        <i class="fa-solid fa-spinner fa-spin" style="font-size: 24px; color: var(--mj-brand-primary, #0284c7);"></i>
                        <span>Loading activity timeline…</span>
                    </div>
                } @else if (FilteredActivities.length === 0) {
                    <div class="mja-empty">
                        <i class="fa-solid fa-bolt-slash"></i>
                        <h3>No activities found</h3>
                        <p>No logged communications match the selected filters.</p>
                    </div>
                } @else {
                    <div class="mja-timeline">
                        @for (act of FilteredActivities; track act.ID) {
                            <div class="mja-item" (click)="SelectActivity(act)" [class.mja-item--selected]="SelectedActivity?.ID === act.ID">
                                <div class="mja-item__icon" [attr.data-dir]="act.Direction">
                                    <i [class]="getTypeIcon(act.ActivityType)"></i>
                                </div>
                                <div class="mja-item__body">
                                    <div class="mja-item__header">
                                        <div class="mja-item__title-wrap">
                                            <span class="mja-item__title">{{ act.Title || 'Untitled Activity' }}</span>
                                            <span class="mja-pill" [attr.data-dir]="act.Direction">{{ act.Direction }}</span>
                                            @if (act.Status && act.Status !== 'Completed' && act.Status !== 'Logged') {
                                                <span class="mja-pill mja-pill--status" [attr.data-status]="act.Status">{{ act.Status }}</span>
                                            }
                                            @if (act.Outcome) {
                                                <span class="mja-pill mja-pill--outcome">{{ act.Outcome }}</span>
                                            }
                                        </div>
                                        <span class="mja-item__time">{{ act.StartedAt | date:'mediumDate' }} {{ act.StartedAt | date:'shortTime' }}</span>
                                    </div>
                                    @if (act.Description) {
                                        <p class="mja-item__desc">{{ act.Description }}</p>
                                    }
                                    <div class="mja-item__footer">
                                        @if (act.Location) {
                                            <span class="mja-item__tag"><i class="fa-solid fa-location-dot"></i> {{ act.Location }}</span>
                                        }
                                        @if (act.Source && act.Source !== 'Manual') {
                                            <span class="mja-item__tag"><i class="fa-solid fa-cloud-arrow-down"></i> {{ act.SourceSystem || act.Source }}</span>
                                        }
                                        @if (act.LoggedByUser) {
                                            <span class="mja-item__tag"><i class="fa-solid fa-user-pen"></i> {{ act.LoggedByUser }}</span>
                                        }
                                    </div>
                                </div>
                                <button type="button" class="mja-item__open-btn" (click)="OpenFullRecord(act.ID); $event.stopPropagation()" title="Open Full Record">
                                    <i class="fa-solid fa-arrow-up-right-from-square"></i>
                                </button>
                            </div>
                        }
                    </div>
                }
            </main>

            <!-- Slide-in Detail Drawer -->
            @if (SelectedActivity) {
                <div class="mja-drawer-backdrop" (click)="CloseDrawer()"></div>
                <aside class="mja-drawer">
                    <div class="mja-drawer__head">
                        <div class="mja-drawer__type">
                            <i [class]="getTypeIcon(SelectedActivity.ActivityType)"></i>
                            <span>{{ SelectedActivity.ActivityType || 'Activity' }}</span>
                        </div>
                        <div class="mja-drawer__actions">
                            <button mjButton variant="primary" size="sm" type="button" (click)="OpenFullRecord(SelectedActivity.ID)">
                                <i class="fa-solid fa-arrow-up-right-from-square"></i> Open Record
                            </button>
                            <button type="button" class="mja-drawer__close" (click)="CloseDrawer()">
                                <i class="fa-solid fa-xmark"></i>
                            </button>
                        </div>
                    </div>

                    <div class="mja-drawer__body">
                        <h2 class="mja-drawer__title">{{ SelectedActivity.Title }}</h2>

                        <div class="mja-drawer__meta-grid">
                            <div class="mja-drawer__meta-item">
                                <label>Date &amp; Time</label>
                                <span>{{ SelectedActivity.StartedAt | date:'medium' }}</span>
                            </div>
                            <div class="mja-drawer__meta-item">
                                <label>Direction</label>
                                <span class="mja-pill" [attr.data-dir]="SelectedActivity.Direction">{{ SelectedActivity.Direction }}</span>
                            </div>
                            <div class="mja-drawer__meta-item">
                                <label>Status</label>
                                <span class="mja-pill mja-pill--status" [attr.data-status]="SelectedActivity.Status">{{ SelectedActivity.Status }}</span>
                            </div>
                            @if (SelectedActivity.Outcome) {
                                <div class="mja-drawer__meta-item">
                                    <label>Outcome</label>
                                    <span class="mja-pill mja-pill--outcome">{{ SelectedActivity.Outcome }}</span>
                                </div>
                            }
                        </div>

                        @if (SelectedActivity.Description) {
                            <div class="mja-drawer__section">
                                <label class="mja-drawer__section-label">Notes &amp; Details</label>
                                <div class="mja-drawer__notes">{{ SelectedActivity.Description }}</div>
                            </div>
                        }

                        @if (SelectedActivity.Location) {
                            <div class="mja-drawer__section">
                                <label class="mja-drawer__section-label">Location</label>
                                <div><i class="fa-solid fa-location-dot"></i> {{ SelectedActivity.Location }}</div>
                            </div>
                        }
                    </div>
                </aside>
            }
        </div>
    `,
    styles: [`
        :host { display: block; width: 100%; height: 100%; }

        .mja-dash {
            display: flex;
            flex-direction: column;
            gap: 16px;
            padding: 20px 24px;
            min-height: 100%;
            background: var(--mj-bg-surface-sunken, #f8fafc);
            box-sizing: border-box;
            position: relative;
        }

        .mja-head {
            display: flex;
            flex-direction: column;
            gap: 16px;
            padding: 18px 22px;
            background: var(--mj-bg-surface-card, #ffffff);
            border: 1px solid var(--mj-border-default, #e2e8f0);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        }

        .mja-head__top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }

        .mja-head__identity {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .mja-head__avatar {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            box-shadow: 0 4px 10px rgba(2, 132, 199, 0.25);
            flex-shrink: 0;
        }

        .mja-head__titles { display: flex; flex-direction: column; gap: 2px; }
        .mja-head__title { margin: 0; font-size: 18px; font-weight: 700; color: var(--mj-text-primary, #0f172a); }
        .mja-head__sub { margin: 0; font-size: 12px; color: var(--mj-text-muted, #64748b); }

        .mja-kpis {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
            gap: 12px;
            padding-top: 12px;
            border-top: 1px solid var(--mj-border-default, #e2e8f0);
        }

        .mja-kpi { display: flex; flex-direction: column; gap: 2px; }
        .mja-kpi__label { font-size: 11px; font-weight: 600; color: var(--mj-text-muted, #64748b); text-transform: uppercase; letter-spacing: 0.04em; }
        .mja-kpi__val { font-size: 16px; font-weight: 700; font-family: var(--mj-font-mono, monospace); color: var(--mj-text-primary, #0f172a); }
        .mja-val--green { color: #16a34a; }
        .mja-val--blue { color: #0284c7; }
        .mja-val--amber { color: #d97706; }

        .mja-toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
            padding-top: 10px;
            border-top: 1px dashed var(--mj-border-default, #e2e8f0);
            flex-wrap: wrap;
        }

        .mja-chips { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
        .mja-chip {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 11px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            border: 1px solid var(--mj-border-default, #cbd5e1);
            background: var(--mj-bg-surface, #ffffff);
            color: var(--mj-text-secondary, #475569);
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .mja-chip:hover { background: var(--mj-bg-surface-hover, #f1f5f9); }
        .mja-chip--active { background: var(--mj-brand-primary, #0284c7); color: #ffffff !important; border-color: var(--mj-brand-primary, #0284c7); }

        .mja-search-box { flex: 1; max-width: 380px; min-width: 220px; }
        .mja-search-input { width: 100%; font-size: 12px; }

        .mja-main {
            background: var(--mj-bg-surface-card, #ffffff);
            border: 1px solid var(--mj-border-default, #e2e8f0);
            border-radius: 12px;
            padding: 16px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            flex: 1;
        }

        .mja-loading, .mja-empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 10px;
            padding: 60px 20px;
            color: var(--mj-text-muted, #64748b);
            font-size: 13px;
        }

        .mja-timeline {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .mja-item {
            display: flex;
            align-items: flex-start;
            gap: 14px;
            padding: 14px 16px;
            border-radius: 10px;
            border: 1px solid var(--mj-border-default, #e2e8f0);
            background: var(--mj-bg-surface, #ffffff);
            cursor: pointer;
            transition: all 0.15s ease;
            position: relative;
        }

        .mja-item:hover {
            border-color: var(--mj-brand-primary, #0284c7);
            background: var(--mj-bg-surface-hover, #f8fafc);
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
        }

        .mja-item--selected {
            border-color: var(--mj-brand-primary, #0284c7);
            background: color-mix(in srgb, var(--mj-brand-primary, #0284c7) 6%, #ffffff);
        }

        .mja-item__icon {
            width: 38px;
            height: 38px;
            border-radius: 8px;
            background: #f1f5f9;
            color: #0284c7;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            flex-shrink: 0;
        }

        .mja-item__icon[data-dir="Inbound"] { background: #e0f2fe; color: #0369a1; }
        .mja-item__icon[data-dir="Outbound"] { background: #dcfce7; color: #15803d; }

        .mja-item__body {
            display: flex;
            flex-direction: column;
            gap: 5px;
            flex: 1;
            min-width: 0;
        }

        .mja-item__header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .mja-item__title-wrap {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .mja-item__title {
            font-size: 14px;
            font-weight: 700;
            color: var(--mj-text-primary, #0f172a);
        }

        .mja-pill {
            padding: 2px 7px;
            border-radius: 9999px;
            font-size: 11px;
            font-weight: 600;
            background: #f1f5f9;
            color: #475569;
        }

        .mja-pill[data-dir="Inbound"] { background: #e0f2fe; color: #0369a1; }
        .mja-pill[data-dir="Outbound"] { background: #dcfce7; color: #15803d; }
        .mja-pill--status[data-status="Scheduled"] { background: #fef3c7; color: #92400e; }
        .mja-pill--status[data-status="Completed"] { background: #dcfce7; color: #166534; }
        .mja-pill--outcome { background: #ede9fe; color: #6b21a8; }

        .mja-item__time {
            font-size: 12px;
            color: var(--mj-text-muted, #64748b);
            font-family: var(--mj-font-mono, monospace);
        }

        .mja-item__desc {
            margin: 0;
            font-size: 13px;
            color: var(--mj-text-secondary, #334155);
            line-height: 1.4;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        .mja-item__footer {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 11px;
            color: var(--mj-text-muted, #64748b);
            padding-top: 2px;
            flex-wrap: wrap;
        }

        .mja-item__tag { display: inline-flex; align-items: center; gap: 4px; }

        .mja-item__open-btn {
            background: transparent;
            border: 1px solid var(--mj-border-default, #cbd5e1);
            border-radius: 6px;
            padding: 6px 8px;
            color: var(--mj-text-muted, #64748b);
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .mja-item__open-btn:hover {
            color: var(--mj-brand-primary, #0284c7);
            border-color: var(--mj-brand-primary, #0284c7);
            background: var(--mj-bg-surface-hover, #f1f5f9);
        }

        /* Slide-in Drawer */
        .mja-drawer-backdrop {
            position: fixed; inset: 0; background: rgba(0, 0, 0, 0.4);
            z-index: 999;
        }

        .mja-drawer {
            position: fixed; top: 0; right: 0; bottom: 0;
            width: 480px; max-width: 90vw;
            background: var(--mj-bg-surface-card, #ffffff);
            z-index: 1000;
            box-shadow: -4px 0 24px rgba(0, 0, 0, 0.15);
            display: flex;
            flex-direction: column;
            overflow-y: auto;
        }

        .mja-drawer__head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-bottom: 1px solid var(--mj-border-default, #e2e8f0);
        }

        .mja-drawer__type {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 700;
            color: var(--mj-brand-primary, #0284c7);
        }

        .mja-drawer__actions {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .mja-drawer__close {
            background: transparent;
            border: none;
            font-size: 18px;
            color: var(--mj-text-muted, #64748b);
            cursor: pointer;
            padding: 4px;
        }

        .mja-drawer__body {
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

        .mja-drawer__title {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
            color: var(--mj-text-primary, #0f172a);
        }

        .mja-drawer__meta-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            padding: 12px;
            background: var(--mj-bg-surface-sunken, #f8fafc);
            border-radius: 8px;
            border: 1px solid var(--mj-border-default, #e2e8f0);
        }

        .mja-drawer__meta-item { display: flex; flex-direction: column; gap: 3px; font-size: 12px; }
        .mja-drawer__meta-item label { font-size: 10.5px; font-weight: 600; text-transform: uppercase; color: var(--mj-text-muted, #64748b); }

        .mja-drawer__section { display: flex; flex-direction: column; gap: 6px; }
        .mja-drawer__section-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; color: var(--mj-text-muted, #64748b); }
        .mja-drawer__notes {
            padding: 12px;
            border-radius: 8px;
            background: var(--mj-bg-surface, #ffffff);
            border: 1px solid var(--mj-border-default, #e2e8f0);
            font-size: 13px;
            line-height: 1.5;
            color: var(--mj-text-secondary, #334155);
            white-space: pre-wrap;
        }
    `]
})
export class CommonActivitiesPageComponent implements OnInit {
    private cdr = inject(ChangeDetectorRef);

    public Activities: ActivityDashboardRow[] = [];
    public IsLoading = false;
    public SearchQuery = '';
    public ActiveTypeFilter = 'all';
    public SelectedActivity: ActivityDashboardRow | null = null;

    public KPIs: ActivityKPIs = {
        TotalThisWeek: 0,
        CallsCount: 0,
        MeetingsCount: 0,
        ScheduledCount: 0,
    };

    public readonly TypeFilterOptions = [
        { id: 'all', label: 'All Activities', icon: 'fa-solid fa-list' },
        { id: 'call', label: 'Calls', icon: 'fa-solid fa-phone' },
        { id: 'meeting', label: 'Meetings', icon: 'fa-solid fa-calendar-check' },
        { id: 'email', label: 'Emails', icon: 'fa-solid fa-envelope' },
        { id: 'note', label: 'Notes', icon: 'fa-solid fa-note-sticky' },
    ];

    ngOnInit(): void {
        this.LoadActivities();
    }

    public async LoadActivities(): Promise<void> {
        this.IsLoading = true;
        this.cdr.markForCheck();

        try {
            const rv = new RunView();
            const res = await rv.RunView<ActivityDashboardRow>({
                EntityName: COMMON_ENTITIES.Activity,
                OrderBy: 'StartedAt DESC',
                MaxRows: 250,
                ResultType: 'simple',
            });

            if (res.Success && res.Results) {
                this.Activities = res.Results;
                this.computeKPIs(this.Activities);
            }
        } catch {
            // ignore
        } finally {
            this.IsLoading = false;
            this.cdr.markForCheck();
        }
    }

    private computeKPIs(rows: ActivityDashboardRow[]): void {
        let calls = 0;
        let meetings = 0;
        let scheduled = 0;

        for (const r of rows) {
            const type = (r.ActivityType || r.Title || '').toLowerCase();
            if (type.includes('call') || type.includes('phone')) calls++;
            if (type.includes('meet')) meetings++;
            if (r.Status === 'Scheduled') scheduled++;
        }

        this.KPIs = {
            TotalThisWeek: rows.length,
            CallsCount: calls,
            MeetingsCount: meetings,
            ScheduledCount: scheduled,
        };
    }

    public get FilteredActivities(): ActivityDashboardRow[] {
        let list = this.Activities;

        if (this.ActiveTypeFilter !== 'all') {
            list = list.filter(a => {
                const type = (a.ActivityType || a.Title || '').toLowerCase();
                return type.includes(this.ActiveTypeFilter);
            });
        }

        if (this.SearchQuery?.trim()) {
            const q = this.SearchQuery.toLowerCase();
            list = list.filter(a =>
                (a.Title && a.Title.toLowerCase().includes(q)) ||
                (a.Description && a.Description.toLowerCase().includes(q)) ||
                (a.Outcome && a.Outcome.toLowerCase().includes(q)) ||
                (a.Location && a.Location.toLowerCase().includes(q))
            );
        }

        return list;
    }

    public SetTypeFilter(typeId: string): void {
        this.ActiveTypeFilter = typeId;
        this.cdr.markForCheck();
    }

    public OnSearchChanged(): void {
        this.cdr.markForCheck();
    }

    public SelectActivity(act: ActivityDashboardRow): void {
        this.SelectedActivity = act;
        this.cdr.markForCheck();
    }

    public CloseDrawer(): void {
        this.SelectedActivity = null;
        this.cdr.markForCheck();
    }

    public OpenFullRecord(id: string): void {
        OpenCommonRecord(COMMON_ENTITIES.Activity, id);
    }

    public NewActivity(): void {
        OpenNewCommonRecord(COMMON_ENTITIES.Activity);
    }

    public getTypeIcon(type: string | null): string {
        if (!type) return 'fa-solid fa-bolt';
        const lower = type.toLowerCase();
        if (lower.includes('call') || lower.includes('phone')) return 'fa-solid fa-phone';
        if (lower.includes('meet')) return 'fa-solid fa-calendar-check';
        if (lower.includes('email') || lower.includes('mail')) return 'fa-solid fa-envelope';
        if (lower.includes('note')) return 'fa-solid fa-note-sticky';
        if (lower.includes('sms') || lower.includes('chat')) return 'fa-solid fa-comments';
        return 'fa-solid fa-bolt';
    }
}
