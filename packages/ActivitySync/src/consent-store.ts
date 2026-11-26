/**
 * @fileoverview Where a Tagged connection's consent lives, and the one write it makes.
 *
 * CONSENT BELONGS TO A CONNECTION, NOT TO AN ACTIVITY ROW. One email in two ADs' mailboxes is one
 * Activity (it is keyed on the RFC Message-ID), but each mailbox owner consents separately. So consent
 * is read from the RUN DETAILS of this connection's own runs — `DecidedByStage = 'Consent'`, decision
 * `Included` or `Duplicate` — never from `Activity.ActivitySyncConnectionID`, which names only whichever
 * connection happened to write the row first.
 *
 * Every read is for ONE SURFACE (mail or calendar, by Activity type code), so the mail pass never treats a
 * meeting's iCalUId as a Message-ID and the calendar pass never counts tagged emails as missing.
 *
 * The interface is what `ConsentIntake` depends on; `DatabaseConsentStore` is the SQL behind it.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { RunView, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import { UUIDMap } from '@memberjunction/global';
import type { mjBizAppsCommonActivityEntity, mjBizAppsCommonActivityLinkEntity } from '@mj-biz-apps/common-entities';

import { WITHDRAWN_PREFIX, WITHDRAWN_TITLE } from './consent.js';
import { ACTIVITY_SYNC_ENTITIES } from './entity-names.js';
import { EscapeText, RequireUUID, UuidInList } from './sql.js';
import type { ActivityLinkRole } from './types.js';
import { IsDatabaseProvider } from './writer.js';

/** One activity this connection consented to, with the reason of its LATEST consent decision. */
export interface ConsentRecord {
    ActivityID: string;
    ExternalID: string;
    ExternalThreadID: string | null;
    /** The stored Graph payload (`Activity.Details`), for the participants of a prior message. */
    Details: string | null;
    /** e.g. `Tagged "AIDP" by the mailbox owner`, `Proven reply to <id>`. */
    Reason: string;
    /** When this connection last consented to it. Withdrawal windows on this, not on the message's date. */
    ConsentedAt: Date;
}

export interface ConsentQuery {
    ConnectionID: string;
    /** `Email` or `Meeting`: the surface being run. */
    TypeCode: string;
    /** Only these activities (by ExternalID). */
    ExternalIDs?: readonly string[];
    /** Only consent given at or after this instant. */
    ConsentedSince?: Date;
    /** Newest first, at most this many. */
    MaxRows?: number;
}

export type StoreResult<T> = { Failed: false; Value: T } | { Failed: true; Issue: string };

export interface ConsentStore {
    ConsentedActivities(query: ConsentQuery): Promise<StoreResult<ConsentRecord[]>>;
    /**
     * Which of these messages (by ExternalID) ANOTHER connection still consents to, judged by that
     * connection's LATEST Consent decision, so they must not be withdrawn here.
     */
    ConsentedElsewhere(externalIDs: readonly string[], connectionID: string): Promise<StoreResult<Set<string>>>;
    /** Purge one activity's content and participant links, keep the row. Returns an issue, or null. */
    Withdraw(activityID: string): Promise<string | null>;
}

/** Common's own links, written from the message's participants. `Regarding`/`LoggedFor` belong to consumers. */
const PARTICIPANT_ROLES: readonly ActivityLinkRole[] = ['Participant', 'From', 'To', 'Cc', 'Bcc', 'Organizer', 'Attendee'];
/**
 * Every Consent-stage decision counts, including the `Excluded` one a mailbox records when its consent
 * ends: a mailbox's LATEST decision about a message says whether it consents now.
 *
 * Linked by ExternalID, not ActivityID: `CK_ActivitySyncRunDetail_ActivityOnlyWhenIncluded` keeps
 * ActivityID off every non-Included detail, so a `Duplicate` (the second mailbox's consent to a shared
 * Activity) can only be tied to its message by ExternalID, which on a Tagged connection is the stable
 * RFC Message-ID / iCalUId the Activity carries too.
 */
// Real decisions only. A dry run writes `WouldInclude` / `WouldExclude` under the same stage; it decided
// nothing, so it must never be the "latest" decision that hides a mailbox's actual consent.
const CONSENT_STAGE = `DecidedByStage = 'Consent' AND Decision IN ('Included', 'Duplicate', 'Excluded')`;
const GRANTING: ReadonlySet<string> = new Set(['Included', 'Duplicate']);

interface DetailRow {
    ExternalID: string;
    ActivitySyncRunID: string;
    Decision: string;
    Reason: string | null;
    __mj_CreatedAt: Date | string;
}

interface ActivityRow {
    ID: string;
    ExternalID: string;
    ExternalThreadID: string | null;
    Details: string | null;
}

export class DatabaseConsentStore implements ConsentStore {
    public constructor(
        private readonly provider: IMetadataProvider,
        private readonly user: UserInfo,
    ) {}

    public async ConsentedActivities(query: ConsentQuery): Promise<StoreResult<ConsentRecord[]>> {
        const conn = RequireUUID(query.ConnectionID, 'ActivitySyncConnectionID');
        const rv = RunView.FromMetadataProvider(this.provider);

        // Step 1 (RLS-safe, batched): read this connection's runs and the surface's Activity Type
        // via RunViews instead of embedding raw SQL subqueries against vw* views.
        const [runsRes, typesRes] = await rv.RunViews(
            [
                {
                    EntityName: ACTIVITY_SYNC_ENTITIES.Runs,
                    ExtraFilter: `ActivitySyncConnectionID = '${conn}'`,
                    Fields: ['ID'],
                    ResultType: 'simple',
                    CacheLocal: false,
                },
                {
                    EntityName: ACTIVITY_SYNC_ENTITIES.ActivityTypes,
                    ExtraFilter: `Code = '${EscapeText(query.TypeCode)}'`,
                    Fields: ['ID'],
                    ResultType: 'simple',
                    CacheLocal: false,
                },
            ],
            this.user,
        );
        if (!runsRes?.Success) return { Failed: true, Issue: `Consent run lookup failed: ${runsRes?.ErrorMessage}` };
        if (!typesRes?.Success) return { Failed: true, Issue: `Consent activity type lookup failed: ${typesRes?.ErrorMessage}` };

        const runIDs = ((runsRes.Results ?? []) as Array<{ ID: string }>).map((r) => r.ID);
        const typeIDs = ((typesRes.Results ?? []) as Array<{ ID: string }>).map((t) => t.ID);
        if (runIDs.length === 0 || typeIDs.length === 0) {
            return { Failed: false, Value: [] };
        }

        // Step 2: read consent-stage run details scoped to those runs.
        const details = await rv.RunView<DetailRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.RunDetails,
                ExtraFilter:
                    `${CONSENT_STAGE} AND ActivitySyncRunID IN (${UuidInList(runIDs, 'ActivitySyncRunID')})` +
                    (query.ExternalIDs ? ` AND ExternalID IN (${inList(query.ExternalIDs)})` : '') +
                    (query.ConsentedSince ? ` AND __mj_CreatedAt >= '${query.ConsentedSince.toISOString()}'` : ''),
                Fields: ['ExternalID', 'ActivitySyncRunID', 'Decision', 'Reason', '__mj_CreatedAt'],
                OrderBy: '__mj_CreatedAt DESC',
                ResultType: 'simple',
                CacheLocal: false,
            },
            this.user,
        );
        if (!details.Success) return { Failed: true, Issue: `Consent lookup failed: ${details.ErrorMessage}` };
        const granting = latestPerMessage(details.Results ?? []).filter((d) => GRANTING.has(d.Decision));
        if (granting.length === 0) return { Failed: false, Value: [] };

        // Step 3: read matching live (non-withdrawn) activities for this surface via RunView.
        const rows = await rv.RunView<ActivityRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Activities,
                ExtraFilter:
                    `ExternalID IN (${inList(granting.map((d) => d.ExternalID))}) ` +
                    `AND ExternalID NOT LIKE '${WITHDRAWN_PREFIX}%' ` +
                    `AND ActivityTypeID IN (${UuidInList(typeIDs, 'ActivityTypeID')})`,
                Fields: ['ID', 'ExternalID', 'ExternalThreadID', 'Details'],
                ResultType: 'simple',
                CacheLocal: false,
            },
            this.user,
        );
        if (!rows.Success) return { Failed: true, Issue: `Consented activity lookup failed: ${rows.ErrorMessage}` };
        const byExternal = new Map((rows.Results ?? []).map((r) => [r.ExternalID, r] as const));
        const records = granting.flatMap((d) => toRecord(d, byExternal.get(d.ExternalID))); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        return {
            Failed: false,
            Value: query.MaxRows === undefined ? records : records.slice(0, query.MaxRows),
        };
    }

    public async ConsentedElsewhere(externalIDs: readonly string[], connectionID: string): Promise<StoreResult<Set<string>>> {
        const found = new Set<string>();
        if (externalIDs.length === 0) return { Failed: false, Value: found };
        const conn = RequireUUID(connectionID, 'ActivitySyncConnectionID');
        const rv = RunView.FromMetadataProvider(this.provider);

        // Two-step RLS-safe read: query consent details for the specific ExternalIDs first, then
        // resolve their runs excluding this connection via RunView (never a raw vw* subquery).
        const details = await rv.RunView<DetailRow>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.RunDetails,
                ExtraFilter: `${CONSENT_STAGE} AND ExternalID IN (${inList(externalIDs)})`,
                Fields: ['ExternalID', 'ActivitySyncRunID', 'Decision', 'Reason', '__mj_CreatedAt'],
                OrderBy: '__mj_CreatedAt DESC',
                ResultType: 'simple',
                CacheLocal: false,
            },
            this.user,
        );
        if (!details.Success) return { Failed: true, Issue: `Other-mailbox consent lookup failed: ${details.ErrorMessage}` };
        const rows = details.Results ?? [];
        if (rows.length === 0) return { Failed: false, Value: found };

        const runRows = await rv.RunView<{ ID: string; ActivitySyncConnectionID: string }>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.Runs,
                ExtraFilter:
                    `ID IN (${UuidInList([...new Set(rows.map((r) => r.ActivitySyncRunID))], 'ActivitySyncRunID')}) ` +
                    `AND ActivitySyncConnectionID <> '${conn}'`,
                Fields: ['ID', 'ActivitySyncConnectionID'],
                ResultType: 'simple',
                CacheLocal: false,
            },
            this.user,
        );
        if (!runRows.Success) return { Failed: true, Issue: `Other-mailbox run lookup failed: ${runRows.ErrorMessage}` };
        const connectionOf = new UUIDMap<string>();
        for (const r of runRows.Results ?? []) connectionOf.Set(r.ID, r.ActivitySyncConnectionID);
        // Newest first: the first row per (connection, message) is that mailbox's current decision.
        const decided = new Set<string>();
        for (const d of rows) {
            const otherConn = connectionOf.Get(d.ActivitySyncRunID);
            if (!otherConn) continue;
            const key = `${otherConn.toLowerCase()}|${d.ExternalID}`;
            if (decided.has(key)) continue;
            decided.add(key);
            if (GRANTING.has(d.Decision)) found.add(d.ExternalID);
        }
        return { Failed: false, Value: found };
    }

    public async Withdraw(activityID: string): Promise<string | null> {
        const provider = this.provider;
        if (!IsDatabaseProvider(provider)) return 'Withdrawal needs a database provider; nothing was withdrawn.';
        const links = await RunView.FromMetadataProvider(provider).RunView<mjBizAppsCommonActivityLinkEntity>(
            {
                EntityName: ACTIVITY_SYNC_ENTITIES.ActivityLinks,
                ExtraFilter: `ActivityID = '${RequireUUID(activityID, 'ActivityID')}' AND Role IN (${PARTICIPANT_ROLES.map((r) => `'${r}'`).join(', ')})`,
                ResultType: 'entity_object',
            },
            this.user,
        );
        if (!links.Success) return `Withdraw ${activityID}: link lookup failed: ${links.ErrorMessage}`;
        const scope = await provider.BeginEntityTransaction();
        try {
            for (const link of links.Results ?? []) {
                if (!(await link.Delete())) throw new Error(`link ${link.ID}: ${link.LatestResult?.CompleteMessage ?? 'delete failed'}`);
            }
            const activity = await provider.GetEntityObject<mjBizAppsCommonActivityEntity>(ACTIVITY_SYNC_ENTITIES.Activities, this.user);
            if (!(await activity.Load(activityID))) throw new Error('activity could not be loaded');
            activity.ExternalID = `${WITHDRAWN_PREFIX}${activity.ID}`;
            activity.ExternalThreadID = null;
            activity.Title = WITHDRAWN_TITLE;
            activity.Description = null;
            activity.Details = null;
            activity.Visibility = 'Private';
            if (!(await activity.Save())) throw new Error(activity.LatestResult?.CompleteMessage ?? 'save failed');
            await scope.Commit();
            return null;
        } catch (e) {
            await scope.Rollback();
            return `Withdraw ${activityID} failed and was rolled back: ${(e as Error).message}`;
        }
    }
}

/** Details arrive newest first; keep the first (latest) per message. */
function latestPerMessage(details: readonly DetailRow[]): DetailRow[] {
    const seen = new Set<string>();
    const out: DetailRow[] = [];
    for (const d of details) {
        if (seen.has(d.ExternalID)) continue; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        seen.add(d.ExternalID);
        out.push(d);
    }
    return out;
}

function inList(values: readonly string[]): string {
    return values.length > 0 ? values.map((v) => `'${EscapeText(v)}'`).join(', ') : "''";
}

function toRecord(detail: DetailRow, activity: ActivityRow | undefined): ConsentRecord[] {
    if (!activity) return [];
    return [
        {
            ActivityID: activity.ID,
            ExternalID: activity.ExternalID,
            ExternalThreadID: activity.ExternalThreadID,
            Details: activity.Details,
            Reason: detail.Reason ?? '',
            ConsentedAt: new Date(detail.__mj_CreatedAt),
        },
    ];
}
