import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

import {
    EscapeText,
    InList,
    InvalidFilterInputError,
    RequireUUID,
    RequireUUIDs,
    UuidInList,
} from '../sql.js';

const SRC = join(dirname(fileURLToPath(import.meta.url)), '..');
const GOOD = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

describe('sql guards', () => {
    it('accepts a UUID unchanged', () => {
        expect(RequireUUID(GOOD, 'ID')).toBe(GOOD);
    });

    it.each([
        ["' OR 1=1 --", 'the classic widening injection'],
        [`' OR '1'='1`, 'quote-balanced variant'],
        [`${GOOD}' OR '1'='1`, 'a real id with a payload appended'],
        ['not-a-uuid', 'plain garbage'],
        ['', 'empty'],
    ])('rejects %s (%s)', (bad) => {
        expect(() => RequireUUID(bad, 'ActivitySyncConnectionID')).toThrow(InvalidFilterInputError);
    });

    it('names the offending field', () => {
        expect(() => RequireUUID('nope', 'ActivitySyncProviderTypeID')).toThrow(
            /ActivitySyncProviderTypeID/,
        );
    });

    it('validates every element of an id list, including a non-string', () => {
        expect(RequireUUIDs([GOOD, GOOD], 'ActivitySyncRuleSetID')).toEqual([GOOD, GOOD]);
        expect(() => RequireUUIDs([GOOD, "' OR 1=1 --"], 'ActivitySyncRuleSetID')).toThrow(
            InvalidFilterInputError,
        );
        expect(() => RequireUUIDs([GOOD, 1], 'ActivitySyncRuleSetID')).toThrow(InvalidFilterInputError);
        expect(RequireUUIDs(undefined, 'ActivitySyncRuleSetID')).toEqual([]);
    });

    it('escapes free text by dropping NULs and doubling quotes', () => {
        expect(EscapeText("O'Brien")).toBe("O''Brien");
        expect(EscapeText("a\0b'c")).toBe("ab''c");
        expect(EscapeText(null)).toBe('');
        expect(EscapeText(12)).toBe('12');
    });

    it('InList coerces a non-string element instead of calling .replace on it', () => {
        expect(InList(["o'brien@x.test", 7])).toBe("'o''brien@x.test','7'");
    });

    it('UuidInList quotes only values that already passed RequireUUID', () => {
        expect(UuidInList([GOOD], 'ActivitySyncRuleSetID')).toBe(`'${GOOD}'`);
        expect(() => UuidInList([GOOD, "' OR 1=1 --"], 'ActivitySyncRuleSetID')).toThrow(
            InvalidFilterInputError,
        );
    });
});

describe('ExtraFilter call sites', () => {
    it('engine ID filters go through RequireUUID / UuidInList, not quote-doubling', () => {
        const source = readFileSync(join(SRC, 'ActivitySyncEngine.ts'), 'utf8');
        expect(source).toMatch(/RequireUUID\(id, 'ActivitySyncConnectionID'\)/);
        expect(source).toMatch(/RequireUUID\(id, 'ActivitySyncProviderTypeID'\)/);
        expect(source).toMatch(/UuidInList\(setIds, 'ActivitySyncRuleSetID'\)/);
        expect(source).not.toMatch(/EscapeText\(id\)/);
        expect(source).not.toMatch(/EscapeSql/);
    });

    it('inbound addresses go through InList / EscapeText', () => {
        const source = readFileSync(join(SRC, 'identity.ts'), 'utf8');
        expect(source).toMatch(/InList\(addresses\)/);
        expect(source).not.toMatch(/EscapeSql/);
    });
});
