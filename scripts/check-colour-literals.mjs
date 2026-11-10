#!/usr/bin/env node
/**
 * Every colour in `packages/Angular/src` must come from a semantic `--mj-*` CSS custom property
 * (#306).
 *
 * Raw hex (`#rgb`, `#rrggbb`, `#rrggbbaa`), `rgb(...)`, `rgba(...)`, `hsl(...)`, and `hsla(...)`
 * literals outside `var(--mj-..., <fallback>)` or custom-property definitions bypass the active
 * theme and break dark mode.
 *
 * Allowed contexts:
 *   1. Custom-property definitions: `--mj-foo: #fff;`
 *   2. `var(--token, <fallback>)` fallback arguments
 *   3. Lines annotated with (or immediately preceded by) a comment carrying a written reason:
 *      `/* colour-literal-ok: <reason> *\/` or `// colour-literal-ok: <reason>`
 */
import { readdirSync, readFileSync, realpathSync, statSync } from 'node:fs';
import { dirname, extname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

export const SEARCH_ROOTS = ['packages/Angular/src'];

const SKIP_DIRS = new Set(['generated', 'node_modules', 'dist', '__tests__']);
const SOURCE_EXTS = new Set(['.ts', '.html', '.css', '.scss']);
const TEST_OR_DECL_FILE = /\.(?:test|spec|d)\.ts$/;

const COLOUR_PATTERNS = [
    { kind: 'hex', re: /#[0-9a-fA-F]{3,8}\b/ },
    { kind: 'rgb', re: /\brgba?\(\s*\d[^)]*\)/i },
    { kind: 'hsl', re: /\bhsla?\(\s*\d[^)]*\)/i },
];

const ALLOW_COMMENT_RE = /(?:colou?r-literal-ok\s*:\s*[A-Za-z0-9]|ui-gate:\s*allow-literal-color(?:\(\d+\))?\s*—\s*[A-Za-z0-9])/i;

const BLOCK_COMMENTS = [
    { open: '/*', close: '*/' },
    { open: '<!--', close: '-->' },
];

/**
 * Strip `/* ... *\/`, `<!-- ... -->`, and `// ...` comments while preserving line count so prose
 * (including issue references like `#311`) is never mistaken for a hex colour literal.
 */
export function stripComments(rawLines) {
    let closing = null;
    return rawLines.map((line) => {
        let out = '';
        let i = 0;
        while (i < line.length) {
            if (closing) {
                const end = line.indexOf(closing, i);
                if (end === -1) return out;
                i = end + closing.length;
                closing = null;
                continue;
            }
            let opener = null;
            for (const { open, close } of BLOCK_COMMENTS) {
                const at = line.indexOf(open, i);
                if (at !== -1 && (opener === null || at < opener.at)) {
                    opener = { at, open, close };
                }
            }
            const slash = findLineCommentStart(line, i);
            if (slash !== -1 && (opener === null || slash < opener.at)) {
                return out + line.slice(i, slash);
            }
            if (opener === null) return out + line.slice(i);
            out += line.slice(i, opener.at);
            closing = opener.close;
            i = opener.at + opener.open.length;
        }
        return out;
    });
}

function findLineCommentStart(line, fromIndex) {
    for (let i = fromIndex; i < line.length - 1; i++) {
        if (line[i] === '/' && line[i + 1] === '/') {
            // Ignore `http://` or `https://` protocol slashes
            if (i > 0 && line[i - 1] === ':') continue;
            return i;
        }
    }
    return -1;
}

/**
 * Strip `var(--token, <fallback>)` expressions (including nested parentheses such as
 * `var(--mj-bg-overlay, rgba(0, 0, 0, 0.4))`) so fallback literals are not flagged.
 */
export function stripVarFallbacks(line) {
    let out = '';
    let i = 0;
    const varStartRe = /var\(\s*--[\w-]+\s*,/g;
    varStartRe.lastIndex = 0;
    while (i < line.length) {
        varStartRe.lastIndex = i;
        const match = varStartRe.exec(line);
        if (!match) {
            out += line.slice(i);
            break;
        }
        out += line.slice(i, match.index) + 'var()';
        let depth = 1;
        let j = match.index + match[0].length;
        while (j < line.length && depth > 0) {
            if (line[j] === '(') depth++;
            else if (line[j] === ')') depth--;
            j++;
        }
        i = j;
    }
    return out;
}

/** Return the first raw colour match on `text`, or null if none. */
export function findRawColourLiteral(text) {
    for (const { kind, re } of COLOUR_PATTERNS) {
        const m = re.exec(text);
        if (m) return { kind, literal: m[0] };
    }
    return null;
}

export function isAllowedColourLine(codeLine) {
    const trimmed = codeLine.trim();
    // Custom property definitions (`--mj-foo: #fff;` or `--mjc-foo: rgba(...)`)
    if (/^--[\w-]+\s*:/.test(trimmed)) return true;
    const withoutFallbacks = stripVarFallbacks(codeLine);
    return findRawColourLiteral(withoutFallbacks) === null;
}

function hasAllowanceAnnotation(rawLines, index) {
    if (ALLOW_COMMENT_RE.test(rawLines[index])) return true;
    for (let j = index - 1; j >= 0; j--) {
        if (rawLines[j].trim() === '') continue;
        return ALLOW_COMMENT_RE.test(rawLines[j]);
    }
    return false;
}

/** Scan a single file's text and return violations with 1-based line numbers. */
export function scanText(text) {
    const rawLines = text.split(/\r?\n/);
    const codeLines = stripComments(rawLines);
    const violations = [];
    for (let i = 0; i < codeLines.length; i++) {
        const codeLine = codeLines[i];
        if (!findRawColourLiteral(codeLine)) continue;
        if (isAllowedColourLine(codeLine)) continue;
        if (hasAllowanceAnnotation(rawLines, i)) continue;
        const hit = findRawColourLiteral(stripVarFallbacks(codeLine));
        if (!hit) continue;
        violations.push({
            line: i + 1,
            kind: hit.kind,
            literal: hit.literal,
            text: rawLines[i].trim().slice(0, 120),
        });
    }
    return violations;
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
        let st;
        try {
            st = statSync(full);
        } catch {
            continue;
        }
        if (st.isDirectory()) {
            if (!SKIP_DIRS.has(name)) yield* walk(full);
        } else if (SOURCE_EXTS.has(extname(name)) && !TEST_OR_DECL_FILE.test(name)) {
            yield full;
        }
    }
}

export function scanRepo(root = REPO_ROOT) {
    const violations = [];
    const emptyRoots = [];
    for (const searchRoot of SEARCH_ROOTS) {
        let files = 0;
        for (const file of walk(join(root, searchRoot))) {
            files++;
            const rel = relative(root, file).split(sep).join('/');
            for (const v of scanText(readFileSync(file, 'utf8'))) {
                violations.push({ file: rel, ...v });
            }
        }
        if (files === 0) emptyRoots.push(searchRoot);
    }
    return { violations, emptyRoots };
}

function main() {
    const { violations, emptyRoots } = scanRepo();
    if (emptyRoots.length > 0) {
        console.error(`colour-literals: ERROR — declared root(s) matched no files: ${emptyRoots.join(', ')}.`);
        process.exit(2);
    }
    if (violations.length === 0) {
        console.log('colour-literals: no raw colour literals in packages/Angular/src.');
        return;
    }
    console.error(`colour-literals: ${violations.length} raw colour literal(s) found in packages/Angular/src:\n`);
    for (const v of violations) {
        console.error(`    ${v.file}:${v.line}  ${v.literal}  (${v.text})`);
    }
    console.error('\nUse a semantic --mj-* token (or annotate an intentional non-theme literal with /* colour-literal-ok: <reason> */).');
    process.exit(1);
}

if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main();
}
