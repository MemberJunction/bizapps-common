/**
 * Attachments — the columns that asked for them and the code that ignored them.
 *
 * THE DEFECT. `ActivitySyncRule.IncludeAttachments` says of itself "1 = also pull attachments into
 * ActivityFile rows". `MaxAttachmentBytes` sits beside it. `ActivityFile`, its `Kind` value list
 * (Body / Attachment / Ics) and its view are migrated and in metadata. Nothing anywhere read a line
 * of it — a rule that asked for attachments got none, and said nothing. Fifth instance in this
 * package of schema and documentation written ahead of the wiring, every test green because nothing
 * exercised the unwired path.
 *
 * WHAT THESE PIN. Two directions of wrong, and the expensive one is not the obvious one:
 *   - fetching when nobody asked pulls every attachment in a mailbox on a decision nobody made;
 *   - dropping quietly loses a signed contract while reporting a successful sync.
 * Most of what follows is about the second.
 */
import { describe, expect, it } from 'vitest';

import {
    AttachmentPolicyFor,
    AttachmentSkipReport,
    SelectAttachments,
    type AttachmentCandidate,
} from '../attachments.js';

const file = (over: Partial<AttachmentCandidate> = {}): AttachmentCandidate => ({
    ID: 'att-1',
    Filename: 'contract.pdf',
    ContentType: 'application/pdf',
    Size: 1_000,
    ...over,
});

describe('deciding whether to go and look', () => {
    it('fetches when the rule asks and the item says it has some', () => {
        const p = AttachmentPolicyFor({ IncludeAttachments: true }, { HasAttachments: true });
        expect(p.Fetch).toBe(true);
    });

    /** The listing costs a call per message; there is nothing to list. */
    it('does not look when the source says there are none', () => {
        expect(AttachmentPolicyFor({ IncludeAttachments: true }, { HasAttachments: false }).Fetch).toBe(false);
    });

    it('does not look when the rule did not ask', () => {
        expect(AttachmentPolicyFor({ IncludeAttachments: false }, { HasAttachments: true }).Fetch).toBe(false);
    });

    /**
     * An item can be included by the KnownParticipant stage or a provider-type default rather than by
     * a rule, and neither expresses an attachment choice. Defaulting to "fetch" there would pull a
     * whole mailbox's attachments on a decision nobody made.
     */
    it('does not look when no rule decided the item', () => {
        expect(AttachmentPolicyFor(null, { HasAttachments: true }).Fetch).toBe(false);
        expect(AttachmentPolicyFor(undefined, { HasAttachments: true }).Fetch).toBe(false);
    });

    it('treats a missing flag on the item as "none", not "go and check"', () => {
        expect(AttachmentPolicyFor({ IncludeAttachments: true }, {}).Fetch).toBe(false);
    });
});

describe('reading the size cap', () => {
    it('takes a positive cap at face value', () => {
        expect(AttachmentPolicyFor({ IncludeAttachments: true, MaxAttachmentBytes: 5_000 }, { HasAttachments: true }).MaxBytes).toBe(5_000);
    });

    it('treats null as no cap', () => {
        expect(AttachmentPolicyFor({ IncludeAttachments: true, MaxAttachmentBytes: null }, { HasAttachments: true }).MaxBytes).toBeNull();
    });

    /**
     * Zero is far more likely an unset column than an instruction to discard everything — and reading
     * it the other way silently keeps nothing while the rule claims to be filing attachments.
     */
    it('treats zero and negative as no cap rather than "keep nothing"', () => {
        expect(AttachmentPolicyFor({ IncludeAttachments: true, MaxAttachmentBytes: 0 }, { HasAttachments: true }).MaxBytes).toBeNull();
        expect(AttachmentPolicyFor({ IncludeAttachments: true, MaxAttachmentBytes: -1 }, { HasAttachments: true }).MaxBytes).toBeNull();
    });
});

describe('choosing which files to keep', () => {
    const ON = { Fetch: true, MaxBytes: null };

    it('keeps ordinary attachments', () => {
        const s = SelectAttachments([file(), file({ ID: 'a2', Filename: 'deck.pptx' })], ON);
        expect(s.Keep.map((k) => k.Filename)).toEqual(['contract.pdf', 'deck.pptx']);
        expect(s.Skipped).toEqual([]);
    });

    it('keeps nothing at all when the policy says not to fetch', () => {
        const s = SelectAttachments([file()], { Fetch: false, MaxBytes: null });
        expect(s.Keep).toEqual([]);
        expect(s.Skipped).toEqual([]);
    });

    /** Signature logos and tracking pixels, one copy per email, would fill file storage. */
    it('drops inline images but records that it did', () => {
        const s = SelectAttachments([file({ IsInline: true, Filename: 'logo.png' }), file()], ON);
        expect(s.Keep.map((k) => k.Filename)).toEqual(['contract.pdf']);
        expect(s.Skipped).toEqual([{ Filename: 'logo.png', Size: 1_000, Reason: 'inline' }]);
    });

    it('drops oversize files and records the size that failed', () => {
        const s = SelectAttachments([file({ Size: 9_000, Filename: 'huge.pdf' }), file({ Size: 100 })], {
            Fetch: true,
            MaxBytes: 1_000,
        });
        expect(s.Keep).toHaveLength(1);
        expect(s.Skipped).toEqual([{ Filename: 'huge.pdf', Size: 9_000, Reason: 'too-large' }]);
    });

    it('keeps a file exactly at the cap', () => {
        const s = SelectAttachments([file({ Size: 1_000 })], { Fetch: true, MaxBytes: 1_000 });
        expect(s.Keep).toHaveLength(1);
    });

    /**
     * A cap that cannot be evaluated must not default to "allow" — that is the one gap through which
     * exactly the oversize file the cap exists to stop would pass.
     */
    it('skips an unmeasurable file while a cap is in force', () => {
        const s = SelectAttachments([file({ Size: undefined as unknown as number })], { Fetch: true, MaxBytes: 1_000 });
        expect(s.Keep).toEqual([]);
        expect(s.Skipped[0].Reason).toBe('no-size');
    });

    it('keeps an unmeasurable file when there is no cap to enforce', () => {
        const s = SelectAttachments([file({ Size: undefined as unknown as number })], ON);
        expect(s.Keep).toHaveLength(1);
    });
});

describe('saying what was dropped', () => {
    /**
     * The load-bearing one. Filing an activity and quietly omitting the contract, while reporting a
     * successful sync, is the failure this package keeps being written against.
     */
    it('names the oversize files, because those are the ones somebody wanted', () => {
        const s = SelectAttachments([file({ Size: 9_000, Filename: 'signed-contract.pdf' })], {
            Fetch: true,
            MaxBytes: 1_000,
        });
        const report = AttachmentSkipReport('msg-1', s);
        expect(report).toMatch(/signed-contract\.pdf/);
        expect(report).toMatch(/over the size cap/);
        expect(report).toMatch(/msg-1/);
    });

    it('says nothing when nothing was dropped', () => {
        expect(AttachmentSkipReport('msg-1', { Keep: [file()], Skipped: [] })).toBeNull();
    });

    /** Forty inline logos must not bury the one line saying a contract was too large. */
    it('summarises inline images by count rather than listing them', () => {
        const many = Array.from({ length: 40 }, (_, i) => file({ ID: `i${i}`, Filename: `logo${i}.png`, IsInline: true }));
        const s = SelectAttachments([...many, file({ Size: 9_000, Filename: 'contract.pdf' })], {
            Fetch: true,
            MaxBytes: 1_000,
        });
        const report = AttachmentSkipReport('msg-1', s)!;
        expect(report).toMatch(/40 inline/);
        expect(report).not.toMatch(/logo7\.png/);
        expect(report).toMatch(/contract\.pdf/);
    });

    it('reports unmeasurable files distinctly from oversize ones', () => {
        const s = SelectAttachments([file({ Size: undefined as unknown as number, Filename: 'mystery.bin' })], {
            Fetch: true,
            MaxBytes: 1_000,
        });
        expect(AttachmentSkipReport('msg-1', s)).toMatch(/unknown size/);
    });
});
