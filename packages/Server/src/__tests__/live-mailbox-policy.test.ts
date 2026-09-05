/**
 * The host's live-mailbox opt-in, read from deployment configuration.
 *
 * WHAT THESE DEFEND. App-only `Mail.Read` reads every mailbox in the tenant, so the two failure
 * modes are not symmetric: refusing when we should allow costs a demo, and allowing when we should
 * refuse hands out tenant-wide mail access. Most of what follows pins the second — that an absent,
 * blank, or half-written configuration leaves the gate SHUT.
 *
 * The partial-configuration case gets its own tests because a silent no-op there is the specific
 * trap this codebase keeps falling into: an operator who set two of three variables would see the
 * provider refuse and go hunting in Exchange for a fault that is actually in their .env.
 */
import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { AllowLiveMailboxFetch, HostAllowsLiveMailboxFetch, HostLiveMailboxPolicy } from '@mj-biz-apps/common-activity-sync';

import {
    ENV_ACCEPTED_RISK,
    ENV_CONFIRMED_AT,
    ENV_CONFIRMED_BY,
    ENV_GROUP,
    LoadLiveMailboxPolicyFromEnv,
} from '../custom/live-mailbox-policy.js';

const COMPLETE = {
    [ENV_GROUP]: 'activity-sync-mailboxes@bluecypress.io',
    [ENV_CONFIRMED_BY]: 'Josue Garcia',
    [ENV_CONFIRMED_AT]: '2026-09-04T00:00:00Z',
} as NodeJS.ProcessEnv;

beforeEach(() => AllowLiveMailboxFetch(null));
afterEach(() => AllowLiveMailboxFetch(null)); // process-wide — never leak an opt-in between tests

describe('a host that has not opted in', () => {
    it('stays refused on an empty environment, without complaining', () => {
        expect(LoadLiveMailboxPolicyFromEnv({})).toBe(false);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    /** Blank is not "set". An empty var in a .env template must not read as an opt-in. */
    it('treats blank and whitespace-only variables as absent', () => {
        const env = { [ENV_GROUP]: '', [ENV_CONFIRMED_BY]: '   ', [ENV_CONFIRMED_AT]: '' } as NodeJS.ProcessEnv;
        expect(LoadLiveMailboxPolicyFromEnv(env)).toBe(false);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    it('ignores unrelated variables', () => {
        expect(LoadLiveMailboxPolicyFromEnv({ DB_HOST: 'localhost' } as NodeJS.ProcessEnv)).toBe(false);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });
});

describe('a fully configured host', () => {
    it('registers the attestation and reports that it did', () => {
        expect(LoadLiveMailboxPolicyFromEnv(COMPLETE)).toBe(true);
        expect(HostAllowsLiveMailboxFetch()).toBe(true);
    });

    it('records what was attested, so an audit can ask who allowed this', () => {
        LoadLiveMailboxPolicyFromEnv(COMPLETE);
        expect(HostLiveMailboxPolicy()).toEqual({
            Confirmed: true,
            Scope: 'RestrictedToGroup',
            ScopedToGroup: 'activity-sync-mailboxes@bluecypress.io',
            ConfirmedBy: 'Josue Garcia',
            ConfirmedAt: new Date('2026-09-04T00:00:00Z'),
        });
    });

    it('trims surrounding whitespace rather than storing it', () => {
        LoadLiveMailboxPolicyFromEnv({
            ...COMPLETE,
            [ENV_GROUP]: '  group@bluecypress.io  ',
            [ENV_CONFIRMED_BY]: '  Josue  ',
        } as NodeJS.ProcessEnv);
        expect(HostLiveMailboxPolicy()?.ScopedToGroup).toBe('group@bluecypress.io');
        expect(HostLiveMailboxPolicy()?.ConfirmedBy).toBe('Josue');
    });

    it('does not require process.env — the environment is injected', () => {
        // Proof the function under test reads its argument. If it read process.env instead, this
        // would return false, because nothing set these on the real environment.
        expect(LoadLiveMailboxPolicyFromEnv(COMPLETE)).toBe(true);
        expect(process.env[ENV_GROUP]).toBeUndefined();
    });
});

describe('a partial configuration fails loudly instead of quietly staying off', () => {
    for (const missing of [ENV_CONFIRMED_BY, ENV_CONFIRMED_AT]) {
        it(`throws when ${missing} is the one left out`, () => {
            const env = { ...COMPLETE };
            delete env[missing];
            expect(() => LoadLiveMailboxPolicyFromEnv(env)).toThrow(/partially configured/);
            expect(HostAllowsLiveMailboxFetch()).toBe(false);
        });
    }

    /**
     * The message names what is MISSING. It no longer names what is set: with two possible
     * decisions, listing the one variable somebody happened to set reads as approval of that
     * choice rather than as a report of what is absent.
     */
    it('names what is missing, so the fix is obvious', () => {
        const env = { [ENV_GROUP]: 'g@bluecypress.io' } as NodeJS.ProcessEnv;
        // Substrings rather than one regex: the two names can appear in either order, and a
        // regex that pinned the order would fail on a harmless rewording of the message.
        expect(() => LoadLiveMailboxPolicyFromEnv(env)).toThrow(ENV_CONFIRMED_BY);
        expect(() => LoadLiveMailboxPolicyFromEnv(env)).toThrow(ENV_CONFIRMED_AT);
    });

    it('rejects a confirmation date that is not a date', () => {
        const env = { ...COMPLETE, [ENV_CONFIRMED_AT]: 'last tuesday' } as NodeJS.ProcessEnv;
        expect(() => LoadLiveMailboxPolicyFromEnv(env)).toThrow(/not a valid date/);
        expect(HostAllowsLiveMailboxFetch()).toBe(false);
    });

    /** A throw must not leave the gate half-open. */
    it('leaves an existing attestation untouched when a later load throws', () => {
        LoadLiveMailboxPolicyFromEnv(COMPLETE);
        const before = HostLiveMailboxPolicy();
        expect(() => LoadLiveMailboxPolicyFromEnv({ [ENV_GROUP]: 'x@y.z' } as NodeJS.ProcessEnv)).toThrow();
        expect(HostLiveMailboxPolicy()).toEqual(before);
    });
});
