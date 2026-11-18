// Regression test for scripts/check-against-published-mj.mjs's explicit-target argument handling.
//
// Spawns the real script (read-only: it never mutates the repo, per its own docstring) with a
// package path that does not exist. Runs entirely against this checkout's own files -- no
// network call happens before the target-resolution step this test exercises.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = join(HERE, 'check-against-published-mj.mjs');

// tooling-4: an explicit target argument that doesn't exist crashed with a raw Node ENOENT
// stack trace, even though the script's own usage doc shows exactly this argument form. Fails
// without the fix because the process dies with an uncaught-exception stack trace instead of a
// clear message.
test('check-against-published-mj.mjs reports a clear error for a nonexistent explicit target', () => {
  const result = spawnSync(process.execPath, [SCRIPT, 'packages/DoesNotExist'], { encoding: 'utf8' });

  assert.notEqual(result.status, 0, 'expected a non-zero exit code');
  const output = result.stdout + result.stderr;
  assert.match(output, /no such package.*packages\/DoesNotExist/i, `expected a clear message, got:\n${output}`);
  assert.doesNotMatch(output, /\n\s+at /, `expected no raw stack trace, got:\n${output}`);
});
