import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { findIDComparisons, looksLikeID, runCheck, scanText } from './check-uuid-comparisons.mjs';

// ── What the gate must catch (#314) ─────────────────────────────────────────────────────────────

test('a property ID compared to a variable ID is a violation', () => {
    assert.deepEqual(findIDComparisons('if (!connection || connection.ID !== connectionID) {'), [
        'connection.ID !== connectionID',
    ]);
});

test('an ID inside a find callback is a violation', () => {
    assert.equal(findIDComparisons('rules.Rows.find((r) => r.ID === verdict.ActivitySyncRuleID)').length, 1);
});

test('an Id-suffixed name is an ID', () => {
    assert.equal(findIDComparisons('@if (EditingId === cm.ID) {').length, 1);
});

test('optional chaining and non-null assertions do not hide the operand', () => {
    assert.equal(findIDComparisons('[class.selected]="SelectedActivity?.ID === act.ID"').length, 1);
    assert.equal(findIDComparisons('items.some(i => i.ID === rel!.ID)').length, 1);
});

test('two comparisons on one line are both reported', () => {
    assert.equal(findIDComparisons('rows.find(r => r.FromPersonID === this.PersonID || r.ToPersonID === this.PersonID)').length, 2);
});

test('loose equality between IDs is a violation', () => {
    assert.equal(findIDComparisons('if (a.PersonID == b.PersonID) {').length, 1);
    assert.equal(findIDComparisons('if (a.PersonID != b.PersonID) {').length, 1);
});

test('an identifier that only starts with null, undefined, true or false is not a literal', () => {
    for (const line of [
        'if (a.PersonID === nullableID) {',
        'if (a.PersonID === undefinedOrID) {',
        'if (a.PersonID === trueOwnerID) {',
        'if (a.PersonID === falseMatchID) {',
    ]) {
        assert.equal(findIDComparisons(line).length, 1, line);
    }
});

test('a Map, Set or array lookup keyed by a row ID field is a violation', () => {
    for (const line of [
        'const list = byMethod.get(consent.ContactMethodID) ?? [];',
        'byMethod.set(row.ID, list);',
        'if (seen.has(rel.ToPersonID)) continue;',
        'cache.delete(cm.ID);',
        'if (ids.includes(row?.LinkedUserID)) {',
    ]) {
        assert.equal(findIDComparisons(line).length, 1, line);
    }
});

test('a lookup keyed by NormalizeUUID, a local or a this. member is not flagged', () => {
    for (const line of [
        'byMethod.get(NormalizeUUID(consent.ContactMethodID));',
        'nodeMap.has(sourceId);',
        'nodeMap.set(this.FocalNodeID!, node);',
        "params.get('recordID');",
    ]) {
        assert.deepEqual(findIDComparisons(line), [], line);
    }
});

// ── What the gate must let through ──────────────────────────────────────────────────────────────

test('a comparison against a literal is not an ID comparison', () => {
    for (const line of [
        'if (encryptionKeyID === null) {',
        'if (recordID !== undefined) {',
        "const label = pageId === 'organizations' ? 'a' : 'b';",
        'if (rowID === 0) {',
        '@if (!ShowAddForm && EditingId === null && EditMode) {',
    ]) {
        assert.deepEqual(findIDComparisons(line), [], line);
    }
});

test('a typeof test is not an ID comparison', () => {
    assert.deepEqual(findIDComparisons("RecordID: typeof item.RecordID === 'string' ? item.RecordID : undefined,"), []);
});

test('UUIDsEqual is not flagged', () => {
    assert.deepEqual(findIDComparisons('rules.Rows.find((r) => UUIDsEqual(r.ID, verdict.ActivitySyncRuleID))'), []);
});

test('a lower-case id is a UI slug, not a record ID', () => {
    assert.deepEqual(findIDComparisons('[class.active]="ActiveTypeFilter === chip.id"'), []);
    assert.equal(looksLikeID('chip.id'), false);
});

test('names that only contain the letters are not IDs', () => {
    assert.equal(looksLikeID('isValid'), false);
    assert.equal(looksLikeID('Identity'), false);
    assert.equal(looksLikeID('row.Grid'), false);
});

test('the marker on the line or the one above exempts it', () => {
    assert.deepEqual(findIDComparisons('a.ExternalID === b.ExternalID // uuid-compare-ok: provider ids are case-sensitive'), []);
    assert.deepEqual(scanText('// uuid-compare-ok: provider ids are case-sensitive\nif (a.ExternalID === b.ExternalID) {}\n'), []);
});

test('scanText reports one-based line numbers', () => {
    assert.deepEqual(scanText('const x = 1;\nif (a.ID === b.ID) {}\n'), [{ line: 2, comparison: 'a.ID === b.ID' }]);
});

// ── The walk ────────────────────────────────────────────────────────────────────────────────────

test('runCheck scans package src and skips generated code and tests', () => {
    const root = mkdtempSync(join(tmpdir(), 'uuid-cmp-'));
    try {
        const src = join(root, 'packages', 'Pkg', 'src');
        for (const dir of ['generated', '__tests__', 'lib']) mkdirSync(join(src, dir), { recursive: true });
        const bad = 'if (a.ID === b.ID) {}\n';
        writeFileSync(join(src, 'lib', 'bad.ts'), bad);
        writeFileSync(join(src, 'lib', 'bad.component.html'), '@if (EditingId === cm.ID) {}\n');
        writeFileSync(join(src, 'lib', 'bad.test.ts'), bad);
        writeFileSync(join(src, 'generated', 'entity.ts'), bad);
        writeFileSync(join(src, '__tests__', 'fixture.ts'), bad);

        const files = runCheck(root).map((v) => v.file.split(/[\\/]/).pop()).sort();
        assert.deepEqual(files, ['bad.component.html', 'bad.ts']);
    } finally {
        rmSync(root, { recursive: true, force: true });
    }
});

test('this repository is clean', () => {
    assert.deepEqual(runCheck(), []);
});
