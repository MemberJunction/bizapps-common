import { describe, expect, it } from 'vitest';

import { LOG_ACTIVITY_DEFAULT_SOURCE_SYSTEM, ParseLogActivityParams } from '../manual-log.js';

const PEOPLE = 'MJ_BizApps_Common: People';
const PERSON_ID = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

describe('ParseLogActivityParams', () => {
    it('requires TypeCode and Title', () => {
        const parsed = ParseLogActivityParams({});
        expect(parsed.Input).toBeNull();
        expect(parsed.Errors).toContain('TypeCode is required.');
        expect(parsed.Errors).toContain('Title is required.');
    });

    it('parses a minimal log and defaults StartedAt to now', () => {
        const before = Date.now();
        const parsed = ParseLogActivityParams({ TypeCode: 'Note', Title: 'hello' });
        expect(parsed.Errors).toEqual([]);
        expect(parsed.Input?.TypeCode).toBe('Note');
        expect(parsed.Input?.Title).toBe('hello');
        expect(parsed.Input?.StartedAt.getTime()).toBeGreaterThanOrEqual(before);
        expect(parsed.Input?.Links).toEqual([]);
    });

    it('accepts ISO strings for dates and rejects garbage', () => {
        const good = ParseLogActivityParams({
            TypeCode: 'Note',
            Title: 'x',
            StartedAt: '2026-08-30T10:00:00Z',
        });
        expect(good.Input?.StartedAt.toISOString()).toBe('2026-08-30T10:00:00.000Z');

        const bad = ParseLogActivityParams({ TypeCode: 'Note', Title: 'x', StartedAt: 'not-a-date' });
        expect(bad.Input).toBeNull();
        expect(bad.Errors.join(' ')).toMatch(/StartedAt/);
    });

    it('validates enum params against their real value lists', () => {
        const bad = ParseLogActivityParams({
            TypeCode: 'Note',
            Title: 'x',
            Direction: 'Sideways',
            Source: 'Integration',
        });
        expect(bad.Input).toBeNull();
        expect(bad.Errors.join(' ')).toMatch(/Direction must be one of/);
        // 'Integration' belongs to the sync engine's entry point, not the manual one.
        expect(bad.Errors.join(' ')).toMatch(/Source must be one of: Manual, System/);
    });

    it('builds a Regarding link from EntityName + RecordData.ID', () => {
        const parsed = ParseLogActivityParams({
            TypeCode: 'SystemEvent',
            Title: 'Person created',
            EntityName: PEOPLE,
            RecordData: { ID: PERSON_ID, FirstName: 'Jane' },
        });
        expect(parsed.Errors).toEqual([]);
        expect(parsed.Input?.Links).toEqual([{ Role: 'Regarding', EntityName: PEOPLE, RecordID: PERSON_ID }]);
    });

    it('refuses EntityName without a record id (and vice versa)', () => {
        const parsed = ParseLogActivityParams({ TypeCode: 'Note', Title: 'x', EntityName: PEOPLE });
        expect(parsed.Input).toBeNull();
        expect(parsed.Errors.join(' ')).toMatch(/provided together/);
    });

    it('EventKey derives an idempotency pair and defaults SourceSystem', () => {
        const parsed = ParseLogActivityParams({
            TypeCode: 'SystemEvent',
            Title: 'Person created',
            EntityName: PEOPLE,
            RecordID: PERSON_ID,
            EventKey: 'AfterCreate',
        });
        expect(parsed.Errors).toEqual([]);
        expect(parsed.Input?.SourceSystem).toBe(LOG_ACTIVITY_DEFAULT_SOURCE_SYSTEM);
        expect(parsed.Input?.ExternalID).toBe(`${PEOPLE}|${PERSON_ID}|AfterCreate`);
    });

    it('EventKey without a record identity is an error, not a silent non-key', () => {
        const parsed = ParseLogActivityParams({ TypeCode: 'Note', Title: 'x', EventKey: 'AfterCreate' });
        expect(parsed.Input).toBeNull();
        expect(parsed.Errors.join(' ')).toMatch(/EventKey requires EntityName/);
    });

    it('an explicit ExternalID wins over EventKey derivation', () => {
        const parsed = ParseLogActivityParams({
            TypeCode: 'Note',
            Title: 'x',
            EntityName: PEOPLE,
            RecordID: PERSON_ID,
            EventKey: 'AfterCreate',
            SourceSystem: 'MyApp',
            ExternalID: 'custom-key',
        });
        expect(parsed.Input?.ExternalID).toBe('custom-key');
        expect(parsed.Input?.SourceSystem).toBe('MyApp');
    });

    it('LinkFields routes to records the subject points at, skipping empty FKs', () => {
        const parsed = ParseLogActivityParams({
            TypeCode: 'SystemEvent',
            Title: 'Relationship started',
            EntityName: 'MJ_BizApps_Common: Relationships',
            RecordData: {
                ID: 'rel-1',
                FromPersonID: PERSON_ID,
                ToOrganizationID: 'org-1',
                ToPersonID: null,
            },
            LinkFields: JSON.stringify([
                { Field: 'FromPersonID', EntityName: PEOPLE, Role: 'Participant' },
                { Field: 'ToPersonID', EntityName: PEOPLE, Role: 'Participant' },
                { Field: 'ToOrganizationID', EntityName: 'MJ_BizApps_Common: Organizations', Role: 'Participant' },
            ]),
        });
        expect(parsed.Errors).toEqual([]);
        expect(parsed.Input?.Links).toEqual([
            { Role: 'Regarding', EntityName: 'MJ_BizApps_Common: Relationships', RecordID: 'rel-1' },
            { Role: 'Participant', EntityName: PEOPLE, RecordID: PERSON_ID },
            { Role: 'Participant', EntityName: 'MJ_BizApps_Common: Organizations', RecordID: 'org-1' },
        ]);
    });

    it('LinkFields without RecordData is an error', () => {
        const parsed = ParseLogActivityParams({
            TypeCode: 'Note',
            Title: 'x',
            LinkFields: [{ Field: 'FromPersonID', EntityName: PEOPLE, Role: 'Participant' }],
        });
        expect(parsed.Input).toBeNull();
        expect(parsed.Errors.join(' ')).toMatch(/LinkFields requires RecordData/);
    });

    it('parses Links from a JSON string and validates roles', () => {
        const good = ParseLogActivityParams({
            TypeCode: 'Note',
            Title: 'x',
            Links: JSON.stringify([{ Role: 'LoggedFor', EntityName: PEOPLE, RecordID: PERSON_ID }]),
        });
        expect(good.Errors).toEqual([]);
        expect(good.Input?.Links).toEqual([{ Role: 'LoggedFor', EntityName: PEOPLE, RecordID: PERSON_ID }]);

        const bad = ParseLogActivityParams({
            TypeCode: 'Note',
            Title: 'x',
            Links: [{ Role: 'BestFriend', EntityName: PEOPLE, RecordID: PERSON_ID }],
        });
        expect(bad.Input).toBeNull();
        expect(bad.Errors.join(' ')).toMatch(/Role must be one of/);
    });

    it('unparseable JSON is an error, never silently ignored', () => {
        const parsed = ParseLogActivityParams({ TypeCode: 'Note', Title: 'x', Links: '{not json' });
        expect(parsed.Input).toBeNull();
        expect(parsed.Errors.join(' ')).toMatch(/Links must be an object or valid JSON/);
    });

    it('Details must be an object, and passes through when it is', () => {
        const good = ParseLogActivityParams({
            TypeCode: 'Note',
            Title: 'x',
            Details: { PreviousStatus: 'Active', NewStatus: 'Inactive' },
        });
        expect(good.Input?.Details).toEqual({ PreviousStatus: 'Active', NewStatus: 'Inactive' });

        const bad = ParseLogActivityParams({ TypeCode: 'Note', Title: 'x', Details: '[1,2]' });
        expect(bad.Input).toBeNull();
        expect(bad.Errors.join(' ')).toMatch(/Details must be a JSON object/);
    });

    it('param names are case-insensitive, as action params are', () => {
        const parsed = ParseLogActivityParams({ typecode: 'Note', TITLE: 'hello' });
        expect(parsed.Errors).toEqual([]);
        expect(parsed.Input?.TypeCode).toBe('Note');
        expect(parsed.Input?.Title).toBe('hello');
    });
});
