import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey } from '@memberjunction/core';
import { UserInfoEngine } from '@memberjunction/core-entities';
import { BaseFormsModule, FormContext, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import { LinkDirectivesModule } from '@memberjunction/ng-link-directives';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';

export interface ActivityTypeStyle {
    icon: string;
    color: string;
    bgGradient: string;
}

const ACTIVITY_TYPE_STYLES: Record<string, ActivityTypeStyle> = {
    email: {
        icon: 'fa-solid fa-envelope',
        color: '#2563eb',
        bgGradient: 'linear-gradient(135deg, #2563eb 0%, #3b82f6 100%)',
    },
    call: {
        icon: 'fa-solid fa-phone',
        color: '#059669',
        bgGradient: 'linear-gradient(135deg, #059669 0%, #10b981 100%)',
    },
    meeting: {
        icon: 'fa-solid fa-calendar-days',
        color: '#4f46e5',
        bgGradient: 'linear-gradient(135deg, #4f46e5 0%, #6366f1 100%)',
    },
    note: {
        icon: 'fa-solid fa-note-sticky',
        color: '#d97706',
        bgGradient: 'linear-gradient(135deg, #d97706 0%, #f59e0b 100%)',
    },
    sms: {
        icon: 'fa-solid fa-comment-sms',
        color: '#7c3aed',
        bgGradient: 'linear-gradient(135deg, #7c3aed 0%, #8b5cf6 100%)',
    },
    chat: {
        icon: 'fa-solid fa-comments',
        color: '#0d9488',
        bgGradient: 'linear-gradient(135deg, #0d9488 0%, #14b8a6 100%)',
    },
    task: {
        icon: 'fa-solid fa-square-check',
        color: '#0284c7',
        bgGradient: 'linear-gradient(135deg, #0284c7 0%, #38bdf8 100%)',
    },
};

const DEFAULT_STYLE: ActivityTypeStyle = {
    icon: 'fa-solid fa-bolt',
    color: '#0284c7',
    bgGradient: 'linear-gradient(135deg, #0284c7 0%, #0ea5e9 100%)',
};

/**
 * Presentational Activity identity strip.
 * Provides type-aware dynamic iconography, directional badges, status tones,
 * computed duration timing, meeting URLs, and participant/source summaries.
 */
@Component({
    standalone: true,
    selector: 'bizapps-activity-identity',
    imports: [CommonModule, BaseFormsModule, LinkDirectivesModule],
    templateUrl: './activity-identity.component.html',
    styleUrls: ['./identity-header.css'],
})
export class ActivityIdentityComponent implements OnInit {
    @Input({ required: true }) Record!: mjBizAppsCommonActivityEntity;
    @Input() EditMode = false;
    @Input() FormContext?: FormContext;
    @Output() Navigate = new EventEmitter<FormNavigationEvent>();

    public Collapsed = false;

    public ngOnInit(): void {
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
            const parsed = JSON.parse(this.Record.Details);
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

    public OnParentActivityClick(event: MouseEvent): void {
        const id = this.Record.ParentActivityID;
        if (!id) return;
        event.preventDefault();
        event.stopPropagation();
        this.Navigate.emit({
            Kind: 'record',
            EntityName: 'MJ_BizApps_Common: Activities',
            PrimaryKey: CompositeKey.FromKeyValuePair('ID', id),
            OpenInNewTab: event.ctrlKey || event.metaKey,
        });
    }
}
