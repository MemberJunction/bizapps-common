import {
    MergePartySignalRows,
    ParseSignalNouns,
    PARTY_SIGNALS_CATEGORY,
    type PartyKind,
    type PartyRosterEntry,
    type PartySignalRow,
    type PartySignalSource,
} from '@mj-biz-apps/common-entities';
import { LogError, Metadata, RunQuery, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import { QueryEngine } from '@memberjunction/core-entities';
import { BaseSingleton } from '@memberjunction/global';

/**
 * The session's answer to "who are our customers".
 *
 * Common cannot see the orders, contracts or sales schemas, so it discovers every query in the
 * `Party Signals` category through metadata, runs each once as the current user, and merges the
 * rows into one roster. Adding an app to the answer is shipping a query in that category — no
 * import, no registration, no change here.
 *
 * Loaded once per session rather than per keystroke: the roster is hundreds to low thousands of
 * rows of IDs, counts and dates, and the picker ranks it in memory. A query the user has no
 * permission to read contributes nothing and is recorded in {@link Warnings}; the picker still
 * searches the directory, so a missing signal degrades ranking rather than breaking the field.
 */
export class PartySignalStore extends BaseSingleton<PartySignalStore> {
    private roster = new Map<string, PartyRosterEntry>();
    private loading: Promise<void> | null = null;
    private warnings: string[] = [];
    private loaded = false;

    public static get Instance(): PartySignalStore {
        return super.getInstance<PartySignalStore>();
    }

    public get Loaded(): boolean {
        return this.loaded;
    }

    /** One entry per signal query that could not be read or did not run. */
    public get Warnings(): ReadonlyArray<string> {
        return this.warnings;
    }

    /** Idempotent, and safe to call from several pickers at once — they share one load. */
    public async Load(provider?: IMetadataProvider, user?: UserInfo): Promise<void> {
        if (this.loaded) {
            return;
        }
        this.loading ??= this.loadRoster(provider, user);
        await this.loading;
    }

    /** Re-read the signals — after creating a party, or when a picker asks for fresh counts. */
    public async Refresh(provider?: IMetadataProvider, user?: UserInfo): Promise<void> {
        await this.Reset();
        await this.Load(provider, user);
    }

    /** Drop everything loaded. Exposed so a test, or a user switch, starts from nothing. */
    public async Reset(): Promise<void> {
        await this.loading?.catch(() => undefined);
        this.roster = new Map<string, PartyRosterEntry>();
        this.warnings = [];
        this.loaded = false;
        this.loading = null;
    }

    /** The roster entry for a party, or null when the party is not a customer of any app. */
    public Get(partyID: string): PartyRosterEntry | null {
        return this.roster.get((partyID ?? '').trim().toLowerCase()) ?? null;
    }

    /** Customers of one kind, most recent activity first, never-active last, then by ID. */
    public Customers(kind: PartyKind): PartyRosterEntry[] {
        return [...this.roster.values()].filter((entry) => entry.Kind === kind).sort(byRecencyThenID);
    }

    private async loadRoster(provider?: IMetadataProvider, user?: UserInfo): Promise<void> {
        const providerToUse = provider ?? Metadata.Provider;
        const userToUse = user ?? new Metadata().CurrentUser;
        try {
            await QueryEngine.Instance.Config(false, userToUse, providerToUse);
            const queries = QueryEngine.Instance.Queries.filter((query) => query.Category === PARTY_SIGNALS_CATEGORY);
            const sources = await Promise.all(queries.map((query) => this.runSource(query.ID, query.Name, query.Description, userToUse)));
            this.roster = new Map(MergePartySignalRows(sources).map((entry) => [entry.PartyID.toLowerCase(), entry]));
        } catch (error) {
            this.warnings.push(`Party Signals could not be loaded: ${messageOf(error)}`);
            LogError(`PartySignalStore: ${messageOf(error)}`);
        }
        this.loaded = true;
    }

    private async runSource(id: string, name: string, description: string | null, user: UserInfo): Promise<PartySignalSource> {
        const source: PartySignalSource = { QueryKey: name, ...ParseSignalNouns(description), Rows: [] };
        try {
            const result = await new RunQuery().RunQuery({ QueryID: id }, user);
            if (result.Success) {
                source.Rows = (result.Results as PartySignalRow[]) ?? [];
            } else {
                this.warnings.push(`${name}: ${result.ErrorMessage ?? 'failed'}`);
            }
        } catch (error) {
            this.warnings.push(`${name}: ${messageOf(error)}`);
            LogError(`PartySignalStore: ${name} failed — ${messageOf(error)}`);
        }
        return source;
    }
}

function byRecencyThenID(a: PartyRosterEntry, b: PartyRosterEntry): number {
    return (b.LastActivityAt?.getTime() ?? 0) - (a.LastActivityAt?.getTime() ?? 0) || a.PartyID.localeCompare(b.PartyID);
}

function messageOf(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
}
