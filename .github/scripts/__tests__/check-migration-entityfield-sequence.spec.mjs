import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = join(HERE, '..', 'check-migration-entityfield-sequence.mjs');

/** A standalone repo with one commit and no `origin/next` (or anything BASE_REF could default to). */
function repoWithUnresolvableBaseRef() {
    const dir = mkdtempSync(join(tmpdir(), 'ef-sequence-'));
    execFileSync('git', ['init', '-q'], { cwd: dir });
    execFileSync('git', ['config', 'user.email', 'test@test.com'], { cwd: dir });
    execFileSync('git', ['config', 'user.name', 'Test'], { cwd: dir });
    execFileSync('git', ['commit', '-q', '--allow-empty', '-m', 'init'], { cwd: dir });
    return dir;
}

// Fails today: main() (around line 397) calls `git(['merge-base', process.env.BASE_REF ||
// 'origin/next', 'HEAD'])` with no try/catch, so an unresolved ref throws a raw, unhandled
// "Command failed: git ... merge-base" Error with a full JS stack trace instead of a clean
// message -- gh-2. Fixed by giving it the same clean, non-zero failure as gh-1.
test('local form fails cleanly (no raw stack trace), naming the ref, when BASE_REF/origin/next does not resolve', () => {
    const dir = repoWithUnresolvableBaseRef();
    const result = spawnSync(process.execPath, [SCRIPT], { cwd: dir, encoding: 'utf8' });

    assert.notEqual(result.status, 0, 'an unresolved base ref must not be treated as success');
    assert.doesNotMatch(result.stderr, /at file:\/\//, 'must not leak a raw JS stack trace');
    assert.doesNotMatch(result.stderr, /node:internal/, 'must not leak a raw JS stack trace');
    assert.match(result.stdout, /origin\/next/, 'must name the unresolved ref');
    assert.match(result.stdout, /BASE_REF/, 'must say how to fix it (fetch the ref, or set BASE_REF)');
});
