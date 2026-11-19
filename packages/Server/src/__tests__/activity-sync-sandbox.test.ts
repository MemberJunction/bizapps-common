/**
 * The Activity Sync replay sandbox: a `sandbox:` CredentialsRef served from fixture files.
 *
 * WHAT THESE DEFEND. The sandbox is test mode on a production code path, so the dangerous failures
 * are the ones that blur test and live: a `sandbox:` ref looked up as a real credential, a host that
 * can serve fixtures AND read real mail, a fixture path built from an unchecked name, and a missing
 * fixture reported as "looked, found nothing". Each has a test below.
 *
 * Failures are asserted at `Fetch`, not at factory time, on purpose: a factory throw escapes the
 * engine before any ActivitySyncRun is saved, while a Fetch throw is recorded as a failed run.
 */
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import {
    AllowLiveMailboxFetch,
    HostActivityTransportFactory,
    RegisterActivityTransportFactory,
    type ActivityMessageTransport,
    type ActivitySourceQuery,
    type ActivityTransportContext,
    type ActivityTransportFactory,
} from '@mj-biz-apps/common-activity-sync';

import {
    ENV_SANDBOX_DIR,
    LoadActivitySyncSandboxFromEnv,
    SANDBOX_DISABLED_REFUSAL,
    SandboxAwareTransportFactory,
} from '../custom/activity-sync-sandbox.js';

const MAILBOX = 'rep@sandbox-internal.test';
const QUERY: ActivitySourceQuery = { Mailbox: MAILBOX, Since: null, Limit: 50 };

const STUB: ActivityMessageTransport = {
    Describe: 'inner stub',
    IsLive: true,
    Fetch: async () => ({ Payloads: [], Issues: [] }),
};

let dir: string;
let inner: ReturnType<typeof vi.fn<ActivityTransportFactory>>;

function context(ref: string | null, driver = 'Microsoft365'): ActivityTransportContext {
    return { CredentialsRef: ref, Mailbox: MAILBOX, DriverClass: driver };
}

function writeScenario(name: string, surface: 'mail' | 'calendar', ids: string[], mailbox = MAILBOX): void {
    writeFileSync(
        join(dir, `${name}.${surface}.json`),
        JSON.stringify({ mailbox, capturedAt: '2026-11-12T00:00:00Z', value: ids.map((id) => ({ id })) }),
    );
}

function build(ref: string | null, driver?: string, sandboxDir: string | null = dir): ActivityMessageTransport {
    const transport = SandboxAwareTransportFactory(inner, sandboxDir)(context(ref, driver));
    if (!transport) throw new Error('factory served no transport');
    return transport;
}

beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), 'as-sandbox-'));
    inner = vi.fn<ActivityTransportFactory>(() => STUB);
});

afterEach(() => {
    rmSync(dir, { recursive: true, force: true });
    AllowLiveMailboxFetch(null);
    RegisterActivityTransportFactory(null);
});

describe('a sandbox ref', () => {
    it('refuses a sandbox ref when the opt-in is off', async () => {
        const transport = build('sandbox:baseline', 'Microsoft365', null);
        expect(transport.IsLive).toBe(false);
        await expect(transport.Fetch(QUERY)).rejects.toThrow(SANDBOX_DISABLED_REFUSAL);
        expect(inner).not.toHaveBeenCalled();
    });

    it('serves the mail file for the primary pass and the calendar file for the calendar pass', async () => {
        writeScenario('baseline', 'mail', ['m1', 'm2']);
        writeScenario('baseline', 'calendar', ['e1']);

        const mail = await build('sandbox:baseline', 'Microsoft365').Fetch(QUERY);
        const calendar = await build('sandbox:baseline', 'Microsoft365.Calendar').Fetch(QUERY);

        expect(mail.Payloads.map((p) => p.id)).toEqual(['m1', 'm2']);
        expect(calendar.Payloads.map((p) => p.id)).toEqual(['e1']);
        expect(mail.Issues.join(' ')).toContain('baseline.mail.json');
        expect(inner).not.toHaveBeenCalled();
    });

    it('trims the ref before deciding', async () => {
        writeScenario('baseline', 'mail', ['m1']);
        const batch = await build('  sandbox:baseline  ').Fetch(QUERY);
        expect(batch.Payloads).toHaveLength(1);
    });

    it.each(['../etc', 'Baseline', '', 'a/b', 'a.b'])('rejects the scenario name "%s"', async (name) => {
        await expect(build(`sandbox:${name}`).Fetch(QUERY)).rejects.toThrow(`"${name}"`);
    });

    it('missing scenario file names the expected path', async () => {
        await expect(build('sandbox:nope').Fetch(QUERY)).rejects.toThrow(join(dir, 'nope.mail.json'));
    });

    it('an unparseable scenario file names the path', async () => {
        writeFileSync(join(dir, 'broken.mail.json'), '{ not json');
        await expect(build('sandbox:broken').Fetch(QUERY)).rejects.toThrow(join(dir, 'broken.mail.json'));
    });

    it('a scenario file without a value array is refused, not read as empty', async () => {
        writeFileSync(join(dir, 'novalue.mail.json'), JSON.stringify({ mailbox: MAILBOX }));
        await expect(build('sandbox:novalue').Fetch(QUERY)).rejects.toThrow('value');
    });

    it('a run tag suffixes every id, so two connections replaying one scenario never collide', async () => {
        writeFileSync(
            join(dir, 'baseline.calendar.json'),
            JSON.stringify({
                mailbox: MAILBOX,
                value: [{ id: 'e1', seriesMasterId: 's1', conversationId: null }, { id: 'e2', seriesMasterId: null }],
            }),
        );
        const tagged = await build('sandbox:baseline:run-7', 'Microsoft365.Calendar').Fetch(QUERY);
        expect(tagged.Payloads.map((p) => p.id)).toEqual(['e1.run-7', 'e2.run-7']);
        expect(tagged.Payloads.map((p) => p.seriesMasterId)).toEqual(['s1.run-7', null]);
        const plain = await build('sandbox:baseline', 'Microsoft365.Calendar').Fetch(QUERY);
        expect(plain.Payloads.map((p) => p.id)).toEqual(['e1', 'e2']);
    });

    it('suffixes the mail conversationId too', async () => {
        writeFileSync(join(dir, 'baseline.mail.json'), JSON.stringify({ mailbox: MAILBOX, value: [{ id: 'm1', conversationId: 'c1' }] }));
        const batch = await build('sandbox:baseline:t1').Fetch(QUERY);
        expect(batch.Payloads[0]).toMatchObject({ id: 'm1.t1', conversationId: 'c1.t1' });
    });

    it.each(['UPPER', 'a.b', '../x', ''])('rejects the run tag "%s"', async (tag) => {
        writeScenario('baseline', 'mail', ['m1']);
        await expect(build(`sandbox:baseline:${tag}`).Fetch(QUERY)).rejects.toThrow(`"${tag}"`);
    });

    it('a fixture recorded for another mailbox fails rather than returning nothing', async () => {
        writeScenario('other', 'mail', ['m1'], 'someone-else@sandbox-internal.test');
        await expect(build('sandbox:other').Fetch(QUERY)).rejects.toThrow('No recorded payloads');
    });
});

describe('everything else', () => {
    it('passes other refs through untouched', () => {
        const prod = context('prod-graph');
        expect(SandboxAwareTransportFactory(inner, dir)(prod)).toBe(STUB);
        expect(inner).toHaveBeenCalledWith(prod);

        const gmail = context('sandbox:baseline', 'Gmail');
        expect(SandboxAwareTransportFactory(inner, dir)(gmail)).toBe(STUB);
        expect(inner).toHaveBeenCalledWith(gmail);
    });

    it('passes a null ref through untouched', () => {
        const none = context(null);
        SandboxAwareTransportFactory(inner, dir)(none);
        expect(inner).toHaveBeenCalledWith(none);
    });
});

describe('LoadActivitySyncSandboxFromEnv', () => {
    it('blank env returns null and still intercepts sandbox refs', async () => {
        expect(LoadActivitySyncSandboxFromEnv({ [ENV_SANDBOX_DIR]: '  ' })).toBeNull();
        const factory = HostActivityTransportFactory();
        expect(factory).not.toBeNull();
        const transport = factory!(context('sandbox:baseline'));
        await expect(transport!.Fetch(QUERY)).rejects.toThrow(SANDBOX_DISABLED_REFUSAL);
    });

    it('returns the directory and serves from it when set', async () => {
        writeScenario('baseline', 'mail', ['m1']);
        expect(LoadActivitySyncSandboxFromEnv({ [ENV_SANDBOX_DIR]: dir })).toBe(dir);
        const batch = await HostActivityTransportFactory()!(context('sandbox:baseline'))!.Fetch(QUERY);
        expect(batch.Payloads).toHaveLength(1);
    });

    it('wraps the factory already registered, rather than replacing it', () => {
        RegisterActivityTransportFactory(inner);
        LoadActivitySyncSandboxFromEnv({});
        const prod = context('prod-graph');
        expect(HostActivityTransportFactory()!(prod)).toBe(STUB);
        expect(inner).toHaveBeenCalledWith(prod);
    });

    it('with nothing registered, non-sandbox refs get no transport (the provider then says so)', () => {
        LoadActivitySyncSandboxFromEnv({});
        expect(HostActivityTransportFactory()!(context('prod-graph'))).toBeNull();
    });

    it('throws when the directory does not exist', () => {
        expect(() => LoadActivitySyncSandboxFromEnv({ [ENV_SANDBOX_DIR]: join(dir, 'missing') })).toThrow(
            join(dir, 'missing'),
        );
    });

    it('throws when the path is a file, not a directory', () => {
        const file = join(dir, 'a-file');
        writeFileSync(file, '');
        expect(() => LoadActivitySyncSandboxFromEnv({ [ENV_SANDBOX_DIR]: file })).toThrow(file);
    });

    it('refuses to start with both sandbox and live policy', () => {
        mkdirSync(join(dir, 'fixtures'));
        AllowLiveMailboxFetch({
            Confirmed: true,
            ConfirmedBy: 'test',
            ConfirmedAt: new Date('2026-11-12T00:00:00Z'),
            Scope: 'RestrictedToGroup',
            ScopedToGroup: 'group@example.com',
        });
        expect(() => LoadActivitySyncSandboxFromEnv({ [ENV_SANDBOX_DIR]: join(dir, 'fixtures') })).toThrow(
            /live/i,
        );
    });
});
