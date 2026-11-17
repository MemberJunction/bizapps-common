/**
 * @fileoverview Consent: who decides that a mail or meeting belongs in the CRM.
 *
 * ── TWO MODES, CHOSEN PER CONNECTION ──────────────────────────────────────────────────────────
 *
 * `KnownContact` (the default, and the behaviour before this module existed): an item is captured when
 * any participant matches a stored ContactMethod. A personal note to a customer who is also a friend
 * matches as well as a quote does, and nothing in a mailbox can tell the two apart.
 *
 * `Tagged`: an item is captured only when the MAILBOX OWNER put an Outlook category on it (the
 * Dynamics 365 "Tracked to Dynamics 365" model), or when it is a PROVEN reply to, or ancestor of, an
 * item that was. Consent is the owner's and stays in the owner's mailbox: a colleague tagging their
 * copy of a thread consents nothing on anyone else's behalf.
 *
 * ── PROOF, NOT A HINT ─────────────────────────────────────────────────────────────────────────
 *
 * Graph's `conversationId` is Exchange's grouping, partly by normalised subject, so an unrelated
 * "Re: Lunch" can share one. Continuation is therefore granted only by RFC 5322 reply headers
 * (`In-Reply-To`, `References`, read as the MAPI properties below) that name a message already
 * consented, and never to an outbound forward or an outbound reply that adds a recipient.
 *
 * Everything here is pure, so each rule can be pinned without a database or a mailbox.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { ActivitySourceKind, NormalizedItem } from './types.js';
import { ParseConnectionSettings } from './watermark.js';

export type ConsentMode = 'KnownContact' | 'Tagged';

export interface ConsentPolicy {
    Mode: ConsentMode;
    /** The Outlook category that means "log this". Null in KnownContact mode. */
    Tag: string | null;
    /** How far the late-tag sweep has read, by `lastModifiedDateTime`. Null before the first sweep. */
    SweptThrough: Date | null;
    /** Tagged items started within this many days are re-checked for a removed tag. */
    WithdrawWindowDays: number;
}

/** The key under `ActivitySyncConnection.Settings`. */
export const CONSENT_SETTING = 'Consent';
export const DEFAULT_CONSENT_TAG = 'AIDP';
export const DEFAULT_WITHDRAW_WINDOW_DAYS = 30;
/** Bounds the re-check of tagged items, so one run's cost has a ceiling. Reported when it binds. */
export const MAX_WITHDRAW_CHECKS = 500;

/** A withdrawn activity keeps its row (deal links, notes, holds) but gives up its dedupe key. */
export const WITHDRAWN_PREFIX = 'withdrawn:';
export const WITHDRAWN_TITLE = '(withdrawn by the mailbox owner)';

export type ConsentPolicyResult = { Policy: ConsentPolicy; Error?: undefined } | { Policy?: undefined; Error: string };

/**
 * Read the consent policy from a connection's Settings.
 *
 * FAILS CLOSED ON ANYTHING IT CANNOT READ. The fallback for an absent block is KnownContact, because
 * that is what every connection did before this existed. But a block that is present and wrong — an
 * unknown mode, a blank tag, Settings that are not JSON — is an error, never a quiet fallback: falling
 * back would turn a mistyped "Tagged" into the broadest capture there is.
 */
export function ConsentPolicyFromSettings(settings: string | null | undefined): ConsentPolicyResult {
    const text = (settings ?? '').trim();
    let bag: Record<string, unknown> = {};
    if (text) {
        let parsed: unknown;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            return { Error: `ActivitySyncConnection.Settings is not JSON (${(e as Error).message}), so its consent mode cannot be read.` };
        }
        if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
            return { Error: 'ActivitySyncConnection.Settings is not a JSON object, so its consent mode cannot be read.' };
        }
        bag = parsed as Record<string, unknown>;
    }
    const block = bag[CONSENT_SETTING];
    if (block === undefined) {
        return { Policy: { Mode: 'KnownContact', Tag: null, SweptThrough: null, WithdrawWindowDays: DEFAULT_WITHDRAW_WINDOW_DAYS } };
    }
    if (block === null || typeof block !== 'object' || Array.isArray(block)) {
        return { Error: `Settings.${CONSENT_SETTING} must be an object like {"Mode":"Tagged","Tag":"AIDP"}.` };
    }
    return policyFromBlock(block as Record<string, unknown>);
}

function policyFromBlock(block: Record<string, unknown>): ConsentPolicyResult {
    const mode = block['Mode'];
    if (mode !== 'KnownContact' && mode !== 'Tagged') {
        return { Error: `Settings.${CONSENT_SETTING}.Mode is ${JSON.stringify(mode)}; use "Tagged" or "KnownContact".` };
    }
    const rawTag = block['Tag'] === undefined ? DEFAULT_CONSENT_TAG : block['Tag'];
    const tag = typeof rawTag === 'string' ? rawTag.trim() : '';
    if (mode === 'Tagged' && !tag) {
        return { Error: `Settings.${CONSENT_SETTING}.Tag is blank; a Tagged connection needs the category name.` };
    }
    const window = block['WithdrawWindowDays'] ?? DEFAULT_WITHDRAW_WINDOW_DAYS;
    if (typeof window !== 'number' || !Number.isInteger(window) || window < 0) {
        return { Error: `Settings.${CONSENT_SETTING}.WithdrawWindowDays must be a whole number of days.` };
    }
    const swept = typeof block['SweptThrough'] === 'string' ? new Date(block['SweptThrough']) : null;
    return {
        Policy: {
            Mode: mode,
            Tag: mode === 'Tagged' ? tag : null,
            SweptThrough: swept && !Number.isNaN(swept.getTime()) ? swept : null,
            WithdrawWindowDays: window,
        },
    };
}

/** Record how far the late-tag sweep read, keeping every other Settings key. */
export function MergeConsentSweptThrough(settings: string | null | undefined, at: Date): string {
    const bag = ParseConnectionSettings(settings);
    const block = bag[CONSENT_SETTING];
    const consent = block !== null && typeof block === 'object' && !Array.isArray(block) ? { ...(block as object) } : {};
    bag[CONSENT_SETTING] = { ...consent, SweptThrough: at.toISOString() };
    return JSON.stringify(bag);
}

// ── Graph signals ─────────────────────────────────────────────────────────────────────────────

/** MAPI properties read through `$expand=singleValueExtendedProperties`. */
export const PROP_IN_REPLY_TO = 'String 0x1042';
export const PROP_REFERENCES = 'String 0x1039';
export const PROP_SENSITIVITY = 'Integer 0x0036';
export const PROP_MESSAGE_CLASS = 'String 0x001A';

/** The `$expand` a transport sends so the signals above arrive with each message. */
export const CONSENT_MESSAGE_EXPAND =
    'singleValueExtendedProperties($filter=' +
    [PROP_IN_REPLY_TO, PROP_REFERENCES, PROP_SENSITIVITY, PROP_MESSAGE_CLASS].map((id) => `id eq '${id}'`).join(' or ') +
    ')';

/**
 * Whether two MAPI property ids name the same property.
 *
 * GRAPH DOES NOT ECHO THE ID YOU ASKED FOR. Asked for `Integer 0x0036` and `String 0x001A`, it answers
 * `Integer 0x36` and `String 0x1a` (seen live on Exchange Online, 2026-11-17): leading zeros dropped, hex
 * lower-cased. A text comparison then never matches and the property reads as absent. So ids are compared
 * as type plus NUMBER.
 */
export function SameExtendedPropertyId(a: string, b: string): boolean {
    return propertyKey(a) === propertyKey(b);
}

function propertyKey(id: string): string {
    const m = /^\s*(\w+)\s+0x([0-9a-f]+)\s*$/i.exec(id);
    return m ? `${m[1].toLowerCase()} ${parseInt(m[2], 16)}` : id.trim().toLowerCase();
}

export function ExtendedProperty(raw: Record<string, unknown>, id: string): string | null {
    const props = raw['singleValueExtendedProperties'];
    if (!Array.isArray(props)) return null;
    for (const prop of props) {
        if (prop && typeof prop === 'object') {
            const p = prop as { id?: unknown; value?: unknown };
            if (typeof p.id === 'string' && SameExtendedPropertyId(p.id, id) && typeof p.value === 'string') return p.value;
        }
    }
    return null;
}

/** True when the item carries `tag` among its Outlook categories (case-insensitive, trimmed). */
export function HasTag(raw: Record<string, unknown>, tag: string): boolean {
    const categories = raw['categories'];
    if (!Array.isArray(categories)) return false;
    const wanted = tag.trim().toLowerCase();
    return categories.some((c) => typeof c === 'string' && c.trim().toLowerCase() === wanted);
}

/** The RFC 5322 Message-ID, angle brackets kept, which is how `References` names it. */
export function InternetMessageId(raw: Record<string, unknown>): string | null {
    const value = raw['internetMessageId'];
    return typeof value === 'string' && value.trim() ? value.trim() : null;
}

/** Every Message-ID this message says it answers: `In-Reply-To` plus the `References` chain. */
export function ReplyReferences(raw: Record<string, unknown>): string[] {
    const text = [ExtendedProperty(raw, PROP_IN_REPLY_TO), ExtendedProperty(raw, PROP_REFERENCES)].filter(Boolean).join(' ');
    return [...new Set(text.match(/<[^<>\s]+>/g) ?? [])];
}

/** "FW:", "Fwd:" and the common localised prefixes. A forward carries a thread somewhere new. */
export function IsForward(raw: Record<string, unknown>): boolean {
    const subject = typeof raw['subject'] === 'string' ? raw['subject'] : '';
    return /^\s*(fw|fwd|wg|tr|rv|vs)\s*:/i.test(subject);
}

/**
 * Why an item can never be captured, whoever consented. Null when nothing blocks it.
 *
 * Drafts were never sent. A meeting invitation arrives in the mailbox as a message and is captured
 * as the meeting, on the calendar surface. An out-of-office reply is a machine talking.
 */
export function BlockReason(raw: Record<string, unknown>, kind: ActivitySourceKind): string | null {
    if (kind !== 'Message') return null;
    if (raw['isDraft'] === true) return 'a draft that was never sent';
    const odataType = typeof raw['@odata.type'] === 'string' ? raw['@odata.type'].toLowerCase() : '';
    if (odataType.includes('eventmessage') || typeof raw['meetingMessageType'] === 'string') {
        return 'a meeting invitation; the meeting is captured from the calendar';
    }
    const messageClass = (ExtendedProperty(raw, PROP_MESSAGE_CLASS) ?? '').toLowerCase();
    if (messageClass.startsWith('ipm.note.rules.ooftemplate') || messageClass.startsWith('ipm.note.rules.replytemplate')) {
        return 'an automatic reply';
    }
    return null;
}

/** Outlook marked it Personal, Private or Confidential. Events carry it directly; mail as MAPI 0x0036. */
export function IsSensitive(raw: Record<string, unknown>, kind: ActivitySourceKind): boolean {
    if (kind === 'Calendar') {
        const s = typeof raw['sensitivity'] === 'string' ? raw['sensitivity'].toLowerCase() : 'normal';
        return s !== 'normal';
    }
    const value = ExtendedProperty(raw, PROP_SENSITIVITY);
    return value !== null && value.trim() !== '' && value.trim() !== '0';
}

/**
 * The id that names this item in EVERY mailbox. Graph's `id` differs per mailbox and changes when an
 * item moves folder; the Message-ID and the iCalendar UID do not. Keying on them is what lets two ADs
 * on one thread produce one Activity, and an archived message stay the same message.
 */
export function StableExternalId(item: NormalizedItem, kind: ActivitySourceKind): string {
    const stable = kind === 'Calendar' ? item.Raw['iCalUId'] : item.Raw['internetMessageId'];
    return typeof stable === 'string' && stable.trim() ? stable.trim() : item.ExternalID;
}

// ── The consent chain ─────────────────────────────────────────────────────────────────────────

/** A message already consented on this connection, with who was on it. */
export interface ConsentedMessage {
    MessageId: string;
    /** Lower-cased addresses, BCC excluded. */
    Participants: string[];
}

export type ConsentGrant =
    | { Kind: 'Tag' }
    | { Kind: 'Reply'; Via: string }
    | { Kind: 'Ancestor'; Via: string };

/**
 * Which items in a batch the owner consented to, and how.
 *
 * Items are keyed by `ExternalID`, which the caller has already made stable. `prior` holds what
 * earlier runs consented on this connection; the batch can extend it. Calendar consent is the tag
 * alone: a meeting has no reply chain to prove anything with.
 *
 * Replies settle in rounds — a reply to a reply is proven by the first reply — and each round grants
 * at least one item or ends the loop, so it finishes within `items.length` rounds.
 */
export function ResolveConsent(
    items: readonly NormalizedItem[],
    prior: ReadonlyMap<string, ConsentedMessage>,
    tag: string,
    kind: ActivitySourceKind,
): Map<string, ConsentGrant> {
    const grants = new Map<string, ConsentGrant>();
    for (const item of items) {
        if (HasTag(item.Raw, tag)) grants.set(item.ExternalID, { Kind: 'Tag' }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
    }
    if (kind !== 'Message') return grants;

    const consented = new Map(prior);
    const byMessageId = new Map(items.map((i) => [InternetMessageId(i.Raw) ?? '', i] as const));
    byMessageId.delete('');
    for (const item of items.filter((i) => grants.has(i.ExternalID))) consented.set(messageIdOf(item), consentedFrom(item)); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID

    grantAncestors(items, grants, consented, byMessageId);
    grantReplies(items, grants, consented);
    return grants;
}

function messageIdOf(item: NormalizedItem): string {
    return InternetMessageId(item.Raw) ?? item.ExternalID;
}

function consentedFrom(item: NormalizedItem): ConsentedMessage {
    return {
        MessageId: messageIdOf(item),
        Participants: item.Participants.filter((p) => p.Role !== 'Bcc').map((p) => p.Address),
    };
}

/** The earlier messages a tagged message names, when they are in this mailbox's batch. */
function grantAncestors(
    items: readonly NormalizedItem[],
    grants: Map<string, ConsentGrant>,
    consented: Map<string, ConsentedMessage>,
    byMessageId: ReadonlyMap<string, NormalizedItem>,
): void {
    for (const tagged of items.filter((i) => grants.get(i.ExternalID)?.Kind === 'Tag')) { // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        for (const ref of ReplyReferences(tagged.Raw)) {
            const ancestor = byMessageId.get(ref);
            if (!ancestor || grants.has(ancestor.ExternalID)) continue; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            grants.set(ancestor.ExternalID, { Kind: 'Ancestor', Via: messageIdOf(tagged) }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            consented.set(ref, consentedFrom(ancestor));
        }
    }
}

function grantReplies(
    items: readonly NormalizedItem[],
    grants: Map<string, ConsentGrant>,
    consented: Map<string, ConsentedMessage>,
): void {
    const pending = [...items].sort((a, b) => a.StartedAt.getTime() - b.StartedAt.getTime());
    for (let round = 0; round < items.length; round++) {
        let granted = false;
        for (const item of pending) {
            if (grants.has(item.ExternalID)) continue; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            const parent = ReplyReferences(item.Raw).map((ref) => consented.get(ref)).find(Boolean);
            if (!parent || !ContinuesThread(item, parent)) continue;
            grants.set(item.ExternalID, { Kind: 'Reply', Via: parent.MessageId }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            consented.set(messageIdOf(item), consentedFrom(item));
            granted = true;
        }
        if (!granted) return;
    }
}

/**
 * Whether a reply stays inside the conversation it answers.
 *
 * A forward never does. An OUTBOUND reply that adds a recipient takes the thread to someone new — a
 * colleague's personal address, a recruiter — so it needs its own tag. An inbound reply may come from
 * a new address (the customer writing from their phone's Gmail), because it is answering us.
 */
export function ContinuesThread(item: NormalizedItem, parent: ConsentedMessage): boolean {
    if (IsForward(item.Raw)) return false;
    if (item.Direction !== 'Outbound') return true;
    const known = new Set(parent.Participants);
    return item.Participants.filter((p) => p.Role === 'To' || p.Role === 'Cc').every((p) => known.has(p.Address));
}
