/**
 * Mutation driver for @mj-biz-apps/common-server.
 *
 * WHY THIS FILE EXISTS. `LoadLiveMailboxPolicyFromEnv` is the single most consequential function in
 * this package: it is what turns on reading real mailboxes, and app-only `Mail.Read` reads EVERY
 * mailbox in the tenant. It had 40 tests and no permanent mutation check, so nothing said whether
 * those tests could fail. They could not, for two of its guards — deleting the mutual-exclusion
 * check and deleting the neither-decision check both left all 40 green.
 *
 * That is the same shape as everything else this branch was opened to remove: a check that documents
 * its own purpose and has no reader. A suite that cannot fail is not evidence, and the gate is
 * exactly where being wrong about that is worst.
 *
 * Restores from a copy, not git, so a dirty tree is safe.
 *
 *   node test-harnesses/mutate-checks.mjs
 *   node test-harnesses/mutate-checks.mjs M-LMP3
 */
import { execSync } from 'node:child_process';
import { copyFileSync, readFileSync, writeFileSync, rmSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const PKG = join(dirname(fileURLToPath(import.meta.url)), '..');

const POLICY = 'src/custom/live-mailbox-policy.ts';

const PRODUCT = [
    /**
     * NOT OPTED IN IS SILENT; PARTIALLY OPTED IN IS NOT. Collapsing the two in either direction is a
     * real failure: a noisy no-op on every unconfigured host, or a half-written opt-in that stays off
     * and sends an operator hunting through Exchange for a fault that is in their .env.
     */
    {
        id: 'M-LMP1',
        file: POLICY,
        expect: ['stays refused on an empty environment, without complaining'],
        from: '    if (present.length === 0) {',
        to: '    if (false) {',
    },
    {
        id: 'M-LMP2',
        file: POLICY,
        expect: ['throws when'],
        from: '    if (missingAlways.length > 0) {',
        to: '    if (false) {',
    },
    /**
     * THE TWO DECISIONS. Both of these survived before the tests beside them existed, which is how
     * they came to be written.
     */
    {
        id: 'M-LMP3',
        file: POLICY,
        expect: ['refuses a host that claims BOTH a group and an accepted tenant-wide risk'],
        from: '    if (group && acceptedRisk) {',
        to: '    if (false) {',
    },
    {
        id: 'M-LMP4',
        file: POLICY,
        expect: ['refuses a host that names a person and a date but neither decision'],
        from: '    if (!group && !acceptedRisk) {',
        to: '    if (false) {',
    },
    /**
     * The DISCRIMINANT, not the value. An earlier version of this mutant rewrote the true branch to
     * `group || acceptedRisk`, which is inert inside a `group ? ...` ternary -- it survived by being
     * a no-op rather than by escaping a check. This one files a knowingly-unrestricted tenant as a
     * restricted one, which is the way round that actually matters: it would make an audit read
     * "scoped to a group" where nobody scoped anything.
     */
    {
        id: 'M-LMP5',
        file: POLICY,
        expect: ['records an accepted tenant-wide grant as tenant-wide'],
        from: "            : { ...common, Scope: 'TenantWideAccepted', AcceptedRisk: acceptedRisk },",
        to: "            : { ...common, Scope: 'RestrictedToGroup', ScopedToGroup: acceptedRisk },",
    },
    /** A date nobody can read is not a date. `ConfirmedAt` exists so staleness is visible. */
    {
        id: 'M-LMP6',
        file: POLICY,
        expect: ['rejects a confirmation date that is not a date'],
        from: '    if (Number.isNaN(confirmedAt.getTime())) {',
        to: '    if (false) {',
    },
    /** Blank is not "set". An empty var in a .env template must never read as an opt-in. */
    {
        id: 'M-LMP7',
        file: POLICY,
        expect: ['treats blank and whitespace-only variables as absent'],
        from: "    const set = (k: string) => (env[k] ?? '').trim();",
        to: "    const set = (k: string) => env[k] ?? '';",
    },
    /**
     * SAYING IT OUT LOUD IS PART OF THE FEATURE. Without the bootstrap line the attestation is
     * written and read by nothing, which is the defect this whole branch is about.
     */
    {
        id: 'M-LMP8',
        file: POLICY,
        expect: ['enabling live fetch is announced at bootstrap'],
        from: '    LogStatus(',
        to: '    (() => undefined)(',
    },
];

function runVitest() {
    return execSync('npx vitest run', { cwd: PKG, encoding: 'utf8', stdio: 'pipe' });
}

const wanted = process.argv.slice(2);
if (wanted.includes('--list')) {
    for (const m of PRODUCT) console.log(`${m.id}  ${m.file}  expect: ${m.expect.join(', ')}`);
    process.exit(0);
}

const selected = wanted.length ? PRODUCT.filter((m) => wanted.includes(m.id)) : PRODUCT;
let failed = 0;

for (const m of selected) {
    const dir = mkdtempSync(join(tmpdir(), `mut-${m.id}-`));
    const backup = join(dir, 'backup');
    const full = join(PKG, m.file);
    copyFileSync(full, backup);
    const original = readFileSync(full, 'utf8');
    const count = original.split(m.from).length - 1;
    if (count !== 1) {
        copyFileSync(backup, full);
        rmSync(dir, { recursive: true, force: true });
        console.error(`SKIP ${m.id}: anchor matched ${count} times in ${m.file}`);
        failed++;
        continue;
    }
    writeFileSync(full, original.replace(m.from, m.to));
    let output = '';
    let threw = false;
    try {
        output = runVitest();
    } catch (err) {
        threw = true;
        output = `${err.stdout ?? ''}${err.stderr ?? ''}`;
    }
    copyFileSync(backup, full);
    const restored = readFileSync(full, 'utf8');
    if (restored !== original) {
        writeFileSync(full, original);
        console.error(`FAIL ${m.id}: restore did not match the copy`);
        failed++;
        rmSync(dir, { recursive: true, force: true });
        continue;
    }
    rmSync(dir, { recursive: true, force: true });

    if (!threw) {
        console.error(`FAIL ${m.id}: suite stayed green`);
        failed++;
        continue;
    }
    const missing = m.expect.filter((name) => !output.includes(name));
    if (missing.length) {
        console.error(`FAIL ${m.id}: failed but did not name ${missing.join(', ')}`);
        failed++;
        continue;
    }
    console.log(`OK   ${m.id}: felled ${m.expect.join(', ')}`);
}

if (failed > 0) {
    console.error(`\n${failed} mutant(s) did not prove their check.`);
    process.exit(1);
}
console.log(`\n${selected.length} mutant(s) proved their checks can fail.`);
