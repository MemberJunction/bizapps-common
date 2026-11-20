/**
 * The `--mj-*` token check (#299): unknown names are reported with or without a fallback, the allowlist
 * must match the Angular package's MJ floor, and this repo's own styles use only defined tokens.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mjFloor, unknownTokenUses, scanRepo } from './check-mj-tokens.mjs';

const KNOWN = new Set(['--mj-bg-surface', '--mj-text-primary']);

test('a defined token passes', () => {
    assert.deepEqual(unknownTokenUses('color: var(--mj-text-primary);', KNOWN), []);
});

test('an undefined token is reported with its line', () => {
    assert.deepEqual(unknownTokenUses('a {}\nbackground: var(--mj-bg-hover);', KNOWN), [
        { line: 2, name: '--mj-bg-hover' },
    ]);
});

test('a fallback does not make an undefined token acceptable', () => {
    assert.deepEqual(unknownTokenUses('font-family: var(--mj-font-mono, monospace);', KNOWN), [
        { line: 1, name: '--mj-font-mono' },
    ]);
});

test('a defined token used as a fallback name is not confused with the outer one', () => {
    assert.deepEqual(unknownTokenUses('color: var(--mj-text-primary, var(--mj-nope));', KNOWN), [
        { line: 1, name: '--mj-nope' },
    ]);
});

test('the floor is read from a caret range or an exact version', () => {
    assert.equal(mjFloor('^6.1.5'), '6.1.5');
    assert.equal(mjFloor('6.2.0'), '6.2.0');
    assert.throws(() => mjFloor('~6.1.5'));
    assert.throws(() => mjFloor(undefined));
});

test('packages/Angular uses only tokens MemberJunction defines', () => {
    const { violations, emptyRoots } = scanRepo();
    assert.deepEqual(emptyRoots, []);
    assert.deepEqual(violations, []);
});
