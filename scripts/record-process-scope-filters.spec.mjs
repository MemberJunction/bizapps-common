/**
 * Guards the ScopeFilter of every record process under metadata/record-processes (#324).
 *
 * MJ applies a ScopeFilter as an ExtraFilter on the entity's base view with no table alias, so a
 * subquery cannot qualify the outer row. A bare `ID` inside a subquery binds to the inner table's
 * own ID column when it has one, which silently turns a correlation into `inner.X = inner.ID`.
 * Filters must reach the outer ID from outside the subquery instead (for example `ID NOT IN (...)`).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PROCESS_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'metadata', 'record-processes');

/** Returns the text of each `(SELECT ...)` subquery, matched by balanced parentheses. */
export function subqueries(filter) {
    const found = [];
    const opener = /\(\s*SELECT\b/gi;
    let match;
    while ((match = opener.exec(filter)) !== null) {
        let depth = 0;
        for (let i = match.index; i < filter.length; i++) {
            if (filter[i] === '(') depth++;
            if (filter[i] === ')' && --depth === 0) {
                found.push(filter.slice(match.index + 1, i));
                break;
            }
        }
    }
    return found;
}

/** True when the text uses `ID` as a bare column, not qualified (`x.ID`) or bracketed. */
export function hasBareId(sql) {
    return /(?<![.\w[])ID(?![\w\]])/.test(sql);
}

function scopeFilters() {
    return readdirSync(PROCESS_DIR)
        .filter((name) => name.endsWith('.json') && name !== '.mj-sync.json')
        .flatMap((name) => {
            const records = JSON.parse(readFileSync(path.join(PROCESS_DIR, name), 'utf8'));
            return records
                .filter((r) => typeof r.fields?.ScopeFilter === 'string')
                .map((r) => ({ name: r.fields.Name, filter: r.fields.ScopeFilter }));
        });
}

test('the bare-ID check catches an unqualified correlation and passes qualified ones', () => {
    const broken = 'X IS NULL OR NOT EXISTS (SELECT 1 FROM [s].[vwT] t WHERE t.PersonID = ID)';
    assert.deepEqual(subqueries(broken).map(hasBareId), [true]);
    assert.deepEqual(subqueries('ID NOT IN (SELECT PersonID FROM [s].[vwT])').map(hasBareId), [false]);
    assert.equal(hasBareId('t.ID = PersonID AND [ID] = SeniorityLevelID'), false);
});

test('no record-process ScopeFilter references a bare ID inside a subquery', () => {
    const offenders = scopeFilters().filter(({ filter }) => subqueries(filter).some(hasBareId));
    assert.deepEqual(offenders, []);
});
