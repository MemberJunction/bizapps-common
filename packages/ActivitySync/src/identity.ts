/**
 * Participant address → Person / Organization.
 *
 * An unmatched address becomes an unresolved ActivityLink (IdentityKind + IdentityValue).
 * This file never creates a Person.
 */
import { RunView, type UserInfo } from '@memberjunction/core';

import type { ResolvedParty, UnresolvedParty } from './BaseActivitySyncExtension.js';
import { ACTIVITY_SYNC_ENTITIES } from './entity-names.js';
import { EscapeText, InList } from './sql.js';
import type { ActivityIdentityKind, ItemParticipant } from './types.js';

/**
 * The ContactType names (the denormalized `ContactType` view column) a participant's IdentityKind
 * may legitimately match, narrowing the lookup so an email address can never resolve through a
 * LinkedIn handle or website URL that happens to carry the same text. 'ExternalUser' has no
 * canonical contact type (hosts seed their own), so it stays unrestricted by type.
 */
const CONTACT_TYPES_BY_KIND: Partial<Record<ActivityIdentityKind, readonly string[]>> = {
    Email: ['Email'],
    Phone: ['Mobile Phone', 'Work Phone', 'Home Phone', 'Fax'],
};

export interface KnownAddress {
    Address: string;
    PersonID: string | null;
    OrganizationID: string | null;
}

export interface IdentityResolution {
    Resolved: ResolvedParty[];
    Unresolved: UnresolvedParty[];
    Known: Map<string, KnownAddress>;
    LookupFailed: boolean;
}

interface ContactMethodRow {
    ID: string;
    Value: string;
    PersonID: string | null;
    OrganizationID: string | null;
}

export class IdentityResolver {
    /**
     * ONE query for the whole batch. A failed read is LookupFailed — not "nobody matched" —
     * because those two look the same and only one may advance the watermark.
     */
    public async Resolve(
        participants: readonly ItemParticipant[],
        contextUser: UserInfo,
    ): Promise<IdentityResolution> {
        const byKind = new Map<ActivityIdentityKind, Set<string>>();
        for (const participant of participants) {
            const address = participant.Address.trim().toLowerCase();
            if (!address) continue;
            let addresses = byKind.get(participant.IdentityKind);
            if (!addresses) byKind.set(participant.IdentityKind, (addresses = new Set()));
            addresses.add(address);
        }
        if (byKind.size === 0) {
            return { Resolved: [], Unresolved: [], Known: new Map(), LookupFailed: false };
        }

        const { known, failed } = await this.lookup(byKind, contextUser);
        const resolved: ResolvedParty[] = [];
        const unresolved: UnresolvedParty[] = [];
        const seen = new Set<string>();

        for (const participant of participants) {
            const address = participant.Address.trim().toLowerCase();
            if (!address) continue;
            const hit = known.get(address);
            if (hit?.PersonID) {
                const key = `p:${hit.PersonID}:${participant.Role}`;
                if (seen.has(key)) continue;
                seen.add(key);
                resolved.push({ Kind: 'Person', RecordID: hit.PersonID, Role: participant.Role });
            } else if (hit?.OrganizationID) {
                const key = `o:${hit.OrganizationID}:${participant.Role}`;
                if (seen.has(key)) continue;
                seen.add(key);
                resolved.push({ Kind: 'Organization', RecordID: hit.OrganizationID, Role: participant.Role });
            } else {
                const key = `i:${participant.IdentityKind}:${address}`;
                if (seen.has(key)) continue;
                seen.add(key);
                unresolved.push({
                    Kind: participant.IdentityKind,
                    Value: address,
                    Role: participant.Role,
                });
            }
        }

        return { Resolved: resolved, Unresolved: unresolved, Known: known, LookupFailed: failed };
    }

    private async lookup(
        byKind: ReadonlyMap<ActivityIdentityKind, ReadonlySet<string>>,
        contextUser: UserInfo,
    ): Promise<{ known: Map<string, KnownAddress>; failed: boolean }> {
        const rv = new RunView();
        const res = await rv.RunView<ContactMethodRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ContactMethods,
                // Sargable equality. Literals are already lowercased. SQL Server CI collations
                // match mixed-case stored values; wrapping the column in LOWER() would disable
                // the index on the highest-cardinality lookup in a run. PostgreSQL is CS by
                // default and wants citext or a functional index, not LOWER(Value) as a scan.
                // Each kind's clause is narrowed to the ContactType names that kind may match.
                ExtraFilter: this.buildFilter(byKind),
                ResultType: 'simple',
            },
            contextUser,
        );
        if (!res.Success) {
            return { known: new Map(), failed: true };
        }
        const known = new Map<string, KnownAddress>();
        for (const row of res.Results ?? []) {
            const address = String(row.Value ?? '').trim().toLowerCase();
            if (!address) continue;
            known.set(address, {
                Address: address,
                PersonID: row.PersonID ?? null,
                OrganizationID: row.OrganizationID ?? null,
            });
        }
        return { known, failed: false };
    }

    /** One `Value IN (...)` clause per IdentityKind, each narrowed to that kind's ContactType names. */
    private buildFilter(byKind: ReadonlyMap<ActivityIdentityKind, ReadonlySet<string>>): string {
        const clauses: string[] = [];
        for (const [kind, addresses] of byKind) {
            const values = `Value IN (${InList([...addresses])})`;
            const types = CONTACT_TYPES_BY_KIND[kind];
            clauses.push(types ? `(${values} AND ContactType IN (${InList(types)}))` : values);
        }
        return clauses.join(' OR ');
    }
}

export function Quote(value: string): string {
    return EscapeText(value);
}
