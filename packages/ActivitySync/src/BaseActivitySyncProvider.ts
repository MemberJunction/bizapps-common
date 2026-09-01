/**
 * @fileoverview The provider plugin base class.
 *
 * A BASE CLASS rather than an interface, deliberately. The parts of a sync pass that every provider
 * gets wrong in the same way — the watermark, issue collection, hook ordering — live here once and
 * are not a subclass's to reimplement. A subclass supplies only what is genuinely specific to its
 * transport: how to fetch, how to map, and (where it disagrees with the default) how to compute its
 * own high-water mark.
 *
 * Providers WRAP existing plumbing rather than reinventing transport: MJ Communication providers
 * for Gmail and Microsoft Graph, Twilio for SMS and WhatsApp, MJ Actions for social feeds. A
 * provider's job is to speak its transport in this engine's vocabulary.
 *
 * Registered by `DriverClass`, matching every other plugin surface in MJ:
 *
 * ```ts
 * @RegisterClass(BaseActivitySyncProvider, 'Microsoft365')
 * export class MSGraphActivitySyncProvider extends BaseActivitySyncProvider { ... }
 * ```
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { LogError } from '@memberjunction/core';

import { ResolveHighWatermark } from './watermark.js';
import type { ActivityTransportContext } from './providers/MessageTransport.js';
import type {
    ActivitySourceBatch,
    ActivitySourceKind,
    ActivitySourceQuery,
    NormalizedItem,
    RawBatch,
} from './types.js';

export abstract class BaseActivitySyncProvider {
    /** Which surface this reads. Selects the watermark basis — see `WatermarkBasisForKind`. */
    public abstract readonly Kind: ActivitySourceKind;

    /** Must match an `ActivitySyncProviderType.Code`. */
    public abstract readonly ProviderTypeCode: string;

    /**
     * False for fixtures.
     *
     * Not decoration: the engine refuses to write `Source: 'Integration'` rows from a non-live
     * provider without being told to, so a fixture run cannot be mistaken for a real one in the
     * database.
     */
    public abstract readonly IsLive: boolean;

    /** Ask the transport for whatever it has. Raw payloads — no interpretation. */
    protected abstract FetchRaw(query: ActivitySourceQuery): Promise<RawBatch>;

    /** Map raw payloads into the engine's vocabulary. The one place a transport's shape is known. */
    protected abstract Normalize(raw: RawBatch, query: ActivitySourceQuery): NormalizedItem[];

    /**
     * One sync pass. Template method — subclasses extend it through the hooks below, never by
     * overriding this.
     */
    public async Fetch(query: ActivitySourceQuery): Promise<ActivitySourceBatch> {
        const observedAt = this.Now();
        try {
            await this.OnBeforeFetch(query);
            const raw = await this.FetchRaw(query);
            await this.OnAfterFetch(raw, query);

            await this.OnBeforeNormalize(raw, query);
            const items = this.Normalize(raw, query);
            await this.OnAfterNormalize(items, query);

            return {
                Items: items,
                HighWatermark: this.ComputeHighWatermark(items, observedAt),
                Issues: raw.Issues,
            };
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            LogError(
                `BaseActivitySyncProvider.Fetch failed for provider "${this.ProviderTypeCode}" ` +
                    `on mailbox "${query.Mailbox}": ${message}`,
            );
            await this.OnError(error, query);
            // Failed, not empty. An empty mailbox is a successful look that found nothing; a
            // throw means we saw nothing and must not report SUCCESS or clear LastError.
            return { Items: [], HighWatermark: null, Issues: [message], Failed: true };
        }
    }

    /**
     * The newest point this pass can honestly claim.
     *
     * Overridable for a transport that exposes a better signal than either item time or observation
     * time (a provider `ModifiedAt`, a server-side cursor). Overriding it means taking on the rules
     * in `watermark.ts` — read them first.
     */
    protected ComputeHighWatermark(items: readonly NormalizedItem[], observedAt: Date): Date | null {
        return ResolveHighWatermark(this.Kind, items, observedAt);
    }

    /** Seam for tests. Everything stored is UTC; a JS Date is a UTC instant. */
    protected Now(): Date {
        return new Date();
    }

    /**
     * Told what connection this run is for, BEFORE any fetch.
     *
     * The plugin is built by `MJGlobal.ClassFactory` with no arguments, so this is the only point at
     * which a provider learns which credential the connection named. A no-op by default: a fixture
     * provider has nothing to configure, and every existing provider keeps working untouched.
     *
     * NOT allowed to throw. A provider that cannot configure itself should record the reason and
     * refuse at fetch time, where the refusal reaches the run's Issues and the watermark is
     * preserved — the engine's existing distinction between 'looked, found nothing' and 'could not
     * look' does the rest.
     */
    public Configure(_context: ActivityTransportContext): void {}

    // ── Hooks. All no-ops; override any subset. ────────────────────────────────────────────────

    protected async OnBeforeFetch(_query: ActivitySourceQuery): Promise<void> {}
    protected async OnAfterFetch(_raw: RawBatch, _query: ActivitySourceQuery): Promise<void> {}
    protected async OnBeforeNormalize(_raw: RawBatch, _query: ActivitySourceQuery): Promise<void> {}
    protected async OnAfterNormalize(_items: NormalizedItem[], _query: ActivitySourceQuery): Promise<void> {}
    protected async OnError(_error: unknown, _query: ActivitySourceQuery): Promise<void> {}
}
