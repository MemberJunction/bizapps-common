/**
 * Microsoft Graph mail.
 *
 * WHAT CHANGED AND WHY. This class previously had no transport at all: both `FetchRaw` returns
 * handed back `Payloads: []`, one behind an opt-in flag and one behind a "not supported in this
 * build" log. It was written, typechecked and refused. The consequence was not only that live sync
 * did not work — it was that nothing ever exercised the path that needs a credential, so the absence
 * of any configured credential went unnoticed until someone asked for a live demo.
 *
 * It now delegates to an `ActivityMessageTransport`. The live one wraps MJ's Communication MS Graph
 * provider and MJ's Credentials engine; a recorded one replays captured payloads through the same
 * mapping. Only the outermost call differs between them.
 *
 * THE TENANT-WIDE READ IS STILL REFUSED BY DEFAULT. The reason is unchanged: app-only `Mail.Read`
 * reads EVERY mailbox in the tenant until an Exchange Application Access Policy scopes the app
 * registration to a security group. Wiring a transport does not make that safe, so the gate stays.
 *
 * What changed is that the gate is now REACHABLE. It defaults to the host's attestation
 * (`AllowLiveMailboxFetch`) rather than to a bare `false` that `ClassFactory` could never override —
 * an unconfigured host still refuses, but a scoped one can say so in the one place that ships.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { RegisterClass } from '@memberjunction/global';

import { BaseActivitySyncProvider } from '../BaseActivitySyncProvider.js';
import type { ActivitySourceQuery, NormalizedItem, RawBatch } from '../types.js';
import { MapGraphMessages } from './GraphMessageMapper.js';
import { HostActivityTransportFactory, HostAllowsLiveMailboxFetch } from './MessageTransport.js';
import type {
    ActivityMessageTransport,
    ActivityTransportContext,
    ActivityTransportFactory,
} from './MessageTransport.js';

export const LIVE_GRAPH_REFUSAL =
    'Live Graph fetch is disabled. MSGraphProvider uses app-only auth, so Mail.Read reads ' +
    'EVERY mailbox in the tenant until an Exchange Application Access Policy scopes the ' +
    'app registration to a security group. Confirm that policy exists before enabling ' +
    'this, and use a recorded transport or FixtureActivitySyncProvider until then. ' +
    // Naming the way out matters as much as the refusal: without it an operator who HAS checked the
    // policy has no supported next step, and the tempting one is to edit a database row.
    'Once confirmed, call AllowLiveMailboxFetch() at host bootstrap with the group the policy names.';

export const NO_TRANSPORT_REFUSAL =
    'No mailbox transport was supplied. Construct this provider with a GraphCommunicationTransport ' +
    '(live) or a RecordedMessageTransport (replay).';

export const NO_CREDENTIAL_REF_REFUSAL =
    'This ActivitySyncConnection names no credential. Set its CredentialsRef to the NAME of an ' +
    '"Azure Service Principal" credential in MJ — that column holds a Credentials engine key, ' +
    'never a secret value.';

@RegisterClass(BaseActivitySyncProvider, 'Microsoft365')
export class MSGraphActivitySyncProvider extends BaseActivitySyncProvider {
    public readonly Kind = 'Message' as const;
    public readonly ProviderTypeCode = 'Microsoft365';

    /**
     * Reflects the TRANSPORT rather than being hard-coded true.
     *
     * The engine refuses to write `Source: 'Integration'` rows from a non-live provider without
     * being told to. While this class always claimed `IsLive = true`, a replayed run would have been
     * indistinguishable from a real one in the database afterwards. Deferring to the transport is
     * what makes the recorded path safe to demo with.
     *
     * Defaults to true when there is no transport, so an unconfigured provider is treated as the
     * stricter case rather than quietly downgrading the engine's guard.
     */
    public get IsLive(): boolean {
        return this.Transport?.IsLive ?? true;
    }

    public constructor(
        /**
         * Turning it on is a deliberate act by someone who has confirmed the Application Access
         * Policy exists. Nothing in this package does that for you.
         *
         * It gates the LIVE transport only — a recorded transport needs no such confirmation
         * because it reaches no mailbox, and is allowed through below.
         *
         * DEFAULTS TO THE HOST'S ATTESTATION, NOT TO FALSE. A bare `false` made this unreachable in
         * the only way that ships: `MJGlobal.ClassFactory` builds plugins with no arguments, so
         * through the engine this was permanently off and the parameter could be set by tests and
         * the demo alone. That is the same defect the transport factory had — a seam that was
         * described, exported, and impossible to reach — so it gets the same fix, a host registry.
         * With no attestation registered the default is still false, so an unconfigured host refuses
         * exactly as before.
         */
        private readonly AllowLiveFetch: boolean = HostAllowsLiveMailboxFetch(),
        /** Where messages come from. Without one this provider refuses rather than pretending. */
        private Transport?: ActivityMessageTransport,
        /** How a host builds a transport for a connection. See {@link Configure}. */
        private readonly Factory?: ActivityTransportFactory,
    ) {
        super();
    }

    /** Why this provider cannot fetch, decided at Configure time and reported at fetch time. */
    private ConfigurationRefusal: string | null = null;

    /**
     * Reads `ActivitySyncConnection.CredentialsRef` and builds this connection's transport from it.
     *
     * THE COLUMN EXISTED AND NOTHING READ IT. Its own description says it holds an "MJ Credentials
     * engine key. NEVER a secret value at rest" — and no code anywhere consumed it. A connection
     * could name the credential it wanted and be silently ignored, which is worse than the column
     * being absent: the configuration looked complete and the provider refused for what looked like
     * an unrelated reason.
     *
     * A transport passed to the CONSTRUCTOR wins and is never replaced. Tests and the demo supply
     * one directly, and a database row should not be able to reach in and swap it.
     */
    public override Configure(context: ActivityTransportContext): void {
        if (this.Transport) {
            return;
        }

        const ref = (context.CredentialsRef ?? '').trim();
        if (!ref) {
            this.ConfigurationRefusal = NO_CREDENTIAL_REF_REFUSAL;
            return;
        }
        // A CONSTRUCTOR factory wins; otherwise ask the host registry. Only the second of these is
        // reachable through the engine, because ClassFactory passes no arguments — see
        // RegisterActivityTransportFactory.
        const factory = this.Factory ?? HostActivityTransportFactory();
        if (!factory) {
            this.ConfigurationRefusal =
                `This connection names credential "${ref}", but no transport factory is registered in ` +
                'this host, so the credential cannot be resolved.';
            return;
        }

        // NOT caught. A factory that throws is a host wiring fault, and swallowing it here would
        // recreate the silent misconfiguration this whole change exists to end.
        const built = factory(context);
        if (!built) {
            this.ConfigurationRefusal =
                `The transport factory served no transport for credential "${ref}" on driver ` +
                `"${context.DriverClass}".`;
            return;
        }
        this.Transport = built;
        this.ConfigurationRefusal = null;
    }

    protected async FetchRaw(query: ActivitySourceQuery): Promise<RawBatch> {
        // THE TENANT-WIDE REFUSAL IS CHECKED FIRST, and deliberately so. With no transport and no
        // opt-in — the default construction — the useful thing to say is WHY live fetch is off, not
        // that a transport is missing. Reordering these makes the security-relevant message
        // unreachable in the exact configuration most people will encounter.
        //
        // A recorded transport is exempt: the refusal exists to prevent reading mailboxes we are not
        // scoped to, and a replay reads none. Gating it as well would make the safe path as awkward
        // as the dangerous one, which is how people end up flipping the dangerous flag.
        if ((this.Transport?.IsLive ?? true) && !this.AllowLiveFetch) {
            // The tenant refusal stays FIRST for the reason above. But a Configure-time fault is
            // ALSO true and has a DIFFERENT fix, and reporting only the first sends an operator to
            // chase an Exchange policy when what is actually missing is a CredentialsRef or a
            // factory. Since AllowLiveFetch defaults false and ClassFactory builds this provider
            // with no arguments, returning early here made every Configure-time message below
            // unreachable through the engine — the exact silent misconfiguration this class exists
            // to end. Both are reported, most severe first.
            const issues = [LIVE_GRAPH_REFUSAL];
            if (!this.Transport && this.ConfigurationRefusal) {
                issues.push(this.ConfigurationRefusal);
            }
            return { Payloads: [], Issues: issues };
        }

        if (!this.Transport) {
            // The Configure-time refusal is the specific one when there is one: a connection with no
            // CredentialsRef needs a different fix from a host with no factory, and from a provider
            // simply constructed without a transport. Saying which saves a wrong hunt.
            return { Payloads: [], Issues: [this.ConfigurationRefusal ?? NO_TRANSPORT_REFUSAL] };
        }

        // Deliberately NOT caught here. `BaseActivitySyncProvider.Fetch` already distinguishes a
        // throw ("could not look" — Failed: true, LastError preserved) from an empty batch ("looked,
        // found nothing"). Swallowing a transport failure into an empty batch would report a
        // successful sync of a mailbox we never reached.
        return await this.Transport.Fetch(query);
    }

    protected Normalize(raw: RawBatch, query: ActivitySourceQuery): NormalizedItem[] {
        if (raw.Payloads.length === 0) return [];

        // `Payloads` is a FLAT array of Graph message objects — that is what MJ's `SourceData`
        // carries, since it is `response.value` verbatim.
        //
        // The previous form, `Payloads.length === 1 ? Payloads[0] : Payloads`, was wrong at both
        // ends and silently so. `MapGraphMessages` accepts an array of messages OR a single response
        // envelope (`{ value: [...] }`), and nothing else. Unwrapping a one-element array therefore
        // handed it a BARE MESSAGE, which matches neither shape, so a mailbox with exactly one new
        // message normalized to nothing at all and reported a clean, empty, successful sync. Read
        // the other way — as a list of envelopes — it broke at two or more instead. It could not be
        // right for both, and it was never right for one message.
        //
        // The envelope case is still honoured because a transport may reasonably hand back a raw
        // Graph response; it is detected explicitly rather than inferred from the array's length.
        const only = raw.Payloads.length === 1 ? raw.Payloads[0] : null;
        const isEnvelope = !!only && Array.isArray((only as { value?: unknown }).value);
        const mapped = MapGraphMessages(isEnvelope ? only : raw.Payloads, query.Mailbox);
        raw.Issues.push(...mapped.Issues);
        const since = query.Since ? query.Since.getTime() : null;
        return since === null ? mapped.Items : mapped.Items.filter((i) => i.StartedAt.getTime() > since);
    }
}
