/**
 * Microsoft Graph mail. Written, typechecked, and refused until an Exchange Application
 * Access Policy scopes app-only Mail.Read. Fixture is how the engine is exercised.
 */
import { LogError } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';

import { BaseActivitySyncProvider } from '../BaseActivitySyncProvider.js';
import type { ActivitySourceQuery, NormalizedItem, RawBatch } from '../types.js';
import { MapGraphMessages } from './GraphMessageMapper.js';

export const LIVE_GRAPH_REFUSAL =
    'Live Graph fetch is disabled. MSGraphProvider uses app-only auth, so Mail.Read reads ' +
    'EVERY mailbox in the tenant until an Exchange Application Access Policy scopes the ' +
    'app registration to a security group. Confirm that policy exists before enabling ' +
    'this, and use FixtureActivitySyncProvider until then.';

@RegisterClass(BaseActivitySyncProvider, 'Microsoft365')
export class MSGraphActivitySyncProvider extends BaseActivitySyncProvider {
    public readonly Kind = 'Message' as const;
    public readonly ProviderTypeCode = 'Microsoft365';
    public readonly IsLive = true;

    public constructor(
        /**
         * Default FALSE. Turning it on is a deliberate act by someone who has confirmed
         * the Application Access Policy exists. This PR never does that.
         */
        private readonly AllowLiveFetch: boolean = false,
    ) {
        super();
    }

    protected async FetchRaw(query: ActivitySourceQuery): Promise<RawBatch> {
        if (!this.AllowLiveFetch) {
            return { Payloads: [], Issues: [LIVE_GRAPH_REFUSAL] };
        }
        LogError(`MSGraphActivitySyncProvider.FetchRaw was enabled for ${query.Mailbox} — not supported in this build.`);
        return {
            Payloads: [],
            Issues: [
                'Live Graph fetch was opted in but no mailbox transport is wired in this package. ' +
                    'Keep AllowLiveFetch false and use FixtureActivitySyncProvider.',
            ],
        };
    }

    protected Normalize(raw: RawBatch, query: ActivitySourceQuery): NormalizedItem[] {
        if (raw.Payloads.length === 0) return [];
        const mapped = MapGraphMessages(raw.Payloads.length === 1 ? raw.Payloads[0] : raw.Payloads, query.Mailbox);
        raw.Issues.push(...mapped.Issues);
        const since = query.Since ? query.Since.getTime() : null;
        return since === null ? mapped.Items : mapped.Items.filter((i) => i.StartedAt.getTime() > since);
    }
}
