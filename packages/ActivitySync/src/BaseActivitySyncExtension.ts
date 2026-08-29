/**
 * @fileoverview The in-process enrichment contract — how a downstream app adds to an Activity
 * without Common knowing it exists.
 *
 * ── WHY IN-STREAM AND NOT AN ENTITY ACTION ─────────────────────────────────────────────────────
 *
 * MJ's `Entity Actions` bind declaratively to `AfterCreate` and are the right tool for most
 * after-the-fact work. They are the wrong tool here for one reason: they fire AFTER the commit, in
 * a separate transaction. An activity's links are what make it reachable — every read starts from a
 * link — so an activity that commits without its deal link is briefly, and observably, unattributed.
 * Running extensions inside the write transaction keeps "the activity and everything that explains
 * it" a single atomic fact.
 *
 * ── EXTENSIONS ENRICH; THEY NEVER VETO ─────────────────────────────────────────────────────────
 *
 * Qualification is the engine's job and has already run by the time an extension sees anything. If
 * an extension could reject an activity, whether a message got captured would depend on which apps
 * happened to be installed on the host — precisely the coupling this design exists to prevent. An
 * extension that wants an activity gone should record why, not suppress it.
 *
 * Registered by `DriverClass`, enabled and ordered by an `ActivitySyncExtension` row the consumer
 * app ships in its OWN metadata:
 *
 * ```ts
 * @RegisterClass(BaseActivitySyncExtension, 'Sales.DealLinker')
 * export class DealLinkerExtension extends BaseActivitySyncExtension { ... }
 * ```
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';
import type {
    mjBizAppsCommonActivityEntity,
    mjBizAppsCommonActivityLinkEntity,
} from '@mj-biz-apps/common-entities';

import type { ActivityIdentityKind, ActivityLinkRole, NormalizedItem } from './types.js';

/** A party the engine matched to a Common record. */
export interface ResolvedParty {
    Kind: 'Person' | 'Organization';
    RecordID: string;
    Role: ActivityLinkRole;
}

/** A party the engine could not match, recorded so a later sweep can resolve it. */
export interface UnresolvedParty {
    Kind: ActivityIdentityKind;
    Value: string;
    Role: ActivityLinkRole;
}

/**
 * What an extension is handed.
 *
 * The activity is already saved and the transaction is still open, so an extension adds rows that
 * commit or roll back with it.
 */
export interface ActivityWriteContext {
    /** The saved activity. Mutating and re-saving it is allowed; deleting it is not. */
    Activity: mjBizAppsCommonActivityEntity;
    /** Links written by the engine so far, in write order. */
    Links: mjBizAppsCommonActivityLinkEntity[];
    /** The source item, for anything the entity does not carry. */
    Item: NormalizedItem;
    ResolvedParties: ResolvedParty[];
    UnresolvedParties: UnresolvedParty[];
    ConnectionID: string;
    ProviderTypeCode: string;
    ContextUser: UserInfo;
    /**
     * The provider the engine is writing through.
     *
     * Carried rather than left to the extension to obtain, because an extension MUST write through
     * the same provider as the engine or its rows land outside the write transaction — which is the
     * one guarantee an in-stream extension exists to give. It is also how an extension resolves an
     * `EntityID` for a link (`Provider.Entities`).
     */
    Provider: IMetadataProvider;
}

export abstract class BaseActivitySyncExtension {
    /**
     * Add whatever this app knows to the activity, inside its transaction.
     *
     * Throwing is a legitimate way to report failure. What happens next is the REGISTRATION's
     * choice, not this class's: `FailurePolicy = 'Skip'` (the default) records the error and lets
     * the activity commit without the enrichment; `'Abort'` rolls the whole write back. Skip is the
     * default because the activity is worth more than the enrichment, and one buggy consumer app
     * must not be able to halt ingestion for every other app on the host.
     *
     * Keep it inside the registration's `TimeoutMS`: this runs with the write transaction open.
     */
    public abstract Enrich(context: ActivityWriteContext): Promise<void>;
}
