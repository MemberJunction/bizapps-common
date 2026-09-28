// Regression test for scripts/pg-objectmodel-test.mjs's failure-reporting path.
//
// Spawns the real script against a definitely-closed local port so `pg` fails fast (no real
// Postgres, no network beyond an immediately-refused loopback connection). PGPASSWORD is
// required by the script's own guard, so a dummy value is supplied; no credentials leave the
// machine because the connection never completes.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createServer } from 'node:net';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = join(HERE, 'pg-objectmodel-test.mjs');

// Strip any PGHOST/PGPORT the ambient environment happens to carry, so each test's override is
// the only thing in effect and the script's own `?? 'localhost'` / `?? 5433` defaults apply.
const { PGHOST: _pgHost, PGPORT: _pgPort, ...BASE_ENV } = process.env;

/**
 * A TCP port that nothing is listening on, so `pg` gets an immediate ECONNREFUSED. Bound on all
 * interfaces (no host argument) and then closed, so it is free on both the IPv4 and IPv6 loopback
 * addresses `pg` tries when PGHOST is left at the script's default ('localhost') -- that dual-stack
 * attempt is what produces the AggregateError this test targets.
 */
async function closedPort() {
  const srv = createServer();
  await new Promise((resolve, reject) => {
    srv.once('error', reject);
    srv.listen(0, resolve);
  });
  const { port } = srv.address();
  await new Promise((resolve) => srv.close(resolve));
  return port;
}

// tooling-1: pg's Pool throws an AggregateError whose own `.message` is "" when a dual-stack
// connection is refused; the real reason lives in `.errors`. Fails without the fix because
// `main().catch((e) => ... e.message)` prints a blank reason ("  ✗ EXCEPTION — ").
test('pg-objectmodel-test.mjs surfaces the inner AggregateError reasons, not a blank message', async () => {
  const port = await closedPort();
  const result = spawnSync(process.execPath, [SCRIPT], {
    encoding: 'utf8',
    env: { ...BASE_ENV, PGPASSWORD: 'dummy', PGPORT: String(port) },
  });

  const exceptionLine = result.stdout.split('\n').find((l) => l.includes('EXCEPTION'));
  assert.ok(exceptionLine, `expected an EXCEPTION line in stdout:\n${result.stdout}`);
  assert.doesNotMatch(
    exceptionLine,
    /EXCEPTION — \s*$/,
    `expected a non-blank reason after "EXCEPTION —", got: ${JSON.stringify(exceptionLine)}`,
  );
  assert.match(exceptionLine, /ECONNREFUSED/, `expected the real connection failure reason, got: ${exceptionLine}`);
});
