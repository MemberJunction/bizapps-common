/**
 * Client-transport dispatcher for BizApps Common.
 *
 * Bootstraps GraphQLDataProvider against a running MJAPI (GRAPHQL_PORT / MJ_API_KEY),
 * then runs registered IntegrationCheckRegistry bundles. Nothing talks to SQL
 * directly — every Save / RunView / Delete goes across the wire.
 *
 *   node test-harnesses/integration.mjs
 *   node test-harnesses/integration.mjs people
 *   node test-harnesses/integration.mjs people.P1
 */
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

const here = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(here, '..', '.env'), quiet: true });
dotenv.config({ path: path.resolve(here, '../../MJ/.env'), quiet: true });

process.env.MJ_INTEGRATION_TEST = '1';
process.env.RUN_MUTATION_TESTS = process.env.RUN_MUTATION_TESTS ?? '1';

const ALL_BUNDLES = [
    'common-world',
    'people',
    'organizations',
    'contacts-addresses',
    'relationships',
    'activities',
];

const args = process.argv.slice(2);
const only = args.filter((a) => !a.startsWith('-'));

const { bootstrapIntegrationClient } = await import('@memberjunction/testing-integration/client');
const { Metadata } = await import('@memberjunction/core');
const { IntegrationCheckRegistry } = await import('@memberjunction/testing-integration/registry');

await bootstrapIntegrationClient();
await import('../packages/IntegrationTests/dist/index.js');

const provider = Metadata.Provider;
const user = provider.CurrentUser;
if (!user) {
    throw new Error('GraphQL provider has no CurrentUser — check MJ_API_KEY and that MJAPI is running.');
}

const ctx = {
    User: user,
    Provider: provider,
    Schema: process.env.MJ_CORE_SCHEMA || '__mj',
    Storage: undefined,
};

const registry = IntegrationCheckRegistry.Instance;
const requested = only.length ? only : ALL_BUNDLES;
let pass = 0;
let fail = 0;
const failures = [];

console.log(`\n  Common integration (GraphQL → ${process.env.MJAPI_URL ?? `http://localhost:${process.env.GRAPHQL_PORT ?? 4000}`})`);
console.log(`  user: ${user.Email ?? user.Name ?? user.ID}\n`);

for (const request of requested) {
    const [bundle, localId] = request.includes('.') ? request.split('.') : [request, null];
    const checks = registry.GetBundle(bundle).filter((c) => !localId || c.Id === request);
    if (checks.length === 0) {
        console.error(`  unknown bundle/check: ${request}`);
        fail += 1;
        failures.push(request);
        continue;
    }
    const life = registry.GetLifecycle(bundle);
    if (life?.Setup) await life.Setup(ctx);
    try {
        for (const check of checks) {
            const started = Date.now();
            try {
                await check.Fn(ctx);
                const ms = Date.now() - started;
                console.log(`  ok   ${check.Id.padEnd(32)} ${ms}ms  ${check.Name}`);
                pass += 1;
            } catch (err) {
                const ms = Date.now() - started;
                const message = err instanceof Error ? err.message : String(err);
                console.error(`  FAIL ${check.Id.padEnd(32)} ${ms}ms  ${message}`);
                if (process.env.IT_VERBOSE === '1' && err instanceof Error && err.stack) {
                    console.error(err.stack);
                }
                fail += 1;
                failures.push(check.Id);
            }
        }
    } finally {
        if (life?.Teardown) await life.Teardown(ctx);
    }
}

console.log(`\n  ${pass} passed / ${fail} failed\n`);
process.exit(fail === 0 ? 0 : 1);
