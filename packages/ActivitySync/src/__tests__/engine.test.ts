import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

import { LIVE_GRAPH_REFUSAL, MSGraphActivitySyncProvider } from '../providers/MSGraphActivitySyncProvider.js';
import {
    LIVE_GRAPH_CALENDAR_REFUSAL,
    MapGraphEvent,
    MSGraphCalendarSyncProvider,
} from '../providers/MSGraphCalendarSyncProvider.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import { MapGraphMessage } from '../providers/GraphMessageMapper.js';
import { DefaultDeterministicStages, type EngineQualificationContext } from '../stages.js';
import { RunQualificationCascade } from '../qualification.js';
import { AsDryRunDecision } from '../run.js';
import { CanAdvanceWatermark, NextWatermark } from '../watermark.js';
import type { NormalizedItem } from '../types.js';

const SRC = join(dirname(fileURLToPath(import.meta.url)), '..');

const ITEM: NormalizedItem = {
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Q3 renewal',
    Body: 'body',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Location: null,
    HasAttachments: false,
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
                    IncludeAttachments: false,
                    MaxAttachmentBytes: null,
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
        expect(batch.Failed).toBeFalsy();
    });

    it('a thrown FetchRaw is a failed look, not an empty mailbox', async () => {
        const { BaseActivitySyncProvider } = await import('../BaseActivitySyncProvider.js');
        class Boom extends BaseActivitySyncProvider {
            public readonly Kind = 'Message' as const;
            public readonly ProviderTypeCode = 'X';
            public readonly IsLive = false;
            protected async FetchRaw(): Promise<{ Payloads: Record<string, never>[]; Issues: string[] }> {
                throw new Error('mailbox gone');
            }
            protected Normalize(): NormalizedItem[] {
                return [];
            }
        }
        const batch = await new Boom().Fetch({ Mailbox: 'gone@x.test', Since: null, Limit: 10 });
        expect(batch.Failed).toBe(true);
        expect(batch.Items).toEqual([]);
        expect(batch.HighWatermark).toBeNull();
        expect(batch.Issues[0]).toMatch(/mailbox gone/);
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

    it('calendar Graph provider refuses live fetch until an Application Access Policy exists', async () => {
        const graph = new MSGraphCalendarSyncProvider(false);
        const batch = await graph.Fetch({ Mailbox: 'user@tenant.com', Since: null, Limit: 10 });
        expect(batch.Items).toEqual([]);
        expect(batch.HighWatermark).toBeNull();
        expect(batch.Issues[0]).toBe(LIVE_GRAPH_CALENDAR_REFUSAL);
    });

    it('calendar Graph reports observation time, not the event start', async () => {
        const eventStart = '2031-12-01T10:00:00.0000000';
        // A transport rather than the old `GraphEventFetcher`: that seam was never implemented and
        // was reachable only through a constructor ClassFactory does not use. Calendar now rides the
        // same ActivityMessageTransport as mail.
        const transport = {
            calls: 0,
            Describe: 'stub',
            IsLive: true,
            async Fetch() {
                this.calls++;
                return {
                    Payloads: [
                        {
                            id: 'ac21-far-future-event',
                            subject: 'planning',
                            start: { dateTime: eventStart, timeZone: 'UTC' },
                            end: { dateTime: '2031-12-01T11:00:00.0000000', timeZone: 'UTC' },
                            organizer: { emailAddress: { address: 'organiser@example.invalid' } },
                            attendees: [{ emailAddress: { address: 'attendee@example.invalid' } }],
                        },
                    ] as Record<string, unknown>[],
                    Issues: [] as string[],
                };
            },
        };
        const before = Date.now();
        const source = new MSGraphCalendarSyncProvider(true, transport);
        const batch = await source.Fetch({ Mailbox: 'ac21@example.invalid', Since: null, Limit: 10 });
        const after = Date.now();
        expect(transport.calls).toBe(1);
        expect(batch.Items).toHaveLength(1);
        expect(batch.Items[0].TypeCode).toBe('Meeting');
        expect(batch.HighWatermark).toBeTruthy();
        expect(batch.HighWatermark!.getTime()).toBeLessThan(batch.Items[0].StartedAt.getTime());
        expect(batch.HighWatermark!.getTime()).toBeGreaterThanOrEqual(before);
        expect(batch.HighWatermark!.getTime()).toBeLessThanOrEqual(after);
        const mapped = MapGraphEvent(
            {
                id: 'x',
                start: { dateTime: eventStart, timeZone: 'UTC' },
                organizer: { emailAddress: { address: 'a@b.c' } },
            },
            [],
        );
        expect(mapped?.Direction).toBe('Internal');
        expect(mapped?.Participants[0].Role).toBe('Organizer');
    });

    it('invokes extensions inside the write transaction, before commit', () => {
        const engine = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        const writer = readFileSync(join(SRC, 'writer.ts'), 'utf8');
        expect(engine).toMatch(/OnWritten:/);
        expect(engine).toMatch(/RunRegisteredExtensions/);
        expect(writer).toMatch(/await onWritten\(writeContext\)/);
        // The dispatch seam (afterLinks) runs inside the transactional core, before the commit.
        expect(writer.indexOf('result.Links = await afterLinks(')).toBeGreaterThan(-1);
        expect(writer.indexOf('await afterLinks(')).toBeLessThan(writer.indexOf('await scope.Commit()'));
    });

    it('keys the companion calendar on CalendarDriverClass, not Connection.Provider', () => {
        const engine = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        expect(engine).toMatch(/CalendarDriverClass/);
        expect(engine).toMatch(/resolvePlugin\(calendarDriver\)/);
        expect(engine).not.toMatch(/new MSGraphCalendarSyncProvider\(\)/);
        expect(engine).not.toMatch(/connection\.Provider \?\? ''\) === 'Microsoft365'/);
    });

    it('stamps connection health from the combined surfaces, not per Run', () => {
        const engine = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        expect(engine).toMatch(/stampHealth: false/);
        expect(engine).toMatch(/healthErrorFromResults\(surfaces\)/);
        expect(engine).not.toMatch(/result\.Issues\[0\] \?\? \(result\.Success/);
    });

    it('stamps extension LastRunAt once per row after the item loop', () => {
        const engine = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        expect(engine).toMatch(/collapseExtensionStamps\(extensionStamps\)/);
        const loop = engine.match(/for \(const item of batch\.Items\) \{([\s\S]*?)\n        \}/);
        expect(loop?.[1]).toBeTruthy();
        expect(loop![1]).not.toMatch(/stampExtensions/);
    });

    it('caps the fleet connection load without false-positiving at exactly the cap', () => {
        const engine = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        expect(engine).toMatch(/MaxRows: MAX_RUNNABLE_CONNECTIONS \+ 1/);
        expect(engine).toMatch(/rows\.length > MAX_RUNNABLE_CONNECTIONS/);
    });

    it('loads CalendarDriverClass by name, not via SELECT *', () => {
        const engine = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        expect(engine).toMatch(/Fields: \['ID', 'Code', 'DriverClass', 'DefaultQualificationPolicy', 'CalendarDriverClass'\]/);
    });

    it('stores a cancelled meeting as Cancelled, not Logged', () => {
        const writer = readFileSync(join(SRC, 'writer.ts'), 'utf8');
        expect(writer).toMatch(/activity\.Status = input\.Item\.Cancelled \? 'Cancelled' : 'Logged'/);
    });

    it('checks ActivitySyncRunDetail.Save and does not abort the detail loop', () => {
        const source = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        const loop = source.match(/for \(const detail of details\) \{([\s\S]*?)\n            \}/);
        expect(loop?.[1]).toBeTruthy();
        const body = loop![1];
        expect(body).toMatch(/if \(!\(await row\.Save\(\)\)\)/);
        expect(body).toMatch(/result\.Issues\.push\(/);
        expect(body).toMatch(/row\.LatestResult\?\.CompleteMessage/);
        expect(body).not.toMatch(/\breturn;/);
        expect(body).not.toMatch(/\bbreak;/);
    });
});
