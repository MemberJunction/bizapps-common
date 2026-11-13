/**
 * The Activity Sync sandbox fixtures, checked without a database.
 *
 * WHAT THESE DEFEND. The fixtures are only worth anything if they still look like Microsoft Graph and
 * still say what the checks expect. So: every item keeps every field of the demo payload it was
 * copied from (no drift toward what our mapper reads), the committed files are what the generator
 * produces (no hand edits), and no address leaves the reserved .test domains.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { describe, expect, it } from 'vitest';

import {
    CALENDAR_CASES,
    MAIL_CASES,
    MAILBOX,
    NEWER_MAIL_CASE,
    type SandboxCase as FixtureCase,
    type SandboxGraphItem as GraphItem,
} from '../../sandbox/build-fixtures.mjs';
interface ScenarioFile {
    mailbox: string;
    capturedAt: string;
    value: GraphItem[];
}

const HERE = dirname(fileURLToPath(import.meta.url));
const SANDBOX = join(HERE, '..', '..', 'sandbox');
const DEMO = join(HERE, '..', '..', '..', 'ActivitySync', 'demo');
const ALLOWED_DOMAINS = ['sandbox-internal.test', 'mail.sandbox-internal.test', 'com-world.test', 'stranger.test'];

function load(name: string): ScenarioFile {
    return JSON.parse(readFileSync(join(SANDBOX, name), 'utf8')) as ScenarioFile;
}

function demoKeys(file: string): Set<string> {
    const doc = JSON.parse(readFileSync(join(DEMO, file), 'utf8')) as { value: GraphItem[] };
    return new Set(doc.value.flatMap((item) => Object.keys(item)));
}

function addressesIn(value: unknown, out: string[] = []): string[] {
    if (Array.isArray(value)) value.forEach((v) => addressesIn(v, out));
    else if (value && typeof value === 'object') {
        for (const [key, v] of Object.entries(value)) {
            if (key === 'address' && typeof v === 'string') out.push(v);
            else addressesIn(v, out);
        }
    }
    return out;
}

const FILES = ['baseline', 'newer', 'mismatch'].flatMap((s) => [`${s}.mail.json`, `${s}.calendar.json`]);

describe('sandbox fixture files', () => {
    it.each(FILES)('%s has the scenario envelope', (name) => {
        const file = load(name);
        expect(typeof file.mailbox).toBe('string');
        expect(file.capturedAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
        expect(Array.isArray(file.value)).toBe(true);
    });

    it('are exactly what build-fixtures.mjs generates', () => {
        const ids = (cases: FixtureCase[]) => cases.map((c) => c.item);
        expect(load('baseline.mail.json').value).toEqual(ids(MAIL_CASES));
        expect(load('baseline.calendar.json').value).toEqual(ids(CALENDAR_CASES));
        expect(load('newer.mail.json').value).toEqual(ids([...MAIL_CASES, NEWER_MAIL_CASE]));
        expect(load('mismatch.mail.json').mailbox).not.toBe(MAILBOX);
        expect(load('baseline.mail.json').mailbox).toBe(MAILBOX);
    });

    it('keep every field of the demo Graph payloads', () => {
        const messageKeys = demoKeys('graph-sample-messages.json');
        const eventKeys = demoKeys('graph-sample-events.json');
        for (const c of MAIL_CASES) {
            for (const key of messageKeys) expect(c.item, `${c.item.id} lost ${key}`).toHaveProperty([key]);
        }
        for (const c of CALENDAR_CASES) {
            // Event templates differ in which optional fields they carry, so compare with the core set.
            for (const key of ['id', 'subject', 'start', 'end', 'organizer', 'attendees', 'isCancelled', 'type']) {
                expect(eventKeys.has(key)).toBe(true);
                expect(c.item, `${c.item.id} lost ${key}`).toHaveProperty([key]);
            }
        }
    });

    it('have unique ids', () => {
        const all = [...MAIL_CASES, NEWER_MAIL_CASE, ...CALENDAR_CASES].map((c) => c.item.id);
        expect(new Set(all).size).toBe(all.length);
    });

    it('never name an address outside the reserved .test domains', () => {
        for (const name of FILES) {
            for (const address of addressesIn(load(name).value)) {
                if (address === 'undisclosed-recipients') continue; // the documented domain-less case
                const domain = address.slice(address.lastIndexOf('@') + 1);
                expect(ALLOWED_DOMAINS, `${name}: ${address}`).toContain(domain);
            }
        }
    });
});
