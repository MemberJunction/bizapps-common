import { Component, ChangeDetectionStrategy, ChangeDetectorRef, inject, OnInit, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CompositeKey, RunView } from '@memberjunction/core';
import { RegisterClassEx } from '@memberjunction/global';
import { BaseFormPanel, BaseFormsModule, FormNavigationEvent } from '@memberjunction/ng-base-forms';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { EscapeFilterValue } from '../../data/directory-stats';

interface ActivityFileRow {
    ID: string;
    ActivityID: string;
    FileID: string;
    Kind: 'Attachment' | 'Body' | 'Ics';
    File: string | null;
    ContentType?: string | null;
    __mj_CreatedAt?: Date | null;
}

/**
 * Activity Files & Attachments Panel.
 *
 * Displays attached documents, email body previews, and ICS calendar files
 * linked to the activity record.
 */
@RegisterClassEx(BaseFormPanel, {
    key: 'form-panel:Activities:files',
    metadata: {
        entity: 'MJ_BizApps_Common: Activities',
        slot: 'after-fields',
        sortKey: 70,
        contributionKey: 'files',
        sectionKey: 'activityFiles',
        whenEmpty: 'more',
        relatedEntity: 'MJ_BizApps_Common: Activity Files',
        relatedJoinField: 'ActivityID',
    },
})
@Component({
    selector: 'bizapps-activity-files-panel',
    standalone: true,
    imports: [CommonModule, BaseFormsModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <mj-collapsible-panel
            SectionKey="activityFiles"
            SectionName="Files"
            Icon="fa-solid fa-paperclip"
            [Form]="FormComponent"
            [FormContext]="FormContext"
            [BadgeCount]="Files.length"
            [DefaultExpanded]="true">
            @if (!Record.IsSaved) {
                <p class="mja-files-empty">Save the activity to link or attach files.</p>
            } @else if (IsLoading) {
                <div class="mja-files-loading">Loading attachments...</div>
            } @else if (Files.length === 0) {
                <p class="mja-files-empty">No attachments or file records linked yet.</p>
            } @else {
                <div class="mja-files-grid">
                    @for (file of Files; track file.ID) {
                        <div class="mja-file-card" (click)="OpenFile(file)">
                            <div class="mja-file-card__icon" [attr.data-kind]="file.Kind.toLowerCase()">
                                <i [class]="getFileIcon(file)"></i>
                            </div>
                            <div class="mja-file-card__meta">
                                <div class="mja-file-card__name">
                                    {{ file.File || 'Unnamed File' }}
                                </div>
                                <div class="mja-file-card__sub">
                                    <span class="mja-file-badge" [attr.data-kind]="file.Kind.toLowerCase()">
                                        {{ file.Kind }}
                                    </span>
                                    @if (file.__mj_CreatedAt) {
                                        <span class="mja-file-date">{{ file.__mj_CreatedAt | date:'shortDate' }}</span>
                                    }
                                </div>
                            </div>
                            <i class="fa-solid fa-arrow-up-right-from-square mja-file-card__open"></i>
                        </div>
                    }
                </div>
            }
        </mj-collapsible-panel>
    `,
    styles: [`
        :host { display: block; width: 100%; margin-bottom: var(--mj-space-4, 16px); }

        .mja-files-empty {
            color: var(--mj-text-muted);
            font-size: 13px;
            margin: 0;
            padding: 8px 0;
        }

        .mja-files-loading {
            color: var(--mj-text-muted);
            font-size: 13px;
            padding: 12px 0;
        }

        .mja-files-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 10px;
            padding: 4px 0;
        }

        .mja-file-card {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 14px;
            border-radius: var(--mj-radius-md, 8px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .mja-file-card:hover {
            border-color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
        }

        .mja-file-card__icon {
            width: 36px;
            height: 36px;
            border-radius: var(--mj-radius-sm, 6px);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            flex-shrink: 0;
            background: var(--mj-bg-surface-sunken);
            color: var(--mj-text-secondary);
        }

        .mja-file-card__icon[data-kind="body"] { background: var(--mj-status-info-bg); color: var(--mj-brand-primary); }
        .mja-file-card__icon[data-kind="attachment"] { background: var(--mj-status-warning-bg); color: var(--mj-status-warning); }
        .mja-file-card__icon[data-kind="ics"] { background: color-mix(in srgb, var(--mj-brand-accent) 12%, var(--mj-bg-surface)); color: var(--mj-brand-accent); }

        .mja-file-card__meta {
            display: flex;
            flex-direction: column;
            gap: 2px;
            flex: 1;
            min-width: 0;
        }

        .mja-file-card__name {
            font-size: 13px;
            font-weight: 600;
            color: var(--mj-text-primary);
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .mja-file-card__sub {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 11px;
            color: var(--mj-text-muted);
        }

        .mja-file-badge {
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            padding: 1px 5px;
            border-radius: 4px;
            background: var(--mj-bg-surface-sunken);
            color: var(--mj-text-secondary);
        }

        .mja-file-badge[data-kind="body"] { background: var(--mj-status-info-bg); color: var(--mj-status-info-text); }
        .mja-file-badge[data-kind="attachment"] { background: var(--mj-status-warning-bg); color: var(--mj-status-warning-text); }
        .mja-file-badge[data-kind="ics"] { background: color-mix(in srgb, var(--mj-brand-accent) 14%, var(--mj-bg-surface)); color: var(--mj-brand-accent); }

        .mja-file-date {
            color: var(--mj-text-muted);
        }

        .mja-file-card__open {
            font-size: 12px;
            color: var(--mj-text-muted);
            opacity: 0.6;
        }

        .mja-file-card:hover .mja-file-card__open {
            opacity: 1;
            color: var(--mj-brand-primary);
        }
    `]
})
export class ActivityFilesPanel extends BaseFormPanel<mjBizAppsCommonActivityEntity> implements OnInit, OnChanges {
    private cdr = inject(ChangeDetectorRef);
    public Files: ActivityFileRow[] = [];
    public IsLoading = false;

    ngOnInit(): void {
        this.loadFiles();
    }

    ngOnChanges(changes: SimpleChanges): void {
        if (changes['Record'] && this.Record?.IsSaved) {
            this.loadFiles();
        }
    }

    public async loadFiles(): Promise<void> {
        if (!this.Record?.ID || !this.Record.IsSaved) return;
        this.IsLoading = true;
        this.cdr.markForCheck();

        try {
            const rv = new RunView();
            const res = await rv.RunView<ActivityFileRow>({
                EntityName: 'MJ_BizApps_Common: Activity Files',
                ExtraFilter: `ActivityID = '${EscapeFilterValue(this.Record.ID)}'`,
                OrderBy: '__mj_CreatedAt DESC',
                ResultType: 'simple',
            });
            if (res.Success && res.Results) {
                this.Files = res.Results;
            }
        } catch {
            // ignore
        } finally {
            this.IsLoading = false;
            this.cdr.markForCheck();
        }
    }

    public OpenFile(file: ActivityFileRow): void {
        if (file.FileID && this.FormComponent?.OnFormNavigate) {
            this.FormComponent.OnFormNavigate({
                Kind: 'record',
                EntityName: 'MJ: Files',
                PrimaryKey: CompositeKey.FromKeyValuePair('ID', file.FileID),
            });
        }
    }

    public getFileIcon(file: ActivityFileRow): string {
        if (file.Kind === 'Body') return 'fa-solid fa-file-lines';
        if (file.Kind === 'Ics') return 'fa-solid fa-calendar-check';
        const name = (file.File || '').toLowerCase();
        if (name.endsWith('.pdf')) return 'fa-solid fa-file-pdf';
        if (name.endsWith('.doc') || name.endsWith('.docx')) return 'fa-solid fa-file-word';
        if (name.endsWith('.xls') || name.endsWith('.xlsx') || name.endsWith('.csv')) return 'fa-solid fa-file-excel';
        if (name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.svg')) return 'fa-solid fa-file-image';
        return 'fa-solid fa-file';
    }
}
