import { ChipText, type PartyKind, type PartyRosterEntry } from '@mj-biz-apps/common-entities';
import { RunView } from '@memberjunction/core';
import { RegisterClass } from '@memberjunction/global';
import {
    CombineFilters,
    DefaultFKLookupStrategy,
    FKLookupStrategy,
    QuoteSqlIdList,
    type FKLookupContext,
    type FKLookupGroup,
    type FKLookupRow,
    type FKLookupScopeLabels,
} from '@memberjunction/ng-base-forms';

import { COMMON_ENTITIES } from './entity-names';
import { PartySignalStore } from './party-signal-store';
import { RankPartyMatches } from './rank-party-matches';

/** Columns the second line and the chips need, beyond whatever the dropdown already asked for. */
const ORGANIZATION_FIELDS = ['ID', 'Name', 'LegalName', 'Website', 'PrimaryEmail', 'PrimaryAddressCity', 'PrimaryAddressState', 'Status'];
const PERSON_FIELDS = ['ID', 'DisplayName', 'PrimaryEmail', 'Email', 'Title', 'CurrentOrganizationName', 'PrimaryAddressCity', 'PrimaryAddressState', 'Status'];

/** Fields a typed query filters the in-memory customer roster against. */
const MATCH_FIELDS = ['Name', 'DisplayName', 'LegalName', 'Website', 'PrimaryEmail', 'Email', 'CurrentOrganizationName'];

const CUSTOMER_ROWS = 12;
const HYDRATE_BATCH = 500;
const AFFILIATION_ROWS = 500;

/**
 * The party picker: customers first, the whole directory second.
 *
 * A foreign key pointing at an organization or a person has had no way to tell a customer from
 * any other row in a directory that runs to hundreds of thousands. It offered the first rows
 * containing the letters typed, in no order, with nothing on screen to separate two similar
 * names — so an acronym could offer four organizations that merely contain those letters, and
 * picking the wrong one left a record that looked entirely correct afterwards.
 *
 * This supplies only what is party-specific. The dropdown, keyboard handling, the column plan,
 * recent picks and the create-new footer all remain the platform field's, and everything about
 * querying that is not about parties is inherited from {@link DefaultFKLookupStrategy}.
 *
 * Registered per related entity, so it attaches to every such foreign key in the product at once
 * — orders, contracts and deals get it without any of them importing this.
 */
export class PartyLookupStrategy extends DefaultFKLookupStrategy {
    /** Names resolved once per session, shared across every field using this strategy. */
    private readonly hydrated = new Map<string, FKLookupRow>();

    public override ScopeLabels(context: FKLookupContext): FKLookupScopeLabels {
        return {
            primary: 'Customers',
            all: this.kind(context) === 'person' ? 'All people' : 'All organizations',
        };
    }

    public override async Lookup(context: FKLookupContext): Promise<FKLookupGroup[]> {
        await PartySignalStore.Instance.Load(context.Provider);

        const groups: FKLookupGroup[] = [];
        const scopeOrganizationID = this.scopeOrganizationID(context);
        if (this.kind(context) === 'person' && scopeOrganizationID) {
            const atOrganization = await this.atOrganization(context, scopeOrganizationID);
            if (atOrganization.Rows.length > 0) {
                groups.push(atOrganization);
            }
        }

        groups.push(...(context.Scope === 'primary' ? [await this.customers(context)] : await this.directory(context)));
        return groups;
    }

    public override CreateDefaults(context: FKLookupContext): Record<string, unknown> {
        const typed = context.Query.trim();
        if (!typed) {
            return {};
        }
        if (this.kind(context) === 'organization') {
            return { Name: typed };
        }
        const [first, ...rest] = typed.split(/\s+/);
        return rest.length > 0 ? { FirstName: first, LastName: rest.join(' ') } : { LastName: first };
    }

    /** The dropdown reads these off every row, so the second line and chips have their inputs. */
    protected override fieldsFor(context: FKLookupContext): string[] {
        const party = this.kind(context) === 'person' ? PERSON_FIELDS : ORGANIZATION_FIELDS;
        return [...new Set([...context.Fields, ...party])];
    }

    /**
     * Inactive parties are hidden unless the host asks for them. A dissolved organization is
     * still a real record and still reachable, but offering it by default is how a new order
     * ends up against a company that no longer exists.
     */
    protected override baseFilter(context: FKLookupContext): string {
        const includeInactive = context.Options['IncludeInactive'] === true;
        return CombineFilters(super.baseFilter(context), includeInactive ? '' : `[Status] = 'Active'`);
    }

    /**
     * The wide population, through the platform's own search path.
     *
     * `SearchMode: 'hybrid'` is set unconditionally rather than only once an entity document is
     * vectorized: the platform's search falls back to an escaped LIKE when the search API returns
     * nothing, so asking for hybrid before the vectors exist costs a no-op call and starts
     * working the moment they do, with no second change here.
     */
    private async directory(context: FKLookupContext): Promise<FKLookupGroup[]> {
        const groups = await super.Lookup({
            ...context,
            Options: { ...context.Options, SearchMode: 'hybrid' },
        });
        return groups.map((group) => ({ ...group, Rows: this.decorate(group.Rows) }));
    }

    /** The roster, hydrated once and ranked in memory — no server round trip per keystroke. */
    private async customers(context: FKLookupContext): Promise<FKLookupGroup> {
        const entries = PartySignalStore.Instance.Customers(this.kind(context));
        const rows = await this.hydrateEntries(context, entries);
        const ranked = RankPartyMatches(rows, context.Query, context.NameField, (id) => PartySignalStore.Instance.Get(id), context.PkField);
        const typed = context.Query.trim().toLowerCase();
        const matching = typed ? ranked.filter((row) => this.matches(row, typed)) : ranked;
        return { Key: 'customers', Label: 'Customers', Rows: this.decorate(matching.slice(0, CUSTOMER_ROWS)) };
    }

    /**
     * People affiliated with the organization already chosen on this record, offered ahead of
     * everyone else. `Options.ScopeField` names the host field holding that organization; without
     * it there is no scope and the group is skipped.
     */
    private async atOrganization(context: FKLookupContext, organizationID: string): Promise<FKLookupGroup> {
        const ids = await this.affiliatedPersonIDs(context, organizationID);
        if (ids.length === 0) {
            return { Key: 'at-organization', Label: null, Rows: [] };
        }
        const rows = await this.hydrate(context, ids);
        const typed = context.Query.trim().toLowerCase();
        const filtered = typed ? rows.filter((row) => this.matches(row, typed)) : rows;
        return {
            Key: 'at-organization',
            Label: `At ${this.scopeOrganizationName(context)}`,
            Rows: this.decorate(RankPartyMatches(filtered, context.Query, context.NameField, (id) => PartySignalStore.Instance.Get(id), context.PkField)),
        };
    }

    private async affiliatedPersonIDs(context: FKLookupContext, organizationID: string): Promise<string[]> {
        const types = Array.isArray(context.Options['AffiliationTypes']) ? (context.Options['AffiliationTypes'] as string[]) : ['Employee'];
        const today = new Date().toISOString().slice(0, 10);
        const result = await RunView.FromMetadataProvider(context.Provider).RunView<{ FromPersonID: string }>({
            EntityName: COMMON_ENTITIES.Relationship,
            ExtraFilter: CombineFilters(
                `[ToOrganizationID] IN (${QuoteSqlIdList([organizationID])})`,
                `[FromPersonID] IS NOT NULL`,
                `[Status] = 'Active'`,
                `[RelationshipType] IN (${QuoteSqlIdList(types)})`,
                `([StartDate] IS NULL OR [StartDate] <= '${today}')`,
                `([EndDate] IS NULL OR [EndDate] >= '${today}')`,
            ),
            Fields: ['FromPersonID'],
            ResultType: 'simple',
            MaxRows: AFFILIATION_ROWS,
        });
        return result.Success ? result.Results.map((row) => row.FromPersonID) : [];
    }

    /** Resolve roster IDs to rows, in batches, caching across keystrokes and across fields. */
    private async hydrateEntries(context: FKLookupContext, entries: ReadonlyArray<PartyRosterEntry>): Promise<FKLookupRow[]> {
        const missing = entries.map((entry) => entry.PartyID).filter((id) => !this.hydrated.has(id.toLowerCase()));
        for (let start = 0; start < missing.length; start += HYDRATE_BATCH) {
            const rows = await this.hydrate(context, missing.slice(start, start + HYDRATE_BATCH));
            for (const row of rows) {
                this.hydrated.set(String(row.Values[context.PkField] ?? '').toLowerCase(), row);
            }
        }
        return entries
            .map((entry) => this.hydrated.get(entry.PartyID.toLowerCase()))
            .filter((row): row is FKLookupRow => row !== undefined);
    }

    private decorate(rows: ReadonlyArray<FKLookupRow>): FKLookupRow[] {
        return rows.map((row) => {
            const entry = PartySignalStore.Instance.Get(String(row.Values['ID'] ?? ''));
            return {
                ...row,
                Secondary: this.secondary(row.Values),
                Chips: entry?.Signals.map((signal) => ({ Text: ChipText(signal) })),
            };
        });
    }

    /** The line that tells two same-named parties apart: where they are, and how to reach them. */
    private secondary(values: Record<string, unknown>): string {
        const place = [values['PrimaryAddressCity'], values['PrimaryAddressState']].filter(Boolean).join(', ');
        const person = [values['Title'], values['CurrentOrganizationName']].filter(Boolean).join(' at ');
        const contact = values['Website'] ?? values['PrimaryEmail'] ?? values['Email'] ?? '';
        return [place, person, contact].map((part) => String(part ?? '')).filter((part) => part.length > 0).join(' · ');
    }

    private matches(row: FKLookupRow, typed: string): boolean {
        return MATCH_FIELDS.some((field) => String(row.Values[field] ?? '').toLowerCase().includes(typed));
    }

    private kind(context: FKLookupContext): PartyKind {
        return context.RelatedEntity.Name === COMMON_ENTITIES.Person ? 'person' : 'organization';
    }

    private scopeOrganizationID(context: FKLookupContext): string | null {
        const field = context.Options['ScopeField'];
        if (typeof field !== 'string' || field.length === 0) {
            return null;
        }
        const value = context.Record.Get(field);
        return value ? String(value) : null;
    }

    /** The organization's name for the group header, falling back to wording that still reads. */
    private scopeOrganizationName(context: FKLookupContext): string {
        const field = context.Options['ScopeField'];
        if (typeof field !== 'string') {
            return 'this organization';
        }
        const value = context.Record.Get(field.replace(/ID$/, ''));
        const name = value ? String(value) : '';
        return name.length > 0 ? name : 'this organization';
    }
}

@RegisterClass(FKLookupStrategy, COMMON_ENTITIES.Organization)
export class OrganizationLookupStrategy extends PartyLookupStrategy {}

@RegisterClass(FKLookupStrategy, COMMON_ENTITIES.Person)
export class PersonLookupStrategy extends PartyLookupStrategy {}

/** Registration happens through the decorators; this forces the module to be evaluated. */
export function LoadPartyLookupStrategies(): void {
    void OrganizationLookupStrategy;
    void PersonLookupStrategy;
}
