/**
 * One function turns "this many units of these operations" into credits and money. The enrichment
 * action's Preview uses it now; the importer's estimates reuse it, so a run and an import always price
 * the same way.
 */

export type EnrichmentOperation = 'Enrich' | 'Count' | 'Search' | 'SchoolLookup';

export interface CostLine {
    Operation: EnrichmentOperation;
    Units: number;
    /** True when the real number can only be lower (for example, misses are free). */
    IsUpperBound?: boolean;
}

export interface CostRate {
    Operation: EnrichmentOperation;
    Unit: string;
    CreditsPerUnit: number;
}

export interface CostEstimateInput {
    /** The provider's rate rows. */
    Rates: CostRate[];
    CreditPrice: number | null;
    CreditCurrency: string | null;
    Lines: CostLine[];
}

export interface CostEstimate {
    /** null when any line has no rate row: unknown, never 0. */
    Credits: number | null;
    /** null when Credits is null or the provider is unpriced. */
    Cost: number | null;
    Currency: string | null;
    /** true when any line is an upper bound. */
    IsUpperBound: boolean;
    MissingRates: EnrichmentOperation[];
}

export function EstimateCost(input: CostEstimateInput): CostEstimate {
    const missing = MissingOperations(input);
    const isUpperBound = input.Lines.some((line) => line.IsUpperBound === true);
    if (missing.length > 0) {
        return { Credits: null, Cost: null, Currency: input.CreditCurrency, IsUpperBound: isUpperBound, MissingRates: missing };
    }
    const credits = input.Lines.reduce((sum, line) => sum + line.Units * RateFor(input, line.Operation), 0);
    const priced = input.CreditPrice != null;
    return {
        Credits: credits,
        Cost: priced ? credits * (input.CreditPrice as number) : null,
        Currency: priced ? input.CreditCurrency : null,
        IsUpperBound: isUpperBound,
        MissingRates: [],
    };
}

function MissingOperations(input: CostEstimateInput): EnrichmentOperation[] {
    const missing: EnrichmentOperation[] = [];
    for (const line of input.Lines) {
        const known = input.Rates.some((rate) => rate.Operation === line.Operation);
        if (!known && !missing.includes(line.Operation)) missing.push(line.Operation);
    }
    return missing;
}

function RateFor(input: CostEstimateInput, operation: EnrichmentOperation): number {
    const rate = input.Rates.find((candidate) => candidate.Operation === operation);
    return rate ? rate.CreditsPerUnit : 0;
}

/** Money for display only: two decimals. Stored numbers are never rounded. */
export function FormatCost(estimate: CostEstimate): string {
    if (estimate.Credits == null) {
        return `cost unknown: no rate for ${estimate.MissingRates.join(', ')}`;
    }
    const prefix = estimate.IsUpperBound ? 'up to ' : '';
    if (estimate.Cost == null) return `${prefix}${estimate.Credits} credits (unpriced)`;
    return `${prefix}${estimate.Credits} credits, ${estimate.Cost.toFixed(2)} ${estimate.Currency ?? ''}`.trim();
}
