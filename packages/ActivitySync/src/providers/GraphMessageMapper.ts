/**
 * Raw Microsoft Graph message JSON → NormalizedItem.
 *
 * Maps Graph's own payload, not MJ's Message shape (GetMessages sets To from replyTo[0]).
 */
import type { ActivityDirection, ItemParticipant, NormalizedItem } from '../types.js';

export interface GraphEmailAddress {
    name?: string | null;
    address?: string | null;
}

export interface GraphRecipient {
    emailAddress?: GraphEmailAddress | null;
}

export interface GraphMessage {
    id?: string | null;
    conversationId?: string | null;
    subject?: string | null;
    bodyPreview?: string | null;
    body?: { content?: string | null } | null;
    sentDateTime?: string | null;
    receivedDateTime?: string | null;
    from?: GraphRecipient | null;
    sender?: GraphRecipient | null;
    toRecipients?: GraphRecipient[] | null;
    ccRecipients?: GraphRecipient[] | null;
    bccRecipients?: GraphRecipient[] | null;
    [key: string]: unknown;
}

export interface MapResult {
    Items: NormalizedItem[];
    Issues: string[];
}

function isUsableAddress(trimmed: string): boolean {
    if (!trimmed) return false;
    const at = trimmed.indexOf('@');
    return at > 0 && at < trimmed.length - 1 && !/\s/.test(trimmed);
}

function normalize(value: string): string {
    return value.trim().toLowerCase();
}

function participantFrom(
    recipient: GraphRecipient | null | undefined,
    role: ItemParticipant['Role'],
    issues: string[],
    context: string,
): ItemParticipant | null {
    const ea = recipient?.emailAddress ?? null;
    const raw = (ea?.address ?? '').trim();
    const name = (ea?.name ?? '').trim() || null;
    if (!isUsableAddress(raw)) {
        if (raw) {
            issues.push(`${context}: ${role} address is not usable and was dropped: ${JSON.stringify(raw)}`);
        }
        return null;
    }
    return { Address: normalize(raw), Name: name, Role: role, IdentityKind: 'Email' };
}

function decideDirection(mailbox: string, participants: ItemParticipant[]): ActivityDirection {
    const box = normalize(mailbox);
    const from = participants.find((p) => p.Role === 'From');
    const others = participants.filter((p) => p.Role !== 'From' && p.Address !== box);
    const sentByMailbox = !!from && from.Address === box;
    if (sentByMailbox && others.length === 0) return 'Internal';
    return sentByMailbox ? 'Outbound' : 'Inbound';
}

export function MapGraphMessage(
    message: GraphMessage,
    mailbox: string,
    issues: string[],
): NormalizedItem | null {
    const id = (message.id ?? '').trim();
    const context = `message ${id ? id.slice(0, 24) : '(no id)'}`;
    if (!id) {
        issues.push('a message arrived with no id and was skipped — it has no dedupe key');
        return null;
    }

    const participants: ItemParticipant[] = [];
    const push = (p: ItemParticipant | null): void => {
        if (p) participants.push(p);
    };
    push(participantFrom(message.from ?? message.sender, 'From', issues, context));
    for (const r of message.toRecipients ?? []) push(participantFrom(r, 'To', issues, context));
    for (const r of message.ccRecipients ?? []) push(participantFrom(r, 'Cc', issues, context));
    for (const r of message.bccRecipients ?? []) push(participantFrom(r, 'Bcc', issues, context));

    const stamp = (message.sentDateTime ?? message.receivedDateTime ?? '').trim();
    const startedAt = stamp ? new Date(stamp) : null;
    if (!startedAt || Number.isNaN(startedAt.getTime())) {
        issues.push(`${context}: no usable sentDateTime/receivedDateTime, skipped`);
        return null;
    }

    return {
        ExternalID: id,
        ExternalThreadID: (message.conversationId ?? '').trim() || null,
        TypeCode: 'Email',
        Subject: (message.subject ?? '').trim() || '(no subject)',
        Body: (message.bodyPreview ?? message.body?.content ?? '').trim() || null,
        StartedAt: startedAt,
        EndedAt: null,
        Location: null,
        Direction: decideDirection(mailbox, participants),
        Participants: participants,
        Cancelled: false,
        Raw: message as Record<string, unknown>,
    };
}

export function MapGraphMessages(payload: unknown, mailbox: string): MapResult {
    const issues: string[] = [];
    const raw = payload as { value?: unknown } | unknown[] | null;
    const list: unknown[] = Array.isArray(raw)
        ? raw
        : Array.isArray((raw as { value?: unknown })?.value)
          ? (raw as { value: unknown[] }).value
          : [];
    if (!list.length) {
        issues.push('payload contained no messages — expected an array or an object with a `value` array');
        return { Items: [], Issues: issues };
    }
    const items: NormalizedItem[] = [];
    for (const entry of list) {
        const mapped = MapGraphMessage(entry as GraphMessage, mailbox, issues);
        if (mapped) items.push(mapped);
    }
    return { Items: items, Issues: issues };
}
