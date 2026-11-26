import {
    ChangeDetectionStrategy,
    ChangeDetectorRef,
    Component,
    EventEmitter,
    Input,
    OnInit,
    Optional,
    Output,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IMetadataProvider, Metadata } from '@memberjunction/core';
import { SharedGenericModule } from '@memberjunction/ng-shared-generic';
import { MJButtonDirective } from '@memberjunction/ng-ui-components';
import { CommonEngine, type mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { UUIDsEqual } from '@memberjunction/global';
import {
    SaveQuickActivity,
    SearchLinkableArtifacts,
    StripActivityMarkdownExcerpt,
    type ActivityArtifactSummary,
} from '../../data/activity-artifact';

/** Quick-capture type chip preset matching seeded `MJ_BizApps_Common: Activity Types`. */
export interface QuickActivityTypeOption {
    Code: 'Note' | 'Call' | 'Meeting' | 'Email';
    Label: string;
    Icon: string;
    DefaultID: string;
}

/** Event emitted after a quick Activity is successfully saved. */
export interface ActivityComposerSavedEvent {
    Activity: mjBizAppsCommonActivityEntity;
    ActivityTypeLabel: string;
    LinkedArtifact: ActivityArtifactSummary | null;
}

const DEFAULT_QUICK_TYPES: ReadonlyArray<QuickActivityTypeOption> = [
    { Code: 'Note', Label: 'Note', Icon: 'fa-solid fa-note-sticky', DefaultID: '3569BFCA-CF4D-4F3A-ADE8-FE29F2F30A65' },
    { Code: 'Call', Label: 'Call', Icon: 'fa-solid fa-phone', DefaultID: '09233D7A-5A96-4F39-B2BF-177D8B55B220' },
    { Code: 'Meeting', Label: 'Meeting', Icon: 'fa-solid fa-calendar-check', DefaultID: '40E239B0-20C0-4A12-8014-D82EBCE240DC' },
    { Code: 'Email', Label: 'Email', Icon: 'fa-solid fa-envelope', DefaultID: '5C0674D6-A07B-447B-8755-66BE48B38303' },
];

/**
 * Frictionless <2s Activity Quick-Capture Composer.
 *
 * Strictly obeys the Category B Hybrid Spine rule:
 * - Quick Note, Call, Meeting, and Email entries persist with `ArtifactID = null` by default.
 * - NEVER auto-creates an `MJ: Artifacts` record on quick capture.
 * - Offers a collapsed, strictly opt-in "Link existing MJ Doc" picker for Activities that reference
 *   an existing long-form document.
 * - Uses semantic `--mj-*` CSS custom properties exclusively and `<mj-loading>` for wait states.
 */
@Component({
    selector: 'bizapps-activity-composer',
    standalone: true,
    imports: [CommonModule, FormsModule, MJButtonDirective, SharedGenericModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <section class="mjac-card" aria-label="Quick Activity Composer">
            <div class="mjac-top">
                <div class="mjac-types" role="radiogroup" aria-label="Activity type">
                    @for (opt of TypeOptions; track opt.Code) {
                        <button
                            type="button"
                            class="mjac-type-chip"
                            [class.mjac-type-chip--active]="SelectedTypeCode === opt.Code"
                            [attr.aria-pressed]="SelectedTypeCode === opt.Code"
                            (click)="SelectType(opt.Code)">
                            <i [class]="opt.Icon" aria-hidden="true"></i>
                            <span>{{ opt.Label }}</span>
                        </button>
                    }
                </div>

                <div class="mjac-dir">
                    <label class="mjac-sr-only" for="mjac-direction">Direction</label>
                    <select
                        id="mjac-direction"
                        class="mjac-select"
                        [(ngModel)]="Direction">
                        <option value="Internal">Internal</option>
                        <option value="Outbound">Outbound</option>
                        <option value="Inbound">Inbound</option>
                    </select>
                </div>
            </div>

            <div class="mjac-fields">
                <input
                    class="mj-input mjac-title-input"
                    type="text"
                    name="activityTitle"
                    placeholder="Quick summary (e.g., Called Jane about Q4 renewal)…"
                    [(ngModel)]="Title"
                    [disabled]="IsSaving" />

                <textarea
                    class="mj-input mjac-desc-input"
                    rows="3"
                    name="activityDescription"
                    placeholder="Capture concise call notes, meeting takeaways, or next steps… (stays lightweight; never auto-creates an MJ Doc)"
                    [(ngModel)]="Description"
                    [disabled]="IsSaving">
                </textarea>
            </div>

            <!-- Optional linked MJ Doc chip or opt-in picker -->
            @if (SelectedArtifact) {
                <div class="mjac-linked-row">
                    <span class="mjac-linked-pill">
                        <i class="fa-solid fa-file-lines" aria-hidden="true"></i>
                        <span>Linked MJ Doc: {{ SelectedArtifact.Name }}</span>
                        @if (SelectedArtifact.Type) {
                            <span class="mjac-linked-type">{{ SelectedArtifact.Type }}</span>
                        }
                    </span>
                    <button
                        type="button"
                        class="mjac-text-btn"
                        (click)="ClearSelectedArtifact()"
                        [disabled]="IsSaving">
                        <i class="fa-solid fa-link-slash" aria-hidden="true"></i> Remove link
                    </button>
                </div>
            }

            @if (ShowArtifactPicker) {
                <div class="mjac-picker">
                    <div class="mjac-picker__bar">
                        <input
                            class="mj-input mjac-picker__input"
                            type="search"
                            placeholder="Search existing MJ Docs by name…"
                            [(ngModel)]="ArtifactSearchQuery"
                            (ngModelChange)="OnArtifactSearchChanged($event)" />
                        <button type="button" class="mjac-text-btn" (click)="CloseArtifactPicker()">
                            Close
                        </button>
                    </div>
                    @if (IsSearchingArtifacts) {
                        <div class="mjac-picker__loading">
                            <mj-loading text="Searching MJ Docs…" size="small"></mj-loading>
                        </div>
                    } @else if (ArtifactSearchResults.length === 0) {
                        <div class="mjac-picker__empty">No matching MJ Docs found.</div>
                    } @else {
                        <div class="mjac-picker__list">
                            @for (doc of ArtifactSearchResults; track doc.ID) {
                                <button
                                    type="button"
                                    class="mjac-picker__option"
                                    [class.mjac-picker__option--selected]="IsArtifactSelected(doc.ID)"
                                    (click)="SelectArtifact(doc)">
                                    <span class="mjac-picker__option-main">
                                        <i class="fa-solid fa-file-lines" aria-hidden="true"></i>
                                        <span class="mjac-picker__option-name">{{ doc.Name }}</span>
                                        @if (doc.Type) {
                                            <span class="mjac-linked-type">{{ doc.Type }}</span>
                                        }
                                    </span>
                                    @if (doc.Description) {
                                        <span class="mjac-picker__option-desc">{{ PreviewExcerpt(doc.Description) }}</span>
                                    }
                                </button>
                            }
                        </div>
                    }
                </div>
            }

            @if (ErrorMessage) {
                <div class="mjac-error" role="alert">
                    <i class="fa-solid fa-circle-exclamation" aria-hidden="true"></i>
                    <span>{{ ErrorMessage }}</span>
                </div>
            }

            <div class="mjac-footer">
                <div class="mjac-footer__left">
                    <button
                        mjButton
                        variant="primary"
                        size="sm"
                        type="button"
                        [disabled]="IsSaving || !CanSubmit"
                        (click)="Submit()">
                        <i class="fa-solid fa-check" aria-hidden="true"></i>
                        <span>{{ IsSaving ? 'Saving…' : 'Log ' + SelectedTypeLabel }}</span>
                    </button>

                    <button
                        type="button"
                        class="mjac-optin-btn"
                        [disabled]="IsSaving"
                        (click)="ToggleArtifactPicker()">
                        <i class="fa-solid fa-paperclip" aria-hidden="true"></i>
                        <span>{{ SelectedArtifact ? 'Change MJ Doc' : 'Link MJ Doc (Optional)' }}</span>
                    </button>
                </div>

                <div class="mjac-footer__right">
                    @if (IsSaving) {
                        <mj-loading text="Saving…" size="small"></mj-loading>
                    }
                    <button
                        mjButton
                        variant="outline"
                        size="sm"
                        type="button"
                        [disabled]="IsSaving"
                        (click)="Cancel()">
                        Cancel
                    </button>
                </div>
            </div>
        </section>
    `,
    styles: [`
        :host {
            display: block;
            width: 100%;
        }

        .mjac-card {
            display: flex;
            flex-direction: column;
            gap: var(--mj-space-3, 12px);
            padding: var(--mj-space-4, 16px);
            background: var(--mj-bg-surface-card);
            border: 1px solid var(--mj-border-default);
            border-radius: var(--mj-radius-md, 10px);
            box-shadow: var(--mj-shadow-sm);
        }

        .mjac-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: var(--mj-space-3, 12px);
            flex-wrap: wrap;
        }

        .mjac-types {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
        }

        .mjac-type-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 12px;
            border-radius: var(--mj-radius-full, 9999px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-secondary);
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.15s ease, border-color 0.15s ease, color 0.15s ease;
        }

        .mjac-type-chip:hover {
            background: var(--mj-bg-surface-hover);
            border-color: var(--mj-brand-primary);
        }

        .mjac-type-chip--active {
            background: var(--mj-brand-primary);
            border-color: var(--mj-brand-primary);
            color: var(--mj-brand-on-primary);
        }

        .mjac-select {
            padding: 5px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-primary);
            font-size: 12px;
            font-weight: 500;
        }

        .mjac-sr-only {
            position: absolute;
            width: 1px;
            height: 1px;
            padding: 0;
            margin: -1px;
            overflow: hidden;
            clip: rect(0, 0, 0, 0);
            border: 0;
        }

        .mjac-fields {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .mjac-title-input,
        .mjac-desc-input {
            width: 100%;
            box-sizing: border-box;
            padding: 8px 12px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-primary);
            font-size: 13px;
            font-family: inherit;
        }

        .mjac-desc-input {
            resize: vertical;
            min-height: 68px;
            line-height: 1.5;
        }

        .mjac-linked-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 8px 12px;
            border-radius: var(--mj-radius-sm, 6px);
            background: var(--mj-status-info-bg);
            border: 1px solid var(--mj-status-info-border, var(--mj-border-default));
            flex-wrap: wrap;
        }

        .mjac-linked-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 600;
            color: var(--mj-status-info-text);
        }

        .mjac-linked-type {
            padding: 1px 6px;
            border-radius: var(--mj-radius-sm, 4px);
            background: var(--mj-bg-surface);
            color: var(--mj-text-secondary);
            font-size: 10px;
            font-weight: 500;
        }

        .mjac-picker {
            display: flex;
            flex-direction: column;
            gap: 8px;
            padding: 10px 12px;
            border-radius: var(--mj-radius-sm, 6px);
            background: var(--mj-bg-surface-sunken);
            border: 1px solid var(--mj-border-default);
        }

        .mjac-picker__bar {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .mjac-picker__input {
            flex: 1;
            font-size: 12px;
            padding: 6px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-primary);
        }

        .mjac-picker__loading,
        .mjac-picker__empty {
            font-size: 12px;
            color: var(--mj-text-muted);
            padding: 8px 4px;
        }

        .mjac-picker__list {
            display: flex;
            flex-direction: column;
            gap: 4px;
            max-height: 180px;
            overflow-y: auto;
        }

        .mjac-picker__option {
            display: flex;
            flex-direction: column;
            gap: 2px;
            padding: 7px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-primary);
            text-align: left;
            cursor: pointer;
            transition: border-color 0.15s ease, background 0.15s ease;
        }

        .mjac-picker__option:hover,
        .mjac-picker__option--selected {
            border-color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
        }

        .mjac-picker__option-main {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 600;
        }

        .mjac-picker__option-name {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .mjac-picker__option-desc {
            font-size: 11px;
            color: var(--mj-text-muted);
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .mjac-error {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 8px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            background: var(--mj-status-error-bg);
            color: var(--mj-status-error-text);
            font-size: 12px;
        }

        .mjac-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            flex-wrap: wrap;
        }

        .mjac-footer__left,
        .mjac-footer__right {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .mjac-optin-btn,
        .mjac-text-btn {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: transparent;
            color: var(--mj-text-secondary);
            font-size: 12px;
            font-weight: 500;
            cursor: pointer;
            transition: color 0.15s ease, border-color 0.15s ease, background 0.15s ease;
        }

        .mjac-optin-btn:hover,
        .mjac-text-btn:hover {
            color: var(--mj-brand-primary);
            border-color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
        }
    `],
})
export class ActivityComposerComponent implements OnInit {
    @Input() public Provider?: IMetadataProvider;
    @Output() public readonly ActivityCreated = new EventEmitter<ActivityComposerSavedEvent>();
    @Output() public readonly Cancelled = new EventEmitter<void>();

    public readonly TypeOptions: ReadonlyArray<QuickActivityTypeOption> = DEFAULT_QUICK_TYPES;
    public SelectedTypeCode: QuickActivityTypeOption['Code'] = 'Note';
    public Direction: mjBizAppsCommonActivityEntity['Direction'] = 'Internal';
    public Title = '';
    public Description = '';
    public SelectedArtifact: ActivityArtifactSummary | null = null;
    public ShowArtifactPicker = false;
    public ArtifactSearchQuery = '';
    public ArtifactSearchResults: ActivityArtifactSummary[] = [];
    public IsSearchingArtifacts = false;
    public IsSaving = false;
    public ErrorMessage: string | null = null;

    constructor(@Optional() private readonly cdr?: ChangeDetectorRef) {}

    public ngOnInit(): void {
        // Hydrate taxonomy in the background if not yet loaded; quick capture never blocks on it.
        void this.ensureActivityTypesLoaded();
    }

    public get SelectedTypeLabel(): string {
        return this.TypeOptions.find((t) => t.Code === this.SelectedTypeCode)?.Label ?? 'Activity';
    }

    public get CanSubmit(): boolean {
        return this.Title.trim().length > 0;
    }

    public SelectType(code: QuickActivityTypeOption['Code']): void {
        this.SelectedTypeCode = code;
        if (code === 'Note') {
            this.Direction = 'Internal';
        } else if (code === 'Call' || code === 'Email') {
            this.Direction = 'Outbound';
        }
        this.cdr?.markForCheck();
    }

    public async ToggleArtifactPicker(): Promise<void> {
        this.ShowArtifactPicker = !this.ShowArtifactPicker;
        this.cdr?.markForCheck();
        if (this.ShowArtifactPicker) {
            await this.LoadArtifacts(this.ArtifactSearchQuery);
        }
    }

    public CloseArtifactPicker(): void {
        this.ShowArtifactPicker = false;
        this.cdr?.markForCheck();
    }

    public async OnArtifactSearchChanged(term: string): Promise<void> {
        this.ArtifactSearchQuery = term;
        await this.LoadArtifacts(term);
    }

    public async LoadArtifacts(term: string): Promise<void> {
        this.IsSearchingArtifacts = true;
        this.cdr?.markForCheck();
        try {
            this.ArtifactSearchResults = await SearchLinkableArtifacts(term, this.activeProvider);
        } finally {
            this.IsSearchingArtifacts = false;
            this.cdr?.markForCheck();
        }
    }

    public SelectArtifact(doc: ActivityArtifactSummary): void {
        this.SelectedArtifact = doc;
        this.ShowArtifactPicker = false;
        this.cdr?.markForCheck();
    }

    public ClearSelectedArtifact(): void {
        this.SelectedArtifact = null;
        this.cdr?.markForCheck();
    }

    public IsArtifactSelected(artifactID: string): boolean {
        return this.SelectedArtifact !== null && UUIDsEqual(this.SelectedArtifact.ID, artifactID);
    }

    public PreviewExcerpt(text: string | null | undefined): string {
        return StripActivityMarkdownExcerpt(text, 120);
    }

    public async Submit(): Promise<boolean> {
        if (!this.CanSubmit || this.IsSaving) {
            return false;
        }
        this.IsSaving = true;
        this.ErrorMessage = null;
        this.cdr?.markForCheck();

        try {
            const typeID = this.resolveSelectedActivityTypeID();
            const result = await SaveQuickActivity(
                {
                    ActivityTypeID: typeID,
                    Title: this.Title,
                    Description: this.Description.trim() ? this.Description : null,
                    Direction: this.Direction,
                    Status: 'Logged',
                    StartedAt: new Date(),
                    ArtifactID: this.SelectedArtifact?.ID ?? null,
                },
                this.activeProvider,
            );

            if (!result.Success || !result.Activity) {
                this.ErrorMessage = result.ErrorMessage ?? 'Unable to log activity.';
                return false;
            }

            const linked = this.SelectedArtifact;
            const typeLabel = this.SelectedTypeLabel;
            this.ResetForm();
            this.ActivityCreated.emit({
                Activity: result.Activity,
                ActivityTypeLabel: typeLabel,
                LinkedArtifact: linked,
            });
            return true;
        } finally {
            this.IsSaving = false;
            this.cdr?.markForCheck();
        }
    }

    public Cancel(): void {
        this.ResetForm();
        this.Cancelled.emit();
    }

    public ResetForm(): void {
        this.Title = '';
        this.Description = '';
        this.SelectedArtifact = null;
        this.ShowArtifactPicker = false;
        this.ArtifactSearchQuery = '';
        this.ErrorMessage = null;
        this.cdr?.markForCheck();
    }

    private get activeProvider(): IMetadataProvider {
        return this.Provider ?? Metadata.Provider;
    }

    private resolveSelectedActivityTypeID(): string {
        const fromEngine =
            CommonEngine.Instance.GetActivityTypeByCode(this.SelectedTypeCode) ??
            CommonEngine.Instance.GetActivityTypeByName(this.SelectedTypeCode);
        if (fromEngine?.ID) {
            return fromEngine.ID;
        }
        return (
            this.TypeOptions.find((t) => t.Code === this.SelectedTypeCode)?.DefaultID ??
            DEFAULT_QUICK_TYPES[0].DefaultID
        );
    }

    private async ensureActivityTypesLoaded(): Promise<void> {
        if (CommonEngine.Instance.ActivityTypes.length > 0) {
            return;
        }
        try {
            await CommonEngine.Instance.Config(false, undefined, this.activeProvider);
        } catch {
            // Seeded DefaultIDs remain available for offline/lightweight capture.
        }
    }
}
