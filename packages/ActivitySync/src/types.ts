/**
 * @fileoverview The provider-neutral shapes every activity source speaks.
 *
 * Nothing downstream of a provider knows what produced an item, which is what makes a fixture
 * provider a genuine substitute rather than a mock: the fixture and a live mailbox hand over the
 * same type, so a test exercises the real code path instead of a parallel one.
 *
 * @module @mj-biz-apps/common-activity-sync
 */

/** Mirrors `CK_Activity_Direction`. */
export type ActivityDirection = 'Inbound' | 'Outbound' | 'Internal';

/** Mirrors `CK_ActivityLink_Role`. */
export type ActivityLinkRole =
    | 'Regarding'
    | 'Participant'
    | 'From'
    | 'To'
    | 'Cc'
    | 'Bcc'
    | 'Organizer'
    | 'Attendee'
    | 'LoggedFor';

/** Mirrors `CK_ActivityLink_IdentityKind`. */
export type ActivityIdentityKind = 'Email' | 'Phone' | 'ExternalUser';

/**
 * Runtime value lists for the two unions above, for validating link specs that arrive as data
 * (JSON params on `Common.LogActivity`) rather than as typed code. The compiler checks every
 * member is a legal union value; keep them in lockstep with the CHECK constraints.
 */
export const ACTIVITY_LINK_ROLES: readonly ActivityLinkRole[] = [
    'Regarding',
    'Participant',
    'From',
    'To',
    'Cc',
    'Bcc',
    'Organizer',
    'Attendee',
    'LoggedFor',
];

export const ACTIVITY_IDENTITY_KINDS: readonly ActivityIdentityKind[] = ['Email', 'Phone', 'ExternalUser'];

/**
 * The surface a provider reads.
 *
 * This is not decoration — it selects the watermark basis. See {@link WatermarkBasisForKind}.
 */
export type ActivitySourceKind = 'Message' | 'Calendar' | 'Social' | 'Chat';

/**
 * How a surface's watermark advances.
 *
 * `ItemTime` — the newest item's own timestamp. Valid only where a timestamp is always in the past.
 * `ObservationTime` — when the source looked. Required wherever an item can be dated in the FUTURE.
 */
export type WatermarkBasis = 'ItemTime' | 'ObservationTime';

/** One party on an item, as the source reports them — an address, not yet a person. */
export interface ItemParticipant {
    /** Lower-cased by the provider. Matching is case-insensitive and normalization belongs at the edge. */
    Address: string;
    Name: string | null;
    Role: ActivityLinkRole;
    /** Which identity column an unresolved link would use. */
    IdentityKind: ActivityIdentityKind;
}

/** A provider-neutral item, ready for qualification. */
export interface NormalizedItem {
    /**
     * The provider's own stable id — half of the dedupe key, paired with `SourceSystem`.
     *
     * For Graph this is the message id, NOT the RFC-822 `Message-ID` header. The distinction
     * matters: the RFC header is stable across mailboxes and the Graph id is not, so keying on the
     * Graph id means a message ingested from two mailboxes yields two rows.
     */
    ExternalID: string;
    /** Groups replies. Becomes `Activity.ExternalThreadID`. */
    ExternalThreadID: string | null;
    /** `ActivityType.Code` — resolved by CODE so renaming a type never breaks ingestion. */
    TypeCode: string;
    /** Becomes `Activity.Title`. */
    Subject: string;
    /** Body or preview. Becomes `Activity.Description`. */
    Body: string | null;
    StartedAt: Date;
    /** Set for calendar items; null for messages. */
    EndedAt: Date | null;
    /** Set for calendar items. */
    Location: string | null;
    Direction: ActivityDirection;
    Participants: ItemParticipant[];
    /**
     * The item was called off and did not happen.
     *
     * First-class rather than something to dig out of `Raw`, because the write branches on it:
     * `CK_Activity_Status` allows `'Cancelled'`, so a cancelled meeting is recorded as cancelled
     * rather than as completed. Always false for messages — a sent mail cannot be un-sent.
     */
    Cancelled: boolean;
    /** The provider payload, verbatim. Stringified into `Activity.Details`. */
    Raw: Record<string, unknown>;
}

/** What the engine asks a provider for. */
export interface ActivitySourceQuery {
    /** The account/mailbox/handle to read, from `ActivitySyncConnection.Mailbox`. */
    Mailbox: string;
    /**
     * The watermark — `ActivitySyncConnection.LastSyncAt`. Null on a first run.
     *
     * ADVISORY TO THE PROVIDER, NOT A GUARANTEE. Several transports expose no date filter at all
     * (MJ's `GetMessagesParams` is `{ Identifier, NumMessages, UnreadOnly, IncludeHeaders }`), so a
     * provider may have to fetch the most recent `Limit` and let the engine discard what it has
     * already seen.
     */
    Since: Date | null;
    /** Hard cap on items returned. */
    Limit: number;
}

/** Whatever a provider's transport handed back, before normalization. */
export interface RawBatch {
    Payloads: Record<string, unknown>[];
    /** Reported, never thrown — a partial batch is still worth filing. */
    Issues: string[];
}

/** One provider pass. */
export interface ActivitySourceBatch {
    Items: NormalizedItem[];
    /**
     * Advanced from the ITEMS (or the observation), never from a bare clock read at the end of the
     * run: a wall-clock watermark skips anything that arrives while the run is in flight, whereas
     * an item-derived one cannot, because it never claims to have seen past the newest thing it
     * actually saw.
     */
    HighWatermark: Date | null;
    Issues: string[];
}

/**
 * The watermark basis a surface requires.
 *
 * A CALENDAR source must never advance on `max(StartedAt)`. A meeting's start is routinely in the
 * FUTURE, so one December event sets the watermark to December and every meeting created afterwards
 * for an earlier date is filtered out as already-seen — permanently, and with no error. The
 * calendar simply stops ingesting.
 */
export function WatermarkBasisForKind(kind: ActivitySourceKind): WatermarkBasis {
    return kind === 'Calendar' ? 'ObservationTime' : 'ItemTime';
}
