import { describe, expect, it } from 'vitest';

import {
    collapseExtensionStamps,
    healthErrorFromResults,
    type SyncEngineResult,
} from '../ActivitySyncEngine.js';

function result(partial: Partial<SyncEngineResult>): SyncEngineResult {
    return {
        Success: true,
        RunID: null,
        Fetched: 0,
        Included: 0,
        Excluded: 0,
        Duplicates: 0,
        Failed: 0,
        ExtensionErrors: 0,
        WatermarkAdvancedTo: null,
        Issues: [],
        ...partial,
    };
}

describe('healthErrorFromResults', () => {
    /**
     * This used to end `.slice(0, 4000)`. `LastError` is NVARCHAR(MAX), so the cap was inherited
     * rather than required — and because this flattens every failed surface's issues, a broadly
     * failing run lost the tail of its own diagnosis. The equivalent slice on the run's issue list
     * was removed for the same reason.
     */
    it('keeps the whole diagnosis when many surfaces fail, past the old 4000 cap', () => {
        const many = Array.from({ length: 60 }, (_, i) =>
            `surface ${i + 1}: the mailbox read failed and nothing was written for this batch`,
        );
        const error = healthErrorFromResults([result({ Success: false, Issues: many })]);
        const joined = many.join(' | ');
        expect(joined.length, 'the fixture must clear the old cap or this proves nothing')
            .toBeGreaterThan(4000);
        expect(error?.length, 'LastError must not truncate').toBe(joined.length);
        expect(error, 'the last surface is what the cap ate').toContain('surface 60');
    });

    it('is null when every surface succeeded — mapping warnings on a success do not become LastError', () => {
        expect(
            healthErrorFromResults([
                result({ Success: true, Issues: ['Event X had no usable start time and was skipped.'] }),
            ]),
        ).toBeNull();
    });

    it('joins issues from the failed surfaces, not Issues[0] of the whole run', () => {
        const error = healthErrorFromResults([
            result({
                Success: false,
                Issues: ['ContactMethod lookup failed — watermark will not advance.'],
            }),
            result({
                Success: true,
                Issues: ['Live Graph calendar fetch is disabled.'],
            }),
        ]);
        expect(error).toMatch(/ContactMethod lookup failed/);
        expect(error).not.toMatch(/calendar fetch is disabled/);
    });
});

describe('collapseExtensionStamps', () => {
    it('writes once per extension id and keeps a batch error over a later success', () => {
        const collapsed = collapseExtensionStamps([
            { ID: 'a', LastError: null },
            { ID: 'a', LastError: 'matcher failed' },
            { ID: 'a', LastError: null },
            { ID: 'b', LastError: null },
        ]);
        expect(collapsed).toEqual([
            { ID: 'a', LastError: 'matcher failed' },
            { ID: 'b', LastError: null },
        ]);
    });
});
