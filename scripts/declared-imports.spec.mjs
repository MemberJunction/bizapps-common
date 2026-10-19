// Every package a root-level script imports must be declared in the root package.json. pnpm links
// only declared dependencies into the root node_modules, so an undeclared import resolves inside a
// dev workspace (whose parent hoists everything) and fails with ERR_MODULE_NOT_FOUND in a plain
// clone (issues #331, #286).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { builtinModules } from 'node:module';
import { fileURLToPath } from 'node:url';
import { readFileSync, readdirSync, existsSync } from 'node:fs';

const SELF = fileURLToPath(import.meta.url);
const HERE = path.dirname(SELF);
const REPO_ROOT = path.join(HERE, '..');

/** Root-level directories whose scripts run from the repo root, resolving against its node_modules. */
const ROOT_SCRIPT_DIRS = ['scripts', 'ci', 'test-harnesses'];

const STATIC_IMPORT = /^\s*import\s+(?:[^'"]*?\s+from\s+)?['"]([^'"]+)['"]/gm;
const DYNAMIC_IMPORT = /\bimport\(\s*['"]([^'"]+)['"]\s*\)/g;

/** `@scope/name/sub` → `@scope/name`; `name/sub` → `name`. */
function packageName(specifier) {
    const parts = specifier.split('/');
    return specifier.startsWith('@') ? parts.slice(0, 2).join('/') : parts[0];
}

function isBareSpecifier(specifier) {
    if (specifier.startsWith('.') || specifier.startsWith('/') || specifier.startsWith('node:')) return false;
    return !builtinModules.includes(packageName(specifier));
}

/** `{ file, pkg }` for each bare import in the given source text. */
function bareImports(file, source) {
    const found = [];
    for (const pattern of [STATIC_IMPORT, DYNAMIC_IMPORT]) {
        for (const [, specifier] of source.matchAll(pattern)) {
            if (isBareSpecifier(specifier)) found.push({ file, pkg: packageName(specifier) });
        }
    }
    return found;
}

function rootScriptImports() {
    const found = [];
    for (const dir of ROOT_SCRIPT_DIRS.filter((d) => existsSync(path.join(REPO_ROOT, d)))) {
        for (const name of readdirSync(path.join(REPO_ROOT, dir)).filter((f) => f.endsWith('.mjs'))) {
            const file = `${dir}/${name}`;
            // This spec's own fixtures are import lines written as strings, not imports.
            if (path.join(REPO_ROOT, file) === SELF) continue;
            found.push(...bareImports(file, readFileSync(path.join(REPO_ROOT, file), 'utf8')));
        }
    }
    return found;
}

test('the import reader finds static and dynamic bare imports and ignores builtins and relatives', () => {
    const source = [
        "import { Pool } from 'pg';",
        "import dotenv from 'dotenv';",
        "import 'side-effect-only';",
        "import path from 'node:path';",
        "import fs from 'fs';",
        "import { x } from './local.mjs';",
        "const { Metadata } = await import('@memberjunction/core');",
        "const reg = await import('@memberjunction/testing-integration/registry');",
        "const text = \"a regex like /from '(x)'/ in a string is not an import\";",
    ].join('\n');
    assert.deepEqual(
        bareImports('f.mjs', source).map((i) => i.pkg).sort(),
        ['@memberjunction/core', '@memberjunction/testing-integration', 'dotenv', 'pg', 'side-effect-only'],
    );
});

test('every package a root-level script imports is declared in the root package.json', () => {
    const pkg = JSON.parse(readFileSync(path.join(REPO_ROOT, 'package.json'), 'utf8'));
    const declared = new Set([...Object.keys(pkg.dependencies ?? {}), ...Object.keys(pkg.devDependencies ?? {})]);
    const missing = rootScriptImports().filter((i) => !declared.has(i.pkg));
    assert.deepEqual(missing, [], 'add these to the root devDependencies, then pnpm install at the workspace parent');
});
