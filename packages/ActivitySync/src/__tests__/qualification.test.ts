import { describe, expect, it } from 'vitest';

import {
    AssertInferenceRunsLast,
    RunQualificationCascade,
    type IQualificationStage,
    type QualificationContext,
    type QualificationDecision,
    type QualificationVerdict,
} from '../qualification.js';
import type { NormalizedItem } from '../types.js';

const ITEM: NormalizedItem = {
    ExternalID: 'msg-1',
    ExternalThreadID: null,
    TypeCode: 'Email',
    Subject: 'Q3 renewal',
    Body: 'body',
    StartedAt: new Date('2026-08-05T10:00:00Z'),
    EndedAt: null,
    Location: null,
    Direction: 'Inbound',
    Participants: [],
    Cancelled: false,
    Raw: {},
};

const CONTEXT: QualificationContext = { ConnectionID: 'conn-1', ProviderTypeCode: 'Microsoft365' };

/** A stage that always answers the same way, and records whether it was consulted. */
function stage(
    name: string,
    decision: QualificationDecision,
    requiresInference = false,
): IQualificationStage & { Consulted: boolean } {
    const s = {
        Name: name,
        RequiresInference: requiresInference,
        Consulted: false,
        async Evaluate(): Promise<QualificationVerdict> {
            s.Consulted = true;
            return { Decision: decision, Reason: `${name} said ${decision}`, StageName: name };
        },
    };
    return s;
}

describe('RunQualificationCascade', () => {
    it('returns the first decisive verdict and does not consult later stages', async () => {
        const first = stage('Rules', 'Exclude');
        const second = stage('KnownParticipant', 'Include');

        const verdict = await RunQualificationCascade([first, second], ITEM, CONTEXT, 'Exclude');

        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.StageName).toBe('Rules');
        expect(second.Consulted).toBe(false);
    });

    it('walks past abstaining stages to the one that decides', async () => {
        const first = stage('Rules', 'Undecided');
        const second = stage('KnownParticipant', 'Include');

        const verdict = await RunQualificationCascade([first, second], ITEM, CONTEXT, 'Exclude');

        expect(verdict.Decision).toBe('Include');
        expect(verdict.StageName).toBe('KnownParticipant');
        expect(first.Consulted).toBe(true);
    });

    it('FAILS CLOSED when every stage abstains — the mailbox default', async () => {
        const stages = [stage('Rules', 'Undecided'), stage('KnownParticipant', 'Undecided')];

        const verdict = await RunQualificationCascade(stages, ITEM, CONTEXT, 'Exclude');

        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.StageName).toBe('DefaultPolicy');
        expect(verdict.Reason).toContain('DefaultQualificationPolicy');
    });

    it('honours an Include default where a provider type opts into it', async () => {
        const verdict = await RunQualificationCascade([stage('Rules', 'Undecided')], ITEM, CONTEXT, 'Include');
        expect(verdict.Decision).toBe('Include');
    });

    it('abstains to the default policy when there are no stages at all', async () => {
        const verdict = await RunQualificationCascade([], ITEM, CONTEXT, 'Exclude');
        expect(verdict.Decision).toBe('Exclude');
        expect(verdict.Reason).toContain('(none)');
    });

    it('lets an inference stage decide once the deterministic stages have abstained', async () => {
        const rules = stage('Rules', 'Undecided');
        const infer = stage('Infer', 'Include', true);

        const verdict = await RunQualificationCascade([rules, infer], ITEM, CONTEXT, 'Exclude');

        expect(verdict.Decision).toBe('Include');
        expect(verdict.StageName).toBe('Infer');
    });

    it('REFUSES to run a cascade where a deterministic stage follows inference', async () => {
        const infer = stage('Infer', 'Undecided', true);
        const rules = stage('Rules', 'Include');

        await expect(RunQualificationCascade([infer, rules], ITEM, CONTEXT, 'Exclude')).rejects.toThrow(
            /must run last/i,
        );
        // And it refuses BEFORE sending anything to the model.
        expect(infer.Consulted).toBe(false);
    });
});

describe('AssertInferenceRunsLast', () => {
    it('accepts a cascade with no inference stage', () => {
        expect(() => AssertInferenceRunsLast([stage('A', 'Undecided'), stage('B', 'Undecided')])).not.toThrow();
    });

    it('accepts consecutive inference stages at the end', () => {
        const stages = [stage('A', 'Undecided'), stage('I1', 'Undecided', true), stage('I2', 'Undecided', true)];
        expect(() => AssertInferenceRunsLast(stages)).not.toThrow();
    });

    it('names both stages in the error so the fix is obvious', () => {
        const stages = [stage('Infer', 'Undecided', true), stage('Rules', 'Undecided')];
        expect(() => AssertInferenceRunsLast(stages)).toThrow(/"Rules".*"Infer"/s);
    });
});
