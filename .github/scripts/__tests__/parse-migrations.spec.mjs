import { test } from 'node:test';
import assert from 'node:assert/strict';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { listMigrationFiles } from '../parse-migrations.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));

// gh-3. Fails today: listMigrationFiles is a bare `readdirSync(absDir).filter(...).sort()` with no
// try/catch, so a missing/mistyped --dir throws Node's raw ENOENT Error (code 'ENOENT', no mention
// of the --dir value the caller passed) instead of a descriptive, actionable message. Fixed by
// wrapping the readdirSync call and throwing a new Error that names dirArg and absDir.
test('a missing directory throws a descriptive error, not a raw ENOENT', () => {
    const missing = join(HERE, 'does-not-exist-fixture-dir');

    assert.throws(
        () => listMigrationFiles(missing, '--dir value from the caller'),
        (err) => {
            assert.notEqual(err.code, 'ENOENT', 'must not be the raw fs error');
            assert.match(err.message, /--dir value from the caller/, 'must name the --dir value the caller passed');
            assert.match(err.message, new RegExp(missing.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), 'must name the resolved path');
            return true;
        },
    );
});
