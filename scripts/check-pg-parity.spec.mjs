import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  stripNonExecutable,
  isHollow,
  findForbidden,
  findUnported,
  checkPgParity,
} from './check-pg-parity.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..');

function withTempWorkspace(fn) {
  const root = mkdtempSync(join(tmpdir(), 'pg-parity-'));
  mkdirSync(join(root, 'migrations'), { recursive: true });
  mkdirSync(join(root, 'migrations-pg'), { recursive: true });
  try {
    return fn(root);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

describe('stripNonExecutable & isHollow', () => {
  it('flags files that carry the converter gap banner and have no executable body left as hollow', () => {
    const content = `
      -- CONVERSION GAPS — resolve before relying on this migration
      -- 1 statement(s) UNHANDLED BY THE AST TRANSPILER
      CREATE EXTENSION IF NOT EXISTS "pgcrypto";
      CREATE SCHEMA IF NOT EXISTS "__mj_BizAppsCommon";
      SET search_path TO "__mj_BizAppsCommon", "__mj", public;
      SET standard_conforming_strings = on;
    `;
    assert.equal(isHollow(content), true);
  });

  it('does not flag files with real DDL or DML statements even if the gap banner is present', () => {
    const content = `
      -- CONVERSION GAPS — resolve before relying on this migration
      SET search_path TO "__mj_BizAppsCommon", "__mj", public;
      ALTER TABLE "__mj_BizAppsCommon"."Person" ADD COLUMN "Nickname" VARCHAR(100) NULL;
    `;
    assert.equal(isHollow(content), false);
  });

  it('ignores SQL keywords that appear only inside string literals or dollar-quoted strings', () => {
    const stripped = stripNonExecutable(`SELECT 'EXEC sp_foo' AS msg;`);
    assert.ok(!stripped.includes('EXEC'));
  });
});

describe('findForbidden', () => {
  it('catches bracket-quoted identifiers outside comments and strings', () => {
    const hits = findForbidden(`SELECT [ID] FROM "__mj_BizAppsCommon"."Person";`);
    assert.ok(hits.some((h) => h.name.includes('bracket-quoted')));
  });

  it('ignores Postgres array subscripts like arr[1] or text[]', () => {
    const hits = findForbidden(`SELECT tags[1], ARRAY['a']::text[] FROM "__mj_BizAppsCommon"."Person";`);
    assert.equal(hits.length, 0);
  });

  it('catches GO batch separators, EXEC, DECLARE @var, THROW, converter failure markers, and quoted T-SQL builtins', () => {
    const sql = [
      '-- Could not parse: EXEC something',
      'DECLARE @v INT;',
      'EXEC sp_addextendedproperty;',
      'THROW 50001, \'boom\', 1;',
      'SELECT "JSON_MODIFY"(doc, \'$.a\', 1);',
      'GO',
    ].join('\n');
    const names = findForbidden(sql).map((h) => h.name);
    assert.ok(names.includes('converter failure marker'));
    assert.ok(names.includes('T-SQL variable declaration'));
    assert.ok(names.includes('EXEC of a stored procedure'));
    assert.ok(names.includes('THROW'));
    assert.ok(names.includes('untranslated T-SQL builtin'));
    assert.ok(names.includes('GO batch separator'));
  });
});

describe('findUnported & checkPgParity', () => {
  it('flags an unported SQL Server migration not in .pg-parity-allow.json', () => {
    withTempWorkspace((root) => {
      writeFileSync(
        join(root, 'migrations', 'V202610150000__v5.53.x__New_Migration.sql'),
        'ALTER TABLE [__mj_BizAppsCommon].[Person] ADD [Foo] INT NULL;\n',
      );
      const res = checkPgParity({ root, schema: '__mj_BizAppsCommon' });
      assert.equal(res.ok, false);
      assert.equal(res.problems.length, 1);
      assert.equal(res.problems[0].kind, 'unported');
      assert.equal(
        res.problems[0].file,
        'migrations/V202610150000__v5.53.x__New_Migration.sql',
      );
    });
  });

  it('respects .pg-parity-allow.json for legacy pre-cutoff migrations and flags newly added ones', () => {
    withTempWorkspace((root) => {
      writeFileSync(
        join(root, 'migrations', 'V202609010000__v5.38.x__Legacy.sql'),
        'ALTER TABLE [__mj_BizAppsCommon].[Person] ADD [OldCol] INT NULL;\n',
      );
      writeFileSync(
        join(root, 'migrations-pg', '.pg-parity-allow.json'),
        JSON.stringify({ unported: ['V202609010000__v5.38.x__Legacy.sql'] }),
      );
      const clean = checkPgParity({ root, schema: '__mj_BizAppsCommon' });
      assert.equal(clean.ok, true);

      writeFileSync(
        join(root, 'migrations', 'V202610150000__v5.53.x__Fresh.sql'),
        'ALTER TABLE [__mj_BizAppsCommon].[Person] ADD [NewCol] INT NULL;\n',
      );
      const dirty = checkPgParity({ root, schema: '__mj_BizAppsCommon' });
      assert.equal(dirty.ok, false);
      assert.equal(dirty.problems.length, 1);
      assert.equal(dirty.problems[0].file, 'migrations/V202610150000__v5.53.x__Fresh.sql');
    });
  });

  it('passes against the repository migrations/ and migrations-pg/ directories', () => {
    const res = checkPgParity({ root: REPO_ROOT, schema: '__mj_BizAppsCommon' });
    assert.equal(res.ok, true, JSON.stringify(res.problems, null, 2));
  });
});
