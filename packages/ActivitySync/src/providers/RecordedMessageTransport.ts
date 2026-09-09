/**
 * A transport that replays Graph payloads captured earlier, instead of reaching the network.
 *
 * WHAT THIS IS NOT. It is not a fixture and it is not a mock of the engine. `FixtureActivitySyncProvider`
 * is a DIFFERENT provider — it substitutes for the whole Graph path, so a run against it proves the
 * engine works and proves nothing whatever about the Graph mapping, the credential resolution or the
 * provider. That is exactly how the credential gap survived unnoticed: everything green, nothing
 * exercised.
 *
 * This replaces only the outermost call, the one that reaches the network. Everything downstream —
 * `MapGraphMessages`, direction inference, participant resolution, identity matching, de-duplication,
 * the watermark, the writes — is the same code running on the same shapes as a live run. What a
 * replayed run does NOT prove is precisely one thing: that the network call and its auth succeed.
 *
 * WHY IT IS DELIBERATELY NOT LIVE. `IsLive` is false, so the engine's existing guard refuses to
 * write `Source: 'Integration'` rows from it without being told to. A replayed run cannot be
 * mistaken for a real one in the database afterwards, which is the property that makes it safe to
 * demo with.
 *
 * THE PAYLOADS MUST BE REAL GRAPH JSON. Hand-written approximations would re-introduce the failure
 * this file exists to avoid — a shape that agrees with our mapper rather than with Microsoft. Capture
 * them from an actual `GET /users/{id}/messages` response.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { ActivitySourceQuery, RawBatch } from '../types.js';
import type { ActivityMessageTransport } from './MessageTransport.js';

/** A captured Graph response, keyed by the mailbox it was captured from. */
export interface RecordedMailbox {
    /** Lower-cased on construction; mailbox matching is case-insensitive everywhere else too. */
    Mailbox: string;
    /** Verbatim entries from a Graph `value` array. */
    Payloads: Record<string, unknown>[];
    /** Where and when this was captured. Reported as an issue so a run is always attributable. */
    Provenance: string;
}

export class RecordedMessageTransport implements ActivityMessageTransport {
    public readonly Describe: string;

    /**
     * FALSE, and not configurable. A recorded run that could claim to be live would defeat the
     * engine's guard against writing Integration-sourced rows from a non-live provider.
     */
    public readonly IsLive = false;

    private readonly ByMailbox: Map<string, RecordedMailbox>;

    public constructor(recordings: RecordedMailbox[]) {
        this.ByMailbox = new Map(recordings.map((r) => [r.Mailbox.trim().toLowerCase(), r]));
        this.Describe = `recorded Graph payloads (${recordings.length} mailbox(es))`;
    }

    public async Fetch(query: ActivitySourceQuery): Promise<RawBatch> {
        const key = (query.Mailbox ?? '').trim().toLowerCase();
        const recording = this.ByMailbox.get(key);

        if (!recording) {
            // THROW rather than return empty. An empty batch means "looked, found nothing", which
            // would report a successful sync of a mailbox that was never recorded — the silent
            // success this codebase keeps having to design against.
            throw new Error(
                `No recorded payloads for mailbox "${query.Mailbox}". ` +
                    `Recorded mailboxes: ${[...this.ByMailbox.keys()].join(', ') || '(none)'}.`,
            );
        }

        // The window is applied downstream in Normalize, exactly as it is for the live transport, so
        // the two paths differ in nothing but where the bytes came from.
        const payloads = recording.Payloads.slice(0, query.Limit);

        const issues = [
            `REPLAYED, NOT LIVE: ${recording.Provenance}. Nothing was read from Microsoft 365 on this run.`,
        ];
        const capped = recording.Payloads.length > query.Limit;
        if (capped) {
            issues.push(
                `Recording holds ${recording.Payloads.length} message(s); Limit is ${query.Limit}, so ` +
                    `${recording.Payloads.length - query.Limit} were not returned.`,
            );
        }

        /**
         * A CAPPED REPLAY WITHHOLDS THE WATERMARK TOO, and not only for symmetry.
         *
         * The live transport already does this: Graph returns newest-first, so a truncated live batch
         * strands everything between the old watermark and its oldest item. A replay truncates the
         * other way — `slice(0, Limit)` takes the FIRST N of the recording — so if a recording happens
         * to be ordered oldest-first, the batch IS contiguous with the watermark and advancing would
         * be safe.
         *
         * That safety is an accident of file order, and nothing enforces it. A recording captured
         * newest-first, or re-sorted by an editor, silently becomes the live bug with no code change
         * anywhere. Withholding costs a re-read that de-duplication absorbs, so the flag is set
         * whenever the limit binds and a watermark is in play, exactly as on the live path.
         */
        return { Payloads: payloads, Issues: issues, Capped: capped && !!query.Since };
    }
}
