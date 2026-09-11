/**
 * The host's transport factory — the last link between a configured credential and live mail.
 *
 * WHY THIS FILE EXISTS. `graph-transport-factory.ts` shipped with a comment reading "Exported for
 * tests", and there were none: the Server package declared `test: echo "No tests configured yet"`.
 * That is the same defect this PR fixes elsewhere — a seam that typechecks, is exported, is
 * documented, and is never exercised — so leaving it here would have been the joke telling itself.
 *
 * WHAT IS ASSERTED. Everything reachable from the two exported functions, including the two internal
 * collaborators, which are observed through the arguments handed to `MJGraphTransportDeps` rather
 * than by exporting them purely for a test. The base-class check in particular is load-bearing and
 * subtle enough that it needs to be pinned: MJ's `ClassFactory.CreateInstance` returns an instance of
 * the BASE class when nothing matches, so "no provider registered" arrives as a truthy object.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest';

/**
 * Hoisted because `vi.mock` factories run before the module body. The base class is declared with its
 * real name deliberately — `ResolveCommunicationProvider` compares `constructor.name` against the
 * literal string `'BaseCommunicationProvider'`, so a differently-named stand-in would make the test
 * pass for the wrong reason.
 */
const H = vi.hoisted(() => {
    class BaseCommunicationProvider {}
    return {
        BaseCommunicationProvider,
        createInstance: vi.fn(),
        ensureLoaded: vi.fn(async () => undefined),
        getCredential: vi.fn(async () => ({ values: { ClientID: 'client', TenantID: 'tenant' } })),
        deps: vi.fn((args: Record<string, unknown>) => ({ __deps: args })),
        register: vi.fn(),
        transportBuilt: vi.fn(),
        order: [] as string[],
    };
});

vi.mock('@memberjunction/communication-types', () => ({
    BaseCommunicationProvider: H.BaseCommunicationProvider,
}));

vi.mock('@memberjunction/credentials', () => ({
    CredentialEngine: {
        Instance: {
            EnsureLoaded: async (user: unknown) => {
                H.order.push('EnsureLoaded');
                return H.ensureLoaded(user as never);
            },
            getCredential: async (name: string, options: unknown) => {
                H.order.push('getCredential');
                return H.getCredential(name as never, options as never);
            },
        },
    },
}));

vi.mock('@memberjunction/global', () => ({
    MJGlobal: { Instance: { ClassFactory: { CreateInstance: H.createInstance } } },
}));

vi.mock('@mj-biz-apps/common-activity-sync', () => ({
    GRAPH_COMMUNICATION_PROVIDER: 'Microsoft Graph',
    GraphCommunicationTransport: class {
        // Describe/IsLive mirror the real class so a test can tell the two surfaces apart by the
        // transport it got back, rather than by trusting which branch it believes ran.
        public readonly Describe = 'Microsoft Graph (live, via MJ Communication)';
        public readonly IsLive = true;
        constructor(deps: unknown) {
            H.transportBuilt(deps);
        }
    },
    GraphCalendarTransport: class {
        public readonly Describe = 'Microsoft Graph calendar (live, via MJ Communication)';
        public readonly IsLive = true;
        constructor(deps: unknown) {
            H.transportBuilt(deps);
        }
    },
    MJGraphTransportDeps: H.deps,
    MJGraphCalendarTransportDeps: H.deps,
    RegisterActivityTransportFactory: H.register,
}));

import {
    GRAPH_COMMUNICATION_PROVIDER,
    GraphTransportFactory,
    LoadGraphTransportFactory,
} from '../custom/graph-transport-factory.js';

/** A context shaped like the one the engine hands the factory. */
const ctx = (over: Record<string, unknown> = {}) => ({
    DriverClass: 'Microsoft365',
    CredentialsRef: 'graph-mailbox-credential',
    ...over,
});

/** The argument object the factory handed to `MJGraphTransportDeps` on its most recent call. */
const lastDeps = () => H.deps.mock.calls[H.deps.mock.calls.length - 1][0] as {
    CredentialName: string;
    ContextUser?: unknown;
    GetCredentialEngine: () => { getCredential: (n: string, o?: Record<string, unknown>) => Promise<unknown> };
    GetCommunicationProvider: (name: string) => unknown;
};

beforeEach(() => {
    vi.clearAllMocks();
    H.order.length = 0;
});

describe('it declines, quietly, when the connection is not its business', () => {
    it('returns null for a driver it does not serve', () => {
        expect(GraphTransportFactory(ctx({ DriverClass: 'Fixture' }) as never)).toBeNull();
    });

    it('does not even start building a transport for another driver', () => {
        GraphTransportFactory(ctx({ DriverClass: 'Calendar' }) as never);
        expect(H.deps).not.toHaveBeenCalled();
        expect(H.transportBuilt).not.toHaveBeenCalled();
    });

    it.each([
        ['undefined', undefined],
        ['empty', ''],
        ['whitespace only', '   '],
    ])('returns null when CredentialsRef is %s, leaving the provider to say why', (_label, ref) => {
        expect(GraphTransportFactory(ctx({ CredentialsRef: ref }) as never)).toBeNull();
        expect(H.deps).not.toHaveBeenCalled();
    });
});

describe('it builds a transport when it can serve the connection', () => {
    it('returns a transport for Microsoft365 with a credential named', () => {
        expect(GraphTransportFactory(ctx() as never)).not.toBeNull();
        expect(H.transportBuilt).toHaveBeenCalledTimes(1);
    });

    it('trims the credential name before resolving it', () => {
        GraphTransportFactory(ctx({ CredentialsRef: '  padded-name  ' }) as never);
        expect(lastDeps().CredentialName).toBe('padded-name');
    });

    it('carries the context user through to the transport', () => {
        const user = { ID: 'user-1', Name: 'Rep' };
        GraphTransportFactory(ctx({ ContextUser: user }) as never);
        expect(lastDeps().ContextUser).toBe(user);
    });
});

describe('one factory, two surfaces', () => {
    /**
     * A connection has ONE CredentialsRef and two surfaces. Before this, the factory served only the
     * message driver, so a calendar connection with a perfectly good credential got "no transport
     * factory is registered in this host" — a message pointing at host wiring when the wiring was
     * fine and the driver simply was not served.
     */
    it('serves the calendar driver, not just the message one', () => {
        expect(GraphTransportFactory(ctx({ DriverClass: 'Microsoft365.Calendar' }) as never)).not.toBeNull();
    });

    it('builds a LIVE calendar transport, which the provider then gates', () => {
        const built = GraphTransportFactory(ctx({ DriverClass: 'Microsoft365.Calendar' }) as never);
        expect(built?.IsLive).toBe(true);
        expect(built?.Describe).toMatch(/calendar/i);
    });

    it('builds the message transport for the message driver', () => {
        const built = GraphTransportFactory(ctx({ DriverClass: 'Microsoft365' }) as never);
        expect(built?.Describe).not.toMatch(/calendar/i);
    });

    /** Still declines anything it does not serve — widening must not become "serves everything". */
    it('still returns null for an unrelated driver', () => {
        expect(GraphTransportFactory(ctx({ DriverClass: 'Microsoft365.Chat' }) as never)).toBeNull();
        expect(GraphTransportFactory(ctx({ DriverClass: 'Gmail' }) as never)).toBeNull();
    });

    it('still needs a credential for the calendar surface too', () => {
        expect(
            GraphTransportFactory(ctx({ DriverClass: 'Microsoft365.Calendar', CredentialsRef: '   ' }) as never),
        ).toBeNull();
    });
});

describe('resolving MJs communication provider — the base-class trap', () => {
    /**
     * The whole reason `ResolveCommunicationProvider` is not a one-liner. `CreateInstance` answers with
     * a BASE instance when no subclass is registered, so a truthy return does not mean "found".
     */
    it('treats a bare BaseCommunicationProvider as NOT registered', () => {
        H.createInstance.mockReturnValue(new H.BaseCommunicationProvider());
        GraphTransportFactory(ctx() as never);
        expect(lastDeps().GetCommunicationProvider(GRAPH_COMMUNICATION_PROVIDER)).toBeNull();
    });

    it('returns a real registered provider', () => {
        class GraphProvider extends H.BaseCommunicationProvider {}
        const registered = new GraphProvider();
        H.createInstance.mockReturnValue(registered);
        GraphTransportFactory(ctx() as never);
        expect(lastDeps().GetCommunicationProvider(GRAPH_COMMUNICATION_PROVIDER)).toBe(registered);
    });

    it('returns null when the class factory answers with nothing at all', () => {
        H.createInstance.mockReturnValue(null);
        GraphTransportFactory(ctx() as never);
        expect(lastDeps().GetCommunicationProvider(GRAPH_COMMUNICATION_PROVIDER)).toBeNull();
    });

    it('asks the class factory for the Graph provider by its published name', () => {
        H.createInstance.mockReturnValue(null);
        GraphTransportFactory(ctx() as never);
        lastDeps().GetCommunicationProvider(GRAPH_COMMUNICATION_PROVIDER);
        expect(H.createInstance).toHaveBeenCalledWith(H.BaseCommunicationProvider, 'Microsoft Graph');
    });
});

describe('loading the credential', () => {
    /**
     * `getCredential` throws "Metadata not loaded" if the engine was never configured, and this factory
     * can run from a scheduled Action that fires before anything else has touched credentials.
     */
    it('ensures the engine is loaded BEFORE asking for the credential', async () => {
        GraphTransportFactory(ctx() as never);
        await lastDeps().GetCredentialEngine().getCredential('graph-mailbox-credential');
        expect(H.order).toEqual(['EnsureLoaded', 'getCredential']);
    });

    it('prefers a context user passed at call time over the one captured at build time', async () => {
        const built = { ID: 'built' };
        const called = { ID: 'called' };
        GraphTransportFactory(ctx({ ContextUser: built }) as never);
        await lastDeps().GetCredentialEngine().getCredential('name', { contextUser: called });
        expect(H.ensureLoaded).toHaveBeenCalledWith(called);
        expect(H.getCredential.mock.calls[0][1]).toMatchObject({ contextUser: called });
    });

    it('falls back to the context user captured at build time', async () => {
        const built = { ID: 'built' };
        GraphTransportFactory(ctx({ ContextUser: built }) as never);
        await lastDeps().GetCredentialEngine().getCredential('name');
        expect(H.ensureLoaded).toHaveBeenCalledWith(built);
    });

    it('tags the request with its subsystem so credential access is attributable', async () => {
        GraphTransportFactory(ctx() as never);
        await lastDeps().GetCredentialEngine().getCredential('name');
        expect(H.getCredential.mock.calls[0][1]).toMatchObject({
            subsystem: 'BizApps Common ActivitySync',
        });
    });

    it('asks for the credential the connection named, not a hardcoded one', async () => {
        GraphTransportFactory(ctx({ CredentialsRef: 'mailbox-a' }) as never);
        await lastDeps().GetCredentialEngine().getCredential('mailbox-a');
        expect(H.getCredential.mock.calls[0][0]).toBe('mailbox-a');
    });
});

describe('registration', () => {
    it('registers this factory as the host factory', () => {
        LoadGraphTransportFactory();
        expect(H.register).toHaveBeenCalledWith(GraphTransportFactory);
    });

    it('registers exactly one factory per call, replacing rather than stacking', () => {
        LoadGraphTransportFactory();
        LoadGraphTransportFactory();
        expect(H.register).toHaveBeenCalledTimes(2);
        expect(H.register.mock.calls.every((c) => c[0] === GraphTransportFactory)).toBe(true);
    });
});
