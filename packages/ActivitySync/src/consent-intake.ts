/**
 * @fileoverview What a `Tagged` connection does around the cascade: gather, then withdraw.
 *
 * GATHER (before qualification)
 * - The window read only sees mail by RECEIVED time. A tag added later changes `lastModifiedDateTime`,
 *   so a second read, the late-tag sweep, asks for tagged items modified since the last sweep. It reads
 *   in windows and only ever claims to have read a window that came back whole (a capped page means the
 *   window is narrowed, never skipped).
 * - Every item is re-keyed to its stable id (Message-ID / iCalUId) and loses its blind copy.
 * - A tagged message names its ancestors in `References`; those not in hand are read by Message-ID.
 *   A message tagged LATE may already have replies behind the watermark, so its conversation is read too.
 * - What this connection consented to on earlier runs, among the messages the batch names, is loaded so a
 *   reply arriving today can be proven against it.
 *
 * WITHDRAW (after the writes)
 * A capture is withdrawn only on POSITIVE evidence that consent is gone: the item was read and carries no
 * tag, or it was proven only by a message that is itself being withdrawn and is not tagged now. Anything
 * that cannot be read, a re-read that came back cut off, or an item another mailbox still consents to, is
 * KEPT and reported. Mass-withdrawing history because a read went wrong is the worst failure this pass has.
 *
 * Consent is per connection and per surface; see `consent-store.ts`.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { BaseActivitySyncProvider } from './BaseActivitySyncProvider.js';
import {
    HasTag,
    InternetMessageId,
    MAX_ANCESTOR_REFERENCES,
    MAX_WITHDRAW_CHECKS,
    PreferTaggedCopy,
    ReplyReferences,
    StableItem,
    type ConsentPolicy,
    type ConsentedMessage,
} from './consent.js';
import { REASON_PROVEN, REASON_TAGGED } from './consent-stages.js';
import type { ConsentRecord, ConsentStore } from './consent-store.js';
import type { ActivitySourceKind, ActivitySourceQuery, NormalizedItem } from './types.js';

/** The Activity type code each surface writes (GraphMessageMapper / MSGraphCalendarSyncProvider). */
export const SURFACE_TYPE_CODE: Record<ActivitySourceKind, string> = {
    Message: 'Email',
    Calendar: 'Meeting',
    Social: 'Social',
    Chat: 'Chat',
};
/** Requests one sweep may make. Each either drains a window or halves it. */
export const MAX_SWEEP_REQUESTS = 12;
/**
 * Each sweep starts this far before its recorded position. The position is our clock; the tag time is
 * Exchange's. A server running ahead of Exchange would otherwise skip a tag made in the gap, for good.
 * Items read twice are absorbed by de-duplication.
 */
export const SWEEP_OVERLAP_MS = 10 * 60_000;
/** Message-IDs per re-read request, so a page holds every copy of every id it names. */
export const REREAD_BATCH = 10;

export interface GatherResult {
    Items: NormalizedItem[];
    Prior: Map<string, ConsentedMessage>;
    Issues: string[];
    /** How far the sweep has read COMPLETELY; where the next sweep starts. Null: no progress to record. */
    SweptThrough: Date | null;
    /** Set when a read failed: the run must fail closed rather than decide on half the picture. */
    Failure?: string;
}

export interface WithdrawResult {
    Withdrawn: number;
    Unknown: number;
    Issues: string[];
    /**
     * Items whose consent THIS mailbox no longer gives, whether or not the row was withdrawn (another
     * mailbox may still hold it). The run records each as a Consent `Excluded` decision, so this mailbox
     * stops counting as consenting the next time anyone asks.
     */
    Revoked: NormalizedItem[];
}

type TaggedPolicy = ConsentPolicy & { Tag: string };

export class ConsentIntake {
    public constructor(private readonly Now: () => Date = () => new Date()) {}

    public async Gather(
        plugin: BaseActivitySyncProvider,
        query: ActivitySourceQuery,
        windowItems: readonly NormalizedItem[],
        policy: TaggedPolicy,
        connectionID: string,
        store: ConsentStore,
    ): Promise<GatherResult> {
        const issues: string[] = [];
        const items = new Map<string, NormalizedItem>();
        const add = (batch: readonly NormalizedItem[]): void => {
            for (const item of batch) {
                const stable = StableItem(item, plugin.Kind);
                items.set(stable.ExternalID, PreferTaggedCopy(items.get(stable.ExternalID), stable, policy.Tag)); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            }
        };
        add(windowItems);
        if (plugin.Kind !== 'Message') {
            return { Items: [...items.values()], Prior: new Map(), Issues: issues, SweptThrough: null };
        }
        const failed = (failure: string): GatherResult => ({ Items: [], Prior: new Map(), Issues: issues, SweptThrough: null, Failure: failure });

        const sweep = await this.sweep(plugin, query, policy, windowItems);
        if (sweep.Failure) return failed(sweep.Failure);
        issues.push(...sweep.Issues);
        add(sweep.Items);

        const lateTagged = sweep.Items.filter((i) => HasTag(i.Raw, policy.Tag));
        const threads = [...new Set(lateTagged.map((i) => i.ExternalThreadID).filter((t): t is string => !!t))];
        if (threads.length > 0) {
            const conversations = await plugin.Fetch({ ...query, Lookup: { Kind: 'Conversations', ConversationIds: threads } });
            if (conversations.Failed) return failed(`Conversation lookup failed: ${conversations.Issues.join(' | ')}`);
            if (conversations.Capped) issues.push('A late-tagged conversation held more messages than one read returns; later replies may be missing.');
            add(conversations.Items);
        }

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
        const prior = await loadPrior(all, connectionID, SURFACE_TYPE_CODE[plugin.Kind], store);
        if (prior.Failed) return failed(prior.Issue);
        return { Items: all, Prior: prior.Value, Issues: issues, SweptThrough: sweep.SweptThrough };
    }

    /**
     * Tagged items modified since the last sweep, read window by window.
     *
     * Graph returns a lookup page in no order we can rely on, so a page that comes back FULL says only
     * that the window holds too much: the window is halved and read again. A window that comes back short
     * was read completely, and only then does the sweep position move past it.
     */
    private async sweep(
        plugin: BaseActivitySyncProvider,
        query: ActivitySourceQuery,
        policy: TaggedPolicy,
        windowItems: readonly NormalizedItem[],
    ): Promise<{ Items: NormalizedItem[]; Issues: string[]; SweptThrough: Date | null; Failure?: string }> {
        const now = this.Now();
        // A FIRST RUN HAS NOTHING TO SWEEP: with no watermark the window read covers every message, tagged
        // or not. Its position is the newest change it actually READ (Exchange's clock, not ours), so the
        // next sweep catches every tag made after the read.
        const recorded = policy.SweptThrough ?? query.Since;
        if (recorded === null) return { Items: [], Issues: [], SweptThrough: newestModified(windowItems) };
        const start = new Date(recorded.getTime() - SWEEP_OVERLAP_MS);
        let from: Date | null = start;
        let to = now;
        const items: NormalizedItem[] = [];
        for (let request = 0; request < MAX_SWEEP_REQUESTS; request++) {
            const page = await plugin.Fetch({ ...query, Lookup: { Kind: 'Tagged', Tag: policy.Tag, ModifiedSince: from, ModifiedBefore: to } });
            if (page.Failed) return { Items: [], Issues: [], SweptThrough: null, Failure: `Late-tag sweep failed: ${page.Issues.join(' | ')}` };
            if (page.Capped) {
                const lower = from?.getTime() ?? 0;
                const half = Math.floor((to.getTime() - lower) / 2);
                if (half < 1_000) break;
                to = new Date(lower + half);
                continue;
            }
            items.push(...page.Items);
            from = to;
            if (to.getTime() >= now.getTime()) return { Items: items, Issues: [], SweptThrough: now };
            to = now;
        }
        const issues = [`The late-tag sweep did not reach the present in ${MAX_SWEEP_REQUESTS} reads; the next run continues from ${from?.toISOString() ?? 'the start'}.`];
        const advanced = from !== null && from.getTime() > recorded.getTime();
        return { Items: items, Issues: issues, SweptThrough: advanced ? from : null };
    }

    /**
     * Withdraw captures whose consent is gone. `present` is what the run already read: for the calendar
     * the whole window, so no second read is needed; for mail, every candidate is re-read by Message-ID.
     */
    public async Withdraw(
        plugin: BaseActivitySyncProvider,
        query: ActivitySourceQuery,
        present: readonly NormalizedItem[],
        policy: TaggedPolicy,
        connectionID: string,
        dryRun: boolean,
        store: ConsentStore,
    ): Promise<WithdrawResult> {
        const result: WithdrawResult = { Withdrawn: 0, Unknown: 0, Issues: [], Revoked: [] };
        const since = new Date(this.Now().getTime() - policy.WithdrawWindowDays * 86_400_000);
        const loaded = await store.ConsentedActivities({
            ConnectionID: connectionID,
            TypeCode: SURFACE_TYPE_CODE[plugin.Kind],
            ConsentedSince: since,
            MaxRows: MAX_WITHDRAW_CHECKS + 1,
        });
        if (loaded.Failed) {
            result.Issues.push(`Withdrawal skipped: ${loaded.Issue}`);
            return result;
        }
        if (loaded.Value.length > MAX_WITHDRAW_CHECKS) {
            result.Issues.push(`More than ${MAX_WITHDRAW_CHECKS} consented items in the window; only the newest were checked for a removed tag.`);
        }
        const candidates = loaded.Value.slice(0, MAX_WITHDRAW_CHECKS);
        if (candidates.length === 0) return result;

        const seen = await this.currentState(plugin, query, present, candidates, policy.Tag);
        if ('Issue' in seen) {
            result.Issues.push(seen.Issue);
            return result;
        }
        const chosen = ChooseWithdrawals(candidates, seen.Items, policy.Tag);
        result.Unknown = chosen.Unknown;
        const elsewhere = await store.ConsentedElsewhere(chosen.Rows.map((r) => r.ExternalID), connectionID);
        if (elsewhere.Failed) {
            result.Issues.push(`Withdrawal skipped: ${elsewhere.Issue}`);
            return result;
        }
        result.Revoked = chosen.Rows.flatMap((r) => {
            const item = seen.Items.get(r.ExternalID); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            return item ? [item] : [];
        });
        const kept = chosen.Rows.filter((r) => elsewhere.Value.has(r.ExternalID)); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        for (const row of chosen.Rows.filter((r) => !elsewhere.Value.has(r.ExternalID))) { // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            const issue = dryRun ? null : await store.Withdraw(row.ActivityID);
            if (issue) result.Issues.push(issue);
            else result.Withdrawn++;
        }
        if (result.Withdrawn > 0) {
            result.Issues.push(`${dryRun ? 'Would withdraw' : 'Withdrew'} ${result.Withdrawn} item(s) whose "${policy.Tag}" tag was removed.`);
        }
        if (kept.length > 0) result.Issues.push(`${kept.length} untagged item(s) were kept because another mailbox also consented to them.`);
        if (result.Unknown > 0) {
            result.Issues.push(`${result.Unknown} tagged item(s) could not be found in the mailbox and were kept, not withdrawn.`);
        }
        return result;
    }

    /** The candidates as they are now. A re-read that came back cut off proves nothing, so it is refused. */
    private async currentState(
        plugin: BaseActivitySyncProvider,
        query: ActivitySourceQuery,
        present: readonly NormalizedItem[],
        candidates: readonly ConsentRecord[],
        tag: string,
    ): Promise<{ Items: Map<string, NormalizedItem> } | { Issue: string }> {
        const seen = new Map<string, NormalizedItem>();
        const keep = (item: NormalizedItem): void => {
            const stable = StableItem(item, plugin.Kind);
            seen.set(stable.ExternalID, PreferTaggedCopy(seen.get(stable.ExternalID), stable, tag)); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        };
        present.forEach(keep);
        if (plugin.Kind !== 'Message') return { Items: seen };
        const ids = candidates.map((c) => c.ExternalID);
        for (let i = 0; i < ids.length; i += REREAD_BATCH) {
            const reread = await plugin.Fetch({ ...query, Lookup: { Kind: 'MessageIds', MessageIds: ids.slice(i, i + REREAD_BATCH) } });
            if (reread.Failed) return { Issue: `Could not re-read consented items, so none were withdrawn: ${reread.Issues.join(' | ')}` };
            if (reread.Capped) return { Issue: 'A re-read of consented items came back cut off, so none were withdrawn this run.' };
            reread.Items.forEach(keep);
        }
        return { Items: seen };
    }
}

/**
 * Which consented captures lose their consent.
 *
 * A TAGGED capture whose item was read and carries no tag. A PROVEN capture whose proving message
 * (`Via`, from its reason) is being withdrawn, unless the item is tagged now itself; this follows the
 * actual reply chain, not the whole conversation, and settles chains of replies in rounds. A tagged
 * capture that could not be read is counted Unknown and kept.
 */
export function ChooseWithdrawals(
    candidates: readonly ConsentRecord[],
    seen: ReadonlyMap<string, NormalizedItem>,
    tag: string,
): { Rows: ConsentRecord[]; Unknown: number } {
    const taggedNow = (r: ConsentRecord): boolean => {
        const item = seen.get(r.ExternalID); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        return item !== undefined && HasTag(item.Raw, tag);
    };
    let unknown = 0;
    const gone = new Set<string>();
    for (const r of candidates.filter((c) => c.Reason.startsWith(REASON_TAGGED))) {
        if (!seen.has(r.ExternalID)) unknown++; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        else if (!taggedNow(r)) gone.add(r.ExternalID);
    }
    const proven = candidates.filter((c) => c.Reason.startsWith(REASON_PROVEN));
    for (let round = 0; round < proven.length; round++) {
        const next = proven.filter((r) => !gone.has(r.ExternalID) && !taggedNow(r) && gone.has(ViaOf(r.Reason) ?? '')); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        if (next.length === 0) break;
        next.forEach((r) => gone.add(r.ExternalID));
    }
    return { Rows: candidates.filter((c) => gone.has(c.ExternalID)), Unknown: unknown }; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
}

/** The Message-ID a proven capture was proven by: the last `<...>` in its reason. */
export function ViaOf(reason: string): string | null {
    const ids = reason.match(/<[^<>\s]+>/g);
    return ids ? ids[ids.length - 1] : null;
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

function missingAncestors(items: readonly NormalizedItem[], tag: string): string[] {
    const have = new Set(items.map((i) => InternetMessageId(i.Raw)).filter(Boolean));
    const wanted = items.filter((i) => HasTag(i.Raw, tag)).flatMap((i) => ReplyReferences(i.Raw).slice(-MAX_ANCESTOR_REFERENCES));
    return [...new Set(wanted)].filter((id) => !have.has(id));
}

/**
 * What THIS connection consented to on earlier runs, among the messages the batch names in its reply
 * headers. Looked up by Message-ID, not by conversation: proof is by headers, and a reply whose subject
 * changed lands in a new conversation while still answering a consented message.
 */
async function loadPrior(
    items: readonly NormalizedItem[],
    connectionID: string,
    typeCode: string,
    store: ConsentStore,
): Promise<{ Failed: false; Value: Map<string, ConsentedMessage> } | { Failed: true; Issue: string }> {
    const prior = new Map<string, ConsentedMessage>();
    const named = [...new Set(items.flatMap((i) => ReplyReferences(i.Raw).slice(-MAX_ANCESTOR_REFERENCES)))];
    if (named.length === 0) return { Failed: false, Value: prior };
    const res = await store.ConsentedActivities({ ConnectionID: connectionID, TypeCode: typeCode, ExternalIDs: named });
    if (res.Failed) return { Failed: true, Issue: res.Issue };
    for (const r of res.Value) {
        prior.set(r.ExternalID, { MessageId: r.ExternalID, Participants: ParticipantsFromDetails(r.Details) }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
    }
    return { Failed: false, Value: prior };
}

/**
 * The addresses on a stored Graph payload (`Activity.Details`), as the mapper reads them: `from`, or
 * `sender` when `from` is absent, plus To and Cc. Never BCC.
 */
export function ParticipantsFromDetails(details: string | null): string[] {
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
    grab(raw['from'] ?? raw['sender']);
    for (const key of ['toRecipients', 'ccRecipients']) {
        const list = raw[key];
        if (Array.isArray(list)) list.forEach(grab);
    }
    return out;
}
