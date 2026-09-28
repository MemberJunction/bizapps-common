import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = join(HERE, '..', 'check-migration-no-prune.mjs');

/**
 * A standalone repo with no `origin/next` (or anything else `BASE_REF` could default to), one
 * commit, and a committed migration that trips the gate. This is gh-1's repro: local form, no
 * args, in a repo whose only remote lacks the ref BASE_REF defaults to.
 */
function repoWithUnresolvableBaseRefAndAViolation() {
    const dir = mkdtempSync(join(tmpdir(), 'no-prune-'));
    execFileSync('git', ['init', '-q'], { cwd: dir });
    execFileSync('git', ['config', 'user.email', 'test@test.com'], { cwd: dir });
    execFileSync('git', ['config', 'user.name', 'Test'], { cwd: dir });
    writeFileSync(
        join(dir, 'V202609281200__test.sql'),
        "EXEC [__mj].[spDeleteUnneededEntityFields] @ExcludedSchemaNames='sys,staging';\n",
    );
    execFileSync('git', ['add', '.'], { cwd: dir });
    execFileSync('git', ['commit', '-q', '-m', 'add migration'], { cwd: dir });
    return dir;
}

// Fails today: main()'s local-form branch (around line 223) has `catch { mergeBase = 'HEAD'; }`,
// which swallows the unresolved-ref error and silently diffs HEAD against itself, so the commit
// above is never scanned and the script exits 0. Fixed by replacing that catch with a loud,
// non-zero failure naming the ref -- gh-1.
test('local form fails loudly, naming the ref, when BASE_REF/origin/next does not resolve', () => {
    const dir = repoWithUnresolvableBaseRefAndAViolation();
    const result = spawnSync(process.execPath, [SCRIPT], { cwd: dir, encoding: 'utf8' });

    assert.notEqual(result.status, 0, 'must not silently pass when the base ref cannot be resolved');
    assert.match(result.stderr, /origin\/next/, 'must name the unresolved ref');
    assert.match(result.stderr, /BASE_REF/, 'must say how to fix it (fetch the ref, or set BASE_REF)');
});
