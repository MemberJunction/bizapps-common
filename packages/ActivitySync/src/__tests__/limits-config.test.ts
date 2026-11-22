import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Metadata, RunView, UserInfo } from '@memberjunction/core';
import { afterEach, describe, expect, it, vi } from 'vitest';
import {
    ACTIVITY_SYNC_LIMITS_BOUNDS,
    ActivitySyncEngine,
    BodyForStorage,
    DEFAULT_ACTIVITY_SYNC_LIMITS,
    GetRegisteredActivitySyncLimits,
    MAX_RUNNABLE_CONNECTIONS,
    RegisterActivitySyncLimits,
    ResetActivitySyncLimits,
    ResolveActivitySyncLimits,
} from '../index.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const SRC_ROOT = resolve(HERE, '..');

describe('ActivitySync Limits Configuration Resolver', () => {
    afterEach(() => {
        ResetActivitySyncLimits();
        vi.restoreAllMocks();
    });

    it('resolves canonical defaults and documents zero RunawayGuard hits', () => {
        const resolved = ResolveActivitySyncLimits();
        expect(resolved).toEqual(DEFAULT_ACTIVITY_SYNC_LIMITS);
        expect(resolved.RunawayGuards.ZeroHitsConfirmed).toBe(true);
        expect(resolved.ResourceGuards.MaxRunnableConnections).toBe(500);
        expect(resolved.ResourceGuards.MaxSweepRequests).toBe(48);
        expect(resolved.ResourceGuards.MaxWithdrawChecks).toBe(500);
        expect(resolved.ResourceGuards.MaxAncestorReferences).toBe(20);
        expect(resolved.ResourceGuards.MaxCalendarPages).toBe(10);
        expect(resolved.ResourceGuards.MaxMailRequests).toBe(16);
        expect(resolved.Tuning.SweepOverlapMs).toBe(600_000);
        expect(resolved.Tuning.RereadBatchSize).toBe(10);
        expect(resolved.Tuning.WithdrawWindowDays).toBe(30);
        expect(resolved.Tuning.FirstRunLookbackDays).toBe(30);
        expect(resolved.Tuning.ForwardHorizonDays).toBe(30);
        expect(resolved.Tuning.MessageIdBatchSize).toBe(10);
        expect(resolved.Tuning.BodySnippetChars).toBe(500);
    });

    it('applies runtime overrides with bounds clamping and BodyForStorage wiring', () => {
        RegisterActivitySyncLimits({
            ResourceGuards: { MaxCalendarPages: 9999 },
            Tuning: { BodySnippetChars: 120 },
        });
        expect(GetRegisteredActivitySyncLimits()?.Tuning?.BodySnippetChars).toBe(120);

        const resolved = ResolveActivitySyncLimits();
        expect(resolved.ResourceGuards.MaxCalendarPages).toBe(
            ACTIVITY_SYNC_LIMITS_BOUNDS.ResourceGuards.MaxCalendarPages.Max,
        );
        expect(resolved.Tuning.BodySnippetChars).toBe(120);
        expect(BodyForStorage('a'.repeat(200), 'Snippet')).toHaveLength(120);
    });

    it('falls back to safe defaults on invalid numeric overrides', () => {
        const resolved = ResolveActivitySyncLimits({
            ResourceGuards: { MaxSweepRequests: Number.NaN, MaxMailRequests: -5 },
            Tuning: { BodySnippetChars: Number.POSITIVE_INFINITY },
        });
        expect(resolved.ResourceGuards.MaxSweepRequests).toBe(48);
        expect(resolved.ResourceGuards.MaxMailRequests).toBe(16);
        expect(resolved.Tuning.BodySnippetChars).toBe(500);
    });

    it('carries inline ProtocolLimit rationale comments at all 5 ProtocolLimit sites', () => {
        const consentIntake = readFileSync(resolve(SRC_ROOT, 'consent-intake.ts'), 'utf8');
        const mailTransport = readFileSync(resolve(SRC_ROOT, 'providers/GraphCommunicationTransport.ts'), 'utf8');
        const writer = readFileSync(resolve(SRC_ROOT, 'writer.ts'), 'utf8');
        const resolver = readFileSync(resolve(SRC_ROOT, 'limits.config.ts'), 'utf8')
            .replace(/\/\*[\s\S]*?\*\//g, '')
            .replace(/\/\/.*$/gm, '');

        expect((consentIntake.match(/\/\/ ProtocolLimit:/g) ?? []).length).toBe(2);
        expect((mailTransport.match(/\/\/ ProtocolLimit:/g) ?? []).length).toBe(1);
        expect((writer.match(/\/\/ ProtocolLimit:/g) ?? []).length).toBe(2);
        expect(resolver).not.toMatch(/:\s*any\b|\bas\s+any\b|<any>|\bunknown\b/);
    });

    it('honors runtime MaxRunnableConnections overrides in ActivitySyncEngine.RunConnections', async () => {
        expect(MAX_RUNNABLE_CONNECTIONS).toBe(DEFAULT_ACTIVITY_SYNC_LIMITS.ResourceGuards.MaxRunnableConnections);
        RegisterActivitySyncLimits({ ResourceGuards: { MaxRunnableConnections: 2 } });

        const observedMaxRows: Array<number | undefined> = [];
        const stubConnections = [
            {
                ID: '11111111-1111-4111-8111-111111111111',
                Status: 'Active',
                Provider: null,
                Mailbox: 'one@example.test',
                CredentialsRef: null,
                StartAt: null,
                EndAt: null,
                LastSyncAt: null,
                ActivitySyncProviderTypeID: null,
                SkippedContentPolicy: null,
                EncryptionKeyID: null,
                Settings: null,
                OwnerUserID: null,
            },
            {
                ID: '22222222-2222-4222-8222-222222222222',
                Status: 'Active',
                Provider: null,
                Mailbox: 'two@example.test',
                CredentialsRef: null,
                StartAt: null,
                EndAt: null,
                LastSyncAt: null,
                ActivitySyncProviderTypeID: null,
                SkippedContentPolicy: null,
                EncryptionKeyID: null,
                Settings: null,
                OwnerUserID: null,
            },
            {
                ID: '33333333-3333-4333-8333-333333333333',
                Status: 'Active',
                Provider: null,
                Mailbox: 'three@example.test',
                CredentialsRef: null,
                StartAt: null,
                EndAt: null,
                LastSyncAt: null,
                ActivitySyncProviderTypeID: null,
                SkippedContentPolicy: null,
                EncryptionKeyID: null,
                Settings: null,
                OwnerUserID: null,
            },
        ];

        vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async (params) => {
            if (params.EntityName === 'MJ_BizApps_Common: Activity Sync Connections') {
                observedMaxRows.push(params.MaxRows);
                return {
                    Success: true,
                    Results: stubConnections,
                    RowCount: stubConnections.length,
                    TotalRowCount: stubConnections.length,
                    ExecutionTime: 1,
                    ErrorMessage: '',
                    UserViewID: '',
                    UserViewName: '',
                };
            }
            return {
                Success: true,
                Results: [],
                RowCount: 0,
                TotalRowCount: 0,
                ExecutionTime: 1,
                ErrorMessage: '',
                UserViewID: '',
                UserViewName: '',
            };
        });

        const engine = new ActivitySyncEngine(undefined, undefined, undefined, null, null);
        const provider = Metadata.Provider;
        const user = new UserInfo();
        user.ID = 'user-1';
        user.Name = 'Test';
        user.Email = 'test@example.test';

        const fleet = await engine.RunConnections({ DryRun: true, Limit: 10, TriggerType: 'Manual' }, provider, user);
        expect(observedMaxRows).toEqual([3]);
        expect(fleet.Success).toBe(false);
        expect(fleet.ConnectionsAttempted).toBe(2);
        expect(fleet.Issues.some((issue) => issue.includes('exceeded MaxRows=2'))).toBe(true);
    });
});
