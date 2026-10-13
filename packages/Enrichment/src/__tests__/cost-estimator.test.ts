import { describe, expect, it } from 'vitest';
import { EstimateCost, FormatCost, type CostRate } from '../cost-estimator.js';

const rates: CostRate[] = [
    { Operation: 'Enrich', Unit: 'MatchedPerson', CreditsPerUnit: 1 },
    { Operation: 'Search', Unit: 'ReturnedRecord', CreditsPerUnit: 0 },
    { Operation: 'Count', Unit: 'NonEmptyRequest', CreditsPerUnit: 1 },
];

describe('EstimateCost', () => {
    it('prices each operation by its unit rate and the credit price', () => {
        const estimate = EstimateCost({ Rates: rates, CreditPrice: 0.25, CreditCurrency: 'USD', Lines: [{ Operation: 'Enrich', Units: 200 }] });
        expect(estimate).toEqual({ Credits: 200, Cost: 50, Currency: 'USD', IsUpperBound: false, MissingRates: [] });
    });
    it('makes the answer unknown, never free, when a rate is missing', () => {
        const estimate = EstimateCost({ Rates: rates, CreditPrice: 0.25, CreditCurrency: 'USD', Lines: [{ Operation: 'SchoolLookup', Units: 3 }] });
        expect(estimate.Credits).toBeNull();
        expect(estimate.Cost).toBeNull();
        expect(estimate.MissingRates).toEqual(['SchoolLookup']);
        expect(FormatCost(estimate)).toBe('cost unknown: no rate for SchoolLookup');
    });
    it('reports credits only for an unpriced provider', () => {
        const estimate = EstimateCost({ Rates: rates, CreditPrice: null, CreditCurrency: null, Lines: [{ Operation: 'Enrich', Units: 10 }] });
        expect(estimate.Credits).toBe(10);
        expect(estimate.Cost).toBeNull();
        expect(estimate.Currency).toBeNull();
        expect(FormatCost(estimate)).toBe('10 credits (unpriced)');
    });
    it('labels an upper bound', () => {
        const estimate = EstimateCost({ Rates: rates, CreditPrice: 0.5, CreditCurrency: 'USD', Lines: [{ Operation: 'Enrich', Units: 4, IsUpperBound: true }] });
        expect(estimate.IsUpperBound).toBe(true);
        expect(FormatCost(estimate)).toBe('up to 4 credits, 2.00 USD');
    });
    it('handles zero units and mixed lines (a free search plus paid matches)', () => {
        expect(EstimateCost({ Rates: rates, CreditPrice: 1, CreditCurrency: 'USD', Lines: [{ Operation: 'Enrich', Units: 0 }] }).Credits).toBe(0);
        const mixed = EstimateCost({ Rates: rates, CreditPrice: 1, CreditCurrency: 'USD', Lines: [{ Operation: 'Search', Units: 500 }, { Operation: 'Enrich', Units: 50 }] });
        expect(mixed.Credits).toBe(50);
        expect(mixed.Cost).toBe(50);
    });
    it('does not round stored numbers', () => {
        const estimate = EstimateCost({ Rates: [{ Operation: 'Enrich', Unit: 'MatchedPerson', CreditsPerUnit: 0.3333 }], CreditPrice: 0.1, CreditCurrency: 'EUR', Lines: [{ Operation: 'Enrich', Units: 3 }] });
        expect(estimate.Credits).toBeCloseTo(0.9999, 10);
    });
});
