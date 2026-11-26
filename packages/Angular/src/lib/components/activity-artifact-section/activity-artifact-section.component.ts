import {
    ChangeDetectionStrategy,
    ChangeDetectorRef,
    Component,
    Input,
    OnChanges,
    OnInit,
    Optional,
    SimpleChanges,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IMetadataProvider, Metadata } from '@memberjunction/core';
import { NormalizeUUID } from '@memberjunction/global';
import type { BaseFormComponent } from '@memberjunction/ng-base-forms';
import { NavigationService } from '@memberjunction/ng-shared';
import { SharedGenericModule } from '@memberjunction/ng-shared-generic';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { ActivityArtifactBadgeComponent } from '../activity-artifact-badge/activity-artifact-badge.component';
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
} from '../../data/activity-artifact';

/**
 * Reusable Linked MJ Doc (`MJ: Artifacts`) strip for Activity form panels and detail surfaces.
 *
 * - Displays the hydrated linked MJ Doc badge when `Record.ArtifactID` is non-null.
 * - Offers strictly opt-in "Link MJ Doc" and "Expand to MJ Doc" actions when unlinked.
 * - Unlinking sets `ArtifactID = null` while preserving `Description` and `Details`.
 * - Uses semantic `--mj-*` CSS tokens exclusively and `<mj-loading>` for wait states.
 */
@Component({
    selector: 'bizapps-activity-artifact-section',
    standalone: true,
    imports: [CommonModule, FormsModule, SharedGenericModule, ActivityArtifactBadgeComponent],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        <div class="mja-doc-strip">
            <div class="mja-doc-strip__left">
                <span class="mja-doc-strip__label">
                    <i class="fa-solid fa-file-lines" aria-hidden="true"></i>
                    MJ Doc
                </span>
                @if (Record && Record.ArtifactID) {
                    <bizapps-activity-artifact-badge
                        [Badge]="ArtifactBadge"
                        [AllowUnlink]="true"
                        (OpenDoc)="OnOpenLinkedDoc($event)"
                        (UnlinkDoc)="UnlinkArtifact()" />
                } @else {
                    <span class="mja-doc-strip__hint">Quick note (no MJ Doc linked)</span>
                }
            </div>

            <div class="mja-doc-strip__actions">
                @if (IsMutatingArtifact) {
                    <mj-loading text="Updating…" size="small"></mj-loading>
                } @else if (Record && !Record.ArtifactID) {
                    <button
                        type="button"
                        class="mja-doc-btn"
                        (click)="ToggleLinkPicker()">
                        <i class="fa-solid fa-link" aria-hidden="true"></i>
                        <span>Link MJ Doc</span>
                    </button>
                    @if (Record.IsSaved) {
                        <button
                            type="button"
                            class="mja-doc-btn mja-doc-btn--accent"
                            (click)="ExpandToArtifact()">
                            <i class="fa-solid fa-file-circle-plus" aria-hidden="true"></i>
                            <span>Expand to MJ Doc</span>
                        </button>
                    }
                }
            </div>
        </div>

        @if (ShowLinkPicker) {
            <div class="mja-doc-picker">
                <div class="mja-doc-picker__row">
                    <input
                        class="mja-doc-picker__input"
                        type="search"
                        placeholder="Search existing MJ Docs by name…"
                        [(ngModel)]="ArtifactSearchTerm"
                        (ngModelChange)="SearchArtifacts($event)" />
                    <button type="button" class="mja-doc-btn" (click)="CloseLinkPicker()">
                        Close
                    </button>
                </div>
                @if (IsSearchingArtifacts) {
                    <mj-loading text="Searching MJ Docs…" size="small"></mj-loading>
                } @else if (ArtifactSearchResults.length === 0) {
                    <div class="mja-doc-picker__empty">No matching MJ Docs found.</div>
                } @else {
                    <div class="mja-doc-picker__list">
                        @for (doc of ArtifactSearchResults; track doc.ID) {
                            <button
                                type="button"
                                class="mja-doc-picker__item"
                                (click)="LinkExistingArtifact(doc)">
                                <span class="mja-doc-picker__item-name">
                                    <i class="fa-solid fa-file-lines" aria-hidden="true"></i>
                                    {{ doc.Name }}
                                </span>
                                @if (doc.Description) {
                                    <span class="mja-doc-picker__item-desc">{{ PreviewExcerpt(doc.Description) }}</span>
                                }
                            </button>
                        }
                    </div>
                }
            </div>
        }

        @if (ArtifactActionError) {
            <div class="mja-doc-error" role="alert">{{ ArtifactActionError }}</div>
        }
    `,
    styles: [`
        :host {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-bottom: 12px;
        }

        .mja-doc-strip {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 8px 12px;
            border-radius: var(--mj-radius-md);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface-card);
            flex-wrap: wrap;
        }

        .mja-doc-strip__left,
        .mja-doc-strip__actions {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .mja-doc-strip__label {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: var(--mj-text-secondary);
        }

        .mja-doc-strip__hint {
            font-size: 12px;
            color: var(--mj-text-muted);
        }

        .mja-doc-btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 500;
            color: var(--mj-text-secondary);
            background: transparent;
            border: 1px solid var(--mj-border-default);
            border-radius: var(--mj-radius-sm, 6px);
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .mja-doc-btn:hover {
            background: var(--mj-bg-surface-hover);
            color: var(--mj-text-primary);
            border-color: var(--mj-brand-primary);
        }

        .mja-doc-btn--accent {
            background: var(--mj-status-info-bg);
            color: var(--mj-status-info-text);
            border-color: var(--mj-status-info-border, var(--mj-border-default));
        }

        .mja-doc-picker {
            display: flex;
            flex-direction: column;
            gap: 8px;
            padding: 10px 12px;
            border-radius: var(--mj-radius-md);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface-sunken);
        }

        .mja-doc-picker__row {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .mja-doc-picker__input {
            flex: 1;
            padding: 6px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-primary);
            font-size: 12px;
        }

        .mja-doc-picker__empty {
            font-size: 12px;
            color: var(--mj-text-muted);
        }

        .mja-doc-picker__list {
            display: flex;
            flex-direction: column;
            gap: 4px;
            max-height: 160px;
            overflow-y: auto;
        }

        .mja-doc-picker__item {
            display: flex;
            flex-direction: column;
            gap: 2px;
            padding: 6px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-primary);
            text-align: left;
            cursor: pointer;
        }

        .mja-doc-picker__item:hover {
            border-color: var(--mj-brand-primary);
            background: var(--mj-bg-surface-hover);
        }

        .mja-doc-picker__item-name {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 600;
        }

        .mja-doc-picker__item-desc {
            font-size: 11px;
            color: var(--mj-text-muted);
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .mja-doc-error {
            padding: 8px 10px;
            border-radius: var(--mj-radius-sm, 6px);
            background: var(--mj-status-error-bg);
            color: var(--mj-status-error-text);
            font-size: 12px;
        }
    `],
})
export class ActivityArtifactSectionComponent implements OnInit, OnChanges {
    @Input() public Record?: mjBizAppsCommonActivityEntity;
    @Input() public EditMode = false;
    @Input() public FormComponent?: BaseFormComponent;
    @Input() public Provider?: IMetadataProvider;

    public HydratedArtifacts = new Map<string, ActivityArtifactSummary>();
    public ArtifactHydrated = false;
    public ShowLinkPicker = false;
    public ArtifactSearchTerm = '';
    public ArtifactSearchResults: ActivityArtifactSummary[] = [];
    public IsSearchingArtifacts = false;
    public IsMutatingArtifact = false;
    public ArtifactActionError: string | null = null;

    constructor(
        @Optional() private readonly cdr?: ChangeDetectorRef,
        @Optional() private readonly navService?: NavigationService,
    ) {}

    public ngOnInit(): void {
        void this.HydrateArtifactBadge();
    }

    public ngOnChanges(changes: SimpleChanges): void {
        if (changes['Record']) {
            void this.HydrateArtifactBadge();
        }
    }

    public async HydrateArtifactBadge(): Promise<void> {
        const artifactID = this.Record?.ArtifactID ?? null;
        if (!artifactID) {
            this.HydratedArtifacts.clear();
            this.ArtifactHydrated = true;
            this.cdr?.markForCheck();
            return;
        }
        this.HydratedArtifacts = await LoadActivityArtifactsByIDs([artifactID], this.activeProvider);
        this.ArtifactHydrated = true;
        this.cdr?.markForCheck();
    }

    public get ArtifactBadge(): ActivityArtifactBadgeState {
        return ResolveActivityArtifactBadge(this.Record?.ArtifactID, this.HydratedArtifacts, {
            hydrationComplete: this.ArtifactHydrated,
            virtualName: this.Record?.Artifact ?? null,
        });
    }

    public PreviewExcerpt(raw: string | null | undefined): string {
        return StripActivityMarkdownExcerpt(raw, 120);
    }

    public OnOpenLinkedDoc(event: { ArtifactID: string; Name: string }): void {
        OpenLinkedArtifact(
            event.ArtifactID,
            event.Name,
            this.navService ?? null,
            this.FormComponent?.OnFormNavigate ? (nav) => this.FormComponent?.OnFormNavigate(nav) : undefined,
        );
    }

    public async ToggleLinkPicker(): Promise<void> {
        this.ShowLinkPicker = !this.ShowLinkPicker;
        this.ArtifactActionError = null;
        this.cdr?.markForCheck();
        if (this.ShowLinkPicker) {
            await this.SearchArtifacts(this.ArtifactSearchTerm);
        }
    }

    public CloseLinkPicker(): void {
        this.ShowLinkPicker = false;
        this.cdr?.markForCheck();
    }

    public async SearchArtifacts(term: string): Promise<void> {
        this.ArtifactSearchTerm = term;
        this.IsSearchingArtifacts = true;
        this.cdr?.markForCheck();
        try {
            this.ArtifactSearchResults = await SearchLinkableArtifacts(term, this.activeProvider);
        } finally {
            this.IsSearchingArtifacts = false;
            this.cdr?.markForCheck();
        }
    }

    public async LinkExistingArtifact(doc: ActivityArtifactSummary): Promise<boolean> {
        if (!this.Record || this.IsMutatingArtifact) {
            return false;
        }
        this.IsMutatingArtifact = true;
        this.ArtifactActionError = null;
        this.cdr?.markForCheck();

        try {
            const res = await LinkExistingArtifactToActivity(this.Record, doc.ID, {
                saveNow: Boolean(this.Record.IsSaved && !this.EditMode),
                artifactName: doc.Name,
            });
            if (!res.Success) {
                this.ArtifactActionError = res.ErrorMessage ?? 'Failed to link MJ Doc.';
                return false;
            }
            this.HydratedArtifacts.set(NormalizeUUID(doc.ID), doc);
            this.ArtifactHydrated = true;
            this.ShowLinkPicker = false;
            return true;
        } finally {
            this.IsMutatingArtifact = false;
            this.cdr?.markForCheck();
        }
    }

    public async ExpandToArtifact(): Promise<boolean> {
        if (!this.Record || this.IsMutatingArtifact) {
            return false;
        }
        this.IsMutatingArtifact = true;
        this.ArtifactActionError = null;
        this.cdr?.markForCheck();

        try {
            const res = await ExpandActivityToArtifact(this.Record, { Provider: this.activeProvider });
            if (!res.Success || !res.ArtifactID) {
                this.ArtifactActionError = res.ErrorMessage ?? 'Failed to expand activity into an MJ Doc.';
                return false;
            }
            this.HydratedArtifacts.set(NormalizeUUID(res.ArtifactID), {
                ID: res.ArtifactID,
                Name: res.ArtifactName ?? this.Record.Title,
                Type: 'Markdown Document',
            });
            this.ArtifactHydrated = true;
            this.ShowLinkPicker = false;
            return true;
        } finally {
            this.IsMutatingArtifact = false;
            this.cdr?.markForCheck();
        }
    }

    public async UnlinkArtifact(): Promise<boolean> {
        if (!this.Record || this.IsMutatingArtifact) {
            return false;
        }
        this.IsMutatingArtifact = true;
        this.ArtifactActionError = null;
        this.cdr?.markForCheck();

        try {
            const res = await UnlinkArtifactFromActivity(this.Record, {
                saveNow: Boolean(this.Record.IsSaved && !this.EditMode),
            });
            if (!res.Success) {
                this.ArtifactActionError = res.ErrorMessage ?? 'Failed to unlink MJ Doc.';
                return false;
            }
            this.HydratedArtifacts.clear();
            this.ArtifactHydrated = true;
            return true;
        } finally {
            this.IsMutatingArtifact = false;
            this.cdr?.markForCheck();
        }
    }

    private get activeProvider(): IMetadataProvider {
        return this.Provider ?? Metadata.Provider;
    }
}
