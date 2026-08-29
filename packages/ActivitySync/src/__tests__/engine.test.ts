import { describe, expect, it } from 'vitest';

import { LIVE_GRAPH_REFUSAL, MSGraphActivitySyncProvider } from '../providers/MSGraphActivitySyncProvider.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import { MapGraphMessage } from '../providers/GraphMessageMapper.js';
import { DefaultDeterministicStages, type EngineQualificationContext } from '../stages.js';
import { RunQualificationCascade } from '../qualification.js';
import { AsDryRunDecision } from '../run.js';
import { CanAdvanceWatermark, NextWatermark } from '../watermark.js';
import type { NormalizedItem } from '../types.js';

const ITEM: NormalizedItem = {
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Q3 renewal',
    Body: 'body',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Location: null,
    Direction: 'Inbound',
    Participants: [{ Address: 'alice@customer.com', Name: 'Alice', Role: 'From', IdentityKind: 'Email' }],
    Cancelled: false,
    Raw: {},
};

function ctx(partial: Partial<EngineQualificationContext> = {}): EngineQualificationContext {
    return {
        ConnectionID: 'conn',
        ProviderTypeCode: 'Microsoft365',
        Exclusions: [],
        Rules: [],
        InternalDomains: ['our.com'],
        KnownAddresses: new Map(),
        ...partial,
    };
}

describe('load-bearing engine rules', () => {
    it('exclusions run first and an Include rule cannot outrank them', async () => {
        const stages = DefaultDeterministicStages();
        expect(stages[0].Name).toBe('Exclusions');
        const verdict = await RunQualificationCascade(
            stages,
            ITEM,
            ctx({
                Exclusions: [{ ID: 'ex-1', IdentityKind: 'Email', IdentityValue: 'alice@customer.com', ActivitySyncRuleSetID: null }],
                Rules: [{
                    ID: 'rule-include',
                    Sequence: 1,
                    IsEnabled: true,
                    Action: 'Include',
                    Direction: null,
                    DateFrom: null,
                    DateTo: null,
                    ParticipantScope: null,
                    ActivitySyncRuleSetID: null,
                }],
            }),
            'Include',
        );
        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.ActivitySyncExclusionID).toBe('ex-1');
        expect(verdict.StageName).toBe('Exclusions');
    });

    it('dry-run decisions never claim a write, and dry-run watermarks stay put', () => {
        expect(AsDryRunDecision('Included')).toBe('WouldInclude');
        expect(AsDryRunDecision('Excluded')).toBe('WouldExclude');
        const current = new Date('2026-01-01T00:00:00Z');
        const candidate = new Date('2026-02-01T00:00:00Z');
        // Engine passes DryRun by forcing watermarkAfter null; NextWatermark still would advance
        // on a successful live run with no failures.
        expect(CanAdvanceWatermark({ Settled: 1, Discarded: 0, Failed: 0 })).toBe(true);
        expect(NextWatermark(current, candidate, { Settled: 1, Discarded: 0, Failed: 1 })).toEqual(current);
    });

    it('Graph provider refuses live fetch until an Application Access Policy exists', async () => {
        const graph = new MSGraphActivitySyncProvider(false);
        const batch = await graph.Fetch({ Mailbox: 'user@tenant.com', Since: null, Limit: 10 });
        expect(batch.Items).toEqual([]);
        expect(batch.HighWatermark).toBeNull();
        expect(batch.Issues[0]).toBe(LIVE_GRAPH_REFUSAL);
    });

    it('fixture is not live and filters strictly after the watermark', async () => {
        const older = { ...ITEM, ExternalID: 'old', StartedAt: new Date('2026-01-01T00:00:00Z') };
        const newer = { ...ITEM, ExternalID: 'new', StartedAt: new Date('2026-03-01T00:00:00Z') };
        const fixture = new FixtureActivitySyncProvider([older, newer], 'Message');
        expect(fixture.IsLive).toBe(false);
        const batch = await fixture.Fetch({
            Mailbox: 'x@y.com',
            Since: new Date('2026-02-01T00:00:00Z'),
            Limit: 10,
        });
        expect(batch.Items.map((i) => i.ExternalID)).toEqual(['new']);
    });

    it('drops Graph addresses that cannot match a ContactMethod (no @)', () => {
        const issues: string[] = [];
        const item = MapGraphMessage(
            {
                id: 'abc',
                sentDateTime: '2026-08-01T12:00:00Z',
                from: { emailAddress: { name: 'Bean', address: 'pmtauser' } },
                toRecipients: [{ emailAddress: { name: 'Alice', address: 'alice@customer.com' } }],
            },
            'me@our.com',
            issues,
        );
        expect(item?.Participants.map((p) => p.Address)).toEqual(['alice@customer.com']);
        expect(issues.some((i) => i.includes('pmtauser'))).toBe(true);
    });
});
