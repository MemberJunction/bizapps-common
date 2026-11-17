/**
 * @fileoverview What a `Tagged` connection does around the cascade: gather, then withdraw.
 *
 * GATHER (before qualification)
 * - The window read only sees mail by RECEIVED time. A tag added later changes `lastModifiedDateTime`,
 *   so a second read, the late-tag sweep, asks for tagged items modified since the last sweep.
 * - Every item is re-keyed to its stable id (Message-ID / iCalUId) and loses its BCC participants:
 *   recording who was blind-copied would show it to everyone who can see the activity.
 * - A tagged reply names its ancestors in `References`. Those not in hand are read by Message-ID.
 * - Messages consented on earlier runs, in the same threads, are loaded so a reply arriving today
 *   can be proven against them.
 *
 * WITHDRAW (after the writes)
 * An item captured because it was tagged, whose tag is now GONE, is withdrawn — but only on POSITIVE
 * evidence: the item was read and has no tag. An item that cannot be found (archived, moved, mailbox
 * disabled) is "unknown" and kept; mass-withdrawing a departed AD's history because their mailbox
 * went away would be the worst failure this pass could have.
 *
 * A withdrawn activity is not deleted. Sales may have linked it to a deal and a rep may have written
 * notes on it; Common must not cascade into either. Its content and participant links are purged,
 * it is made Private, and its ExternalID is freed so a later re-tag files it afresh.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { RunView, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import { UUIDMap } from '@memberjunction/global';
import type { mjBizAppsCommonActivityEntity, mjBizAppsCommonActivityLinkEntity } from '@mj-biz-apps/common-entities';

import type { BaseActivitySyncProvider } from './BaseActivitySyncProvider.js';
import {
    HasTag,
    InternetMessageId,
    MAX_WITHDRAW_CHECKS,
    ReplyReferences,
    StableExternalId,
    WITHDRAWN_PREFIX,
    WITHDRAWN_TITLE,
    type ConsentPolicy,
    type ConsentedMessage,
} from './consent.js';
import { REASON_PROVEN, REASON_TAGGED } from './consent-stages.js';
import { ACTIVITY_SYNC_ENTITIES } from './entity-names.js';
import { EscapeText, RequireUUID, UuidInList } from './sql.js';
import type { ActivityLinkRole, ActivitySourceQuery, NormalizedItem } from './types.js';
import { IsDatabaseProvider } from './writer.js';

/** Common's own links, written from the message's participants. `Regarding`/`LoggedFor` belong to consumers. */
const PARTICIPANT_ROLES: readonly ActivityLinkRole[] = ['Participant', 'From', 'To', 'Cc', 'Bcc', 'Organizer', 'Attendee'];

export interface GatherResult {
    Items: NormalizedItem[];
    Prior: Map<string, ConsentedMessage>;
    Issues: string[];
    /** The newest `lastModifiedDateTime` the sweep saw; where the next sweep starts. */
    SweptThrough: Date | null;
    /** Set when a read failed: the run must fail closed rather than decide on half the picture. */
    Failure?: string;
}

export interface WithdrawResult {
    Withdrawn: number;
    Unknown: number;
    Issues: string[];
}

interface CandidateRow {
    ID: string;
    ExternalID: string;
    ExternalThreadID: string | null;
}

export class ConsentIntake {
    public async Gather(
        plugin: BaseActivitySyncProvider,
        query: ActivitySourceQuery,
        windowItems: readonly NormalizedItem[],
        policy: ConsentPolicy & { Tag: string },
        connectionID: string,
        provider: IMetadataProvider,
        user: UserInfo,
    ): Promise<GatherResult> {
        const issues: string[] = [];
        const items = new Map<string, NormalizedItem>();
        const add = (batch: readonly NormalizedItem[]): void => {
            for (const item of batch) {
                const stable = toStable(item, plugin.Kind);
                if (!items.has(stable.ExternalID)) items.set(stable.ExternalID, stable); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            }
        };
        add(windowItems);
        if (plugin.Kind !== 'Message') {
            return { Items: [...items.values()], Prior: new Map(), Issues: issues, SweptThrough: null };
        }

        const sweep = await plugin.Fetch({
            ...query,
            Lookup: { Kind: 'Tagged', Tag: policy.Tag, ModifiedSince: policy.SweptThrough ?? query.Since },
        });
        if (sweep.Failed) return failed(`Late-tag sweep failed: ${sweep.Issues.join(' | ')}`);
        add(sweep.Items);
        issues.push(...sweep.Issues);

        const missing = missingAncestors([...items.values()], policy.Tag);
        if (missing.length > 0) {
            const ancestors = await plugin.Fetch({ ...query, Lookup: { Kind: 'MessageIds', MessageIds: missing } });
            if (ancestors.Failed) return failed(`Ancestor lookup failed: ${ancestors.Issues.join(' | ')}`);
            add(ancestors.Items);
        }

        const all = [...items.values()];
        if (all.length > 0 && !all.some((i) => Array.isArray(i.Raw['singleValueExtendedProperties']))) {
            issues.push(
                'No reply headers came back with these messages, so no reply could be proven: only tagged items ' +
                    'are captured. The MJ Graph provider must forward ContextData.Expand.',
            );
        }
        const prior = await loadPrior(all, connectionID, provider, user);
        if ('Failure' in prior) return failed(prior.Failure);
        return { Items: all, Prior: prior.Map, Issues: issues, SweptThrough: newestModified(sweep.Items) };

        function failed(failure: string): GatherResult {
            return { Items: [], Prior: new Map(), Issues: issues, SweptThrough: null, Failure: failure };
        }
    }

    /**
     * Withdraw tagged captures whose tag is gone. `present` is what the run has already read: for the
     * calendar it is the whole window, so no second read is needed; for mail, the tagged candidates
     * are re-read by Message-ID.
     */
    public async Withdraw(
        plugin: BaseActivitySyncProvider,
        query: ActivitySourceQuery,
        present: readonly NormalizedItem[],
        policy: ConsentPolicy & { Tag: string },
        connectionID: string,
        dryRun: boolean,
        provider: IMetadataProvider,
        user: UserInfo,
    ): Promise<WithdrawResult> {
        const result: WithdrawResult = { Withdrawn: 0, Unknown: 0, Issues: [] };
        const candidates = await loadCandidates(connectionID, policy.WithdrawWindowDays, provider, user);
        if ('Failure' in candidates) {
            result.Issues.push(candidates.Failure);
            return result;
        }
        if (candidates.Capped) {
            result.Issues.push(`More than ${MAX_WITHDRAW_CHECKS} tagged items in the window; only the newest were checked for a removed tag.`);
        }
        const { Tagged, Proven } = candidates;
        if (Tagged.length === 0) return result;

        const seen = new Map(present.map((i) => [i.ExternalID, i] as const));
        if (plugin.Kind === 'Message') {
            const reread = await plugin.Fetch({ ...query, Lookup: { Kind: 'MessageIds', MessageIds: Tagged.map((t) => t.ExternalID) } });
            if (reread.Failed) {
                result.Issues.push(`Could not re-read tagged items, so none were withdrawn: ${reread.Issues.join(' | ')}`);
                return result;
            }
            for (const item of reread.Items) seen.set(toStable(item, plugin.Kind).ExternalID, item);
        }

        const untagged = Tagged.filter((row) => {
            const item = seen.get(row.ExternalID); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            if (!item) result.Unknown++;
            return item !== undefined && !HasTag(item.Raw, policy.Tag);
        });
        const goneThreads = new Set(untagged.map((r) => r.ExternalThreadID).filter((t): t is string => !!t));
        const stillTagged = new Set(Tagged.filter((r) => !untagged.includes(r)).map((r) => r.ExternalThreadID));
        const orphaned = Proven.filter((r) => r.ExternalThreadID && goneThreads.has(r.ExternalThreadID) && !stillTagged.has(r.ExternalThreadID)); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID

        for (const row of [...untagged, ...orphaned]) {
            if (dryRun) {
                result.Withdrawn++;
                continue;
            }
            const issue = await withdraw(row.ID, provider, user);
            if (issue) result.Issues.push(issue);
            else result.Withdrawn++;
        }
        if (result.Withdrawn > 0) {
            result.Issues.push(`${dryRun ? 'Would withdraw' : 'Withdrew'} ${result.Withdrawn} item(s) whose "${policy.Tag}" tag was removed.`);
        }
        if (result.Unknown > 0) {
            result.Issues.push(`${result.Unknown} tagged item(s) could not be found in the mailbox and were kept, not withdrawn.`);
        }
        return result;
    }
}

function toStable(item: NormalizedItem, kind: BaseActivitySyncProvider['Kind']): NormalizedItem {
    return {
        ...item,
        ExternalID: StableExternalId(item, kind),
        Participants: item.Participants.filter((p) => p.Role !== 'Bcc'),
    };
}

function missingAncestors(items: readonly NormalizedItem[], tag: string): string[] {
    const have = new Set(items.map((i) => InternetMessageId(i.Raw)).filter(Boolean));
    const wanted = items.filter((i) => HasTag(i.Raw, tag)).flatMap((i) => ReplyReferences(i.Raw));
    return [...new Set(wanted)].filter((id) => !have.has(id));
}

function newestModified(items: readonly NormalizedItem[]): Date | null {
    let newest: number | null = null;
    for (const item of items) {
        const raw = item.Raw['lastModifiedDateTime'];
        const at = typeof raw === 'string' ? Date.parse(raw) : NaN;
        if (!Number.isNaN(at) && (newest === null || at > newest)) newest = at;
    }
    return newest === null ? null : new Date(newest);
}

/** Messages consented on earlier runs of THIS connection, in the threads at hand. */
async function loadPrior(
    items: readonly NormalizedItem[],
    connectionID: string,
    provider: IMetadataProvider,
    user: UserInfo,
): Promise<{ Map: Map<string, ConsentedMessage> } | { Failure: string }> {
    const threads = [...new Set(items.map((i) => i.ExternalThreadID).filter((t): t is string => !!t))];
    const prior = new Map<string, ConsentedMessage>();
    if (threads.length === 0) return { Map: prior };
    const res = await RunView.FromMetadataProvider(provider).RunView<{ ExternalID: string; Details: string | null }>(
        {
            EntityName: ACTIVITY_SYNC_ENTITIES.Activities,
            ExtraFilter:
                `ActivitySyncConnectionID = '${RequireUUID(connectionID, 'ActivitySyncConnectionID')}' ` +
                `AND ExternalThreadID IN (${threads.map((t) => `'${EscapeText(t)}'`).join(', ')}) ` +
                `AND ExternalID NOT LIKE '${WITHDRAWN_PREFIX}%'`,
            Fields: ['ExternalID', 'Details'],
            ResultType: 'simple',
        },
        user,
    );
    if (!res.Success) return { Failure: `Consented-thread lookup failed: ${res.ErrorMessage}` };
    for (const row of res.Results ?? []) {
        prior.set(row.ExternalID, { MessageId: row.ExternalID, Participants: participantsFromDetails(row.Details) }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
    }
    return { Map: prior };
}

/** `Activity.Details` is the Graph payload as written; the addresses come back out of it. */
function participantsFromDetails(details: string | null): string[] {
    if (!details) return [];
    let raw: Record<string, unknown>;
    try {
        raw = JSON.parse(details) as Record<string, unknown>;
    } catch {
        // Details is written by this package as JSON.stringify(Raw). Unreadable means hand-edited; an
        // empty list makes any outbound reply to it look like it adds recipients, which fails closed.
        return [];
    }
    const out: string[] = [];
    const grab = (r: unknown): void => {
        const address = (r as { emailAddress?: { address?: unknown } })?.emailAddress?.address;
        if (typeof address === 'string' && address.trim()) out.push(address.trim().toLowerCase());
    };
    grab(raw['from']);
    for (const key of ['toRecipients', 'ccRecipients']) {
        const list = raw[key];
        if (Array.isArray(list)) list.forEach(grab);
    }
    return out;
}

/** Captured activities in the window, split by how their consent was granted. */
async function loadCandidates(
    connectionID: string,
    windowDays: number,
    provider: IMetadataProvider,
    user: UserInfo,
): Promise<{ Tagged: CandidateRow[]; Proven: CandidateRow[]; Capped: boolean } | { Failure: string }> {
    const since = new Date(Date.now() - windowDays * 86_400_000).toISOString();
    const rv = RunView.FromMetadataProvider(provider);
    const activities = await rv.RunView<CandidateRow>(
        {
            EntityName: ACTIVITY_SYNC_ENTITIES.Activities,
            ExtraFilter:
                `ActivitySyncConnectionID = '${RequireUUID(connectionID, 'ActivitySyncConnectionID')}' ` +
                `AND StartedAt >= '${since}' AND ExternalID NOT LIKE '${WITHDRAWN_PREFIX}%'`,
            Fields: ['ID', 'ExternalID', 'ExternalThreadID'],
            OrderBy: 'StartedAt DESC',
            MaxRows: MAX_WITHDRAW_CHECKS + 1,
            ResultType: 'simple',
        },
        user,
    );
    if (!activities.Success) return { Failure: `Withdrawal candidate lookup failed: ${activities.ErrorMessage}` };
    const rows = (activities.Results ?? []).slice(0, MAX_WITHDRAW_CHECKS);
    if (rows.length === 0) return { Tagged: [], Proven: [], Capped: false };
    const details = await rv.RunView<{ ActivityID: string; Reason: string | null }>(
        {
            EntityName: ACTIVITY_SYNC_ENTITIES.RunDetails,
            ExtraFilter: `DecidedByStage = 'Consent' AND Decision = 'Included' AND ActivityID IN (${UuidInList(rows.map((r) => r.ID), 'ActivityID')})`,
            Fields: ['ActivityID', 'Reason'],
            ResultType: 'simple',
        },
        user,
    );
    if (!details.Success) return { Failure: `Withdrawal consent lookup failed: ${details.ErrorMessage}` };
    const how = new UUIDMap<string>();
    for (const d of details.Results ?? []) how.Set(d.ActivityID, d.Reason ?? '');
    const reasonOf = (r: CandidateRow): string => how.Get(r.ID) ?? '';
    return {
        Tagged: rows.filter((r) => reasonOf(r).startsWith(REASON_TAGGED)),
        Proven: rows.filter((r) => reasonOf(r).startsWith(REASON_PROVEN)),
        Capped: (activities.Results ?? []).length > MAX_WITHDRAW_CHECKS,
    };
}

/** Purge one activity's content and participant links, in one transaction. Returns an issue, or null. */
async function withdraw(activityID: string, provider: IMetadataProvider, user: UserInfo): Promise<string | null> {
    if (!IsDatabaseProvider(provider)) return 'Withdrawal needs a database provider; nothing was withdrawn.';
    const links = await RunView.FromMetadataProvider(provider).RunView<mjBizAppsCommonActivityLinkEntity>(
        {
            EntityName: ACTIVITY_SYNC_ENTITIES.ActivityLinks,
            ExtraFilter: `ActivityID = '${RequireUUID(activityID, 'ActivityID')}' AND Role IN (${PARTICIPANT_ROLES.map((r) => `'${r}'`).join(', ')})`,
            ResultType: 'entity_object',
        },
        user,
    );
    if (!links.Success) return `Withdraw ${activityID}: link lookup failed: ${links.ErrorMessage}`;
    const scope = await provider.BeginEntityTransaction();
    try {
        for (const link of links.Results ?? []) {
            if (!(await link.Delete())) throw new Error(`link ${link.ID}: ${link.LatestResult?.CompleteMessage ?? 'delete failed'}`);
        }
        const activity = await provider.GetEntityObject<mjBizAppsCommonActivityEntity>(ACTIVITY_SYNC_ENTITIES.Activities, user);
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
