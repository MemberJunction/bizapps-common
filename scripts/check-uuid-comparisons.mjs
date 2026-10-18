#!/usr/bin/env node
/**
 * Refuse `===` / `!==` between record IDs in hand-written package code (#314).
 *
 * SQL Server returns UUIDs upper-cased and PostgreSQL lower-cased, and an ID from a route, an input
 * binding or another provider can be spelled either way. `a.ID === b.ID` is then false for the same
 * record, and nothing errors: a lookup returns undefined, a node is drawn twice, a rule is decided as
 * if none matched. Compare with `UUIDsEqual` from `@memberjunction/global`, and key a Map or Set by
 * `NormalizeUUID(id)`.
 *
 * The check is a line scan, not a type check. An operand counts as an ID when its last segment ends
 * in `ID` or `Id` (`connection.ID`, `typeID`, `EditingId`). A bare lower-case `id` is left out: MJ
 * entity fields are PascalCase, and in this repo `id` names UI slugs (`chip.id`). A comparison
 * against a literal (`null`, `undefined`, a string, a number, a boolean) or a `typeof` test is not
 * an ID comparison and passes. A line that really does compare non-UUID values whose names end in ID carries
 * `uuid-compare-ok: <reason>` on that line or the one above it.
 *
 * Plain Node, stdlib only, like the other gates in scripts/.
 */
import { readdirSync, readFileSync, realpathSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/** Where hand-written code lives, relative to each package directory. */
export const SCANNED_PACKAGE_DIR = 'src';

/** Directories skipped while walking. CodeGen output is regenerated; tests compare fixtures. */
const EXCLUDED_SEGMENTS = Object.freeze(['generated', '__tests__', 'node_modules', 'dist']);
const EXCLUDED_SUFFIXES = Object.freeze(['.test.ts', '.spec.ts']);
const SCANNED_SUFFIXES = Object.freeze(['.ts', '.html']);

const MARKER = 'uuid-compare-ok:';
const OPERATOR = /(===|!==)/g;
const OPERAND_CHAR = /[\w$.?!\[\]]/;
const LITERAL = /^(null|undefined|true|false|-?\d|['"`])/;

/** Pure. Is this operand text a record ID by its name? */
export function looksLikeID(operand) {
    const cleaned = operand.replace(/[?!]+$/g, '').replace(/^[!(]+/, '');
    const last = cleaned.split(/[.?!]+/).filter(Boolean).pop() ?? '';
    return /(ID|Id)$/.test(last);
}

function leftOperand(line, index) {
    let start = index;
    while (start > 0 && line[start - 1] === ' ') start--;
    const end = start;
    while (start > 0 && OPERAND_CHAR.test(line[start - 1])) start--;
    const before = line.slice(0, start).trimEnd();
    return { text: line.slice(start, end), typeofTest: before.endsWith('typeof') };
}

function rightOperand(line, index) {
    const rest = line.slice(index).trimStart();
    if (LITERAL.test(rest)) return { text: rest[0], literal: true };
    if (rest.startsWith('typeof')) return { text: 'typeof', literal: true };
    let end = 0;
    while (end < rest.length && OPERAND_CHAR.test(rest[end])) end++;
    return { text: rest.slice(0, end), literal: false };
}

/** Pure. The ID comparisons on one line, or [] when the line is clean or carries the marker. */
export function findIDComparisons(line, previousLine = '') {
    if (line.includes(MARKER) || previousLine.includes(MARKER)) return [];
    const found = [];
    for (const match of line.matchAll(OPERATOR)) {
        const left = leftOperand(line, match.index);
        const right = rightOperand(line, match.index + match[0].length);
        if (left.typeofTest || right.literal || LITERAL.test(left.text)) continue;
        if (looksLikeID(left.text) || looksLikeID(right.text)) {
            found.push(`${left.text} ${match[0]} ${right.text}`);
        }
    }
    return found;
}

/** Pure. Every violation in one file's text, as `{ line, comparison }`. */
export function scanText(text) {
    const lines = text.split('\n');
    return lines.flatMap((line, i) =>
        findIDComparisons(line, i > 0 ? lines[i - 1] : '').map((comparison) => ({ line: i + 1, comparison })),
    );
}

function isScanned(path) {
    if (EXCLUDED_SUFFIXES.some((suffix) => path.endsWith(suffix))) return false;
    return SCANNED_SUFFIXES.some((suffix) => path.endsWith(suffix));
}

function filesUnder(dir) {
    let entries;
    try {
        entries = readdirSync(dir, { withFileTypes: true });
    } catch {
        return [];
    }
    return entries.flatMap((entry) => {
        const path = join(dir, entry.name);
        if (entry.isDirectory()) return EXCLUDED_SEGMENTS.includes(entry.name) ? [] : filesUnder(path);
        return isScanned(path) ? [path] : [];
    });
}

function packageDirs(dir) {
    try {
        return readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => join(dir, e.name));
    } catch {
        return [];
    }
}

/** Scans every package under `root`. Returns `{ file, line, comparison }[]`. */
export function runCheck(root = REPO_ROOT) {
    return packageDirs(join(root, 'packages')).flatMap((pkg) =>
        filesUnder(join(pkg, SCANNED_PACKAGE_DIR)).flatMap((file) =>
            scanText(readFileSync(file, 'utf8')).map((v) => ({ file: relative(root, file), ...v })),
        ),
    );
}

function main() {
    const violations = runCheck();
    if (violations.length === 0) {
        console.log('No === / !== between record IDs in hand-written package code.');
        return;
    }
    console.error('Record IDs compared with === / !== (UUID casing differs between SQL Server and PostgreSQL, #314):');
    for (const v of violations) console.error(`  ${v.file}:${v.line}  ${v.comparison}`);
    console.error(`Use UUIDsEqual / NormalizeUUID from @memberjunction/global, or mark the line "${MARKER} <reason>".`);
    process.exitCode = 1;
}

if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main();
}
