// Regression test for scripts/pg-finalize.mjs's handling of a missing migrations-pg/ directory.
//
// pg-finalize.mjs rewrites files under migrations-pg/ in place, so this test must never point it
// at the real repo directory. It uses the PG_FINALIZE_DIR env var seam to point the script at a
// directory that does not exist, in a temp path -- nothing in the real repo is read or written.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = join(HERE, 'pg-finalize.mjs');

// tooling-7: a missing migrations-pg/ directory crashed with a raw ENOENT stack trace from
// readdirSync(PG_DIR). Fails without the fix because the process dies with an uncaught-exception
// stack trace instead of a clear message.
test('pg-finalize.mjs reports a clear error when its migrations directory is missing', () => {
  const root = mkdtempSync(join(tmpdir(), 'bac-pg-finalize-nodir-'));
  const missingDir = join(root, 'migrations-pg'); // deliberately never created
  try {
    const result = spawnSync(process.execPath, [SCRIPT], {
      encoding: 'utf8',
      env: { ...process.env, PG_FINALIZE_DIR: missingDir },
    });

    assert.notEqual(result.status, 0, 'expected a non-zero exit code');
    const output = result.stdout + result.stderr;
    assert.match(output, /migrations-pg.*not found|no such.*migrations-pg/i, `expected a clear message, got:\n${output}`);
    assert.doesNotMatch(output, /\n\s+at /, `expected no raw stack trace, got:\n${output}`);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
