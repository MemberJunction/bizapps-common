/**
 * Builds the Activity Sync sandbox fixtures from the ActivitySync demo payloads.
 *
 *   node packages/IntegrationTests/sandbox/build-fixtures.mjs
 *
 * WHY GENERATED, NOT HAND-WRITTEN. A hand-written fixture drifts toward whatever our mapper reads and
 * away from what Microsoft sends. Each item here is a deep copy of a demo payload with only its id,
 * addresses, subject and times replaced, so every field the demo carries is still present. The demo
 * MESSAGE shapes were compared field-by-field against 25 live Graph payloads on 2026-09-04; the demo
 * EVENT shapes were hand-built from Microsoft's schema and never compared with live data. The calendar
 * files say so in their $comment.
 *
 * Re-run after changing a case; the output is committed. `src/__tests__/sandbox-fixtures.test.ts`
 * checks the committed files against this script's case table.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const DEMO = join(HERE, '..', '..', 'ActivitySync', 'demo');
const demoMessages = JSON.parse(readFileSync(join(DEMO, 'graph-sample-messages.json'), 'utf8')).value;
const demoEvents = JSON.parse(readFileSync(join(DEMO, 'graph-sample-events.json'), 'utf8')).value;

export const MAILBOX = 'rep@sandbox-internal.test';
const REP = { name: 'Sam Rep', address: MAILBOX };
const COLLEAGUE = { name: 'Casey Colleague', address: 'colleague@sandbox-internal.test' };
const HR = { name: 'People Team', address: 'hr@sandbox-internal.test' };
const NORA = { name: 'Nora Calhoun', address: 'nora.calhoun@com-world.test' };
const ADA = { name: 'Ada Lovelace', address: 'ada.lovelace@com-world.test' };
const STRANGER = { name: 'Pat Stranger', address: 'pat@stranger.test' };
const SUBDOMAIN = { name: 'Mail Relay', address: 'relay@mail.sandbox-internal.test' };
/** Graph's placeholder for a hidden recipient list: an address with no domain. */
const MALFORMED = { name: 'undisclosed-recipients', address: 'undisclosed-recipients' };

const clone = (x) => JSON.parse(JSON.stringify(x));
const box = (who) => ({ emailAddress: { name: who.name, address: who.address } });

/** The demo message used as the shape template: an inbound message with every field populated. */
const MESSAGE_TEMPLATE = demoMessages.find((m) => m.replyTo && m.replyTo.length > 0) ?? demoMessages[0];

function message({ id, from, to, cc = [], subject, at }) {
    const m = clone(MESSAGE_TEMPLATE);
    m.id = id;
    m.subject = subject;
    m.bodyPreview = `${subject}.`;
    m.body = { contentType: 'text', content: `${subject}.` };
    m.createdDateTime = m.lastModifiedDateTime = m.receivedDateTime = m.sentDateTime = at;
    m.internetMessageId = `<${id}@sandbox.test>`;
    m.conversationId = `conv-${id}`;
    m.sender = m.from = box(from);
    m.toRecipients = to.map(box);
    m.ccRecipients = cc.map(box);
    m.bccRecipients = [];
    m.replyTo = [box(from)];
    return m;
}

function event(templateId, { id, organizer, attendees, subject, start, end }) {
    const template = demoEvents.find((e) => e.id === templateId);
    if (!template) throw new Error(`demo event ${templateId} not found`);
    const e = clone(template);
    e.id = id;
    e.subject = subject;
    e.bodyPreview = `${subject}.`;
    e.organizer = box(organizer);
    e.attendees = attendees.map((who) => ({
        type: 'required',
        status: { response: 'accepted', time: start.dateTime + 'Z' },
        ...box(who),
    }));
    e.start = start;
    e.end = end;
    if (e.seriesMasterId) e.seriesMasterId = `${id}-series`;
    return e;
}

const utc = (dateTime) => ({ dateTime: `${dateTime}.0000000`, timeZone: 'UTC' });

/**
 * The case table. `Expected` is the decision under the baseline rule set (internal domain
 * sandbox-internal.test, Exclude + AllInternal, an exclusion on hr@, no Include rules).
 */
export const MAIL_CASES = [
    { Expected: 'Included', Why: 'rep to a known customer', item: message({ id: 'sbx-m1-customer', from: REP, to: [NORA], subject: 'Quote for the library renewal', at: '2026-11-02T14:00:00Z' }) },
    { Expected: 'Excluded', Why: 'colleagues only (AllInternal rule)', item: message({ id: 'sbx-m2-internal', from: REP, to: [COLLEAGUE], subject: 'Can we discount the Riverside quote', at: '2026-11-02T15:00:00Z' }) },
    { Expected: 'Included', Why: 'customer plus a colleague (mixed)', item: message({ id: 'sbx-m3-mixed', from: REP, to: [ADA], cc: [COLLEAGUE], subject: 'Editorial plan follow-up', at: '2026-11-02T16:00:00Z' }) },
    { Expected: 'Excluded', Why: 'hr@ is excluded, customer on the thread does not matter', item: message({ id: 'sbx-m4-hr', from: REP, to: [HR, NORA], subject: 'Personal matter', at: '2026-11-02T17:00:00Z' }) },
    { Expected: 'Excluded', Why: 'unknown sender, nothing matched (fail closed)', item: message({ id: 'sbx-m5-stranger', from: STRANGER, to: [REP], subject: 'Partnership opportunity', at: '2026-11-03T09:00:00Z' }) },
    // NOT what participants.ts alone would suggest. GraphMessageMapper drops a domain-less address
    // (with an issue) BEFORE classification, so this thread reaches the rules as colleagues-only and
    // the AllInternal rule excludes it. Pinned as measured; see the sandbox report.
    { Expected: 'Excluded', Why: 'domain-less address is dropped by the mapper, leaving colleagues only (AllInternal rule)', item: message({ id: 'sbx-m6-malformed', from: REP, to: [COLLEAGUE, MALFORMED], subject: 'Team notes', at: '2026-11-03T10:00:00Z' }) },
    { Expected: 'Excluded', Why: 'a subdomain is not internal; no known person', item: message({ id: 'sbx-m7-subdomain', from: REP, to: [SUBDOMAIN], subject: 'Relay test', at: '2026-11-03T11:00:00Z' }) },
];

export const NEWER_MAIL_CASE = {
    Expected: 'Included',
    Why: 'newer than the baseline watermark',
    item: message({ id: 'sbx-m8-newer', from: NORA, to: [REP], subject: 'Re: Quote for the library renewal', at: '2026-11-05T09:00:00Z' }),
};

export const CALENDAR_CASES = [
    { Expected: 'Included', Why: 'external meeting', item: event('evt-ext-1', { id: 'sbx-e1-external', organizer: REP, attendees: [NORA], subject: 'Renewal walkthrough', start: utc('2026-11-04T15:00:00'), end: utc('2026-11-04T16:00:00') }) },
    { Expected: 'Included', Why: 'recurring occurrence keeps its own start', item: event('evt-occ-2', { id: 'sbx-e2-occurrence', organizer: REP, attendees: [ADA], subject: 'Weekly editorial sync', start: utc('2026-11-05T09:30:00'), end: utc('2026-11-05T10:00:00') }) },
    { Expected: 'Included', Why: 'cancelled meeting carries Cancelled', item: event('evt-cancel-3', { id: 'sbx-e3-cancelled', organizer: REP, attendees: [NORA], subject: 'Contract review (cancelled)', start: utc('2026-11-06T13:00:00'), end: utc('2026-11-06T13:30:00') }) },
    { Expected: 'Excluded', Why: 'colleagues only', item: event('evt-int-4', { id: 'sbx-e4-internal', organizer: REP, attendees: [COLLEAGUE], subject: 'Pipeline review', start: utc('2026-11-04T16:00:00'), end: utc('2026-11-04T16:30:00') }) },
    { Expected: 'Skipped', Why: 'naive local time with a named zone is never guessed', item: event('evt-tz-5', { id: 'sbx-e5-naive-tz', organizer: REP, attendees: [NORA], subject: 'West coast call', start: { dateTime: '2026-11-04T09:00:00.0000000', timeZone: 'Pacific Standard Time' }, end: { dateTime: '2026-11-04T09:30:00.0000000', timeZone: 'Pacific Standard Time' } }) },
];

const MAIL_NOTE = [
    'GENERATED by build-fixtures.mjs from packages/ActivitySync/demo/graph-sample-messages.json.',
    'Message shapes were compared field-by-field with 25 live Graph payloads on 2026-09-04 (see that file).',
    'Every address is on a reserved .test domain.',
];
const CALENDAR_NOTE = [
    'GENERATED by build-fixtures.mjs from packages/ActivitySync/demo/graph-sample-events.json.',
    'SHAPE NOT LIVE-CHECKED: the demo events were built from Microsoft\'s published schema and never compared',
    'with a live Graph response. These cases prove pipeline decisions, not Microsoft\'s shapes.',
];

function scenario(name, surface, cases, note) {
    const table = cases.map((c) => `${c.item.id}: ${c.Expected} (${c.Why})`);
    const doc = {
        $comment: [...note, '', 'EXPECTED UNDER THE BASELINE RULE SET:', ...table],
        mailbox: name === 'mismatch' ? 'someone-else@sandbox-internal.test' : MAILBOX,
        capturedAt: '2026-11-12T00:00:00Z',
        value: cases.map((c) => c.item),
    };
    writeFileSync(join(HERE, `${name}.${surface}.json`), JSON.stringify(doc, null, 2) + '\n');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
    scenario('baseline', 'mail', MAIL_CASES, MAIL_NOTE);
    scenario('baseline', 'calendar', CALENDAR_CASES, CALENDAR_NOTE);
    scenario('newer', 'mail', [...MAIL_CASES, NEWER_MAIL_CASE], MAIL_NOTE);
    scenario('newer', 'calendar', [], CALENDAR_NOTE);
    scenario('mismatch', 'mail', MAIL_CASES.slice(0, 1), MAIL_NOTE);
    scenario('mismatch', 'calendar', [], CALENDAR_NOTE);
    console.log('wrote 6 sandbox fixture files to', HERE);
}
