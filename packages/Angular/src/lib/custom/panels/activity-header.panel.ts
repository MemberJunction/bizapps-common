import { Component, ChangeDetectionStrategy, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel } from '@memberjunction/ng-base-forms';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';

/**
 * Activity Form Hero Banner.
 *
 * Renders a rich summary card at the top of the Activity form showing the
 * Activity Type icon/color, Direction, Status pill, Outcome badge, and timestamp.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Activities:header',
    metadata: {
        entity: 'MJ_BizApps_Common: Activities',
        slot: 'before-fields',
        sortKey: 100,
        contributionKey: 'header',
        replacesSectionKey: 'details',
    },
})
@Component({
    selector: 'bizapps-activity-header-panel',
    standalone: true,
    imports: [CommonModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <div class="mja-hero" [attr.data-direction]="Record.Direction.toLowerCase()">
            <div class="mja-hero__top">
                <div class="mja-hero__icon" [style.background-color]="typeColor">
                    <i [class]="typeIcon" aria-hidden="true"></i>
                </div>
                <div class="mja-hero__meta">
                    <div class="mja-hero__title-row">
                        <h2 class="mja-hero__title">{{ Record.Title || 'Untitled Activity' }}</h2>
                        <div class="mja-hero__badges">
                            @if (Record.Direction) {
                                <span class="mja-badge mja-badge--direction" [attr.data-dir]="Record.Direction">
                                    <i [class]="directionIcon"></i> {{ Record.Direction }}
                                </span>
                            }
                            @if (Record.Status) {
                                <span class="mja-badge mja-badge--status" [attr.data-status]="Record.Status">
                                    {{ Record.Status }}
                                </span>
                            }
                            @if (Record.Outcome) {
                                <span class="mja-badge mja-badge--outcome">
                                    {{ Record.Outcome }}
                                </span>
                            }
                        </div>
                    </div>
                    <div class="mja-hero__sub">
                        @if (Record.StartedAt) {
                            <span class="mja-hero__time">
                                <i class="fa-regular fa-clock"></i> {{ Record.StartedAt | date:'medium' }}
                            </span>
                        }
                        @if (Record.Location) {
                            <span class="mja-hero__location">
                                <i class="fa-solid fa-location-dot"></i> {{ Record.Location }}
                            </span>
                        }
                        @if (Record.Source && Record.Source !== 'Manual') {
                            <span class="mja-hero__source">
                                <i class="fa-solid fa-cloud-arrow-down"></i> Synced from {{ Record.SourceSystem || Record.Source }}
                            </span>
                        }
                    </div>
                </div>
            </div>

            @if (Record.Description) {
                <div class="mja-hero__desc">
                    {{ Record.Description }}
                </div>
            }
        </div>
    `,
    styles: [`
        :host { display: block; width: 100%; margin-bottom: var(--mj-space-4, 16px); }

        .mja-hero {
            background: var(--mj-bg-surface-card, #ffffff);
            border: 1px solid var(--mj-border-default, #e2e8f0);
            border-radius: var(--mj-radius-lg, 12px);
            padding: var(--mj-space-4, 16px) var(--mj-space-5, 20px);
            display: flex;
            flex-direction: column;
            gap: var(--mj-space-3, 12px);
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        }

        .mja-hero__top {
            display: flex;
            align-items: flex-start;
            gap: var(--mj-space-4, 16px);
        }

        .mja-hero__icon {
            width: 44px;
            height: 44px;
            border-radius: var(--mj-radius-md, 8px);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            flex-shrink: 0;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12);
        }

        .mja-hero__meta {
            display: flex;
            flex-direction: column;
            gap: 4px;
            flex: 1;
            min-width: 0;
        }

        .mja-hero__title-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .mja-hero__title {
            margin: 0;
            font-size: 17px;
            font-weight: 700;
            color: var(--mj-text-primary, #0f172a);
        }

        .mja-hero__badges {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
        }

        .mja-badge {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 2px 8px;
            border-radius: 9999px;
            font-size: 11px;
            font-weight: 600;
            text-transform: capitalize;
        }

        .mja-badge--direction[data-dir="Inbound"] { background: #e0f2fe; color: #0369a1; }
        .mja-badge--direction[data-dir="Outbound"] { background: #dcfce7; color: #15803d; }
        .mja-badge--direction[data-dir="Internal"] { background: #f1f5f9; color: #475569; }

        .mja-badge--status[data-status="Completed"] { background: #dcfce7; color: #166534; }
        .mja-badge--status[data-status="Scheduled"] { background: #fef3c7; color: #92400e; }
        .mja-badge--status[data-status="Cancelled"] { background: #fee2e2; color: #991b1b; }
        .mja-badge--status[data-status="Logged"] { background: #f1f5f9; color: #334155; }

        .mja-badge--outcome {
            background: #ede9fe;
            color: #6b21a8;
        }

        .mja-hero__sub {
            display: flex;
            align-items: center;
            gap: 16px;
            font-size: 12px;
            color: var(--mj-text-muted, #64748b);
            flex-wrap: wrap;
        }

        .mja-hero__desc {
            padding-top: var(--mj-space-3, 10px);
            border-top: 1px solid var(--mj-border-subtle, #f1f5f9);
            font-size: 13px;
            color: var(--mj-text-secondary, #334155);
            line-height: 1.5;
            white-space: pre-wrap;
        }
    `]
})
export class ActivityHeaderPanel extends BaseFormPanel<mjBizAppsCommonActivityEntity> {
    public get typeIcon(): string {
        return 'fa-solid fa-bolt';
    }

    public get typeColor(): string {
        return '#0284c7';
    }

    public get directionIcon(): string {
        switch (this.Record.Direction) {
            case 'Inbound': return 'fa-solid fa-arrow-down-left';
            case 'Outbound': return 'fa-solid fa-arrow-up-right';
            default: return 'fa-solid fa-arrows-left-right';
        }
    }
}
