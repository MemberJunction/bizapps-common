/**
 * The Activity Sync replay sandbox: test mode for the real sync pipeline.
 *
 * WHAT IT IS. A connection whose `CredentialsRef` is `sandbox:<scenario>` reads its mail and calendar
 * from fixture files (`<scenario>.mail.json`, `<scenario>.calendar.json`) in the directory named by
 * `ACTIVITY_SYNC_SANDBOX_DIR`, instead of from Microsoft Graph. Everything downstream — the action,
 * the engine, the rules, the writes — is the code a live run uses. The fixtures replay through
 * `RecordedMessageTransport`, so `IsLive` is false and every written Activity is `Source = 'System'`,
 * never `'Integration'`: a sandbox row cannot be mistaken for a live one.
 *
 * WHY THE `sandbox:` CHECK IS ALWAYS ON. Without this module a `sandbox:x` ref would be handed to
 * `GraphTransportFactory` and looked up as a real credential named "sandbox:x". So the prefix is
 * intercepted on every host; only SERVING fixtures needs the opt-in. With the opt-in off the ref gets
 * a transport that refuses, which is the one behaviour change a non-sandbox host sees.
 *
 * WHY EVERY FAILURE IS AT `Fetch`. A transport factory that throws escapes the provider's `Configure`
 * and the engine's `Run` up to the action's catch, so no ActivitySyncRun is saved and the other
 * connections in the call do not run. A `Fetch` that throws is recorded as a failed run on that one
 * connection. A misconfigured sandbox connection should look exactly like that.
 *
 * WHY SANDBOX AND LIVE ARE EXCLUSIVE. A host that can serve fixtures AND read real mailboxes is one
 * mistyped ref away from mixing the two. Bootstrap refuses that combination outright.
 *
 * @module @mj-biz-apps/common-server
 */
import { statSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

import { LogStatus } from '@memberjunction/core';
import {
    HostActivityTransportFactory,
    HostAllowsLiveMailboxFetch,
    RecordedMessageTransport,
    RegisterActivityTransportFactory,
    type ActivityMessageTransport,
    type ActivitySourceQuery,
    type ActivityTransportContext,
    type ActivityTransportFactory,
    type RawBatch,
} from '@mj-biz-apps/common-activity-sync';

import { MICROSOFT_365, MICROSOFT_365_CALENDAR } from './graph-transport-factory.js';

/** The opt-in. An absolute path to the fixture directory; unset or blank means off. */
export const ENV_SANDBOX_DIR = 'ACTIVITY_SYNC_SANDBOX_DIR';

/** A `CredentialsRef` with this prefix names a sandbox scenario, never a credential. */
export const SANDBOX_REF_PREFIX = 'sandbox:';

export const SANDBOX_DISABLED_REFUSAL =
    `This connection is a sandbox connection (CredentialsRef starts with "${SANDBOX_REF_PREFIX}"), but ` +
    `this host has no ${ENV_SANDBOX_DIR}, so it serves no fixtures. Sandbox refs are never looked up as ` +
    'credentials. Point the connection at a real credential, or run it on a sandbox host.';

/** Lower-case letters, digits and hyphens: a file-name stem that cannot leave the directory. */
const SCENARIO_NAME = /^[a-z0-9-]+$/;

interface ScenarioFile {
    mailbox: string;
    capturedAt?: string;
    value: Record<string, unknown>[];
}

/**
 * Wrap a transport factory so `sandbox:` refs on the Graph drivers are served from fixtures.
 *
 * @param inner the factory every other connection still goes to.
 * @param sandboxDir the fixture directory, or null when this host has not opted in.
 */
export function SandboxAwareTransportFactory(
    inner: ActivityTransportFactory,
    sandboxDir: string | null,
): ActivityTransportFactory {
    return (context: ActivityTransportContext) => {
        const ref = (context.CredentialsRef ?? '').trim();
        const isGraph = context.DriverClass === MICROSOFT_365 || context.DriverClass === MICROSOFT_365_CALENDAR;
        if (!isGraph || !ref.startsWith(SANDBOX_REF_PREFIX)) {
            return inner(context);
        }
        const surface = context.DriverClass === MICROSOFT_365_CALENDAR ? 'calendar' : 'mail';
        const [scenario, tag] = splitRef(ref.slice(SANDBOX_REF_PREFIX.length));
        return new SandboxFixtureTransport(scenario, tag, surface, sandboxDir);
    };
}

/**
 * Register the sandbox-aware factory, reading the opt-in from the environment.
 *
 * Wraps the factory already registered and re-registers the wrapper. Always does so — the
 * `sandbox:` interception is on for every host — and returns the fixture
 * directory when the opt-in is set, or null. Throws on an opt-in that is present but wrong: a
 * directory that is missing or not a directory, or a host that also allows live mailbox fetch.
 * Must run after `LoadGraphTransportFactory()` and `LoadLiveMailboxPolicyFromEnv()`.
 */
export function LoadActivitySyncSandboxFromEnv(env: NodeJS.ProcessEnv = process.env): string | null {
    // Wrap what is registered (normally GraphTransportFactory, from LoadGraphTransportFactory) so a
    // host's own factory keeps serving every non-sandbox ref.
    const inner: ActivityTransportFactory = HostActivityTransportFactory() ?? NO_FACTORY;
    const raw = (env[ENV_SANDBOX_DIR] ?? '').trim();
    if (!raw) {
        RegisterActivityTransportFactory(SandboxAwareTransportFactory(inner, null));
        return null;
    }
    const dir = resolve(raw);
    requireDirectory(dir);
    if (HostAllowsLiveMailboxFetch()) {
        throw new Error(
            `${ENV_SANDBOX_DIR} is set and this host also allows live mailbox fetch. A host is either a ` +
                'sandbox or reads real mail, never both. Unset one of them.',
        );
    }
    RegisterActivityTransportFactory(SandboxAwareTransportFactory(inner, dir));
    LogStatus(`Activity Sync sandbox ON: sandbox: connections replay fixtures from ${dir}`);
    return dir;
}

/** Nothing was registered: serve no transport, so the provider reports "no transport factory". */
const NO_FACTORY: ActivityTransportFactory = () => null;

function requireDirectory(dir: string): void {
    let isDirectory: boolean;
    try {
        isDirectory = statSync(dir).isDirectory();
    } catch (e) {
        throw new Error(`${ENV_SANDBOX_DIR} points at ${dir}, which cannot be read: ${(e as Error).message}`);
    }
    if (!isDirectory) {
        throw new Error(`${ENV_SANDBOX_DIR} points at ${dir}, which is not a directory.`);
    }
}

/** `<scenario>` or `<scenario>:<tag>`. A present-but-empty tag is kept as '' so it is refused. */
function splitRef(rest: string): [string, string | null] {
    const colon = rest.indexOf(':');
    return colon < 0 ? [rest, null] : [rest.slice(0, colon), rest.slice(colon + 1)];
}

/**
 * The fields that carry a Graph item's identity. A run tag suffixes each, so the engine's dedupe key
 * (SourceSystem + ExternalID, the same for every mailbox) never matches another connection's replay
 * of the same fixture. Real Graph ids are unique per mailbox, so this has no live counterpart.
 */
const IDENTITY_FIELDS = ['id', 'seriesMasterId', 'conversationId'] as const;

function tagPayload(payload: Record<string, unknown>, tag: string): Record<string, unknown> {
    const tagged = { ...payload };
    for (const field of IDENTITY_FIELDS) {
        const value = tagged[field];
        if (typeof value === 'string' && value.length > 0) tagged[field] = `${value}.${tag}`;
    }
    return tagged;
}

function requireName(kind: 'scenario' | 'run tag', value: string): void {
    if (!SCENARIO_NAME.test(value)) {
        throw new Error(`Sandbox ${kind} "${value}" is not a valid name: use lower-case letters, digits and hyphens.`);
    }
}

/**
 * Serves one scenario file for one surface, optionally run-tagged. Every check is made at `Fetch`
 * (see the module comment).
 */
class SandboxFixtureTransport implements ActivityMessageTransport {
    public readonly IsLive = false;
    public readonly Describe: string;

    public constructor(
        private readonly scenario: string,
        private readonly tag: string | null,
        private readonly surface: 'mail' | 'calendar',
        private readonly sandboxDir: string | null,
    ) {
        this.Describe = `sandbox fixture "${scenario}"${tag === null ? '' : ` tagged "${tag}"`} (${surface})`;
    }

    public async Fetch(query: ActivitySourceQuery): Promise<RawBatch> {
        if (this.sandboxDir === null) {
            throw new Error(SANDBOX_DISABLED_REFUSAL);
        }
        requireName('scenario', this.scenario);
        if (this.tag !== null) requireName('run tag', this.tag);
        const path = join(this.sandboxDir, `${this.scenario}.${this.surface}.json`);
        const file = await readScenarioFile(path);
        const tag = this.tag;
        const recorded = new RecordedMessageTransport([
            {
                Mailbox: file.mailbox,
                Payloads: tag === null ? file.value : file.value.map((p) => tagPayload(p, tag)),
                Provenance: `sandbox fixture ${path} (captured ${file.capturedAt ?? 'unknown'})`,
            },
        ]);
        return recorded.Fetch(query);
    }
}

async function readScenarioFile(path: string): Promise<ScenarioFile> {
    let text: string;
    try {
        text = await readFile(path, 'utf8');
    } catch (e) {
        throw new Error(`Sandbox fixture ${path} cannot be read: ${(e as Error).message}`);
    }
    let parsed: Partial<ScenarioFile>;
    try {
        parsed = JSON.parse(text) as Partial<ScenarioFile>;
    } catch (e) {
        throw new Error(`Sandbox fixture ${path} is not valid JSON: ${(e as Error).message}`);
    }
    if (typeof parsed.mailbox !== 'string' || !Array.isArray(parsed.value)) {
        throw new Error(`Sandbox fixture ${path} needs a "mailbox" string and a "value" array.`);
    }
    return { mailbox: parsed.mailbox, capturedAt: parsed.capturedAt, value: parsed.value };
}
