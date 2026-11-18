// Regression tests for scripts/check-against-published-mj.mjs (#315, tooling-4).
import { describe, it, test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, lstatSync, mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  ensurePublishedTarballs,
  classifyDiagnostics,
  judgePackage,
} from './check-against-published-mj.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = join(HERE, 'check-against-published-mj.mjs');

// tooling-4: an explicit target argument that doesn't exist crashed with a raw Node ENOENT
// stack trace, even though the script's own usage doc shows exactly this argument form.
test('check-against-published-mj.mjs reports a clear error for a nonexistent explicit target', () => {
  const result = spawnSync(process.execPath, [SCRIPT, 'packages/DoesNotExist'], { encoding: 'utf8' });

  assert.notEqual(result.status, 0, 'expected a non-zero exit code');
  const output = result.stdout + result.stderr;
  assert.match(output, /no such package.*packages\/DoesNotExist/i, `expected a clear message, got:\n${output}`);
  assert.doesNotMatch(output, /\n\s+at /, `expected no raw stack trace, got:\n${output}`);
});

describe('ensurePublishedTarballs (#315)', () => {
  it('symlinks non-MJ third-party packages from .pnpm/node_modules and node_modules while excluding @memberjunction', () => {
    const tmp = mkdtempSync(join(tmpdir(), 'published-mj-test-'));
    try {
      const fakeWorkspace = join(tmp, 'workspace');
      const fakeRepo = join(fakeWorkspace, 'repo');
      const fakeCache = join(fakeRepo, 'node_modules', '.cache', 'published-mj');

      const pnpmNm = join(fakeWorkspace, 'node_modules', '.pnpm', 'node_modules');
      mkdirSync(join(pnpmNm, 'type-graphql'), { recursive: true });
      writeFileSync(join(pnpmNm, 'type-graphql', 'package.json'), '{"name":"type-graphql"}');
      mkdirSync(join(pnpmNm, '@angular', 'core'), { recursive: true });
      writeFileSync(join(pnpmNm, '@angular', 'core', 'package.json'), '{"name":"@angular/core"}');
      mkdirSync(join(pnpmNm, '@memberjunction', 'server'), { recursive: true });
      writeFileSync(join(pnpmNm, '@memberjunction', 'server', 'package.json'), '{"name":"@memberjunction/server"}');

      const nmRoot = ensurePublishedTarballs(fakeCache, [fakeRepo]);

      assert.ok(lstatSync(join(nmRoot, 'type-graphql')).isSymbolicLink(), 'expected type-graphql symlink in cache node_modules');
      assert.ok(lstatSync(join(nmRoot, '@angular', 'core')).isSymbolicLink(), 'expected @angular/core symlink in cache node_modules');
      assert.equal(
        existsSync(join(nmRoot, '@memberjunction')),
        false,
        'must not expose workspace @memberjunction packages inside cache node_modules',
      );
    } finally {
      rmSync(tmp, { recursive: true, force: true });
    }
  });
});

describe('classifyDiagnostics & judgePackage (#315)', () => {
  it('filters out diagnostics inside .cache and node_modules while keeping own-package errors', () => {
    const raw = [
      'node_modules/.cache/published-mj/@memberjunction__server/6.1.0/package/src/index.ts(4,15): error TS2307: Cannot find module \'express\'.',
      'src/custom/attach-address.action.ts(332,85): error TS2339: Property \'ID\' does not exist on type \'AddressFieldsInput\'.',
    ].join('\n');

    const classified = classifyDiagnostics(raw, ['@memberjunction/server (types: ./src/index.ts)']);
    assert.equal(classified.mine.length, 1);
    assert.equal(classified.ownErrors.length, 1);
    assert.match(classified.ownErrors[0], /attach-address\.action\.ts.*TS2339/);

    // Even though sourceTyped is non-empty, a real error in our own code must fail, not short-circuit to inconclusive!
    const verdict = judgePackage(classified, {
      fetched: ['@memberjunction/server@6.1.0'],
      unresolvable: [],
      sourceTyped: ['@memberjunction/server (types: ./src/index.ts)'],
    });
    assert.equal(verdict, 'failed');
  });

  it('returns ok when a package compiles with 0 own errors even if a dependency is sourceTyped', () => {
    const classified = classifyDiagnostics('', ['@memberjunction/server (types: ./src/index.ts)']);
    const verdict = judgePackage(classified, {
      fetched: ['@memberjunction/server@6.1.0'],
      unresolvable: [],
      sourceTyped: ['@memberjunction/server (types: ./src/index.ts)'],
    });
    assert.equal(verdict, 'ok');
  });

  it('returns inconclusive only when the sole own-file errors are cascades from an unresolved module inside a sourceTyped dependency', () => {
    const raw = [
      'node_modules/.cache/published-mj/@memberjunction__server/6.1.0/package/src/index.ts(1,1): error TS2307: Cannot find module \'type-graphql\'.',
      'src/generated/graphql-schemas/__mj_BizAppsCommon.ts(10,10): error TS2305: Module \'"@memberjunction/server"\' has no exported member \'Arg\'.',
    ].join('\n');

    const classified = classifyDiagnostics(raw, ['@memberjunction/server (types: ./src/index.ts)']);
    assert.equal(classified.ownErrors.length, 0);
    assert.equal(classified.sourceTypedCascade.length, 1);

    const verdict = judgePackage(classified, {
      fetched: ['@memberjunction/server@6.1.0'],
      unresolvable: [],
      sourceTyped: ['@memberjunction/server (types: ./src/index.ts)'],
    });
    assert.equal(verdict, 'inconclusive');
  });
});
