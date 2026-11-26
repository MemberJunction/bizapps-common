import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import type { ActivityArtifactBadgeState } from '../../data/activity-artifact';

/**
 * Compact linked MJ Doc (`MJ: Artifacts`) badge rendered on Activity timeline cards,
 * detail drawers, and form panels when `Activity.ArtifactID` is non-null.
 *
 * - Resolved state: displays the hydrated Artifact name + optional type label and opens via click.
 * - Unavailable state: degrades gracefully when the Artifact is restricted or deleted (zero console errors).
 * - Uses semantic `--mj-*` CSS custom properties exclusively.
 */
@Component({
    selector: 'bizapps-activity-artifact-badge',
    standalone: true,
    imports: [CommonModule],
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        @if (Badge.Status === 'resolved') {
            <span class="mja-doc-badge-wrap">
                <button
                    type="button"
                    class="mja-doc-badge mja-doc-badge--resolved"
                    [title]="'Open linked MJ Doc: ' + Badge.Name"
                    (click)="OnOpen($event)">
                    <i class="fa-solid fa-file-lines" aria-hidden="true"></i>
                    <span class="mja-doc-badge__label">{{ Badge.Name }}</span>
                    @if (Badge.TypeLabel) {
                        <span class="mja-doc-badge__type">{{ Badge.TypeLabel }}</span>
                    }
                    <i class="fa-solid fa-arrow-up-right-from-square mja-doc-badge__ext" aria-hidden="true"></i>
                </button>
                @if (AllowUnlink) {
                    <button
                        type="button"
                        class="mja-doc-badge__unlink"
                        title="Unlink MJ Doc (keeps activity notes)"
                        aria-label="Unlink MJ Doc"
                        (click)="OnUnlink($event)">
                        <i class="fa-solid fa-link-slash" aria-hidden="true"></i>
                    </button>
                }
            </span>
        } @else if (Badge.Status === 'unavailable') {
            <span class="mja-doc-badge-wrap">
                <span
                    class="mja-doc-badge mja-doc-badge--unavailable"
                    title="Linked MJ Doc is unavailable or you lack permission to view it">
                    <i class="fa-solid fa-file-circle-question" aria-hidden="true"></i>
                    <span class="mja-doc-badge__label">{{ Badge.FallbackLabel }}</span>
                </span>
                @if (AllowUnlink) {
                    <button
                        type="button"
                        class="mja-doc-badge__unlink"
                        title="Unlink unavailable MJ Doc"
                        aria-label="Unlink MJ Doc"
                        (click)="OnUnlink($event)">
                        <i class="fa-solid fa-link-slash" aria-hidden="true"></i>
                    </button>
                }
            </span>
        }
    `,
    styles: [`
        :host {
            display: inline-flex;
            align-items: center;
        }

        .mja-doc-badge-wrap {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            max-width: 100%;
        }

        .mja-doc-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 3px 9px;
            border-radius: var(--mj-radius-full, 9999px);
            font-size: 11px;
            font-weight: 600;
            line-height: 1.3;
            max-width: 280px;
            border: 1px solid var(--mj-border-default);
            transition: background 0.15s ease, border-color 0.15s ease;
        }

        .mja-doc-badge--resolved {
            background: var(--mj-status-info-bg);
            color: var(--mj-status-info-text);
            border-color: var(--mj-status-info-border, var(--mj-border-default));
            cursor: pointer;
        }

        .mja-doc-badge--resolved:hover {
            background: color-mix(in srgb, var(--mj-brand-primary) 16%, var(--mj-bg-surface));
            border-color: var(--mj-brand-primary);
            color: var(--mj-brand-primary);
        }

        .mja-doc-badge--unavailable {
            background: var(--mj-status-warning-bg);
            color: var(--mj-status-warning-text);
            border-color: var(--mj-status-warning-border, var(--mj-border-default));
            cursor: default;
        }

        .mja-doc-badge__label {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .mja-doc-badge__type {
            padding: 1px 5px;
            border-radius: var(--mj-radius-sm, 4px);
            background: var(--mj-bg-surface);
            color: var(--mj-text-secondary);
            font-size: 10px;
            font-weight: 500;
            flex-shrink: 0;
        }

        .mja-doc-badge__ext {
            font-size: 9px;
            opacity: 0.75;
            flex-shrink: 0;
        }

        .mja-doc-badge__unlink {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 22px;
            height: 22px;
            border-radius: var(--mj-radius-full, 9999px);
            border: 1px solid var(--mj-border-default);
            background: var(--mj-bg-surface);
            color: var(--mj-text-muted);
            font-size: 10px;
            cursor: pointer;
            padding: 0;
            transition: color 0.15s ease, border-color 0.15s ease, background 0.15s ease;
        }

        .mja-doc-badge__unlink:hover {
            color: var(--mj-status-error);
            border-color: var(--mj-status-error);
            background: var(--mj-status-error-bg);
        }
    `],
})
export class ActivityArtifactBadgeComponent {
    private _badge: ActivityArtifactBadgeState = { Status: 'none' };

    @Input()
    public get Badge(): ActivityArtifactBadgeState {
        return this._badge;
    }
    public set Badge(value: ActivityArtifactBadgeState | null | undefined) {
        this._badge = value ?? { Status: 'none' };
    }

    @Input() public AllowUnlink = false;

    @Output() public readonly OpenDoc = new EventEmitter<{ ArtifactID: string; Name: string }>();
    @Output() public readonly UnlinkDoc = new EventEmitter<string>();

    public OnOpen(event: MouseEvent): void {
        event.stopPropagation();
        if (this._badge.Status === 'resolved') {
            this.OpenDoc.emit({ ArtifactID: this._badge.ArtifactID, Name: this._badge.Name });
        }
    }

    public OnUnlink(event: MouseEvent): void {
        event.stopPropagation();
        if (this._badge.Status !== 'none') {
            this.UnlinkDoc.emit(this._badge.ArtifactID);
        }
    }
}
