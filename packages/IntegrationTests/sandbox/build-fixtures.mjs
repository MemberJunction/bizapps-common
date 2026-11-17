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

// ── Consent (Tagged connections) ─────────────────────────────────────────────────────────────
//
// The same mailbox read by a connection whose Settings say {"Consent":{"Mode":"Tagged","Tag":"AIDP"}}.
// Expected decisions are under the baseline rule set (AllInternal exclude, hr@ exclusion) PLUS consent.

const TAG = 'AIDP';
const PHONE = { name: 'Nora (phone)', address: 'nora.phone@stranger.test' };
const RECRUITER = { name: 'A Recruiter', address: 'recruiter@stranger.test' };
const msgId = (id) => `<${id}@sandbox.test>`;
// The ids exactly as Graph RETURNS them (Exchange Online, 2026-11-17): asked for 0x0036 and 0x001A, it
// answers 0x36 and 0x1a. Fixtures carry the returned form, so a reader that compares ids as text fails here.
const PROP = { InReplyTo: 'String 0x1042', References: 'String 0x1039', Sensitivity: 'Integer 0x36', Class: 'String 0x1a' };

/**
 * A message as a Tagged connection sees it: categories, a Message-ID, reply headers and
 * sensitivity/class as the extended properties a transport expands. `thread` defaults to the case's
 * own conversation, so only cases that SHARE a conversation share one.
 */
function consentMessage({ id, from, to, cc = [], bcc = [], subject, at, tags = [], inReplyTo, references, thread, modified, sensitivity = '0', messageClass = 'IPM.Note', extra = {} }) {
    const m = message({ id, from, to, cc, subject, at });
    m.categories = tags;
    m.internetMessageId = msgId(id);
    m.conversationId = `conv-${thread ?? id}`;
    m.bccRecipients = bcc.map(box);
    m.lastModifiedDateTime = modified ?? at;
    const props = [{ id: PROP.Sensitivity, value: sensitivity }, { id: PROP.Class, value: messageClass }];
    if (inReplyTo) props.push({ id: PROP.InReplyTo, value: msgId(inReplyTo) });
    if (references) props.push({ id: PROP.References, value: references.map(msgId).join(' ') });
    m.singleValueExtendedProperties = props;
    return Object.assign(m, extra);
}

const consentMail = (late) => [
    { Expected: late ? 'Withdrawn' : 'Included', Why: 'the owner tagged it (tag removed in consent-late)', item: consentMessage({ id: 'sbx-c1-tagged-quote', from: REP, to: [NORA], subject: 'Renewal quote', at: '2026-11-02T09:00:00Z', tags: late ? [] : [TAG], thread: 'c1', modified: late ? '2026-11-10T09:00:00Z' : undefined }) },
    { Expected: late ? 'Withdrawn' : 'Included', Why: 'proven reply to a tagged message', item: consentMessage({ id: 'sbx-c2-reply', from: NORA, to: [REP], subject: 'Re: Renewal quote', at: '2026-11-02T10:00:00Z', inReplyTo: 'sbx-c1-tagged-quote', references: ['sbx-c1-tagged-quote'], thread: 'c1' }) },
    { Expected: 'Excluded', Why: 'untagged, though a known contact is on it (the dinner case)', item: consentMessage({ id: 'sbx-c3-friend', from: REP, to: [NORA], subject: 'Dinner Saturday?', at: '2026-11-02T11:00:00Z' }) },
    { Expected: late ? 'Withdrawn' : 'Included', Why: 'proven reply from the customer\'s personal address', item: consentMessage({ id: 'sbx-c4-phone-reply', from: PHONE, to: [REP], subject: 'Re: Renewal quote', at: '2026-11-02T12:00:00Z', inReplyTo: 'sbx-c1-tagged-quote', references: ['sbx-c1-tagged-quote'], thread: 'c1' }) },
    { Expected: 'Excluded', Why: 'a forward is never a continuation', item: consentMessage({ id: 'sbx-c5-forward', from: REP, to: [STRANGER], subject: 'FW: Renewal quote', at: '2026-11-02T13:00:00Z', references: ['sbx-c1-tagged-quote'], thread: 'c1' }) },
    { Expected: 'Excluded', Why: 'an outbound reply that adds a recipient needs its own tag', item: consentMessage({ id: 'sbx-c6-new-recipient', from: REP, to: [NORA, RECRUITER], subject: 'Re: Renewal quote', at: '2026-11-02T14:00:00Z', inReplyTo: 'sbx-c2-reply', references: ['sbx-c1-tagged-quote', 'sbx-c2-reply'], thread: 'c1' }) },
    { Expected: 'Excluded', Why: 'same conversationId, no reply headers: not proof', item: consentMessage({ id: 'sbx-c7-same-conversation', from: NORA, to: [REP], subject: 'Re: Lunch', at: '2026-11-02T15:00:00Z', thread: 'c1' }) },
    { Expected: 'Excluded', Why: 'a tagged draft was never sent', item: consentMessage({ id: 'sbx-c8-draft', from: REP, to: [NORA], subject: 'Draft terms', at: '2026-11-02T16:00:00Z', tags: [TAG], extra: { isDraft: true } }) },
    { Expected: 'Excluded', Why: 'tagged, but internal-only (AllInternal rule wins)', item: consentMessage({ id: 'sbx-c9-internal-tagged', from: REP, to: [COLLEAGUE], subject: 'Pricing for Nora', at: '2026-11-02T17:00:00Z', tags: [TAG] }) },
    { Expected: 'Excluded', Why: 'a reply in a tagged thread marked Private', item: consentMessage({ id: 'sbx-c10-private-reply', from: NORA, to: [REP], subject: 'Re: Renewal quote (personal)', at: '2026-11-03T08:00:00Z', inReplyTo: 'sbx-c1-tagged-quote', references: ['sbx-c1-tagged-quote'], thread: 'c1', sensitivity: '2' }) },
    { Expected: 'Excluded', Why: 'an automatic reply is a machine talking', item: consentMessage({ id: 'sbx-c11-out-of-office', from: NORA, to: [REP], subject: 'Automatic reply: Renewal quote', at: '2026-11-03T08:30:00Z', inReplyTo: 'sbx-c1-tagged-quote', thread: 'c1', messageClass: 'IPM.Note.Rules.OofTemplate.Microsoft' }) },
    { Expected: 'Excluded', Why: 'a meeting invitation is captured from the calendar, not as mail', item: consentMessage({ id: 'sbx-c12-invite', from: NORA, to: [REP], subject: 'Invitation: Renewal walkthrough', at: '2026-11-03T09:00:00Z', tags: [TAG], extra: { '@odata.type': '#microsoft.graph.eventMessageRequest', meetingMessageType: 'meetingRequest' } }) },
    { Expected: 'Included', Why: 'the earlier message a tagged reply names (ancestor)', item: consentMessage({ id: 'sbx-c13a-original', from: REP, to: [ADA], subject: 'Editorial plan', at: '2026-11-03T10:00:00Z', thread: 'c13' }) },
    { Expected: 'Included', Why: 'the owner tagged the customer\'s reply', item: consentMessage({ id: 'sbx-c13b-tagged-reply', from: ADA, to: [REP], subject: 'Re: Editorial plan', at: '2026-11-03T11:00:00Z', tags: [TAG], inReplyTo: 'sbx-c13a-original', references: ['sbx-c13a-original'], thread: 'c13' }) },
    { Expected: 'Included', Why: 'tagged; the blind copy is never recorded', item: consentMessage({ id: 'sbx-c14-bcc', from: REP, to: [NORA], bcc: [COLLEAGUE], subject: 'Signed order form', at: '2026-11-03T12:00:00Z', tags: [TAG] }) },
    { Expected: late ? 'Included' : 'Excluded', Why: 'tagged six days after it arrived: found by the late-tag sweep', item: consentMessage({ id: 'sbx-c15-tagged-late', from: REP, to: [ADA], subject: 'Editorial terms', at: '2026-11-03T13:00:00Z', tags: late ? [TAG] : [], modified: late ? '2026-11-09T13:00:00Z' : undefined }) },
];

export const CONSENT_MAIL_CASES = consentMail(false);
export const CONSENT_LATE_MAIL_CASES = consentMail(true);

function consentEvent(templateId, spec, { tags = [], sensitivity = 'normal' } = {}) {
    const e = event(templateId, spec);
    e.categories = tags;
    e.sensitivity = sensitivity;
    e.iCalUId = `ical-${spec.id}`;
    return e;
}

const consentCalendar = (late) => [
    { Expected: late ? 'Withdrawn' : 'Included', Why: 'a tagged meeting (tag removed in consent-late)', item: consentEvent('evt-ext-1', { id: 'sbx-ce1-tagged', organizer: REP, attendees: [NORA], subject: 'Renewal walkthrough', start: utc('2026-11-04T15:00:00'), end: utc('2026-11-04T16:00:00') }, { tags: late ? [] : [TAG] }) },
    { Expected: 'Excluded', Why: 'an untagged lunch with a known contact', item: consentEvent('evt-ext-1', { id: 'sbx-ce2-lunch', organizer: REP, attendees: [NORA], subject: 'Lunch', start: utc('2026-11-05T12:00:00'), end: utc('2026-11-05T13:00:00') }) },
    { Expected: 'Excluded', Why: 'a Private, untagged doctor appointment', item: consentEvent('evt-ext-1', { id: 'sbx-ce3-private', organizer: REP, attendees: [ADA], subject: 'Doctor', start: utc('2026-11-06T09:00:00'), end: utc('2026-11-06T10:00:00') }, { sensitivity: 'private' }) },
];

export const CONSENT_CALENDAR_CASES = consentCalendar(false);
export const CONSENT_LATE_CALENDAR_CASES = consentCalendar(true);

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
        $comment: [...note, '', name.startsWith('consent') ? 'EXPECTED ON A TAGGED CONNECTION (baseline rules + consent):' : 'EXPECTED UNDER THE BASELINE RULE SET:', ...table],
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
    scenario('consent', 'mail', CONSENT_MAIL_CASES, MAIL_NOTE);
    scenario('consent', 'calendar', CONSENT_CALENDAR_CASES, CALENDAR_NOTE);
    scenario('consent-late', 'mail', CONSENT_LATE_MAIL_CASES, MAIL_NOTE);
    scenario('consent-late', 'calendar', CONSENT_LATE_CALENDAR_CASES, CALENDAR_NOTE);
    console.log('wrote 10 sandbox fixture files to', HERE);
}
