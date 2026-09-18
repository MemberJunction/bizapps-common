import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

/**
 * AUDIT RETENTION FOR MESSAGES THE ENGINE DECLINED TO FILE.
 *
 * Every piece of this existed before and none of it was reachable: two columns on the provider type,
 * their overrides on the connection, `CapturedContent` and `EncryptionKeyID` on the run detail, two
 * CHECK constraints pairing ciphertext with key, and `ResolveCapturePlan` — written, documented and
 * unit-tested with ZERO callers.
 *
 * So `SkippedContentPolicy = 'SubjectEncrypted'` with a key produced successful runs that retained
 * nothing, and the misconfiguration `ResolveCapturePlan` exists to refuse never fired.
 *
 * These drive the ENGINE rather than the helpers, because the helpers already passed.
 */

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const TYPE = '9a1f8c22-51de-4f0a-9e77-2b6d0a4c1f31';
const KEY = 'c0ffee00-0000-4000-8000-000000000001';

/** Every run-detail row the engine saved, so the test reads what was persisted. */
const savedDetails: Array<Record<string, unknown>> = [];
let connectionRow: Record<string, unknown> = {};
let typeRow: Record<string, unknown> = {};

vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { EntityName?: string }) {
            const name = params.EntityName ?? '';
            if (name === 'MJ_BizApps_Common: Activity Sync Connections') {
                return { Success: true, Results: [connectionRow] };
            }
            if (name === 'MJ_BizApps_Common: Activity Sync Provider Types') {
                return { Success: true, Results: [typeRow] };
            }
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { ActivitySyncEngine } from '../ActivitySyncEngine.js';
import { FixtureActivitySyncProvider } from '../providers/FixtureActivitySyncProvider.js';
import {
    ContentToCapture,
    RegisterActivityContentCipher,
    HostActivityContentCipher,
    type ActivityContentCipher,
} from '../content-capture.js';
import type { IdentityResolver, IdentityResolution } from '../identity.js';
import type { ActivityWriter } from '../writer.js';
import type { NormalizedItem } from '../types.js';

const ITEM: NormalizedItem = {
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Q3 renewal terms',
    Body: 'The numbers we discussed.',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Participants: [{ Address: 'alice@customer.com', Name: null, Role: 'From', IdentityKind: 'Email' }],
    HasAttachments: false,
    Location: null,
    Direction: 'Inbound',
    Cancelled: false,
    Raw: {},
};

/** Records everything set on a row before Save. */
function recordingEntity(sink: Array<Record<string, unknown>>) {
    const row: Record<string, unknown> = {};
    return new Proxy(row, {
        get(target, prop: string) {
            if (prop === 'NewRecord') return () => undefined;
            if (prop === 'Load') return async () => true;
            if (prop === 'Save') {
                return async () => {
                    sink.push({ ...target });
                    return true;
                };
            }
            if (prop === 'LatestResult') return {};
            if (prop === 'ID') return 'row-1';
            return target[prop];
        },
        set(target, prop: string, value) {
            target[prop] = value;
            return true;
        },
    });
}

/** Everything the cipher was handed on the last call, so a dropped argument is visible. */
const cipherCalls: Array<{ plaintext: string; keyID: string; user: UserInfo | undefined }> = [];

/** A cipher that marks what it protected, so the test can tell ciphertext from plaintext. */
const SPY_CIPHER: ActivityContentCipher = {
    Encrypt: async (plaintext: string, keyID: string, contextUser: UserInfo) => {
        cipherCalls.push({ plaintext, keyID, user: contextUser });
        return `enc(${keyID}):${plaintext}`;
    },
};

function setRows(opts: {
    policy?: string | null;
    key?: string | null;
    typePolicy?: string | null;
    typeKey?: string | null;
}) {
    connectionRow = {
        ID: CONN,
        Status: 'Active',
        Provider: 'Microsoft365',
        Mailbox: 'box@tenant.test',
        StartAt: null,
        EndAt: null,
        LastSyncAt: null,
        ActivitySyncProviderTypeID: TYPE,
        SkippedContentPolicy: opts.policy ?? null,
        EncryptionKeyID: opts.key ?? null,
        Settings: null,
    };
    typeRow = {
        ID: TYPE,
        Code: 'Microsoft365',
        DriverClass: 'Microsoft365',
        DefaultQualificationPolicy: 'Exclude',
        CalendarDriverClass: null,
        IsActive: true,
        DefaultSkippedContentPolicy: opts.typePolicy ?? null,
        DefaultEncryptionKeyID: opts.typeKey ?? null,
    };
}

/** What the writer reports back, which is what decides `Duplicate` and `Failed`. */
type WriteOutcome = { Success?: boolean; AlreadyPresent?: boolean };

async function run(dryRun = false, known = false, write: WriteOutcome = {}) {
    savedDetails.length = 0;
    cipherCalls.length = 0;
    // By default nothing resolves, so nothing is a known participant and the Exclude default decides
    // — which is the whole point: these are the messages a retention policy is about. `known` flips
    // it so one test can check the opposite case.
    const resolution: IdentityResolution = known
        ? {
              LookupFailed: false,
              Resolved: [{ Kind: 'Person', RecordID: 'person-1', Role: 'From' }],
              Unresolved: [],
              Known: new Map([
                  ['alice@customer.com', { Address: 'alice@customer.com', PersonID: 'person-1', OrganizationID: null }],
              ]),
          }
        : {
              LookupFailed: false,
              Resolved: [],
              // UnresolvedParty, not a bare address. Vitest transpiles through esbuild and ran past
              // the wrong shape here; the typecheck gate caught it.
              Unresolved: [{ Kind: 'Email', Value: 'alice@customer.com', Role: 'From' }],
              Known: new Map(),
          };
    const resolver = { Resolve: async () => resolution } as unknown as IdentityResolver;
    const writer = {
        Write: async () => ({
            Success: write.Success ?? true,
            // A duplicate carries the Activity that already holds this content -- which is the whole
            // reason it must not be captured a second time.
            ActivityID: write.AlreadyPresent ? 'act-1' : known ? 'act-1' : null,
            AlreadyPresent: write.AlreadyPresent ?? false,
            Links: [],
            Activity: write.AlreadyPresent || known ? { ID: 'act-1' } : null,
            Issues: write.Success === false ? ['the write failed'] : [],
        }),
    } as unknown as ActivityWriter;
    const provider = {
        Entities: [],
        GetEntityObject: async () => recordingEntity(savedDetails),
    } as unknown as IMetadataProvider;

    const engine = new ActivitySyncEngine(resolver, writer);
    const result = await engine.Run(
        CONN,
        { DryRun: dryRun, TriggerType: 'Manual', Limit: 10 },
        provider,
        { ID: 'user-1' } as UserInfo,
        new FixtureActivitySyncProvider([ITEM], 'Message'),
    );
    return { result, detail: savedDetails.find((r) => 'Decision' in r) };
}

beforeEach(() => RegisterActivityContentCipher(null));

describe('what a capture plan calls for', () => {
    it('keeps nothing when the policy is None', () => {
        expect(ContentToCapture('None', ITEM)).toBeNull();
    });

    it('keeps the subject alone for SubjectEncrypted', () => {
        expect(ContentToCapture('Subject', ITEM)).toBe('Q3 renewal terms');
    });

    it('keeps subject and body for FullEncrypted', () => {
        expect(ContentToCapture('Full', ITEM)).toContain('The numbers we discussed.');
    });

    it('still reports a subject-less message rather than returning nothing', () => {
        // Null here would make "captured an empty subject" indistinguishable from "captured nothing".
        expect(ContentToCapture('Subject', { ...ITEM, Subject: '   ' })).toBe('(no subject)');
    });

    it('does not invent a blank line when there is no body to add', () => {
        expect(ContentToCapture('Full', { ...ITEM, Body: null })).toBe('Q3 renewal terms');
    });
});

describe('the engine writes captured content for a skipped message', () => {
    it('writes ciphertext and the key that opens it, together', async () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'SubjectEncrypted', key: KEY });
        const { result, detail } = await run();

        expect(result.Success, result.Issues.join(' | ')).toBe(true);
        expect(detail?.Decision).toBe('Excluded');
        // THE ASSERTION THAT DID NOT EXIST. Before this, CapturedContent was never set by anything.
        expect(detail?.CapturedContent).toBe(`enc(${KEY}):Q3 renewal terms`);
        expect(detail?.EncryptionKeyID, 'CK_ActivitySyncRunDetail_ContentKey pairs them').toBe(KEY);
    });

    /**
     * A CIPHER HAS TO READ SOMETHING TO ANSWER, AND ON THE SERVER THAT READ NEEDS A USER.
     *
     * MJ's `EncryptionEngine.Encrypt` configures itself lazily, and `BaseEngine.Load` throws
     * `'For server-side use of all engine classes, you must provide the contextUser parameter'` when
     * it configures against a database provider without one.
     *
     * MJAPI does configure that engine at startup, so on a healthy host the lazy path never runs. The
     * case this protects is the unhealthy one: startup validation fails whenever the key is missing or
     * unusable, the engine stays unloaded, and the first capture configures it lazily. Without a user
     * the run issue then reads `'you must provide the contextUser parameter'` — naming the wrong fault
     * on the exact path where an operator needs to be told their KEY is wrong.
     *
     * Asserted here rather than left to the type signature, which binds only callers that typecheck
     * against it.
     */
    it('hands the cipher the run user, because the key lookup runs as somebody', async () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'SubjectEncrypted', key: KEY });
        await run();

        expect(cipherCalls, 'the cipher was reached at all').toHaveLength(1);
        expect(cipherCalls[0].user?.ID, 'the same user the rest of the run reads as').toBe('user-1');
    });

    it('keeps the body too when the policy says Full', async () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'FullEncrypted', key: KEY });
        const { detail } = await run();
        expect(String(detail?.CapturedContent)).toContain('The numbers we discussed.');
    });

    it('writes nothing when the policy is None', async () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'None' });
        const { detail } = await run();
        // An absence assertion passes for free when nothing was saved at all, so prove the row exists
        // and reached a real decision before claiming its content column is empty.
        expect(detail?.Decision, 'a detail row must have been written').toBe('Excluded');
        expect(detail?.CapturedContent).toBeUndefined();
        expect(detail?.EncryptionKeyID).toBeUndefined();
    });

    it('writes nothing for a message it DID file', async () => {
        /**
         * An included message already has an Activity carrying its content. Copying it into
         * `CapturedContent` as well would put a second, encrypted duplicate of ordinary mail in a
         * column whose whole purpose is messages that were NOT filed — and the policy an operator set
         * says "skipped", not "everything".
         *
         * No test covered this until a mutation that captured on every decision survived.
         */
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'FullEncrypted', key: KEY });
        const { detail } = await run(false, true);
        expect(detail?.Decision, 'this message must have been filed').toBe('Included');
        expect(detail?.CapturedContent).toBeUndefined();
        expect(detail?.EncryptionKeyID).toBeUndefined();
    });

    it('writes nothing for a DUPLICATE, which is already filed', async () => {
        /**
         * The same argument as `Included`, and it took a review to notice. The writer reports
         * `AlreadyPresent` and the detail carries an `ActivityID`, so the content is already
         * retrievable from the Activity holding it. Capturing it puts an encrypted second copy of
         * ordinary filed mail in a column meant for messages that were NOT filed.
         *
         * The cost is what settled it: the calendar window is always `[now - 30d, now + 30d]`, so a
         * meeting comes back a duplicate on roughly sixty subsequent daily runs. Under `FullEncrypted`
         * that was about sixty encrypted copies of every meeting.
         */
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'FullEncrypted', key: KEY });
        const { detail } = await run(false, true, { AlreadyPresent: true });

        expect(detail?.Decision, 'this message must have been seen as a duplicate').toBe('Duplicate');
        expect(detail?.CapturedContent).toBeUndefined();
        expect(detail?.EncryptionKeyID).toBeUndefined();
    });

    it('DOES write for a Failed message, which is the one nothing else holds', async () => {
        /**
         * The other half, and the reason dropping `Duplicate` is not simply "capture less". A message
         * that could not be written has no Activity behind it, so this column is the only place its
         * content survives at all — it is exactly what an auditor asks about.
         *
         * The PR flagged this as its most arguable call and nothing pinned it either way, which is
         * how a later tidy-up could have swept it out alongside `Duplicate`.
         */
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'FullEncrypted', key: KEY });
        // KNOWN, so the message is INCLUDED and the writer actually runs -- then the write fails.
        // With nothing resolving, the Exclude default decides first and the writer never sees it.
        const { detail } = await run(false, true, { Success: false });

        expect(detail?.Decision, 'the write must have failed').toBe('Failed');
        expect(detail?.CapturedContent, 'nothing else holds this message').toBe(
            `enc(${KEY}):Q3 renewal terms

The numbers we discussed.`,
        );
        expect(detail?.EncryptionKeyID).toBe(KEY);
    });

    it('writes nothing on a dry run, because nothing was actually declined', async () => {
        // A preview must not put real content behind a retention policy on the strength of a rehearsal.
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'FullEncrypted', key: KEY });
        const { detail } = await run(true);
        expect(detail?.Decision).toBe('WouldExclude');
        expect(detail?.CapturedContent).toBeUndefined();
    });
});

describe('the fallback chain the columns describe', () => {
    it('takes the provider type default when the connection says nothing', async () => {
        // "Overridable per connection" implies a default to override. Nothing read it before.
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ typePolicy: 'SubjectEncrypted', typeKey: KEY });
        const { detail } = await run();
        expect(detail?.CapturedContent).toBe(`enc(${KEY}):Q3 renewal terms`);
    });

    it('lets the connection override the type down to None', async () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ typePolicy: 'FullEncrypted', typeKey: KEY, policy: 'None' });
        const { detail } = await run();
        expect(detail?.Decision, 'a detail row must have been written').toBe('Excluded');
        expect(detail?.CapturedContent).toBeUndefined();
    });

    it('lets the connection override the key', async () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        const other = 'c0ffee00-0000-4000-8000-000000000002';
        setRows({ typePolicy: 'SubjectEncrypted', typeKey: KEY, key: other });
        const { detail } = await run();
        expect(detail?.EncryptionKeyID).toBe(other);
    });
});

describe('a misconfiguration refuses the run rather than retaining nothing quietly', () => {
    it('refuses a policy above None with no key anywhere', async () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'SubjectEncrypted' });
        const { result } = await run();
        expect(result.Success).toBe(false);
        expect(result.Issues.join(' ')).toMatch(/no encryption key is configured/);
    });

    it('refuses before reading a single message', async () => {
        // The order matters: refusing after a fetch costs a read and leaves the run holding content
        // it has been told it may not keep.
        RegisterActivityContentCipher(SPY_CIPHER);
        setRows({ policy: 'SubjectEncrypted' });
        const { result } = await run();
        expect(result.Fetched, 'nothing should have been fetched').toBe(0);
    });

    it('refuses when the host registered no cipher, naming the way out', async () => {
        RegisterActivityContentCipher(null);
        setRows({ policy: 'SubjectEncrypted', key: KEY });
        const { result } = await run();
        expect(result.Success).toBe(false);
        expect(result.Issues.join(' ')).toMatch(/RegisterActivityContentCipher/);
    });

    it('runs normally with no cipher when no policy asks for one', async () => {
        RegisterActivityContentCipher(null);
        setRows({ policy: 'None' });
        const { result } = await run();
        expect(result.Success, result.Issues.join(' | ')).toBe(true);
    });

    it('records the decision without content when encryption itself fails', async () => {
        // Losing the whole run record because one message could not be encrypted is a worse trade
        // than an audit gap that says so out loud.
        RegisterActivityContentCipher({
            Encrypt: async () => {
                throw new Error('key revoked');
            },
        });
        setRows({ policy: 'SubjectEncrypted', key: KEY });
        const { result, detail } = await run();
        expect(detail?.Decision).toBe('Excluded');
        expect(detail?.CapturedContent).toBeUndefined();
        expect(detail?.EncryptionKeyID, 'the key must not be recorded without the ciphertext').toBeUndefined();
        expect(result.Issues.join(' ')).toMatch(/Could not encrypt captured content/);
    });
});

describe('the host registry', () => {
    it('is what the engine defaults to', () => {
        RegisterActivityContentCipher(SPY_CIPHER);
        expect(HostActivityContentCipher()).toBe(SPY_CIPHER);
        const engine = new ActivitySyncEngine();
        expect((engine as unknown as { cipher: ActivityContentCipher | null }).cipher).toBe(SPY_CIPHER);
    });

    it('is null on a host that registered none', () => {
        RegisterActivityContentCipher(null);
        expect(HostActivityContentCipher()).toBeNull();
    });
});
