import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Optional, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey, LogError, Metadata, RunView } from '@memberjunction/core';
import { IsValidUUID, UUIDsEqual } from '@memberjunction/global';
import { UserInfoEngine } from '@memberjunction/core-entities';
import { BaseFormsModule, FormContext, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { LinkDirectivesModule } from '@memberjunction/ng-link-directives';
import { NavigationService } from '@memberjunction/ng-shared';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { ActivityArtifactBadgeComponent } from '../activity-artifact-badge/activity-artifact-badge.component'; import { LoadActivityArtifactsByIDs, OpenLinkedArtifact, ResolveActivityArtifactBadge, type ActivityArtifactBadgeState, type ActivityArtifactSummary } from '../../data/activity-artifact';
const ACTIVITIES_ENTITY = 'MJ_BizApps_Common: Activities';

export interface ActivityTypeStyle {
    icon: string;
    color: string;
    bgGradient: string;
}

const ACTIVITY_TYPE_STYLES: Record<string, ActivityTypeStyle> = {
    email: {
        icon: 'fa-solid fa-envelope',
        color: 'var(--mj-brand-primary)',
        bgGradient: 'linear-gradient(135deg, var(--mj-brand-primary) 0%, var(--mj-brand-primary-hover) 100%)',
    },
    call: {
        icon: 'fa-solid fa-phone',
        color: 'var(--mj-status-success)',
        bgGradient: 'linear-gradient(135deg, var(--mj-status-success) 0%, var(--mj-color-success-500) 100%)',
    },
    meeting: {
        icon: 'fa-solid fa-calendar-days',
        color: 'var(--mj-color-indigo-600)',
        bgGradient: 'linear-gradient(135deg, var(--mj-color-indigo-600) 0%, var(--mj-color-indigo-500) 100%)',
    },
    note: {
        icon: 'fa-solid fa-note-sticky',
        color: 'var(--mj-status-warning)',
        bgGradient: 'linear-gradient(135deg, var(--mj-status-warning) 0%, var(--mj-color-warning-500) 100%)',
    },
    sms: {
        icon: 'fa-solid fa-comment-sms',
        color: 'var(--mj-color-violet-600)',
        bgGradient: 'linear-gradient(135deg, var(--mj-color-violet-600) 0%, var(--mj-color-violet-500) 100%)',
    },
    chat: {
        icon: 'fa-solid fa-comments',
        color: 'var(--mj-brand-accent)',
        bgGradient: 'linear-gradient(135deg, var(--mj-brand-accent) 0%, var(--mj-brand-accent-hover) 100%)',
    },
    task: {
        icon: 'fa-solid fa-square-check',
        color: 'var(--mj-status-info)',
        bgGradient: 'linear-gradient(135deg, var(--mj-status-info) 0%, var(--mj-color-info-400) 100%)',
    },
};

const DEFAULT_STYLE: ActivityTypeStyle = {
    icon: 'fa-solid fa-bolt',
    color: 'var(--mj-status-info)',
    bgGradient: 'linear-gradient(135deg, var(--mj-status-info) 0%, var(--mj-brand-primary) 100%)',
};

/**
 * Presentational Activity identity strip.
 * Provides type-aware dynamic iconography, directional badges, status tones,
 * computed duration timing, meeting URLs, linked MJ Doc badge, and participant/source summaries.
 */
@Component({
    standalone: true, changeDetection: ChangeDetectionStrategy.OnPush,
    selector: 'bizapps-activity-identity',
    imports: [CommonModule, BaseFormsModule, LinkDirectivesModule, ActivityArtifactBadgeComponent],
    templateUrl: './activity-identity.component.html',
    styleUrls: ['./identity-header.css'],
})
export class ActivityIdentityComponent implements OnInit {
    @Input({ required: true }) Record!: mjBizAppsCommonActivityEntity;
    @Input() EditMode = false;
    @Input() FormContext?: FormContext;
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    public Collapsed = false;

    private parentTitle: string | null = null;
    private parentTitleFor: string | null = null;

    public ngOnInit(): void {
        void this.loadParentTitle(); void this.loadLinkedArtifact();
        const raw = UserInfoEngine.Instance.GetSetting('mj.identityHeader.collapsed.activity');
        if (raw) {
            try {
                this.Collapsed = JSON.parse(raw) === true;
            } catch {
                this.Collapsed = false;
            }
        }
    }

    public ToggleCollapsed(): void {
        this.Collapsed = !this.Collapsed;
        UserInfoEngine.Instance.SetSettingDebounced(
            'mj.identityHeader.collapsed.activity',
            JSON.stringify(this.Collapsed),
        );
    }

    public get TypeStyle(): ActivityTypeStyle {
        const typeName = (this.Record.ActivityType || '').toLowerCase().trim();
        return ACTIVITY_TYPE_STYLES[typeName] || DEFAULT_STYLE;
    }

    public get TypeIcon(): string {
        return this.TypeStyle.icon;
    }

    public get TypeBackground(): string {
        return this.TypeStyle.bgGradient;
    }

    public get DirectionIcon(): string {
        switch (this.Record.Direction) {
            case 'Inbound':
                return 'fa-solid fa-arrow-down-left';
            case 'Outbound':
                return 'fa-solid fa-arrow-up-right';
            case 'Internal':
            default:
                return 'fa-solid fa-arrows-left-right';
        }
    }

    public get StatusTone(): 'success' | 'warning' | 'danger' | 'info' | 'muted' {
        switch (this.Record.Status) {
            case 'Completed':
                return 'success';
            case 'Scheduled':
                return 'warning';
            case 'Cancelled':
            case 'Failed':
                return 'danger';
            case 'Logged':
                return 'info';
            default:
                return 'muted';
        }
    }

    public get SentimentDisplay(): string | null {
        if (this.Record.SentimentScore === null || this.Record.SentimentScore === undefined) return null;
        const score = Number(this.Record.SentimentScore);
        if (isNaN(score)) return null;
        const sign = score > 0 ? '+' : '';
        return `${sign}${score.toFixed(2)}`;
    }

    public get SentimentTone(): 'success' | 'danger' | 'info' {
        const score = Number(this.Record.SentimentScore ?? 0);
        // UX: Sentiment badge classification thresholds (+0.25 positive, -0.25 negative).
        if (score >= 0.25) return 'success';
        if (score <= -0.25) return 'danger';
        return 'info';
    }

    public get SentimentIcon(): string {
        const score = Number(this.Record.SentimentScore ?? 0);
        // UX: Sentiment icon classification thresholds (+0.25 smile, -0.25 frown).
        if (score >= 0.25) return 'fa-solid fa-face-smile';
        if (score <= -0.25) return 'fa-solid fa-face-frown';
        return 'fa-solid fa-face-meh';
    }

    public get DurationText(): string | null {
        if (!this.Record.StartedAt || !this.Record.EndedAt) return null;
        const start = new Date(this.Record.StartedAt).getTime();
        const end = new Date(this.Record.EndedAt).getTime();
        if (isNaN(start) || isNaN(end) || end < start) return null;

        const diffMinutes = Math.round((end - start) / (1000 * 60));
        if (diffMinutes === 0) return '< 1 min';
        if (diffMinutes < 60) return `${diffMinutes}m`;
        const hours = Math.floor(diffMinutes / 60);
        const mins = diffMinutes % 60;
        return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
    }

    public get MeetingURL(): string | null {
        if (!this.Record.Details) return null;
        try {
            const parsed = JSON.parse(this.Record.Details) as { MeetingURL?: string; JoinURL?: string; ConferenceURL?: string };
            return parsed.MeetingURL || parsed.JoinURL || parsed.ConferenceURL || null;
        } catch {
            return null;
        }
    }

    public get LocationDisplay(): string | null {
        return this.Record.Location || this.Record.Address || null;
    }

    public get SourceDisplay(): string {
        if (this.Record.SourceSystem) {
            return `Synced from ${this.Record.SourceSystem}`;
        }
        if (this.Record.Source && this.Record.Source !== 'Manual') {
            return `Synced (${this.Record.Source})`;
        }
        return 'Manual';
    }

    /**
     * The "Thread / Parent" label. Reads `ParentActivityID` and the parent's own Title, never the
     * virtual `ParentActivity` name field: V202609112330 removes that field on hosts whose
     * `vwActivities` lacks the column, where it always reads null and hid the link.
     */
    public get ParentActivityLabel(): string {
        const loaded = this.parentTitle && UUIDsEqual(this.parentTitleFor, this.Record.ParentActivityID);
        return loaded ? (this.parentTitle as string) : 'Parent activity';
    }

    private async loadParentTitle(): Promise<void> {
        const parentID = this.Record.ParentActivityID;
        if (!parentID) {
            return;
        }
        if (!IsValidUUID(parentID)) {
            // Checked before it goes into the filter; the link still renders with a generic label.
            LogError(`ActivityIdentity: ParentActivityID '${parentID}' is not a UUID; not loading its title`);
            return;
        }
        const result = await new RunView(this.Record.RunViewProviderToUse).RunView<{ Title: string | null }>({
            EntityName: ACTIVITIES_ENTITY,
            Fields: ['Title'],
            ExtraFilter: `ID = '${parentID.trim()}'`,
            ResultType: 'simple',
            MaxRows: 1,
        });
        if (!result.Success) {
            // The link still renders, with a generic label; only the parent's name is missing.
            LogError(`ActivityIdentity: failed to load parent activity '${parentID}': ${result.ErrorMessage ?? 'error'}`);
            return;
        }
        this.parentTitle = result.Results[0]?.Title || null;
        this.parentTitleFor = parentID;
        this.cdr?.markForCheck();
    }

    public OnParentActivityClick(event: MouseEvent): void {
        const id = this.Record.ParentActivityID;
        if (!id) return;
        event.preventDefault();
        event.stopPropagation();
        this.Navigate.emit({
            Kind: 'record',
            EntityName: ACTIVITIES_ENTITY,
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', id),
            OpenInNewTab: event.ctrlKey || event.metaKey,
        });
    }

    public HydratedArtifacts = new Map<string, ActivityArtifactSummary>();
    public ArtifactHydrated = false;

    constructor(
        @Optional() private readonly cdr?: ChangeDetectorRef,
        @Optional() private readonly navService?: NavigationService,
    ) {}

    public get LinkedArtifactBadge(): ActivityArtifactBadgeState {
        return ResolveActivityArtifactBadge(this.Record?.ArtifactID, this.HydratedArtifacts, {
            hydrationComplete: this.ArtifactHydrated,
            virtualName: this.Record?.Artifact ?? null,
        });
    }

    public OnOpenLinkedDoc(event: { ArtifactID: string; Name: string }): void {
        OpenLinkedArtifact(event.ArtifactID, event.Name, this.navService ?? null, (nav) => this.Navigate.emit(nav));
    }

    private async loadLinkedArtifact(): Promise<void> {
        const artifactID = this.Record?.ArtifactID;
        if (!artifactID) {
            this.ArtifactHydrated = true;
            return;
        }
        this.HydratedArtifacts = await LoadActivityArtifactsByIDs([artifactID], Metadata.Provider);
        this.ArtifactHydrated = true;
        this.cdr?.markForCheck();
    }
}
