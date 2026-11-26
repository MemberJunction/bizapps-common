import {
    ChangeDetectionStrategy,
    ChangeDetectorRef,
    Component,
    Inject,
    Input,
    OnInit,
    Optional,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IMetadataProvider, Metadata, RunView } from '@memberjunction/core';
import { UserInfoEngine } from '@memberjunction/core-entities';
import { NormalizeUUID, UUIDsEqual } from '@memberjunction/global';
import { NavigationService } from '@memberjunction/ng-shared';
import { SharedGenericModule } from '@memberjunction/ng-shared-generic';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import {
    COMMON_ANGULAR_LIMITS_CONFIG,
    ResolveCommonAngularLimits,
    type CommonAngularLimitsOverride,
} from '../config/limits.config';
import { DashboardFilterBarComponent } from '../components/dashboard-filter-bar/dashboard-filter-bar.component';
import { CALENDAR_YEAR_START, WithinWindow } from '../components/dashboard-filter-bar/dashboard-period';
import { PeriodWindowOf, type DashboardPeriodState } from '../components/dashboard-filter-bar/dashboard-period-state';
import { ActivityArtifactBadgeComponent } from '../components/activity-artifact-badge/activity-artifact-badge.component';
import {
    ActivityComposerComponent,
    type ActivityComposerSavedEvent,
} from '../components/activity-composer/activity-composer.component';
import {
    ExpandActivityToArtifact,
    LinkExistingArtifactToActivity,
    LoadActivityArtifactsByIDs,
    OpenLinkedArtifact,
    ResolveActivityArtifactBadge,
    SearchLinkableArtifacts,
    StripActivityMarkdownExcerpt,
    UnlinkArtifactFromActivity,
    type ActivityArtifactBadgeState,
    type ActivityArtifactSummary,
} from '../data/activity-artifact';
import { OpenCommonRecord, OpenNewCommonRecord } from '../open-record';
import { COMMON_ENTITIES } from '../data/entity-names';

const COMPOSER_OPEN_SETTING_KEY = 'mj.common.activities.quickComposerOpen';

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
    ArtifactID: string | null;
    Artifact?: string | null;
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
    imports: [
        CommonModule,
        FormsModule,
        MJButtonDirective,
        SharedGenericModule,
        DashboardFilterBarComponent,
        ActivityArtifactBadgeComponent,
        ActivityComposerComponent,
    ],
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
                        <button mjButton variant="primary" size="sm" type="button" (click)="ToggleQuickComposer()">
                            <i class="fa-solid fa-bolt" aria-hidden="true"></i>
                            {{ ShowQuickComposer ? 'Hide Quick Log' : 'Quick Log' }}
                        </button>
                        <button mjButton variant="outline" size="sm" type="button" (click)="NewActivity()">
                            <i class="fa-solid fa-plus" aria-hidden="true"></i> Full Form
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
                                <i [class]="chip.icon" aria-hidden="true"></i> {{ chip.label }}
                            </button>
                        }
                    </div>

                    <bizapps-dashboard-filter-bar
                        [ShowCompanies]="false"
                        [(PeriodState)]="PeriodFilter"
                        (PeriodStateChange)="OnPeriodFilterChanged($event)" />

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

            <!-- Frictionless <2s Quick-Capture Activity Composer (defaults ArtifactID = null) -->
            @if (ShowQuickComposer) {
                <bizapps-activity-composer
                    (ActivityCreated)="OnQuickActivityCreated($event)"
                    (Cancelled)="SetQuickComposerOpen(false)" />
            }

            <!-- Activity Stream -->
            <main class="mja-main">
                @if (IsLoading) {
                    <div class="mja-loading">
                        <mj-loading text="Loading activity timeline…" size="medium"></mj-loading>
                    </div>
                } @else if (FilteredActivities.length === 0) {
                    <div class="mja-empty">
                        <i class="fa-solid fa-bolt-slash" aria-hidden="true"></i>
                        <h3>No activities found</h3>
                        <p>No logged communications match the selected filters.</p>
                    </div>
                } @else {
                    <div class="mja-timeline">
                        @for (act of FilteredActivities; track act.ID) {
                            <div class="mja-item" (click)="SelectActivity(act)" [class.mja-item--selected]="IsSelected(act)">
                                <div class="mja-item__icon" [attr.data-dir]="act.Direction">
                                    <i [class]="getTypeIcon(act.ActivityType)" aria-hidden="true"></i>
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
                                            @if (act.ArtifactID) {
                                                <bizapps-activity-artifact-badge
                                                    [Badge]="GetArtifactBadge(act)"
                                                    (OpenDoc)="OnOpenLinkedDoc($event)" />
                                            }
                                        </div>
                                        <span class="mja-item__time">{{ act.StartedAt | date:'mediumDate' }} {{ act.StartedAt | date:'shortTime' }}</span>
                                    </div>
                                    @if (act.Description) {
                                        <p class="mja-item__desc">{{ FormatCardExcerpt(act.Description) }}</p>
                                    }
                                    <div class="mja-item__footer">
                                        @if (act.Location) {
                                            <span class="mja-item__tag"><i class="fa-solid fa-location-dot" aria-hidden="true"></i> {{ act.Location }}</span>
                                        }
                                        @if (act.Source && act.Source !== 'Manual') {
                                            <span class="mja-item__tag"><i class="fa-solid fa-cloud-arrow-down" aria-hidden="true"></i> {{ act.SourceSystem || act.Source }}</span>
                                        }
                                        @if (act.LoggedByUser) {
                                            <span class="mja-item__tag"><i class="fa-solid fa-user-pen" aria-hidden="true"></i> {{ act.LoggedByUser }}</span>
                                        }
                                    </div>
                                </div>
                                <button type="button" class="mja-item__open-btn" (click)="OpenFullRecord(act.ID); $event.stopPropagation()" title="Open Full Record">
                                    <i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i>
                                </button>
                            </div>
                        }
                    </div>
                }
            </main>

            <!-- Slide-in Detail Drawer -->
            @if (SelectedActivity) {
                <div class="mja-drawer-backdrop" (click)="CloseDrawer()"></div>
                <aside class="mja-drawer" aria-label="Activity Details">
                    <div class="mja-drawer__head">
                        <div class="mja-drawer__type">
                            <i [class]="getTypeIcon(SelectedActivity.ActivityType)" aria-hidden="true"></i>
                            <span>{{ SelectedActivity.ActivityType || 'Activity' }}</span>
                        </div>
                        <div class="mja-drawer__actions">
                            <button mjButton variant="primary" size="sm" type="button" (click)="OpenFullRecord(SelectedActivity.ID)">
                                <i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i> Open Record
                            </button>
                            <button type="button" class="mja-drawer__close" aria-label="Close detail drawer" (click)="CloseDrawer()">
                                <i class="fa-solid fa-xmark" aria-hidden="true"></i>
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

                        <!-- Optional Linked MJ Doc Section -->
                        <div class="mja-drawer__section">
                            <label class="mja-drawer__section-label">Linked MJ Doc (Optional)</label>
                            @if (IsMutatingArtifact) {
                                <mj-loading text="Updating linked MJ Doc…" size="small"></mj-loading>
                            } @else if (SelectedActivity.ArtifactID) {
                                <div class="mja-drawer__doc-row">
                                    <bizapps-activity-artifact-badge
                                        [Badge]="GetArtifactBadge(SelectedActivity)"
                                        [AllowUnlink]="true"
                                        (OpenDoc)="OnOpenLinkedDoc($event)"
                                        (UnlinkDoc)="UnlinkSelectedActivityDoc()" />
                                </div>
                            } @else {
                                <div class="mja-drawer__doc-actions">
                                    <button
                                        type="button"
                                        class="mja-doc-action-btn"
                                        (click)="ToggleDrawerLinkPicker()">
                                        <i class="fa-solid fa-link" aria-hidden="true"></i> Link Existing MJ Doc
                                    </button>
                                    <button
                                        type="button"
                                        class="mja-doc-action-btn mja-doc-action-btn--primary"
                                        (click)="ExpandSelectedActivityToDoc()">
                                        <i class="fa-solid fa-file-circle-plus" aria-hidden="true"></i> Expand to MJ Doc
                                    </button>
                                </div>
                            }

                            @if (ShowDrawerLinkPicker) {
                                <div class="mja-drawer__picker">
                                    <input
                                        class="mj-input mja-drawer__picker-input"
                                        type="search"
                                        placeholder="Search existing MJ Docs…"
                                        [(ngModel)]="DrawerArtifactSearch"
                                        (ngModelChange)="SearchDrawerArtifacts($event)" />
                                    @if (IsSearchingDrawerArtifacts) {
                                        <mj-loading text="Searching…" size="small"></mj-loading>
                                    } @else if (DrawerArtifactOptions.length === 0) {
                                        <p class="mja-drawer__picker-empty">No matching MJ Docs found.</p>
                                    } @else {
                                        <div class="mja-drawer__picker-list">
                                            @for (doc of DrawerArtifactOptions; track doc.ID) {
                                                <button
                                                    type="button"
                                                    class="mja-drawer__picker-item"
                                                    (click)="LinkSelectedActivityToDoc(doc)">
                                                    <i class="fa-solid fa-file-lines" aria-hidden="true"></i>
                                                    <span>{{ doc.Name }}</span>
                                                </button>
                                            }
                                        </div>
                                    }
                                </div>
                            }

                            @if (DrawerArtifactError) {
                                <div class="mja-drawer__error" role="alert">{{ DrawerArtifactError }}</div>
                            }
                        </div>

                        @if (SelectedActivity.Description) {
                            <div class="mja-drawer__section">
                                <label class="mja-drawer__section-label">Notes &amp; Details</label>
                                <div class="mja-drawer__notes">{{ FormatCardExcerpt(SelectedActivity.Description, 2000) }}</div>
                            </div>
                        }

                        @if (SelectedActivity.Location) {
                            <div class="mja-drawer__section">
                                <label class="mja-drawer__section-label">Location</label>
                                <div><i class="fa-solid fa-location-dot" aria-hidden="true"></i> {{ SelectedActivity.Location }}</div>
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
            background: var(--mj-bg-surface-sunken);
            box-sizing: border-box;
            position: relative;
        }

        .mja-head {
            display: flex;
            flex-direction: column;
            gap: 16px;
            padding: 18px 22px;
            background: var(--mj-bg-surface-card);
            border: 1px solid var(--mj-border-default);
            border-radius: 12px;
            box-shadow: var(--mj-shadow-sm);
        }

        .mja-head__top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }

        .mja-head__actions {
            display: flex;
            align-items: center;
            gap: 8px;
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
            background: linear-gradient(135deg, var(--mj-brand-primary) 0%, var(--mj-brand-primary-hover) 100%);
            color: var(--mj-brand-on-primary);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            box-shadow: var(--mj-shadow-brand-sm);
            flex-shrink: 0;
        }

        .mja-head__titles { display: flex; flex-direction: column; gap: 2px; }
        .mja-head__title { margin: 0; font-size: 18px; font-weight: 700; color: var(--mj-text-primary); }
        .mja-head__sub { margin: 0; font-size: 12px; color: var(--mj-text-muted); }

        .mja-kpis {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
            gap: 12px;
            padding-top: 12px;
            border-top: 1px solid var(--mj-border-default);
        }

        .mja-kpi { display: flex; flex-direction: column; gap: 2px; }
        .mja-kpi__label { font-size: 11px; font-weight: 600; color: var(--mj-text-muted); text-transform: uppercase; letter-spacing: 0.04em; }
        .mja-kpi__val { font-size: 16px; font-weight: 700; font-family: var(--mj-font-family-mono); color: var(--mj-text-primary); }
        .mja-val--green { color: var(--mj-status-success); }
        .mja-val--blue { color: var(--mj-brand-primary); }
        .mja-val--amber { color: var(--mj-status-warning); }

        .mja-toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
            padding-top: 10px;
            border-top: 1px dashed var(--mj-border-default);
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
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-secondary);
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .mja-chip:hover { background: var(--mj-bg-surface-hover); }
        .mja-chip--active { background: var(--mj-brand-primary); color: var(--mj-brand-on-primary) !important; border-color: var(--mj-brand-primary); }

        .mja-search-box { flex: 1; max-width: 380px; min-width: 220px; }
        .mja-search-input { width: 100%; font-size: 12px; }

        .mja-main {
            background: var(--mj-bg-surface-card);
            border: 1px solid var(--mj-border-default);
            border-radius: 12px;
            padding: 16px;
            box-shadow: var(--mj-shadow-sm);
            flex: 1;
        }

        .mja-loading, .mja-empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 10px;
            padding: 60px 20px;
            color: var(--mj-text-muted);
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
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            cursor: pointer;
            transition: all 0.15s ease;
            position: relative;
        }

        .mja-item:hover {
            border-color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
            transform: translateY(-1px);
            box-shadow: var(--mj-shadow-md);
        }

        .mja-item--selected {
            border-color: var(--mj-brand-primary);
            background: color-mix(in srgb, var(--mj-brand-primary) 6%, var(--mj-bg-surface));
        }

        .mja-item__icon {
            width: 38px;
            height: 38px;
            border-radius: 8px;
            background: var(--mj-bg-surface-sunken);
            color: var(--mj-brand-primary);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            flex-shrink: 0;
        }

        .mja-item__icon[data-dir="Inbound"] { background: var(--mj-status-info-bg); color: var(--mj-status-info-text); }
        .mja-item__icon[data-dir="Outbound"] { background: var(--mj-status-success-bg); color: var(--mj-status-success-text); }

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
            color: var(--mj-text-primary);
        }

        .mja-pill {
            padding: 2px 7px;
            border-radius: 9999px;
            font-size: 11px;
            font-weight: 600;
            background: var(--mj-bg-surface-sunken);
            color: var(--mj-text-secondary);
        }

        .mja-pill[data-dir="Inbound"] { background: var(--mj-status-info-bg); color: var(--mj-status-info-text); }
        .mja-pill[data-dir="Outbound"] { background: var(--mj-status-success-bg); color: var(--mj-status-success-text); }
        .mja-pill--status[data-status="Scheduled"] { background: var(--mj-status-warning-bg); color: var(--mj-status-warning-text); }
        .mja-pill--status[data-status="Completed"] { background: var(--mj-status-success-bg); color: var(--mj-status-success-text); }
        .mja-pill--outcome { background: var(--mj-color-violet-100); color: var(--mj-color-violet-700); }

        .mja-item__time {
            font-size: 12px;
            color: var(--mj-text-muted);
            font-family: var(--mj-font-family-mono);
        }

        .mja-item__desc {
            margin: 0;
            font-size: 13px;
            color: var(--mj-text-secondary);
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
            color: var(--mj-text-muted);
            padding-top: 2px;
            flex-wrap: wrap;
        }

        .mja-item__tag { display: inline-flex; align-items: center; gap: 4px; }

        .mja-item__open-btn {
            background: transparent;
            border: 1px solid var(--mj-border-default);
            border-radius: 6px;
            padding: 6px 8px;
            color: var(--mj-text-muted);
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .mja-item__open-btn:hover {
            color: var(--mj-brand-primary);
            border-color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
        }

        /* Slide-in Drawer */
        .mja-drawer-backdrop {
            position: fixed; inset: 0; background: var(--mj-bg-overlay);
            z-index: 999;
        }

        .mja-drawer {
            position: fixed; top: 0; right: 0; bottom: 0;
            width: 480px; max-width: 90vw;
            background: var(--mj-bg-surface-card);
            z-index: 1000;
            box-shadow: var(--mj-shadow-2xl);
            display: flex;
            flex-direction: column;
            overflow-y: auto;
        }

        .mja-drawer__head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-bottom: 1px solid var(--mj-border-default);
        }

        .mja-drawer__type {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 700;
            color: var(--mj-brand-primary);
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
            color: var(--mj-text-muted);
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
            color: var(--mj-text-primary);
        }

        .mja-drawer__meta-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            padding: 12px;
            background: var(--mj-bg-surface-sunken);
            border-radius: 8px;
            border: 1px solid var(--mj-border-default);
        }

        .mja-drawer__meta-item { display: flex; flex-direction: column; gap: 3px; font-size: 12px; }
        .mja-drawer__meta-item label { font-size: 10.5px; font-weight: 600; text-transform: uppercase; color: var(--mj-text-muted); }

        .mja-drawer__section { display: flex; flex-direction: column; gap: 6px; }
        .mja-drawer__section-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; color: var(--mj-text-muted); }
        .mja-drawer__notes {
            padding: 12px;
            border-radius: 8px;
            background: var(--mj-bg-surface);
            border: 1px solid var(--mj-border-default);
            font-size: 13px;
            line-height: 1.5;
            color: var(--mj-text-secondary);
            white-space: pre-wrap;
        }

        .mja-drawer__doc-row,
        .mja-drawer__doc-actions {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .mja-doc-action-btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-secondary);
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: border-color 0.15s ease, color 0.15s ease, background 0.15s ease;
        }

        .mja-doc-action-btn:hover {
            border-color: var(--mj-brand-primary);
            color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
        }

        .mja-doc-action-btn--primary {
            background: var(--mj-status-info-bg);
            color: var(--mj-status-info-text);
            border-color: var(--mj-status-info-border, var(--mj-border-default));
        }

        .mja-drawer__picker {
            display: flex;
            flex-direction: column;
            gap: 8px;
            padding: 10px;
            border-radius: var(--mj-radius-sm, 6px);
            background: var(--mj-bg-surface-sunken);
            border: 1px solid var(--mj-border-default);
        }

        .mja-drawer__picker-input {
            width: 100%;
            box-sizing: border-box;
            font-size: 12px;
        }

        .mja-drawer__picker-empty {
            margin: 0;
            font-size: 12px;
            color: var(--mj-text-muted);
        }

        .mja-drawer__picker-list {
            display: flex;
            flex-direction: column;
            gap: 4px;
            max-height: 160px;
            overflow-y: auto;
        }

        .mja-drawer__picker-item {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 8px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-primary);
            font-size: 12px;
            text-align: left;
            cursor: pointer;
        }

        .mja-drawer__picker-item:hover {
            border-color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
        }

        .mja-drawer__error {
            padding: 8px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            background: var(--mj-status-error-bg);
            color: var(--mj-status-error-text);
            font-size: 12px;
        }
    `]
})
export class CommonActivitiesPageComponent implements OnInit {
    @Input() public Provider?: IMetadataProvider;
    private readonly limits;

    public Activities: ActivityDashboardRow[] = [];
    public HydratedArtifacts = new Map<string, ActivityArtifactSummary>();
    public ArtifactsHydrated = false;
    public IsLoading = false;
    public SearchQuery = '';
    public ActiveTypeFilter = 'all';
    public PeriodFilter: DashboardPeriodState = { Period: 'alltime', CustomStart: null, CustomEnd: null };
    public SelectedActivity: ActivityDashboardRow | null = null;
    public ShowQuickComposer = false;
    public ShowDrawerLinkPicker = false;
    public DrawerArtifactSearch = '';
    public DrawerArtifactOptions: ActivityArtifactSummary[] = [];
    public IsSearchingDrawerArtifacts = false;
    public IsMutatingArtifact = false;
    public DrawerArtifactError: string | null = null;

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

    constructor(
        @Optional() private readonly cdr?: ChangeDetectorRef,
        @Optional() @Inject(COMMON_ANGULAR_LIMITS_CONFIG) limitsOverride?: CommonAngularLimitsOverride | null,
        @Optional() private readonly navService?: NavigationService,
    ) {
        this.limits = ResolveCommonAngularLimits(limitsOverride);
    }

    ngOnInit(): void {
        this.restoreComposerPreference();
        void this.LoadActivities();
    }

    public async LoadActivities(): Promise<void> {
        this.IsLoading = true;
        this.ArtifactsHydrated = false;
        this.cdr?.markForCheck();

        try {
            const provider = this.activeProvider;
            const rv = RunView.FromMetadataProvider(provider);
            const res = await rv.RunView<ActivityDashboardRow>({
                EntityName: COMMON_ENTITIES.Activity,
                Fields: [
                    'ID',
                    'Title',
                    'Description',
                    'StartedAt',
                    'EndedAt',
                    'Direction',
                    'Status',
                    'Outcome',
                    'Location',
                    'ActivityTypeID',
                    'ActivityType',
                    'Source',
                    'SourceSystem',
                    'LoggedByUser',
                    'ArtifactID',
                    'Artifact',
                    '__mj_CreatedAt',
                ],
                OrderBy: 'StartedAt DESC',
                MaxRows: this.limits.Tuning.ActivitiesDashboardMaxRows,
                ResultType: 'simple',
                CacheLocal: false,
            });

            if (res.Success && res.Results) {
                this.Activities = res.Results;
                this.computeKPIs(this.Activities);
                await this.HydrateLinkedArtifacts(this.Activities);
            }
        } catch {
            // Degrade gracefully without throwing console errors.
        } finally {
            this.IsLoading = false;
            this.cdr?.markForCheck();
        }
    }

    /**
     * Hydrates linked `MJ: Artifacts` summaries in a single batched `RunView` call.
     * Short-circuits completely with zero `RunView` calls when zero visible rows have a non-null `ArtifactID`.
     */
    public async HydrateLinkedArtifacts(rows: ReadonlyArray<ActivityDashboardRow>): Promise<void> {
        this.HydratedArtifacts = await LoadActivityArtifactsByIDs(
            rows.map((r) => r.ArtifactID),
            this.activeProvider,
        );
        this.ArtifactsHydrated = true;
        this.cdr?.markForCheck();
    }

    public GetArtifactBadge(act: ActivityDashboardRow): ActivityArtifactBadgeState {
        return ResolveActivityArtifactBadge(act.ArtifactID, this.HydratedArtifacts, {
            hydrationComplete: this.ArtifactsHydrated,
            virtualName: act.Artifact ?? null,
        });
    }

    public FormatCardExcerpt(raw: string | null | undefined, maxLength = 220): string {
        return StripActivityMarkdownExcerpt(raw, maxLength);
    }

    public OnOpenLinkedDoc(event: { ArtifactID: string; Name: string }): void {
        OpenLinkedArtifact(event.ArtifactID, event.Name, this.navService ?? null);
    }

    public ToggleQuickComposer(): void {
        this.SetQuickComposerOpen(!this.ShowQuickComposer);
    }

    public SetQuickComposerOpen(open: boolean): void {
        this.ShowQuickComposer = open;
        try {
            UserInfoEngine.Instance.SetSettingDebounced(COMPOSER_OPEN_SETTING_KEY, JSON.stringify(open));
        } catch {
            // UserInfoEngine may not be configured in isolated unit tests.
        }
        this.cdr?.markForCheck();
    }

    public OnQuickActivityCreated(event: ActivityComposerSavedEvent): void {
        const entity = event.Activity;
        const row: ActivityDashboardRow = {
            ID: entity.ID,
            Title: entity.Title,
            Description: entity.Description,
            StartedAt: entity.StartedAt instanceof Date ? entity.StartedAt.toISOString() : String(entity.StartedAt ?? new Date().toISOString()),
            EndedAt: entity.EndedAt instanceof Date ? entity.EndedAt.toISOString() : null,
            Direction: entity.Direction,
            Status: entity.Status,
            Outcome: entity.Outcome,
            Location: entity.Location,
            ActivityTypeID: entity.ActivityTypeID,
            ActivityType: event.ActivityTypeLabel,
            Source: entity.Source,
            SourceSystem: entity.SourceSystem,
            LoggedByUser: entity.LoggedByUser,
            ArtifactID: entity.ArtifactID,
            Artifact: event.LinkedArtifact?.Name ?? entity.Artifact ?? null,
            __mj_CreatedAt: new Date().toISOString(),
        };

        if (event.LinkedArtifact && entity.ArtifactID) {
            this.HydratedArtifacts.set(NormalizeUUID(entity.ArtifactID), event.LinkedArtifact);
        }

        this.Activities = [row, ...this.Activities];
        this.computeKPIs(this.Activities);
        this.cdr?.markForCheck();
    }

    public async ToggleDrawerLinkPicker(): Promise<void> {
        this.ShowDrawerLinkPicker = !this.ShowDrawerLinkPicker;
        this.DrawerArtifactError = null;
        this.cdr?.markForCheck();
        if (this.ShowDrawerLinkPicker) {
            await this.SearchDrawerArtifacts(this.DrawerArtifactSearch);
        }
    }

    public async SearchDrawerArtifacts(term: string): Promise<void> {
        this.DrawerArtifactSearch = term;
        this.IsSearchingDrawerArtifacts = true;
        this.cdr?.markForCheck();
        try {
            this.DrawerArtifactOptions = await SearchLinkableArtifacts(term, this.activeProvider);
        } finally {
            this.IsSearchingDrawerArtifacts = false;
            this.cdr?.markForCheck();
        }
    }

    public async LinkSelectedActivityToDoc(doc: ActivityArtifactSummary): Promise<boolean> {
        if (!this.SelectedActivity || this.IsMutatingArtifact) {
            return false;
        }
        this.IsMutatingArtifact = true;
        this.DrawerArtifactError = null;
        this.cdr?.markForCheck();

        try {
            const entity = await this.loadActivityEntity(this.SelectedActivity.ID);
            if (!entity) {
                this.DrawerArtifactError = 'Could not load activity record to link MJ Doc.';
                return false;
            }
            const res = await LinkExistingArtifactToActivity(entity, doc.ID, {
                saveNow: true,
                artifactName: doc.Name,
            });
            if (!res.Success) {
                this.DrawerArtifactError = res.ErrorMessage ?? 'Failed to link MJ Doc.';
                return false;
            }
            this.HydratedArtifacts.set(NormalizeUUID(doc.ID), doc);
            this.applyRowArtifactUpdate(this.SelectedActivity.ID, doc.ID, doc.Name);
            this.ShowDrawerLinkPicker = false;
            return true;
        } finally {
            this.IsMutatingArtifact = false;
            this.cdr?.markForCheck();
        }
    }

    public async ExpandSelectedActivityToDoc(): Promise<boolean> {
        if (!this.SelectedActivity || this.IsMutatingArtifact) {
            return false;
        }
        this.IsMutatingArtifact = true;
        this.DrawerArtifactError = null;
        this.cdr?.markForCheck();

        try {
            const entity = await this.loadActivityEntity(this.SelectedActivity.ID);
            if (!entity) {
                this.DrawerArtifactError = 'Could not load activity record to expand.';
                return false;
            }
            const res = await ExpandActivityToArtifact(entity, { Provider: this.activeProvider });
            if (!res.Success || !res.ArtifactID) {
                this.DrawerArtifactError = res.ErrorMessage ?? 'Failed to expand activity into an MJ Doc.';
                return false;
            }
            const summary: ActivityArtifactSummary = {
                ID: res.ArtifactID,
                Name: res.ArtifactName ?? entity.Title,
                Type: 'Markdown Document',
            };
            this.HydratedArtifacts.set(NormalizeUUID(res.ArtifactID), summary);
            this.applyRowArtifactUpdate(this.SelectedActivity.ID, res.ArtifactID, summary.Name);
            this.ShowDrawerLinkPicker = false;
            return true;
        } finally {
            this.IsMutatingArtifact = false;
            this.cdr?.markForCheck();
        }
    }

    public async UnlinkSelectedActivityDoc(): Promise<boolean> {
        if (!this.SelectedActivity || this.IsMutatingArtifact) {
            return false;
        }
        this.IsMutatingArtifact = true;
        this.DrawerArtifactError = null;
        this.cdr?.markForCheck();

        try {
            const entity = await this.loadActivityEntity(this.SelectedActivity.ID);
            if (!entity) {
                this.DrawerArtifactError = 'Could not load activity record to unlink.';
                return false;
            }
            const res = await UnlinkArtifactFromActivity(entity, { saveNow: true });
            if (!res.Success) {
                this.DrawerArtifactError = res.ErrorMessage ?? 'Failed to unlink MJ Doc.';
                return false;
            }
            this.applyRowArtifactUpdate(this.SelectedActivity.ID, null, null);
            return true;
        } finally {
            this.IsMutatingArtifact = false;
            this.cdr?.markForCheck();
        }
    }

    private get activeProvider(): IMetadataProvider {
        return this.Provider ?? Metadata.Provider;
    }

    private restoreComposerPreference(): void {
        try {
            const raw = UserInfoEngine.Instance.GetSetting(COMPOSER_OPEN_SETTING_KEY);
            if (raw) {
                this.ShowQuickComposer = JSON.parse(raw) === true;
            }
        } catch {
            this.ShowQuickComposer = false;
        }
    }

    private async loadActivityEntity(activityID: string): Promise<mjBizAppsCommonActivityEntity | null> {
        const provider = this.activeProvider;
        const entity = await provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
            COMMON_ENTITIES.Activity,
            provider.CurrentUser,
        );
        const loaded = await entity.Load(activityID);
        return loaded ? entity : null;
    }

    private applyRowArtifactUpdate(activityID: string, artifactID: string | null, artifactName: string | null): void {
        this.Activities = this.Activities.map((row) =>
            UUIDsEqual(row.ID, activityID)
                ? { ...row, ArtifactID: artifactID, Artifact: artifactName }
                : row,
        );
        if (this.SelectedActivity && UUIDsEqual(this.SelectedActivity.ID, activityID)) {
            this.SelectedActivity = {
                ...this.SelectedActivity,
                ArtifactID: artifactID,
                Artifact: artifactName,
            };
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

        if (this.PeriodFilter.Period !== 'alltime') {
            const window = PeriodWindowOf(this.PeriodFilter, CALENDAR_YEAR_START);
            list = list.filter(a => {
                const day = (a.StartedAt || '').slice(0, 10);
                return day.length === 10 && WithinWindow(day, window);
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
        this.cdr?.markForCheck();
    }

    public OnPeriodFilterChanged(period: DashboardPeriodState): void {
        this.PeriodFilter = period;
        this.cdr?.markForCheck();
    }

    public OnSearchChanged(): void {
        this.cdr?.markForCheck();
    }

    /** Whether this row is the open one. IDs compare case-insensitively. */
    public IsSelected(act: ActivityDashboardRow): boolean {
        return this.SelectedActivity !== null && UUIDsEqual(this.SelectedActivity.ID, act.ID);
    }

    public SelectActivity(act: ActivityDashboardRow): void {
        this.SelectedActivity = act;
        this.ShowDrawerLinkPicker = false;
        this.DrawerArtifactError = null;
        this.cdr?.markForCheck();
    }

    public CloseDrawer(): void {
        this.SelectedActivity = null;
        this.ShowDrawerLinkPicker = false;
        this.DrawerArtifactError = null;
        this.cdr?.markForCheck();
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
