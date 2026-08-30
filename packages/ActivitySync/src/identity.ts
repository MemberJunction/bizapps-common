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
import type { ItemParticipant } from './types.js';

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
        const addresses = [
            ...new Set(participants.map((p) => p.Address.trim().toLowerCase()).filter(Boolean)),
        ];
        if (addresses.length === 0) {
            return { Resolved: [], Unresolved: [], Known: new Map(), LookupFailed: false };
        }

        const { known, failed } = await this.lookup(addresses, contextUser);
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
        addresses: string[],
        contextUser: UserInfo,
    ): Promise<{ known: Map<string, KnownAddress>; failed: boolean }> {
        const rv = new RunView();
        const res = await rv.RunView<ContactMethodRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ContactMethods,
                ExtraFilter: `LOWER(Value) IN (${InList(addresses)})`,
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
}

export function Quote(value: string): string {
    return EscapeText(value);
}
