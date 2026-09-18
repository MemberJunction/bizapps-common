import {
    ChangeDetectionStrategy,
    ChangeDetectorRef,
    Component,
    EventEmitter,
    Input,
    type OnDestroy,
    Output,
    ViewEncapsulation,
    inject,
} from '@angular/core';
import { Metadata, RunView, type IMetadataProvider } from '@memberjunction/core';
import type { FormNavigationEvent } from '@memberjunction/ng-base-forms';
import {
    RelatedChipNavigation,
    ResolveRelatedChip,
    type BizAppsRelatedLink,
    type ResolvedRelatedChip,
} from './related-links';

/**
 * `bizapps-related-chips` — the row of links from a record to the records linked to it.
 *
 * THE SHARED BIZAPPS "RELATED" ROW. A tester walking Deal → Order → Contract found no consistent way
 * to get from one record to the next: the Contract header linked its source Deal, the Deal form
 * buried its Order in a panel, the Order form pointed at nothing, and where a link did exist it
 * sometimes rendered a GUID. Each app had solved a slice of it differently. This is the one they
 * collapse into.
 *
 * ## What a caller supplies, and what this owns
 *
 * The caller passes {@link Links} — descriptors naming an entity and either the id it holds or a
 * filter that finds the record holding the id. Which links belong on which form is the caller's
 * decision, because only the form knows its own record.
 *
 * Everything after that is this component's: resolving the entity, reading the record's NAME, and —
 * the part worth having in one place — deciding when a chip must not be drawn at all. Those rules
 * and their reasoning live in `related-links.ts`, deliberately outside this class so they can be
 * tested without DI. In short: no chip for an entity this host does not have or this user cannot
 * read, no chip for a record that is not there, and never a raw id in place of a name.
 *
 * ## Navigation goes up, not out
 *
 * The component emits {@link Navigate} and never touches `NavigationService`. A host form wires it
 * to `FormComponent.OnFormNavigate($event)` — the same path every field link in these apps takes —
 * which keeps this usable from a `BaseFormPanel` hero and from a form component override alike, and
 * keeps the routing decision with the app that owns the surface.
 *
 * ## Example
 *
 * ```html
 * <bizapps-related-chips
 *     [Links]="RelatedLinks"
 *     [Provider]="FormComponent?.ProviderToUse ?? null"
 *     (Navigate)="FormComponent.OnFormNavigate($event)" />
 * ```
 *
 * ```typescript
 * public RelatedLinks: BizAppsRelatedLink[] = [
 *     { Key: 'order', EntityName: 'MJ_BizApps_Orders: Order Headers', RecordID: deal.OrderID, Label: 'Order' },
 *     { Key: 'contract', EntityName: 'MJ_BizApps_Contracts: Contracts', RecordID: deal.ContractID, Label: 'Contract' },
 * ];
 * ```
 */
@Component({
    selector: 'bizapps-related-chips',
    standalone: true,
    encapsulation: ViewEncapsulation.None,
    changeDetection: ChangeDetectionStrategy.OnPush,
    template: `
        @if (Chips.length > 0) {
            <div class="bizapps-related" role="group" aria-label="Related records">
                @for (chip of Chips; track chip.Key) {
                    <button
                        type="button"
                        class="bizapps-related__chip"
                        [attr.aria-label]="chip.AriaLabel"
                        (click)="Open(chip, $event)">
                        @if (chip.Icon) {
                            <i [class]="chip.Icon" aria-hidden="true"></i>
                        }
                        <span class="bizapps-related__label">{{ chip.Label }}</span>
                        <span class="bizapps-related__name">{{ chip.Name || 'Open' }}</span>
                    </button>
                }
            </div>
        }
    `,
    styles: [
        `
            /* Styles are the component's own and use design tokens only, under a class prefix of
               their own: the app kits (orders-kit, contracts-kit) are global under
               ViewEncapsulation.None, and .mj-chip / .mjc-chip / .mjo-* / .biz-hero__chip are all
               already taken by unrelated things. A row that borrowed one of those would render
               differently in each app, which is the failure this component exists to end. */
            .bizapps-related {
                display: flex;
                flex-wrap: wrap;
                align-items: center;
                gap: var(--mj-space-2);
            }
            .bizapps-related__chip {
                display: inline-flex;
                align-items: center;
                gap: var(--mj-space-1-5);
                max-width: 100%;
                margin: 0;
                padding: var(--mj-space-1) var(--mj-space-3);
                font-family: inherit;
                font-size: var(--mj-text-xs);
                font-weight: var(--mj-font-semibold);
                line-height: 1.5;
                background: var(--mj-bg-surface-card);
                border: 1px solid var(--mj-border-default);
                border-radius: var(--mj-radius-full);
                cursor: pointer;
                transition: var(--mj-transition-colors);
            }
            .bizapps-related__chip:hover {
                background: var(--mj-bg-surface-hover);
                border-color: var(--mj-brand-primary);
            }
            .bizapps-related__chip:focus-visible {
                outline: var(--mj-ring-width) solid var(--mj-focus-ring-color);
                outline-offset: var(--mj-ring-offset);
            }
            /* The relationship is the quiet half; the record's NAME is what the reader is looking
               for, so it carries the link colour and the underline on hover. */
            .bizapps-related__label {
                color: var(--mj-text-secondary);
                white-space: nowrap;
            }
            .bizapps-related__name {
                overflow: hidden;
                color: var(--mj-text-link);
                text-overflow: ellipsis;
                white-space: nowrap;
            }
            .bizapps-related__chip:hover .bizapps-related__name {
                color: var(--mj-text-link-hover);
                text-decoration: underline;
            }
        `,
    ],
})
export class RelatedChipsComponent implements OnDestroy {
    private readonly cdr = inject(ChangeDetectorRef);

    /** Chips that resolved. A link that resolved to nothing is absent here, never a blank chip. */
    public Chips: ResolvedRelatedChip[] = [];

    private links: BizAppsRelatedLink[] = [];

    private provider: IMetadataProvider | null = null;

    /**
     * Guards against a slower read for a PREVIOUS set of links landing after the caller moved on —
     * a form navigating between records is the ordinary way that happens. Every resolve captures the
     * generation it started in and discards itself if it no longer matches.
     */
    private generation = 0;

    /**
     * The OTHER way a resolve becomes irrelevant, and the one the generation cannot see: the view it
     * would publish into is gone. `detectChanges()` has no destroyed-view guard of its own, so a read
     * still in flight when the user closes the tab would run change detection over a torn-down
     * `LView`.
     */
    private destroyed = false;

    /**
     * The relationships to offer, in the order they should read.
     *
     * A setter rather than `ngOnChanges`, per MJ's rule: the input's own setter is the one place that
     * knows the value changed. Assign a NEW array to trigger a re-resolve; mutating the existing one
     * in place will not, which is the same contract every other data-driven MJ input has.
     */
    @Input()
    public set Links(value: BizAppsRelatedLink[] | null | undefined) {
        this.links = value ?? [];
        this.scheduleResolve();
    }
    public get Links(): BizAppsRelatedLink[] {
        return this.links;
    }

    /**
     * Metadata provider to read through. Falls back to the ambient one when not supplied.
     *
     * A form panel should pass `FormComponent.ProviderToUse`, so the chips read from the same place
     * the record they describe came from. In a host with more than one provider the fallback reads
     * the wrong database and the failure is a wrong ANSWER rather than an error, which is why this
     * is worth passing even when there is only one today.
     *
     * A SETTER, and re-resolving, for the same reason. Angular assigns bound inputs in template
     * order, and the usage above binds `[Links]` first — so a plain field would be read as `null` by
     * the resolve the `Links` setter kicks off, silently reading the ambient provider, and would
     * never be re-read once the real one arrived. `FormComponent?.ProviderToUse` starting out `null`
     * and resolving a tick later has the same shape. Both resolve against the wrong database, and a
     * wrong database here is a wrong answer rather than an error.
     */
    @Input()
    public set Provider(value: IMetadataProvider | null | undefined) {
        this.provider = value ?? null;
        this.scheduleResolve();
    }
    public get Provider(): IMetadataProvider | null {
        return this.provider;
    }

    /**
     * Emitted when a chip is clicked, with `OpenInNewTab` set for ctrl/cmd-click.
     *
     * Wire it to the host form's `OnFormNavigate`. Nothing happens if it is left unbound — which is
     * why the chip is drawn as a real `<button>` only because a click always has somewhere to go in
     * practice; a host that binds nothing gets a row that looks live and is not.
     */
    @Output() public Navigate = new EventEmitter<FormNavigationEvent>();

    /** The provider actually used — the one passed in, or the ambient one. */
    public get ProviderToUse(): IMetadataProvider {
        return this.provider ?? Metadata.Provider;
    }

    public Open(chip: ResolvedRelatedChip, event: MouseEvent): void {
        event.preventDefault();
        this.Navigate.emit(RelatedChipNavigation(chip, event));
    }

    public ngOnDestroy(): void {
        this.destroyed = true;
    }

    /**
     * Drop what is on screen and queue a fresh resolve for the next microtask.
     *
     * CLEARED FIRST because the chips on screen describe the record we just left. A form container
     * reuses this instance across records, so a header moving from Deal A to Deal B that kept A's
     * chips for the length of the reads would offer a click that navigates to A's related record —
     * a wrong destination, not a slow one.
     *
     * QUEUED because every input that feeds a resolve is assigned in the same change-detection pass,
     * one after another. Resolving inside the setter would read a half-applied set of inputs, and
     * would read twice. The microtask runs once both have landed; the generation it was queued under
     * makes each superseded one drop itself.
     */
    private scheduleResolve(): void {
        const generation = ++this.generation;
        this.Chips = [];
        void Promise.resolve().then(() => {
            if (this.generation !== generation || this.destroyed) {
                return;
            }
            return this.resolve(generation);
        });
    }

    /**
     * Resolve every link concurrently, then publish the survivors in the caller's order.
     *
     * Published in one assignment rather than chip by chip: a row that grows an item at a time
     * reflows the header under the reader, and the links are few enough that the slowest read is the
     * whole wait either way.
     */
    private async resolve(generation: number): Promise<void> {
        const links = this.links;
        if (links.length === 0) {
            return;
        }

        const provider = this.ProviderToUse;
        const entities = provider?.Entities ?? [];
        const runView = RunView.FromMetadataProvider(provider);

        const resolved = await Promise.all(
            links.map((link) =>
                ResolveRelatedChip(link, entities, (params) =>
                    runView.RunView<Record<string, unknown>>({ ...params, ResultType: 'simple' }),
                ),
            ),
        );

        if (this.generation !== generation || this.destroyed) {
            return;
        }

        this.Chips = resolved.filter((chip): chip is ResolvedRelatedChip => chip !== null);
        this.cdr.detectChanges();
    }
}
