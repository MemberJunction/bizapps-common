/**
 * The opt-in has to SAY it happened.
 *
 * Separate file because it mocks `@memberjunction/core` wholesale, and the sibling suite
 * deliberately runs against the real one.
 *
 * WHY THIS IS WORTH A TEST. `ConfirmedAt` exists because "policies get deleted; staleness should be
 * visible" — and nothing was making it visible. It was written into the attestation and then read by
 * nothing: reachable only through `HostLiveMailboxPolicy()`, which has no callers in this repo. A
 * recorded decision that nobody surfaces is the same silent shape the rest of this work exists to
 * remove, so the line that surfaces it gets pinned rather than left to be deleted as noise later.
 *
 * The assertions are about CONTENT, not about the fact that something was logged: a line that omits
 * who confirmed it, or when, or which of the two decisions was made, would satisfy a bare
 * "was called" check while leaving an operator none the wiser.
 */
import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';

const { logStatus } = vi.hoisted(() => ({ logStatus: vi.fn() }));

vi.mock('@memberjunction/core', () => ({
    LogStatus: logStatus,
    LogError: () => undefined,
    RunView: class {
        public async RunView() {
            return { Success: true, Results: [] };
        }
    },
}));

import { AllowLiveMailboxFetch } from '@mj-biz-apps/common-activity-sync';
import {
    ENV_ACCEPTED_RISK,
    ENV_CONFIRMED_AT,
    ENV_CONFIRMED_BY,
    ENV_GROUP,
    LoadLiveMailboxPolicyFromEnv,
} from '../custom/live-mailbox-policy.js';

beforeEach(() => {
    logStatus.mockClear();
    AllowLiveMailboxFetch(null);
});
afterEach(() => AllowLiveMailboxFetch(null));

/** The single line this host would print at bootstrap, or undefined if it printed none. */
const logged = () => logStatus.mock.calls.map((c) => String(c[0])).find((m) => /LIVE mailbox fetch/i.test(m));

describe('enabling live fetch is announced at bootstrap', () => {
    it('names the group, the person and the date when the app is restricted', () => {
        LoadLiveMailboxPolicyFromEnv({
            [ENV_GROUP]: 'activity-sync-mailboxes@bluecypress.io',
            [ENV_CONFIRMED_BY]: 'Josue Garcia',
            [ENV_CONFIRMED_AT]: '2026-09-04T00:00:00Z',
        } as NodeJS.ProcessEnv);

        const line = logged();
        expect(line, 'enabling live mailbox fetch must be announced').toBeDefined();
        expect(line).toMatch(/ENABLED/);
        expect(line).toMatch(/activity-sync-mailboxes@bluecypress\.io/);
        expect(line).toMatch(/Josue Garcia/);
        // The whole reason ConfirmedAt is recorded: staleness has to be readable at a glance.
        expect(line).toMatch(/2026-09-04/);
    });

    it('says which decision was made — tenant-wide is not the same as restricted', () => {
        LoadLiveMailboxPolicyFromEnv({
            [ENV_ACCEPTED_RISK]: 'No Exchange assignment; accepted for the pilot tenant.',
            [ENV_CONFIRMED_BY]: 'Josue Garcia',
            [ENV_CONFIRMED_AT]: '2026-09-04T00:00:00Z',
        } as NodeJS.ProcessEnv);

        const line = logged();
        expect(line).toMatch(/tenant-wide/i);
        expect(line).toMatch(/accepted for the pilot tenant/i);
        // Reporting a tenant-wide grant as group-restricted is the one error that matters here.
        expect(line).not.toMatch(/restricted to group/i);
    });

    it('says nothing at all when the host has not opted in', () => {
        const enabled = LoadLiveMailboxPolicyFromEnv({} as NodeJS.ProcessEnv);

        expect(enabled).toBe(false);
        expect(logged()).toBeUndefined();
    });

    it('says nothing when the configuration is rejected', () => {
        expect(() =>
            LoadLiveMailboxPolicyFromEnv({
                [ENV_GROUP]: 'activity-sync-mailboxes@bluecypress.io',
                [ENV_CONFIRMED_BY]: 'Josue Garcia',
                // no ConfirmedAt — a partial opt-in must throw, and must not announce success first
            } as NodeJS.ProcessEnv),
        ).toThrow(/partially configured/);

        expect(logged()).toBeUndefined();
    });
});
