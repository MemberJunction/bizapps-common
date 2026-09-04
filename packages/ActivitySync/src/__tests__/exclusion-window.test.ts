/**
 * Exclusions: switched off, and the window of items they cover.
 *
 * THE DEFECT. `ActivitySyncExclusion` carries `IsEnabled`, `EffectiveFrom` and `EffectiveTo`, and the
 * qualification cascade read none of them. Two consequences, both silent:
 *
 *   - switching an exclusion OFF left it excluding;
 *   - an exclusion dated to lapse never lapsed, and one dated to start later excluded immediately.
 *
 * Nobody would notice either. The run reports success, the run log records "Exclusion X matched", and
 * the only symptom is mail that quietly never arrives — months after whoever set the date stopped
 * watching for it.
 *
 * WHY ITEM TIME AND NOT RUN TIME. `RuleRow.DateFrom`/`DateTo` are matched against `item.StartedAt`,
 * one stage later in the same cascade. Had the exclusion window meant "while this record is in force"
 * instead, the same two dates would mean different things one stage apart — a trap for whoever writes
 * the second rule set. It also keeps a re-run reproducible: `ActivitySyncRunDetail` exists to answer
 * "which rule ate my message", and an answer that moves with the wall clock is not evidence.
 */
import { describe, expect, it } from 'vitest';

import { DefaultDeterministicStages, ExclusionAppliesTo, type EngineQualificationContext } from '../stages.js';
import { RunQualificationCascade } from '../qualification.js';
import type { NormalizedItem } from '../types.js';

const AUG = new Date('2026-08-15T12:00:00Z');

const item = (occurredAt: Date): NormalizedItem => ({
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Renewal',
    Body: null,
    StartedAt: occurredAt,
    EndedAt: null,
    Location: null,
    Direction: 'Inbound',
    HasAttachments: false,
    Participants: [{ Address: 'alice@customer.com', Name: null, Role: 'From', IdentityKind: 'Email' }],
    Cancelled: false,
    Raw: {},
});

const exclusion = (over: Record<string, unknown> = {}) => ({
    ID: 'ex-1',
    IdentityKind: 'Email',
    IdentityValue: 'alice@customer.com',
    ActivitySyncRuleSetID: null,
    IsEnabled: true,
    EffectiveFrom: null,
    EffectiveTo: null,
    ...over,
});

const ctx = (partial: Partial<EngineQualificationContext> = {}): EngineQualificationContext => ({
    ConnectionID: 'conn',
    ProviderTypeCode: 'Microsoft365',
    Exclusions: [],
    Rules: [],
    InternalDomains: [],
    KnownAddresses: new Map(),
    ...partial,
});

describe('an exclusion that is switched off', () => {
    it('applies when enabled', () => {
        expect(ExclusionAppliesTo({ IsEnabled: true, EffectiveFrom: null, EffectiveTo: null }, AUG)).toBe(true);
    });

    /** The whole point: `IsEnabled = 0` used to change nothing at all. */
    it('does not apply when disabled', () => {
        expect(ExclusionAppliesTo({ IsEnabled: false, EffectiveFrom: null, EffectiveTo: null }, AUG)).toBe(false);
    });

    /**
     * Fail CLOSED on a row that does not say. An exclusion exists to stop something being ingested, so
     * a missing flag must not read as "ingest it" — the damage is asymmetric.
     */
    it('applies when the flag is absent, rather than assuming off', () => {
        expect(
            ExclusionAppliesTo({ IsEnabled: undefined as unknown as boolean, EffectiveFrom: null, EffectiveTo: null }, AUG),
        ).toBe(true);
    });
});

describe('the window of items it covers', () => {
    it('applies with no bounds at all', () => {
        expect(ExclusionAppliesTo(exclusion(), AUG)).toBe(true);
    });

    it('does not apply to an item before EffectiveFrom', () => {
        expect(ExclusionAppliesTo(exclusion({ EffectiveFrom: '2026-09-01T00:00:00Z' }), AUG)).toBe(false);
    });

    it('does not apply to an item after EffectiveTo', () => {
        expect(ExclusionAppliesTo(exclusion({ EffectiveTo: '2026-08-01T00:00:00Z' }), AUG)).toBe(false);
    });

    it('applies inside both bounds', () => {
        expect(
            ExclusionAppliesTo(
                exclusion({ EffectiveFrom: '2026-08-01T00:00:00Z', EffectiveTo: '2026-08-31T00:00:00Z' }),
                AUG,
            ),
        ).toBe(true);
    });

    /** Inclusive on both ends, matching how `RuleRow.DateFrom`/`DateTo` compare. */
    it('is inclusive at each boundary', () => {
        expect(ExclusionAppliesTo(exclusion({ EffectiveFrom: AUG.toISOString() }), AUG)).toBe(true);
        expect(ExclusionAppliesTo(exclusion({ EffectiveTo: AUG.toISOString() }), AUG)).toBe(true);
    });

    it('accepts a Date as readily as a string, since RunView returns either', () => {
        expect(ExclusionAppliesTo(exclusion({ EffectiveFrom: new Date('2026-09-01T00:00:00Z') }), AUG)).toBe(false);
    });

    /**
     * An unparseable date is not a bound. Treating it as one would silently switch an exclusion off
     * on a typo — the direction that lets excluded mail through.
     */
    it('ignores a bound it cannot read, rather than dropping the exclusion', () => {
        expect(ExclusionAppliesTo(exclusion({ EffectiveFrom: 'last tuesday' }), AUG)).toBe(true);
        expect(ExclusionAppliesTo(exclusion({ EffectiveTo: '' }), AUG)).toBe(true);
    });
});

describe('through the cascade, which is where it matters', () => {
    const stages = DefaultDeterministicStages();

    it('still excludes a matching identity inside the window', async () => {
        const verdict = await RunQualificationCascade(
            stages,
            item(AUG),
            ctx({ Exclusions: [exclusion({ EffectiveFrom: '2026-08-01T00:00:00Z' })] }),
            'Include',
        );
        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.ActivitySyncExclusionID).toBe('ex-1');
    });

    /**
     * The lapsed case, end to end. Before this, an exclusion whose window had closed kept matching and
     * the message never arrived.
     */
    it('lets the item through once the exclusion has lapsed', async () => {
        const verdict = await RunQualificationCascade(
            stages,
            item(AUG),
            ctx({ Exclusions: [exclusion({ EffectiveTo: '2026-07-31T00:00:00Z' })] }),
            'Include',
        );
        expect(verdict.Decision).not.toBe('Exclude');
    });

    it('lets the item through before the exclusion starts', async () => {
        const verdict = await RunQualificationCascade(
            stages,
            item(AUG),
            ctx({ Exclusions: [exclusion({ EffectiveFrom: '2026-09-01T00:00:00Z' })] }),
            'Include',
        );
        expect(verdict.Decision).not.toBe('Exclude');
    });

    it('lets the item through when the exclusion is switched off', async () => {
        const verdict = await RunQualificationCascade(
            stages,
            item(AUG),
            ctx({ Exclusions: [exclusion({ IsEnabled: false })] }),
            'Include',
        );
        expect(verdict.Decision).not.toBe('Exclude');
    });

    /**
     * One exclusion lapsing must not disarm another. A cascade that stopped at the first
     * non-applicable row would let everything through the moment one date expired.
     */
    it('keeps evaluating later exclusions after skipping one', async () => {
        const verdict = await RunQualificationCascade(
            stages,
            item(AUG),
            ctx({
                Exclusions: [
                    exclusion({ ID: 'ex-lapsed', EffectiveTo: '2026-07-01T00:00:00Z' }),
                    exclusion({ ID: 'ex-live' }),
                ],
            }),
            'Include',
        );
        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.ActivitySyncExclusionID).toBe('ex-live');
    });

    /**
     * The window is matched against the ITEM, not the clock — so the same inputs give the same verdict
     * whenever the run happens. This is what makes the run log reproducible.
     */
    it('judges by when the item occurred, not when the sync runs', async () => {
        const inWindow = exclusion({ EffectiveFrom: '2026-08-01T00:00:00Z', EffectiveTo: '2026-08-31T00:00:00Z' });
        const inside = await RunQualificationCascade(stages, item(AUG), ctx({ Exclusions: [inWindow] }), 'Include');
        const outside = await RunQualificationCascade(
            stages,
            item(new Date('2026-10-01T12:00:00Z')),
            ctx({ Exclusions: [inWindow] }),
            'Include',
        );
        expect(inside.Decision).toBe('Exclude');
        expect(outside.Decision).not.toBe('Exclude');
    });
});
