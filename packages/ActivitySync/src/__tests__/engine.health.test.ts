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
