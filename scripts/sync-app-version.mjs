#!/usr/bin/env node
/**
 * Keep `mj-app.json`'s `version` and `mjVersionRange` derived from `packages/Entities/package.json`.
 *
 * In bizapps-forms this lived as an inline bash block in publish.yml, where it ran *after*
 * `changeset version` and was committed by a push straight to `main`.
 * MemberJunction/bizapps-forms#177 removed that push, so the derivation has to happen where the
 * version bump now happens — on the release pull request — and CI's job changes from performing it
 * to checking it. `--check` is that half: a hand-edited mj-app.json, or a release PR that forgot
 * `pnpm run version`, fails before anything is published. bizapps-common adopts that model from the
 * start, rather than repeating the push-to-main history that produced it.
 *
 * Both halves are the same function on purpose. A separate checker is a second copy of the
 * derivation rule, and the two drift.
 *
 * Plain Node, stdlib only.
 *
 * Ported from bizapps-forms (MemberJunction/bizapps-forms#177).
 */
import { readFileSync, writeFileSync, realpathSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/** The MJ package whose pin decides the supported range. */
const MJ_ANCHOR = '@memberjunction/core';

/**
 * `mj-app.json`'s derived fields, from the entities package's own manifest.
 *
 * `mjVersionRange` is `>=<pin> <(major+1).0.0>`, the pinning model CLAUDE.md describes: an app
 * supports the MJ line it is built against, up to but not including the next major.
 */
export function deriveAppFields(entitiesPkg) {
    const version = entitiesPkg?.version;
    if (!version) {
        throw new Error('packages/Entities/package.json has no version — cannot derive mj-app.json');
    }
    const pin = entitiesPkg.dependencies?.[MJ_ANCHOR] ?? entitiesPkg.peerDependencies?.[MJ_ANCHOR];
    if (!pin) {
        throw new Error(
            `packages/Entities/package.json declares no ${MJ_ANCHOR} in dependencies or peerDependencies — ` +
                'mjVersionRange has no input to derive from',
        );
    }
    const min = pin.replace(/^[^0-9]*/, '');
    const nextMajor = `${Number(min.split('.')[0]) + 1}.0.0`;
    return { version, mjVersionRange: `>=${min} <${nextMajor}` };
}

/**
 * Sync (or, with `check`, verify) `mj-app.json` against the entities package.
 *
 * Returns the mismatches found. Writing mode returns `[]` because it has just removed them.
 */
export function syncAppVersion({ root = REPO_ROOT, check = false } = {}) {
    const appPath = join(root, 'mj-app.json');
    const app = JSON.parse(readFileSync(appPath, 'utf8'));
    const derived = deriveAppFields(
        JSON.parse(readFileSync(join(root, 'packages', 'Entities', 'package.json'), 'utf8')),
    );

    const mismatches = Object.entries(derived)
        .filter(([field, expected]) => app[field] !== expected)
        .map(
            ([field, expected]) =>
                `mj-app.json ${field} is ${JSON.stringify(app[field])}, expected ${JSON.stringify(expected)}`,
        );

    if (check || mismatches.length === 0) {
        return mismatches;
    }
    writeFileSync(appPath, JSON.stringify({ ...app, ...derived }, null, 2) + '\n');
    return [];
}

/**
 * Validates the CLI's argv (already sliced past the two host args). Only `[]` (write mode) and
 * `['--check']` are valid — anything else, including a typo like `--chekc` or `--help`, used to fall
 * through `process.argv.includes('--check')` as `false`, which is write mode. That silently turned a
 * misspelled or informational flag into the branch that overwrites `mj-app.json`.
 */
export function parseArgs(argv) {
    if (argv.length === 0) {
        return { check: false };
    }
    if (argv.length === 1 && argv[0] === '--check') {
        return { check: true };
    }
    throw new Error(`sync-app-version: unrecognised argument(s) ${argv.join(' ')}. Usage: sync-app-version.mjs [--check]`);
}

/** CLI entry point. */
function main() {
    let check;
    try {
        ({ check } = parseArgs(process.argv.slice(2)));
    } catch (error) {
        console.error(error.message);
        process.exit(2);
    }
    const mismatches = syncAppVersion({ check });
    if (mismatches.length > 0) {
        console.error('mj-app.json is out of sync with packages/Entities/package.json:\n');
        for (const m of mismatches) {
            console.error(`  ✗ ${m}`);
        }
        console.error('\nRun `pnpm run version` on the release branch and commit the result.');
        process.exit(1);
    }
    console.log(check ? 'mj-app.json is in sync.' : 'mj-app.json synced.');
}

// Compared through realpath, not as a `file://` string: that string is never equal under a path with
// spaces (percent-encoded in the URL) or a symlink, and the gate would then silently exit 0.
if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main();
}
