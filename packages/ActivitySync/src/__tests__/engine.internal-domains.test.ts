import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

/**
 * bc-aidp: `ActivitySyncEngine` passed a hard-coded `[]` for `InternalDomains`, so every participant
 * counted as External — `HasExternal` matched everything, including the internal chatter it exists to
 * exclude, and `AllInternal` matched nothing.
 *
 * ── WHY THIS FILE EXISTS ALONGSIDE `internal-domains.test.ts` ───────────────────────────────────
 *
 * That file names this defect in its header and then tests only the pure functions in
 * `participants.ts`. Its "end to end" block calls `ClassifyParticipants([...], [])` — supplying `[]`
 * as a literal argument, which is the very value the engine was supposed to stop producing. It proves
 * what an empty list DOES; it cannot notice the engine handing one over.
 *
 * Measured: reverting the fix to `InternalDomains: []` passed 330 of 330. So did removing the
 * malformed-domains failure. Both are the original defect, and neither was detectable, because the one
 * test that drives `ActivitySyncEngine.Run` stubs `RunView` to return an empty result for every entity
 * except Connections — so rule sets and domains were only ever exercised in their empty case, where
 * "loaded correctly" and "never loaded" are indistinguishable.
 *
 * ── HOW THIS ONE SEES IT ────────────────────────────────────────────────────────────────────────
 *
 * The stub returns real rows for the binding and the rule set, and the engine is constructed with a
 * SPY STAGE. Stages are the third constructor parameter, and the engine hands each one the
 * `EngineQualificationContext` it just built — so the spy observes exactly what the engine produced,
 * rather than what a test hoped it produced.
 */

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const SET = '8c1b9a44-0f2e-4d55-9b31-7a6c5e2d1f00';

/** What the rule set carries, and what the engine must therefore hand the cascade. */
const DOMAINS_JSON = '["bluecypress.io", "example.test"]';

let ruleSetInternalDomains: string | null = DOMAINS_JSON;

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { EntityName?: string }) {
            const name = params.EntityName ?? '';
            if (name === 'MJ_BizApps_Common: Activity Sync Connections') {
                return {
                    Success: true,
                    Results: [
                        {
                            ID: CONN,
                            Status: 'Active',
                            Provider: 'Microsoft365',
                            Mailbox: 'box@tenant.test',
                            StartAt: null,
                            EndAt: null,
                            LastSyncAt: null,
                            ActivitySyncProviderTypeID: null,
                            SkippedContentPolicy: null,
                            Settings: null,
                        },
                    ],
                };
            }
            // The binding. Without a non-empty set list the engine short-circuits and never loads
            // domains at all — which is how the original stub hid the defect.
            if (name === 'MJ_BizApps_Common: Activity Sync Connection Rule Sets') {
                return { Success: true, Results: [{ ID: 'bind-1', ActivitySyncRuleSetID: SET }] };
            }
            if (name === 'MJ_BizApps_Common: Activity Sync Rule Sets') {
                return {
                    Success: true,
                    Results: [{ ID: SET, Name: 'Default', InternalDomains: ruleSetInternalDomains }],
                };
            }
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { ActivitySyncEngine } from '../ActivitySyncEngine.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import type { IdentityResolver, IdentityResolution } from '../identity.js';
import type { ActivityWriter, WriteActivityInput } from '../writer.js';
import type { NormalizedItem } from '../types.js';
import type { IQualificationStage, QualificationContext, QualificationVerdict } from '../qualification.js';
import type { EngineQualificationContext } from '../stages.js';

const ITEM: NormalizedItem = {
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Q3 renewal',
    Body: 'body',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Participants: [{ Address: 'alice@customer.com', Name: null, Role: 'From', IdentityKind: 'Email' }],
    HasAttachments: false,
    Location: null,
    Direction: 'Inbound',
    Cancelled: false,
    Raw: {},
};

/** Records the context the engine builds, then lets the item through unchanged. */
class SpyStage implements IQualificationStage {
    public readonly Name = 'spy';
    public readonly RequiresInference = false;
    public Seen: EngineQualificationContext[] = [];
    public async Evaluate(_item: NormalizedItem, context: QualificationContext): Promise<QualificationVerdict> {
        // The engine always builds an EngineQualificationContext; the interface is the narrower one.
        this.Seen.push(context as EngineQualificationContext);
        return { Decision: 'Include', Reason: 'spy', StageName: this.Name };
    }
}

async function runWith(stage: SpyStage) {
    const known: IdentityResolution = {
        LookupFailed: false,
        Resolved: [{ Kind: 'Person', RecordID: 'person-1', Role: 'From' }],
        Unresolved: [],
        Known: new Map([
            ['alice@customer.com', { Address: 'alice@customer.com', PersonID: 'person-1', OrganizationID: null }],
        ]),
    };
    const resolver = { Resolve: async () => known } as unknown as IdentityResolver;
    const writes: WriteActivityInput[] = [];
    const writer = {
        Write: async (input: WriteActivityInput) => {
            writes.push(input);
            return {
                Success: true,
                ActivityID: 'act-1',
                AlreadyPresent: false,
                Links: [],
                Activity: { ID: 'act-1' },
                Issues: [],
            };
        },
    } as unknown as ActivityWriter;
    const entity = () => ({ NewRecord: () => undefined, Load: async () => true, Save: async () => true, LatestResult: {} });
    const provider = { Entities: [], GetEntityObject: async () => entity() } as unknown as IMetadataProvider;

    const engine = new ActivitySyncEngine(resolver, writer, [stage]);
    const result = await engine.Run(
        CONN,
        { DryRun: false, TriggerType: 'Manual', Limit: 10 },
        provider,
        { ID: 'user-1' } as UserInfo,
        new FixtureActivitySyncProvider([ITEM], 'Message'),
    );
    return { result, writes };
}

describe('the engine hands the cascade the domains it loaded', () => {
    it('passes the rule set’s InternalDomains through, not an empty list', async () => {
        ruleSetInternalDomains = DOMAINS_JSON;
        const stage = new SpyStage();
        const { result } = await runWith(stage);

        expect(result.Success, 'the run itself must succeed').toBe(true);
        expect(stage.Seen, 'the stage must have been reached at all').toHaveLength(1);

        // THE ASSERTION THE OLD SUITE COULD NOT MAKE. Reverting the engine to `InternalDomains: []`
        // fails here and nowhere else.
        expect([...stage.Seen[0].InternalDomains].sort()).toEqual(['bluecypress.io', 'example.test']);
    });

    it('fails the run when the column cannot be parsed, rather than degrading to empty', async () => {
        /**
         * The other half, and the one the changeset promises: a typo in InternalDomains must fail
         * CLOSED. Degrading to `[]` is indistinguishable from the original defect — every participant
         * external, silently — which is exactly why "it just came back empty" is not an acceptable
         * outcome here.
         */
        ruleSetInternalDomains = '{not json';
        const stage = new SpyStage();
        const { result } = await runWith(stage);

        expect(result.Success, 'a malformed domain list must not produce a green run').toBe(false);
        expect(stage.Seen, 'and nothing may be qualified against a list that failed to load').toHaveLength(0);
        ruleSetInternalDomains = DOMAINS_JSON;
    });
});
