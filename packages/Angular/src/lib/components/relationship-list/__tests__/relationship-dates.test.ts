/**
 * Relationship StartDate/EndDate are SQL `date` columns: the driver hands them back as a Date at UTC
 * midnight, so the stored day is the Date's UTC parts. These tests run with the machine zone pinned
 * west of UTC, where reading local parts lands on the previous day (golive #168).
 */
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { FromCalendarDay, ToCalendarDay } from '@mj-biz-apps/common-entities';
import {
    FormatRelationshipDateRange,
    RelationshipDateInputValue,
    RelationshipEndDateFor,
} from '../relationship-dates';

const CENTRAL = 'America/Chicago';
let savedTZ: string | undefined;

beforeAll(() => {
    savedTZ = process.env.TZ;
    process.env.TZ = CENTRAL;
});

afterAll(() => {
    if (savedTZ === undefined) delete process.env.TZ;
    else process.env.TZ = savedTZ;
});

describe('machine zone', () => {
    it('is west of UTC for these tests', () => {
        expect(new Date('2026-01-01T00:00:00.000Z').getDate()).toBe(31);
    });
});

describe('RelationshipDateInputValue', () => {
    it('shows the stored day, not the previous local day', () => {
        expect(RelationshipDateInputValue(FromCalendarDay('2026-01-01'))).toBe('2026-01-01');
    });

    it('round-trips through the edit box unchanged (open Edit, save, nothing moves)', () => {
        const stored = FromCalendarDay('2026-03-15');
        // onSaveEdit writes the box value back as `new Date('YYYY-MM-DD')`, which is UTC midnight.
        const saved = new Date(RelationshipDateInputValue(stored));
        expect(saved.getTime()).toBe(stored.getTime());
    });

    it('is empty for no date', () => {
        expect(RelationshipDateInputValue(null)).toBe('');
    });
});

describe('RelationshipEndDateFor', () => {
    // 8:30 PM Central on Sept 30 is already Oct 1 in UTC.
    const evening = new Date('2026-10-01T01:30:00.000Z');

    it('is the business day, not the UTC day, in the evening', () => {
        expect(ToCalendarDay(RelationshipEndDateFor(CENTRAL, evening))).toBe('2026-09-30');
    });

    it('is UTC midnight, the shape a date column round-trips as', () => {
        expect(RelationshipEndDateFor(CENTRAL, evening).toISOString()).toBe('2026-09-30T00:00:00.000Z');
    });

    it('follows the zone it is given', () => {
        expect(ToCalendarDay(RelationshipEndDateFor('UTC', evening))).toBe('2026-10-01');
    });
});

describe('FormatRelationshipDateRange', () => {
    it('shows a Jan 1 start as January, not the prior December', () => {
        expect(FormatRelationshipDateRange(FromCalendarDay('2026-01-01'), null, 'Active')).toBe('Jan 2026 - Present');
    });

    it('shows both ends by their stored month', () => {
        expect(FormatRelationshipDateRange(FromCalendarDay('2024-07-01'), FromCalendarDay('2026-01-01'), 'Ended')).toBe('Jul 2024 - Jan 2026');
    });

    it('leaves an open end blank unless the relationship is active', () => {
        expect(FormatRelationshipDateRange(FromCalendarDay('2024-07-01'), null, 'Ended')).toBe('Jul 2024 -');
    });

    it('is empty with no dates', () => {
        expect(FormatRelationshipDateRange(null, null, 'Active')).toBe('');
    });
});
