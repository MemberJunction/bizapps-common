import { Component, Input, ViewEncapsulation } from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * `bizapps-stat-row` — the row a set of {@link StatTileComponent}s sits in, plus the one place their
 * failures are reported.
 *
 * WHY THE ERROR LINE LIVES HERE RATHER THAN ON EACH TILE. Dashboard tiles are counted concurrently
 * and fail independently, so the honest report is per-row, not per-tile: each failed tile already
 * says "—" in place of its number, and the row says once, underneath, how many numbers are unknown.
 * Putting the sentence on every tile would repeat it four times and crowd out the numbers; putting
 * it nowhere leaves an em dash the reader has to interpret alone.
 *
 * The caller composes the sentence, because only the caller knows what failed. Pass `null` when
 * everything read.
 *
 * ```html
 * <bizapps-stat-row [Error]="CountError">
 *   <bizapps-stat-tile ... />
 *   <bizapps-stat-tile ... />
 * </bizapps-stat-row>
 * ```
 */
@Component({
    selector: 'bizapps-stat-row',
    standalone: true,
    imports: [CommonModule],
    encapsulation: ViewEncapsulation.None,
    template: `
        <div class="bizapps-stat-row">
            <ng-content />
        </div>
        @if (Error) {
            <p class="bizapps-stat-row__error" role="status">{{ Error }}</p>
        }
    `,
    styles: [
        `
            .bizapps-stat-row {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
                gap: var(--mj-space-4);
            }
            .bizapps-stat-row__error {
                margin: var(--mj-space-2) 0 0;
                font-size: var(--mj-text-xs);
                color: var(--mj-text-muted);
            }
        `,
    ],
})
export class StatRowComponent {
    /**
     * One sentence describing what could not be read, or `null`.
     *
     * Rendered muted rather than in error red on purpose: the tiles are still usable and the ones
     * that read are still true. A red banner over a working dashboard reads as "this page is broken".
     */
    @Input() Error: string | null = null;
}
