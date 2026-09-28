import { test } from 'node:test';
import assert from 'node:assert/strict';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { listMigrationFiles, prepareMigrationSql } from '../parse-migrations.mjs';

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

// gh-4. Fails today: prepareMigrationSql substitutes Flyway placeholders and wraps the batch, but
// never strips a leading UTF-8 BOM (a real artifact of some Windows editors / `Out-File`). SQL
// Server's own parser sees the BOM as an illegal character, not whitespace, so syntactically valid
// SQL saved with a BOM is reported as a syntax error -- a false fail that would block a PR.
// The unit under test is exactly the text-preparation step; it needs no sqlcmd/DB connection
// (that connection-requiring path -- runner.execute() actually calling out to sqlcmd -- is not
// unit-testable per this repo's test conventions, which forbid touching the network or a DB from
// a test; only the real, reachable-Docker-DB repro the smoke hunt ran can exercise it end-to-end).
test('a leading UTF-8 BOM is stripped before the SQL is wrapped for sqlcmd', () => {
    const withBom = '﻿SELECT 1 AS [Test];\n';
    const wrapped = prepareMigrationSql(withBom, { defaultSchema: '__mj_BizAppsCommon', mjSchema: '__mj' });

    assert.ok(!wrapped.includes('﻿'), 'the BOM must not appear anywhere in the text sent to sqlcmd');
    assert.match(wrapped, /^SET PARSEONLY ON;\nGO\nSELECT 1 AS \[Test\];\n\nGO\n$/);
});
