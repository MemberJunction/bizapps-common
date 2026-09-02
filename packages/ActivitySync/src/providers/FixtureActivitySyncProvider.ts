/**
 * A source backed by handed-in items. The substitute the pipeline is proved against.
 *
 * Not a mock: it hands over the same NormalizedItem[] a live provider would, so a test
 * exercises the real cascade, resolver, writer and watermark.
 */
import { RegisterClass } from '@memberjunction/global';

import { BaseActivitySyncProvider } from '../BaseActivitySyncProvider.js';
import type { ActivitySourceKind, ActivitySourceQuery, NormalizedItem, RawBatch } from '../types.js';

@RegisterClass(BaseActivitySyncProvider, 'Generic')
export class FixtureActivitySyncProvider extends BaseActivitySyncProvider {
    public readonly Kind: ActivitySourceKind;
    public readonly ProviderTypeCode = 'Generic';
    public readonly IsLive = false;
    public readonly Calls: ActivitySourceQuery[] = [];
    public fetchedAt: Date = new Date();

    public constructor(
        private readonly items: NormalizedItem[] = [],
        kind: ActivitySourceKind = 'Message',
        private readonly issues: string[] = [],
    ) {
        super();
        this.Kind = kind;
    }

    /**
     * The instant a CALENDAR fixture reports as its watermark. Injectable so a
     * check can assert an exact value instead of racing the clock. Messages
     * still use max(StartedAt) via Kind.
     */
    protected override Now(): Date {
        return this.fetchedAt;
    }

    protected async FetchRaw(query: ActivitySourceQuery): Promise<RawBatch> {
        this.Calls.push(query);
        const since = query.Since ? query.Since.getTime() : null;
        const eligible = this.items
            .filter((item) => since === null || item.StartedAt.getTime() > since)
            .sort((a, b) => a.StartedAt.getTime() - b.StartedAt.getTime())
            .slice(0, Math.max(0, query.Limit));
        return {
            Payloads: eligible.map((item) => ({ item })),
            Issues: [...this.issues],
        };
    }

    protected Normalize(raw: RawBatch): NormalizedItem[] {
        return raw.Payloads.map((p) => p.item as NormalizedItem);
    }
}
