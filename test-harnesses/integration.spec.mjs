// Regression test for test-harnesses/integration.mjs's "no CurrentUser" guard.
//
// integration.mjs unconditionally imports '@memberjunction/testing-integration/client',
// '@memberjunction/core', '@memberjunction/testing-integration/registry', and (relatively)
// '../packages/IntegrationTests/dist/index.js' -- none of which install in a normal checkout
// (tooling-5, a deferred packaging gap: test-harnesses/ isn't a pnpm workspace member). To reach
// the guard without a live MJAPI or those real packages, this test builds a minimal stub
// node_modules tree in a temp directory that mirrors just enough of the real repo layout for the
// script's own imports to resolve, with the stub Metadata.Provider.CurrentUser left falsy. The
// real, unmodified script file is copied in so the test exercises production code, not a
// paraphrase of it. Nothing under the real repo is read or written.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REAL_SCRIPT = join(HERE, 'integration.mjs');

/** Build a temp workspace whose only job is to let integration.mjs's own imports resolve. */
function buildStubWorkspace() {
  const root = mkdtempSync(join(tmpdir(), 'bac-integration-guard-'));
  const nm = join(root, 'node_modules');

  mkdirSync(join(nm, 'dotenv'), { recursive: true });
  writeFileSync(
    join(nm, 'dotenv', 'package.json'),
    JSON.stringify({ name: 'dotenv', version: '0.0.0-stub', main: 'index.js', type: 'commonjs' }),
  );
  writeFileSync(join(nm, 'dotenv', 'index.js'), 'module.exports = { config: () => ({ parsed: {} }) };\n');

  const coreDir = join(nm, '@memberjunction', 'core');
  mkdirSync(coreDir, { recursive: true });
  writeFileSync(
    join(coreDir, 'package.json'),
    JSON.stringify({ name: '@memberjunction/core', version: '0.0.0-stub', type: 'module', exports: { '.': './index.js' } }),
  );
  // CurrentUser is deliberately falsy: this pins the "MJAPI unreachable / bad MJ_API_KEY" case,
  // the realistic trigger for the guard this test targets.
  writeFileSync(join(coreDir, 'index.js'), 'export class Metadata {\n  static Provider = { CurrentUser: null };\n}\n');

  const tiDir = join(nm, '@memberjunction', 'testing-integration');
  mkdirSync(tiDir, { recursive: true });
  writeFileSync(
    join(tiDir, 'package.json'),
    JSON.stringify({
      name: '@memberjunction/testing-integration',
      version: '0.0.0-stub',
      type: 'module',
      exports: { './client': './client.js', './registry': './registry.js' },
    }),
  );
  writeFileSync(join(tiDir, 'client.js'), 'export async function bootstrapIntegrationClient() {}\n');
  writeFileSync(
    join(tiDir, 'registry.js'),
    'export class IntegrationCheckRegistry {\n'
      + '  static Instance = new IntegrationCheckRegistry();\n'
      + '  GetBundle() { return []; }\n'
      + '  GetLifecycle() { return undefined; }\n'
      + '}\n',
  );

  const itDist = join(root, 'packages', 'IntegrationTests', 'dist');
  mkdirSync(itDist, { recursive: true });
  writeFileSync(join(itDist, 'index.js'), 'export {};\n');

  const harnessDir = join(root, 'test-harnesses');
  mkdirSync(harnessDir, { recursive: true });
  writeFileSync(join(harnessDir, 'integration.mjs'), readFileSync(REAL_SCRIPT, 'utf8'));

  return root;
}

// tooling-6: the "no CurrentUser" guard was a bare `throw`, so it dumped Node's raw
// uncaught-exception stack trace instead of the clean console.error+exit(1) pattern its sibling
// scripts use (e.g. pg-objectmodel-test.mjs's requireEnv). Fails without the fix because stderr
// contains stack-trace frames ("    at ...").
test('integration.mjs: no-CurrentUser guard exits cleanly, without a raw stack trace', () => {
  const root = buildStubWorkspace();
  try {
    const result = spawnSync(process.execPath, [join(root, 'test-harnesses', 'integration.mjs')], {
      cwd: root,
      encoding: 'utf8',
    });

    assert.equal(result.status, 1, `expected exit 1, got ${result.status}\nstderr:\n${result.stderr}`);
    assert.match(result.stderr, /GraphQL provider has no CurrentUser/);
    assert.doesNotMatch(result.stderr, /\n\s+at /, `expected no raw stack trace in stderr:\n${result.stderr}`);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
