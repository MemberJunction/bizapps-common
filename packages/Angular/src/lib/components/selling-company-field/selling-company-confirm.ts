/**
 * Which selling-company choices go straight through and which pause for a confirmation.
 *
 * The selling company decides which legal entity books the revenue on an order or a contract, and
 * the picker can offer dozens of companies whose names differ by a word. Getting it wrong is silent
 * — the record looks correct afterwards. So the default is written without ceremony and anything
 * else is held until the user says yes.
 *
 * Pure and synchronous on purpose: the rule is the part worth testing, and it is testable here
 * without a record, a provider or a rendered field.
 */
export class SellingCompanyConfirm {
    private pending: string | null = null;

    /**
     * @param defaultID the resolved default company, or null when this instance has none
     *                  configured — in which case nothing is ever held back, because there is no
     *                  expectation to depart from.
     */
    constructor(private readonly defaultID: string | null) {}

    /** The choice currently awaiting an answer, or null when nothing is pending. */
    public get Pending(): string | null {
        return this.pending;
    }

    /**
     * Offer a choice. Returns what to write now (`Write`) and what to ask about (`Ask`); exactly
     * one of them is non-null. Clearing the field is always allowed — an empty value books nothing.
     */
    public Propose(id: string | null): { Write: string | null; Ask: string | null } {
        if (!id || !this.defaultID || sameID(id, this.defaultID)) {
            this.pending = null;
            return { Write: id, Ask: null };
        }
        this.pending = id;
        return { Write: null, Ask: id };
    }

    /** The user said yes. Returns the value to write. */
    public Confirm(): string | null {
        const confirmed = this.pending;
        this.pending = null;
        return confirmed;
    }

    /** The user said no, or moved on without answering. Returns the value to restore. */
    public Revert(previous: string | null): string | null {
        this.pending = null;
        return previous;
    }
}

function sameID(a: string, b: string): boolean {
    return a.trim().toLowerCase() === b.trim().toLowerCase();
}
