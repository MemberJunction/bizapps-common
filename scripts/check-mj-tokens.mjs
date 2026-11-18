#!/usr/bin/env node
/**
 * Every `var(--mj-…)` in packages/Angular/src must be a token MemberJunction defines (#299).
 *
 * CSS gives no error for an unknown custom property. A declaration that reads one with no fallback is
 * dropped at computed-value time, and one with a fallback always renders the fallback, so the rule
 * follows neither theme.
 *
 * The accepted names are `scripts/mj-tokens.json`, copied from MJ's `_tokens.scss` at the release this
 * repo floors at by `scripts/refresh-mj-tokens.mjs`. The check fails when that copy is for a different
 * MJ version than the `@memberjunction/core` floor in `packages/Angular`, so a floor bump cannot leave
 * it behind.
 *
 * Ported from bizapps-sales `scripts/assert-mj-tokens.mjs`. Plain Node, stdlib only.
 */
import { readdirSync, readFileSync, statSync, realpathSync } from 'node:fs';
import { join, relative, sep, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/** Directories that carry styles. A root that matches no file fails the check. */
export const SEARCH_ROOTS = ['packages/Angular/src'];

const SKIP_DIR = new Set(['generated', 'node_modules', 'dist']);
const SOURCE_FILE = /\.(ts|css|scss|html)$/;
const TOKEN_USE = /var\(\s*(--mj-[a-z0-9-]+)/g;

/** The MJ floor a caret range names: `^6.1.5` → `6.1.5`. */
export function mjFloor(range) {
    const match = /^\^?(\d+\.\d+\.\d+)$/.exec(range ?? '');
    if (!match) {
        throw new Error(`packages/Angular has no caret @memberjunction/core floor (found "${range}")`);
    }
    return match[1];
}

/** `--mj-*` names read in `text` that are not in `known`, with 1-based line numbers. */
export function unknownTokenUses(text, known) {
    const uses = [];
    text.split(/\r?\n/).forEach((line, i) => {
        for (const [, name] of line.matchAll(TOKEN_USE)) {
            if (!known.has(name)) uses.push({ line: i + 1, name });
        }
    });
    return uses;
}

function* walk(dir) {
    let entries;
    try {
        entries = readdirSync(dir);
    } catch {
        return;
    }
    for (const name of entries) {
        const full = join(dir, name);
        if (statSync(full).isDirectory()) {
            if (!SKIP_DIR.has(name)) yield* walk(full);
        } else if (SOURCE_FILE.test(name) && !name.endsWith('.d.ts')) {
            yield full;
        }
    }
}

/** The accepted token names, after checking the list matches the Angular package's MJ floor. */
export function readAllowlist(root = REPO_ROOT) {
    const list = JSON.parse(readFileSync(join(root, 'scripts/mj-tokens.json'), 'utf8'));
    const pkg = JSON.parse(readFileSync(join(root, 'packages/Angular/package.json'), 'utf8'));
    const floor = mjFloor(pkg.devDependencies?.['@memberjunction/core']);
    if (list.mjVersion !== floor) {
        throw new Error(
            `scripts/mj-tokens.json is for MJ ${list.mjVersion}, but packages/Angular floors at ${floor}. ` +
                'Run `node scripts/refresh-mj-tokens.mjs` and commit the result.',
        );
    }
    return new Set(list.tokens);
}

/** Scan every search root; returns violations and the roots that matched no file. */
export function scanRepo(root = REPO_ROOT, known = readAllowlist(root)) {
    const violations = [];
    const emptyRoots = [];
    for (const searchRoot of SEARCH_ROOTS) {
        let files = 0;
        for (const file of walk(join(root, searchRoot))) {
            files++;
            const rel = relative(root, file).split(sep).join('/');
            for (const use of unknownTokenUses(readFileSync(file, 'utf8'), known)) {
                violations.push({ file: rel, ...use });
            }
        }
        if (files === 0) emptyRoots.push(searchRoot);
    }
    return { violations, emptyRoots };
}

function main() {
    let result;
    try {
        result = scanRepo();
    } catch (error) {
        console.error(`mj-tokens: ERROR — ${error.message}`);
        process.exit(2);
    }
    const { violations, emptyRoots } = result;
    if (emptyRoots.length > 0) {
        console.error(`mj-tokens: ERROR — declared root(s) matched no files: ${emptyRoots.join(', ')}.`);
        process.exit(2);
    }
    if (violations.length === 0) {
        console.log('mj-tokens: every --mj-* name is a MemberJunction token.');
        return;
    }
    console.error(`mj-tokens: ${violations.length} use(s) of --mj-* names MemberJunction does not define:\n`);
    for (const v of violations) console.error(`    ${v.file}:${v.line}  ${v.name}`);
    console.error('\nUse a token from scripts/mj-tokens.json.');
    process.exit(1);
}

if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main();
}
