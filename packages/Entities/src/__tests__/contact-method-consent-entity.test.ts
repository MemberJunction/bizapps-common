import { describe, expect, it } from 'vitest';
import { ConsentHistoryEntry, ContactMethodConsentEntity } from '../contact-method-consent-entity.js';

const at = (iso: string): Date => new Date(iso);

const entry = (status: ConsentHistoryEntry['NewConsentStatus'], iso: string): ConsentHistoryEntry => ({
    NewConsentStatus: status,
    ConsentStatusAt: at(iso),
});

describe('ContactMethodConsentEntity.ResolveCurrentStatus', () => {
    it('is Not Specified when nothing was ever recorded', () => {
        expect(ContactMethodConsentEntity.ResolveCurrentStatus([])).toBe('Not Specified');
    });

    it('is the entry with the latest ConsentStatusAt, whatever order the rows arrive in', () => {
        const history = [
            entry('Opted Out', '2026-10-12T00:00:00Z'),
            entry('Not Specified', '2019-06-18T00:00:00Z'),
            entry('Opted In', '2025-03-03T00:00:00Z'),
        ];
        expect(ContactMethodConsentEntity.ResolveCurrentStatus(history)).toBe('Opted Out');
        expect(ContactMethodConsentEntity.ResolveCurrentStatus([...history].reverse())).toBe('Opted Out');
    });

    it('resolves two changes at the same instant to the one recorded later', () => {
        const history = [entry('Opted In', '2026-01-01T00:00:00Z'), entry('Opted Out', '2026-01-01T00:00:00Z')];
        expect(ContactMethodConsentEntity.ResolveCurrentStatus(history)).toBe('Opted Out');
    });
});

describe('ContactMethodConsentEntity.IsLatestChange', () => {
    const history = [entry('Opted In', '2025-03-03T00:00:00Z'), entry('Opted Out', '2026-10-12T00:00:00Z')];

    it('is true for a change newer than everything recorded, and for an empty history', () => {
        expect(ContactMethodConsentEntity.IsLatestChange(history, at('2026-10-13T00:00:00Z'))).toBe(true);
        expect(ContactMethodConsentEntity.IsLatestChange([], at('2000-01-01T00:00:00Z'))).toBe(true);
    });

    it('is false for a late-arriving import with an older date, so it is kept but does not move the status', () => {
        expect(ContactMethodConsentEntity.IsLatestChange(history, at('2019-06-18T00:00:00Z'))).toBe(false);
    });

    it('is true at exactly the latest instant, matching ResolveCurrentStatus on ties', () => {
        expect(ContactMethodConsentEntity.IsLatestChange(history, at('2026-10-12T00:00:00Z'))).toBe(true);
    });
});

describe('ContactMethodConsentEntity.Statuses', () => {
    it('lists the three readable statuses, with Not Specified as the unspecified one', () => {
        expect([...ContactMethodConsentEntity.Statuses]).toEqual(['Not Specified', 'Opted In', 'Opted Out']);
        expect(ContactMethodConsentEntity.UnspecifiedStatus).toBe('Not Specified');
        expect(ContactMethodConsentEntity.StatusListComplete).toBe(true);
    });
});
