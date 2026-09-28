import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const HARNESS = path.join(HERE, 'mutate-checks.mjs');

// ── pkg-1: an unrecognized ID or flag must fail loudly, not report a vacuous pass ──────────────
//
// Fails until mutate-checks.mjs validates `wanted` against PRODUCT's known ids instead of
// silently filtering `selected` down to zero entries and printing "0 mutant(s) proved their
// checks can fail." with exit 0. Arg validation happens before any mutation, so these never touch
// vitest or the real source tree.

test('an unrecognized mutant ID fails non-zero and names it', () => {
    const result = spawnSync(process.execPath, [HARNESS, 'BOGUS-ID-TYPO'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0, `expected non-zero exit; got ${result.status}. stdout: ${result.stdout}`);
    assert.match(result.stderr, /BOGUS-ID-TYPO/);
});

test('an unrecognized flag fails non-zero and names it', () => {
    const result = spawnSync(process.execPath, [HARNESS, '--help'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0, `expected non-zero exit; got ${result.status}. stdout: ${result.stdout}`);
    assert.match(result.stderr, /--help/);
});

test('zero selected mutants never exits 0 -- a fully bogus arg list must fail', () => {
    const result = spawnSync(process.execPath, [HARNESS, 'BOGUS-1', 'BOGUS-2'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /BOGUS-1/);
    assert.match(result.stderr, /BOGUS-2/);
});

test('a real mutant ID mixed with a bogus one is still rejected and names only the bogus one', () => {
    const result = spawnSync(process.execPath, [HARNESS, 'M-LMP1', 'BOGUS-ID-TYPO'], { encoding: 'utf8' });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /BOGUS-ID-TYPO/);
    assert.doesNotMatch(result.stderr, /^M-LMP1 /m);
});

test('--list and --check-anchors are unaffected by the new validation', () => {
    const list = spawnSync(process.execPath, [HARNESS, '--list'], { encoding: 'utf8' });
    assert.equal(list.status, 0, list.stderr);
    assert.match(list.stdout, /M-LMP1/);

    const anchors = spawnSync(process.execPath, [HARNESS, '--check-anchors'], { encoding: 'utf8' });
    assert.equal(anchors.status, 0, anchors.stderr);
});
