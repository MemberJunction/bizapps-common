import { Component, ChangeDetectionStrategy, ChangeDetectorRef, inject, OnInit, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey, RunView } from '@memberjunction/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel, BaseFormsModule, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';

interface ActivityLinkRow {
    ID: string;
    Role: string;
    EntityID: string | null;
    RecordID: string | null;
    Entity: string | null;
    IdentityKind: string | null;
    IdentityValue: string | null;
}

/**
 * Activity Links & Participants Panel.
 *
 * Renders structured participant and regarding entity cards with
 * role badges and clickable deep links to associated records.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Activities:links',
    metadata: {
        entity: 'MJ_BizApps_Common: Activities',
        slot: 'after-fields',
        sortKey: 80,
        contributionKey: 'links',
        relatedEntity: 'MJ_BizApps_Common: Activity Links',
        relatedJoinField: 'ActivityID',
    },
})
@Component({
    selector: 'bizapps-activity-links-panel',
    standalone: true,
    imports: [CommonModule, BaseFormsModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-collapsible-panel
            SectionKey="activityParticipants"
            SectionName="Participants"
            Icon="fa-solid fa-users"
            [Form]="FormComponent"
            [FormContext]="FormContext"
            [DefaultExpanded]="true">
            @if (!Record.IsSaved) {
                <p class="mja-empty-sub">Save the activity to link people, organizations, or deals.</p>
            } @else if (IsLoading) {
                <div class="mja-loading-strip">Loading participants...</div>
            } @else if (Links.length === 0) {
                <p class="mja-empty-sub">No linked participants or records yet.</p>
            } @else {
                <div class="mja-links-grid">
                    @for (link of Links; track link.ID) {
                        <div class="mja-link-card" (click)="OpenLink(link)">
                            <div class="mja-link-card__role" [attr.data-role]="link.Role.toLowerCase()">
                                {{ link.Role }}
                            </div>
                            <div class="mja-link-card__body">
                                <div class="mja-link-card__name">
                                    <i [class]="getIconForEntity(link.Entity)"></i>
                                    <span>{{ link.IdentityValue || link.Entity || 'Linked Record' }}</span>
                                </div>
                                @if (link.Entity) {
                                    <span class="mja-link-card__entity">{{ link.Entity }}</span>
                                }
                            </div>
                            <i class="fa-solid fa-arrow-up-right-from-square mja-link-card__open"></i>
                        </div>
                    }
                </div>
            }
        </mj-collapsible-panel>
    `,
    styles: [`
        :host { display: block; width: 100%; margin-bottom: var(--mj-space-4, 16px); }

        .mja-empty-sub {
            color: var(--mj-text-muted, #64748b);
            font-size: 13px;
            margin: 0;
            padding: 8px 0;
        }

        .mja-loading-strip {
            color: var(--mj-text-muted, #64748b);
            font-size: 13px;
            padding: 12px 0;
        }

        .mja-links-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
            gap: 10px;
            padding: 4px 0;
        }

        .mja-link-card {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 12px;
            border-radius: var(--mj-radius-md, 8px);
            border: 1px solid var(--mj-border-default, #e2e8f0);
            background: var(--mj-bg-surface, #ffffff);
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .mja-link-card:hover {
            border-color: var(--mj-brand-primary, #0284c7);
            background: var(--mj-bg-surface-hover, #f8fafc);
        }

        .mja-link-card__role {
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            padding: 2px 6px;
            border-radius: 4px;
            background: #f1f5f9;
            color: #475569;
            flex-shrink: 0;
        }

        .mja-link-card__role[data-role="regarding"] { background: #e0f2fe; color: #0369a1; }
        .mja-link-card__role[data-role="organizer"] { background: #fef3c7; color: #92400e; }
        .mja-link-card__role[data-role="attendee"] { background: #dcfce7; color: #166534; }

        .mja-link-card__body {
            display: flex;
            flex-direction: column;
            gap: 2px;
            flex: 1;
            min-width: 0;
        }

        .mja-link-card__name {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
            font-weight: 600;
            color: var(--mj-text-primary, #0f172a);
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .mja-link-card__entity {
            font-size: 11px;
            color: var(--mj-text-muted, #64748b);
        }

        .mja-link-card__open {
            font-size: 12px;
            color: var(--mj-text-muted, #94a3b8);
            opacity: 0.6;
        }

        .mja-link-card:hover .mja-link-card__open {
            opacity: 1;
            color: var(--mj-brand-primary, #0284c7);
        }
    `]
})
export class ActivityLinksPanel extends BaseFormPanel<mjBizAppsCommonActivityEntity> implements OnInit, OnChanges {
    private cdr = inject(ChangeDetectorRef);
    public Links: ActivityLinkRow[] = [];
    public IsLoading = false;

    ngOnInit(): void {
        this.loadLinks();
    }

    ngOnChanges(changes: SimpleChanges): void {
        if (changes['Record'] && this.Record?.IsSaved) {
            this.loadLinks();
        }
    }

    public async loadLinks(): Promise<void> {
        if (!this.Record?.ID || !this.Record.IsSaved) return;
        this.IsLoading = true;
        this.cdr.markForCheck();

        try {
            const rv = new RunView();
            const res = await rv.RunView<ActivityLinkRow>({
                EntityName: 'MJ_BizApps_Common: Activity Links',
                ExtraFilter: `ActivityID = '${this.Record.ID}'`,
                OrderBy: 'Sequence ASC, __mj_CreatedAt ASC',
                ResultType: 'simple',
            });
            if (res.Success && res.Results) {
                this.Links = res.Results;
            }
        } catch {
            // ignore
        } finally {
            this.IsLoading = false;
            this.cdr.markForCheck();
        }
    }

    public OpenLink(link: ActivityLinkRow): void {
        if (link.Entity && link.RecordID && this.FormComponent?.OnFormNavigate) {
            this.FormComponent.OnFormNavigate({
                Kind: 'record',
                EntityName: link.Entity,
                PrimaryKey: CompositeKey.FromKeyValuePair('ID', link.RecordID),
            });
        }
    }

    public getIconForEntity(entity: string | null): string {
        if (!entity) return 'fa-solid fa-link';
        const lower = entity.toLowerCase();
        if (lower.includes('person') || lower.includes('people')) return 'fa-solid fa-user';
        if (lower.includes('organization') || lower.includes('company')) return 'fa-solid fa-building';
        if (lower.includes('deal') || lower.includes('opportunity')) return 'fa-solid fa-handshake';
        if (lower.includes('order')) return 'fa-solid fa-bag-shopping';
        return 'fa-solid fa-link';
    }
}
