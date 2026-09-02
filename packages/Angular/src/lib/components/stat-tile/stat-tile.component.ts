import { Component, EventEmitter, Input, Output, ViewEncapsulation } from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * How a tile's number should read. `none` is the ordinary case; `warn` and `error` colour the value
 * only, never the whole tile — a wall of coloured boxes stops meaning anything.
 */
export type StatTileTone = 'none' | 'warn' | 'error';

/**
 * `bizapps-stat-tile` — one headline count, and optionally where clicking it goes.
 *
 * THE SHARED BIZAPPS DASHBOARD TILE. Orders grew the first version of this
 * (`Bizapps-Orders/.../panels/stat-tile.component.ts`); contracts, sales and accounting each grew
 * their own near-copy. This is the one they collapse into.
 *
 * ## Two rules that are behaviour, not styling
 *
 * **A NULL VALUE RENDERS AN EM DASH, NEVER A ZERO.** A dashboard count comes from a query that can
 * fail, and "0" is a specific, reassuring claim — "nothing to do here". Rendering an unknown as zero
 * tells a finance user their queue is empty when it is actually unreadable, which is the one failure
 * mode a work-queue dashboard must not have. Pass `null` for "we could not read this" and the tile
 * says so.
 *
 * **A TILE THAT DOES NOTHING MUST NOT LOOK CLICKABLE.** One flag — {@link IsClickable} — drives the
 * cursor, the `role`, the `tabindex` and the keyboard handlers together, so they cannot drift apart.
 * It defaults to "is anything listening to `Clicked`", which is right for a row where every tile
 * navigates; a row with a mix of live and inert tiles must pass {@link Clickable} explicitly, because
 * a template binding counts as listening whatever its handler decides to do. See that input.
 *
 * ## Styles live here, deliberately
 *
 * Orders' version rendered `class="mj-stat"` and every one of those rules lived in `orders-kit.css`.
 * Copied into another app it rendered as three unstyled spans — which is why this is a rewrite rather
 * than a move. The styles below are the component's own, use design tokens only (no hex), and use a
 * `bizapps-stat` class prefix: the app kits are global under `ViewEncapsulation.None`, and both
 * `.mj-stat` (orders-kit) and `.mjc-stat` (contracts-kit) are already taken by unrelated things.
 *
 * ## Example
 *
 * ```html
 * <bizapps-stat-tile
 *   Label="Awaiting executed document"
 *   Icon="fa-solid fa-file-circle-question"
 *   [Value]="AwaitingCount"
 *   Detail="3 already in force"
 *   Tone="error"
 *   (Clicked)="GoToAwaiting()" />
 * ```
 */
@Component({
    selector: 'bizapps-stat-tile',
    standalone: true,
    imports: [CommonModule],
    encapsulation: ViewEncapsulation.None,
    template: `
        <div
            class="bizapps-stat"
            [class.bizapps-stat--warn]="Tone === 'warn'"
            [class.bizapps-stat--error]="Tone === 'error'"
            [class.bizapps-stat--clickable]="IsClickable"
            [attr.role]="IsClickable ? 'button' : null"
            [attr.tabindex]="IsClickable ? 0 : null"
            [attr.aria-label]="IsClickable ? Label : null"
            [title]="Detail ?? ''"
            (click)="OnActivate()"
            (keydown.enter)="OnActivate()"
            (keydown.space)="OnActivate($event)">
            <span class="bizapps-stat__label">
                @if (Icon) {
                    <i [class]="Icon" aria-hidden="true"></i>
                }
                {{ Label }}
            </span>
            <span class="bizapps-stat__value">{{ DisplayValue }}</span>
            @if (Detail) {
                <span class="bizapps-stat__detail">{{ Detail }}</span>
            }
            <ng-content />
        </div>
    `,
    styles: [
        `
            .bizapps-stat {
                display: flex;
                flex-direction: column;
                gap: 2px;
                min-width: 0;
                padding: var(--mj-space-4);
                background: var(--mj-bg-surface);
                border: 1px solid var(--mj-border-default);
                border-radius: var(--mj-radius-md);
            }
            .bizapps-stat__label {
                display: flex;
                align-items: center;
                gap: 6px;
                font-size: var(--mj-text-xs);
                font-weight: var(--mj-font-semibold);
                letter-spacing: 0.04em;
                text-transform: uppercase;
                color: var(--mj-text-muted);
            }
            .bizapps-stat__value {
                font-size: 25px;
                font-weight: var(--mj-font-bold);
                font-variant-numeric: tabular-nums;
                letter-spacing: -0.02em;
                line-height: 1.15;
            }
            .bizapps-stat__detail {
                font-size: var(--mj-text-xs);
                color: var(--mj-text-muted);
            }

            /* Tone colours the NUMBER, not the tile. */
            .bizapps-stat--warn .bizapps-stat__value {
                color: var(--mj-status-warning-text);
            }
            .bizapps-stat--error .bizapps-stat__value {
                color: var(--mj-status-error-text);
            }

            .bizapps-stat--clickable {
                cursor: pointer;
            }
            .bizapps-stat--clickable:hover {
                border-color: var(--mj-brand-primary);
            }
            .bizapps-stat--clickable:focus-visible {
                outline: 2px solid var(--mj-border-focus, var(--mj-brand-primary));
                outline-offset: 2px;
            }
        `,
    ],
})
export class StatTileComponent {
    /** What the number is. Also the accessible name when the tile is clickable. */
    @Input() Label = '';

    /** Font Awesome class for the small icon beside the label. Optional. */
    @Input() Icon: string | null = null;

    /**
     * The number, or `null` for "could not be read".
     *
     * A string is accepted so a caller can pass an already-formatted value (`'1,204'`); the tile
     * never formats, because formatting rules belong to the app that owns the number.
     */
    @Input() Value: number | string | null = null;

    /** One line under the number — the footnote that qualifies it. Optional. */
    @Input() Detail: string | null = null;

    /** Colours the value when the number is one somebody has to act on. */
    @Input() Tone: StatTileTone = 'none';

    /** Emitted on click, Enter or Space. */
    @Output() Clicked = new EventEmitter<void>();

    /**
     * Force interactivity on or off. Leave unset to infer it from whether anything is listening.
     *
     * ⚠ THE INFERENCE ALONE IS NOT ENOUGH, and this input exists because of a bug it failed to
     * prevent. `Clicked.observed` is true whenever a TEMPLATE binds `(Clicked)` — Angular subscribes
     * to the output at binding time, and it has no idea what the handler expression decides to do.
     * So a consumer writing `(Clicked)="tile.Target ? Go(tile) : null"` for a mixed row of tiles gets
     * every tile focusable, announced as a button and showing a pointer, including the ones whose
     * click resolves to nothing — which is precisely the "invites a click that does nothing" outcome
     * the inference was meant to rule out.
     *
     * Pass `false` for a tile that is deliberately inert, and keep binding `(Clicked)` normally.
     */
    @Input() Clickable: boolean | null = null;

    /** `null` becomes an em dash. See the class comment — this is the rule, not a formatting choice. */
    public get DisplayValue(): string {
        return this.Value === null || this.Value === undefined ? '—' : String(this.Value);
    }

    /**
     * One flag drives cursor, role, tabindex and the keyboard handlers, so they cannot disagree.
     *
     * An explicit {@link Clickable} always wins; otherwise fall back to whether anything is
     * listening, which is right for the common case of a row where every tile navigates.
     */
    public get IsClickable(): boolean {
        return this.Clickable ?? this.Clicked.observed;
    }

    /**
     * @param event present for the Space binding — Space scrolls the page by default, and a tile that
     *              scrolls the dashboard instead of opening the list is a keyboard-only bug nobody
     *              reports.
     */
    public OnActivate(event?: Event): void {
        if (!this.IsClickable) return;
        event?.preventDefault();
        this.Clicked.emit();
    }
}
