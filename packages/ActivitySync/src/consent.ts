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
 * ── STANDING CONSENT, ON A TAGGED CONNECTION ──────────────────────────────────────────────────
 *
 * A Tagged connection may also name sources (`Settings.Consent.Sources`, see
 * `BaseActivityConsentSource.ts`) that list domains the owner has already agreed to have logged, e.g.
 * the accounts they own. An item with a participant on such a domain is captured with no tag. It is an
 * inference, like a reply, so it yields to a Personal/Private/Confidential mark, and on mail it is
 * refused when that mark could not be read at all. `Settings.Consent.SkipTag` is the owner's "never log
 * this": it blocks an item whatever else would capture it.
 *
 * Everything here is pure, so each rule can be pinned without a database or a mailbox.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { DomainOf } from './participants.js';
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
    /** The Outlook category that means "never log this", whatever else would capture it. Null: none. */
    SkipTag: string | null;
    /** `BaseActivityConsentSource` keys that grant standing consent. Empty: the tag is the only consent. */
    Sources: string[];
}

import { DEFAULT_ACTIVITY_SYNC_LIMITS, ResolveActivitySyncLimits } from './limits.config.js';

/** The key under `ActivitySyncConnection.Settings`. */
export const CONSENT_SETTING = 'Consent';
export const DEFAULT_CONSENT_TAG = 'AIDP';
export const DEFAULT_WITHDRAW_WINDOW_DAYS = DEFAULT_ACTIVITY_SYNC_LIMITS.Tuning.WithdrawWindowDays;
/** Bounds the re-check of tagged items, so one run's cost has a ceiling. Reported when it binds. */
export const MAX_WITHDRAW_CHECKS = DEFAULT_ACTIVITY_SYNC_LIMITS.ResourceGuards.MaxWithdrawChecks;

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
        const defaultWindowDays = ResolveActivitySyncLimits().Tuning.WithdrawWindowDays;
        return { Policy: { Mode: 'KnownContact', Tag: null, SweptThrough: null, WithdrawWindowDays: defaultWindowDays, SkipTag: null, Sources: [] } };
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
    const defaultWindowDays = ResolveActivitySyncLimits().Tuning.WithdrawWindowDays;
    const window = block['WithdrawWindowDays'] ?? defaultWindowDays;
    if (typeof window !== 'number' || !Number.isInteger(window) || window < 0) {
        return { Error: `Settings.${CONSENT_SETTING}.WithdrawWindowDays must be a whole number of days.` };
    }
    const extras = standingFromBlock(block, mode, tag);
    if (extras.Error !== undefined) return { Error: extras.Error };
    const swept = typeof block['SweptThrough'] === 'string' ? new Date(block['SweptThrough']) : null;
    return {
        Policy: {
            Mode: mode,
            Tag: mode === 'Tagged' ? tag : null,
            SweptThrough: swept && !Number.isNaN(swept.getTime()) ? swept : null,
            WithdrawWindowDays: window,
            SkipTag: extras.SkipTag,
            Sources: extras.Sources,
        },
    };
}

/**
 * `SkipTag` and `Sources`. Both belong to Tagged mode only, and a block that sets either on a
 * KnownContact connection is refused: it reads as "automatic capture, with an opt-out" while the
 * connection would go on capturing every known contact and honouring no skip tag.
 */
function standingFromBlock(
    block: Record<string, unknown>,
    mode: ConsentMode,
    tag: string,
): { SkipTag: string | null; Sources: string[]; Error?: undefined } | { Error: string } {
    const rawSkip = block['SkipTag'];
    const rawSources = block['Sources'];
    if (mode !== 'Tagged') {
        return rawSkip === undefined && rawSources === undefined
            ? { SkipTag: null, Sources: [] }
            : { Error: `Settings.${CONSENT_SETTING}.SkipTag and .Sources need "Mode":"Tagged".` };
    }
    const skip = typeof rawSkip === 'string' ? rawSkip.trim() : '';
    if (rawSkip !== undefined && !skip) {
        return { Error: `Settings.${CONSENT_SETTING}.SkipTag must be a category name, e.g. "No AIDP".` };
    }
    if (skip && skip.toLowerCase() === tag.toLowerCase()) {
        return { Error: `Settings.${CONSENT_SETTING}.SkipTag is the same category as Tag ("${tag}"); one category cannot mean both.` };
    }
    if (rawSources !== undefined && !Array.isArray(rawSources)) {
        return { Error: `Settings.${CONSENT_SETTING}.Sources must be a list of source keys, e.g. ["Sales.OwnedAccounts"].` };
    }
    const sources: string[] = [];
    for (const entry of rawSources ?? []) {
        const key = typeof entry === 'string' ? entry.trim() : '';
        if (!key) return { Error: `Settings.${CONSENT_SETTING}.Sources holds ${JSON.stringify(entry)}; every entry must be a source key.` };
        if (!sources.includes(key)) sources.push(key);
    }
    return { SkipTag: skip || null, Sources: sources };
}

/** Record how far the late-tag sweep read, keeping every other Settings key. */
export function MergeConsentSweptThrough(settings: string | null | undefined, at: Date): string {
    const bag = ParseConnectionSettings(settings);
    const block = bag[CONSENT_SETTING];
    const consent: Record<string, unknown> = block !== null && typeof block === 'object' && !Array.isArray(block) ? { ...(block as Record<string, unknown>) } : {};
    // NEVER BACKWARDS. Two overlapping runs can finish out of order; the later save must not undo the
    // further position the other one recorded.
    const stored = typeof consent['SweptThrough'] === 'string' ? Date.parse(consent['SweptThrough']) : NaN;
    if (!Number.isNaN(stored) && stored >= at.getTime()) return JSON.stringify(bag);
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

/**
 * One message, two copies: the Inbox and Sent Items copies of an email share a Message-ID but carry their
 * Outlook categories SEPARATELY (seen live: one copy tagged, the other not). Whichever copy is read first
 * must not decide; the item counts as tagged when ANY copy carries the tag.
 */
export function PreferTaggedCopy(current: NormalizedItem | undefined, incoming: NormalizedItem, tag: string, skipTag?: string | null): NormalizedItem {
    if (!current) return incoming;
    // The skip tag is "never log this" and wins over the tag, so the copy carrying it is the one kept.
    if (skipTag && HasTag(current.Raw, skipTag)) return current;
    if (skipTag && HasTag(incoming.Raw, skipTag)) return incoming;
    return !HasTag(current.Raw, tag) && HasTag(incoming.Raw, tag) ? incoming : current;
}

/** How many Message-IDs of a tagged message's `References` are followed back. A real chain is short. */
export const MAX_ANCESTOR_REFERENCES = DEFAULT_ACTIVITY_SYNC_LIMITS.ResourceGuards.MaxAncestorReferences;

/** The RFC 5322 Message-ID, angle brackets kept, which is how `References` names it. */
export function InternetMessageId(raw: Record<string, unknown>): string | null {
    const value = raw['internetMessageId'];
    return typeof value === 'string' && value.trim() ? value.trim() : null;
}

/** Every Message-ID this message says it answers: `In-Reply-To` plus the `References` chain. */
export function ReplyReferences(raw: Record<string, unknown>): string[] {
    // OLDEST FIRST, the direct parent LAST: `References` is ordered oldest to newest (RFC 5322), and
    // `In-Reply-To` goes after it. Callers that keep only the newest N (`slice(-N)`) then always keep
    // the message this one answers.
    const text = [ExtendedProperty(raw, PROP_REFERENCES), ExtendedProperty(raw, PROP_IN_REPLY_TO)].filter(Boolean).join(' ');
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

/**
 * Re-key to the stable id and drop the blind copy everywhere it lives: from the participants (links)
 * AND from the raw payload, which the writer stores verbatim as `Activity.Details`.
 */
export function StableItem(item: NormalizedItem, kind: ActivitySourceKind): NormalizedItem {
    const { bccRecipients: _dropped, ...raw } = item.Raw;
    return {
        ...item,
        ExternalID: StableExternalId(item, kind),
        Participants: item.Participants.filter((p) => p.Role !== 'Bcc'),
        Raw: raw,
    };
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
    | { Kind: 'Standing'; Domain: string; Label: string }
    | { Kind: 'Reply'; Via: string }
    | { Kind: 'Ancestor'; Via: string };

/** Domains with standing consent, each with the label that explains it (`StandingGrantDomains`). */
export type StandingDomains = ReadonlyMap<string, string>;

/** The first participant domain that has standing consent, or null. BCC never counts. */
export function StandingMatch(item: NormalizedItem, standing: StandingDomains): { Domain: string; Label: string } | null {
    for (const participant of item.Participants) {
        if (participant.Role === 'Bcc') continue;
        const domain = DomainOf(participant.Address);
        const label = domain === null ? undefined : standing.get(domain);
        if (domain !== null && label !== undefined) return { Domain: domain, Label: label };
    }
    return null;
}

/**
 * Why a standing grant does NOT capture this item, or null when it does.
 *
 * Standing consent is an inference from a domain, so the owner's Personal/Private/Confidential mark
 * overrides it. FAIL CLOSED WHEN THE MARK CANNOT BE READ: mail carries it only as an extended property,
 * and an MJ Graph provider that does not forward `$expand` (6.2.1) returns none. "No properties" is then
 * not "not Private", and treating it so would file Private mail from every owned account. Message class
 * 0x001A is on every message, so a message read WITH the expand always has the list.
 *
 * The same holds for an event with no `sensitivity`. Graph sends it on every event, so its absence
 * means the payload was trimmed somewhere, and `IsSensitive` reads an absent value as "normal".
 */
export function StandingRefusal(raw: Record<string, unknown>, kind: ActivitySourceKind): string | null {
    if (kind === 'Message' && !Array.isArray(raw['singleValueExtendedProperties'])) {
        return 'its Private mark could not be read (the mail provider returned no extended properties)';
    }
    if (kind === 'Calendar' && typeof raw['sensitivity'] !== 'string') {
        return 'its Private mark could not be read (the calendar provider returned no sensitivity)';
    }
    return IsSensitive(raw, kind) ? 'it is marked Personal/Private/Confidential' : null;
}

/**
 * Which items in a batch the owner consented to, and how.
 *
 * Items are keyed by `ExternalID`, which the caller has already made stable. `prior` holds what
 * earlier runs consented on this connection; the batch can extend it. Calendar consent is the tag or a
 * standing domain: a meeting has no reply chain to prove anything with. `standing` is the cleaned list
 * (`StandingGrantDomains`), so every domain in it is external by construction.
 *
 * Replies settle in rounds — a reply to a reply is proven by the first reply — and each round grants
 * at least one item or ends the loop, so it finishes within `items.length` rounds.
 */
export function ResolveConsent(
    items: readonly NormalizedItem[],
    prior: ReadonlyMap<string, ConsentedMessage>,
    tag: string,
    kind: ActivitySourceKind,
    eligible?: ReadonlySet<string>,
    standing?: StandingDomains,
): Map<string, ConsentGrant> {
    // ONLY ITEMS THE CASCADE WILL NOT BLOCK OR EXCLUDE TAKE PART. A tagged draft, a tagged thread with
    // a never-log address on it, an internal-only tagged message: none of them is captured, so none of
    // them may prove a reply or name an ancestor. `eligible` comes from `ConsentEligible`.
    items = eligible ? items.filter((i) => eligible.has(i.ExternalID)) : items; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
    const grants = new Map<string, ConsentGrant>();
    for (const item of items) {
        // The tag first: it is the owner's explicit choice, and it is what overrides a Private mark.
        const match = HasTag(item.Raw, tag) || !standing ? null : StandingMatch(item, standing);
        if (HasTag(item.Raw, tag)) grants.set(item.ExternalID, { Kind: 'Tag' }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        else if (match) grants.set(item.ExternalID, { Kind: 'Standing', ...match }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
    }
    if (kind !== 'Message') return grants;

    const consented = new Map(prior);
    const byMessageId = new Map(items.map((i) => [InternetMessageId(i.Raw) ?? '', i] as const));
    byMessageId.delete('');
    // A standing grant the Consent stage will refuse (Private, or unreadable) captures nothing, so it proves nothing.
    const captured = (i: NormalizedItem): boolean => {
        const grant = grants.get(i.ExternalID); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        return grant?.Kind === 'Tag' || (grant?.Kind === 'Standing' && StandingRefusal(i.Raw, kind) === null);
    };
    for (const item of items.filter(captured)) consented.set(messageIdOf(item), consentedFrom(item));

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

/**
 * The earlier messages a tagged message names, when they are in this mailbox's batch.
 *
 * `References` is written by whoever sent the tagged message, so it is not trusted on its own: an
 * outsider's email that the owner tags could name the Message-ID of a private message in the mailbox.
 * An ancestor is granted only when it is in the SAME conversation as the tagged message and shares at
 * least one participant with it, and only the last `MAX_ANCESTOR_REFERENCES` references are followed.
 */
function grantAncestors(
    items: readonly NormalizedItem[],
    grants: Map<string, ConsentGrant>,
    consented: Map<string, ConsentedMessage>,
    byMessageId: ReadonlyMap<string, NormalizedItem>,
): void {
    const maxRefs = ResolveActivitySyncLimits().ResourceGuards.MaxAncestorReferences;
    for (const tagged of items.filter((i) => grants.get(i.ExternalID)?.Kind === 'Tag')) { // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
        const people = new Set(consentedFrom(tagged).Participants);
        for (const ref of ReplyReferences(tagged.Raw).slice(-maxRefs)) {
            const ancestor = byMessageId.get(ref);
            if (!ancestor || grants.has(ancestor.ExternalID)) continue; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            if (!ancestor.ExternalThreadID || ancestor.ExternalThreadID !== tagged.ExternalThreadID) continue;
            if (!consentedFrom(ancestor).Participants.some((p) => people.has(p))) continue; // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            grants.set(ancestor.ExternalID, { Kind: 'Ancestor', Via: messageIdOf(tagged) }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            if (!IsSensitive(ancestor.Raw, 'Message')) consented.set(ref, consentedFrom(ancestor));
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
            // Any consented message it answers will do, not just the first one named: a reply that adds
            // a recipient may still continue a later message that already had them.
            const parent = ReplyReferences(item.Raw)
                .map((ref) => consented.get(ref))
                .find((p): p is ConsentedMessage => p !== undefined && ContinuesThread(item, p));
            if (!parent) continue;
            grants.set(item.ExternalID, { Kind: 'Reply', Via: parent.MessageId }); // uuid-compare-ok: an RFC Message-ID / iCalUId / conversation id, not a UUID
            // A Private reply is excluded by the Consent stage, so it must not prove the next one either.
            if (!IsSensitive(item.Raw, 'Message')) consented.set(messageIdOf(item), consentedFrom(item));
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
