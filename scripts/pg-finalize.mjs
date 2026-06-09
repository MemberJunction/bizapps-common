#!/usr/bin/env node
/**
 * pg-finalize.mjs — post-conversion patch layer for the BizApps Common PostgreSQL migrations.
 *
 * WHY THIS EXISTS
 * ---------------
 * `mj migrate convert` (the @memberjunction/sql-converter rule pipeline) translates the
 * canonical SQL Server migrations under `migrations/` into PostgreSQL under `migrations-pg/`.
 * The converter is rule/string based; a small, well-understood set of T-SQL constructs it does
 * not fully translate are corrected here as a deterministic, idempotent post-pass — the
 * "things we fix after the converter" layer (converter → pg-only supplements → this finalize pass).
 *
 * It is intentionally SURGICAL and idempotent: re-running it on already-finalized files is a no-op,
 * and `mj migrate convert` itself never regenerates a `.pg.sql` that already exists, so these fixes
 * are preserved across normal conversion runs. If a migration is ever force-regenerated, re-run this.
 *
 * NO MemberJunction-core changes are involved — this lives entirely in the BizApps Common repo.
 *
 * PATCHES (each documented with the converter gap it compensates for):
 *
 *  1. FK-join alias quoting. CodeGen base views define their FK-join aliases quoted
 *     (`... AS "mjBizAppsCommonOrganizationType_OrganizationTypeID"`) but the converter leaves the
 *     *references* unquoted, so PostgreSQL case-folds them to lowercase and raises
 *     "missing FROM-clause entry". We quote every `mj<Entity>_<FK>.` reference so it matches its
 *     quoted definition. (MJ-core `"MJEntity_*"` aliases are already quoted on both sides.)
 *
 *  2. Skipped-trigger neutralization. The converter cannot translate T-SQL `AFTER UPDATE` triggers,
 *     so it emits a `-- SKIPPED: trigger ...` marker — but only comments the `CREATE TRIGGER` line,
 *     leaving the (often truncated) body (`ON ... AFTER UPDATE AS BEGIN ... SET ...`) live, which is
 *     invalid PostgreSQL. These are the `__mj_UpdatedAt` maintenance triggers that `mj codegen`
 *     regenerates natively on PostgreSQL, so the migration must simply not contain them. We comment
 *     out every live line of each skipped-trigger block up to its blank-line terminator.
 */
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const PG_DIR = join(HERE, '..', 'migrations-pg');

/**
 * Boolean-column map for the MJ-core `__mj` schema (generated from the 5.37.0 core schema via
 * information_schema). Used by Patch 3 to positionally cast integer 0/1 literals to FALSE/TRUE in
 * INSERTs into core tables. Regenerate if the targeted MJ core version changes:
 *   psql ... -c "SELECT json_object_agg(table_name, cols) FROM (SELECT table_name,
 *     json_agg(column_name ORDER BY column_name) cols FROM information_schema.columns
 *     WHERE table_schema='__mj' AND data_type='boolean' GROUP BY table_name) t" > pg-core-boolean-columns.json
 */
const CORE_BOOL_COLS = JSON.parse(readFileSync(join(HERE, 'pg-core-boolean-columns.json'), 'utf8'));

/** Split on top-level commas, respecting single-quoted strings ('' escapes) and parenthesis depth. */
function splitTopLevel(s) {
  const parts = [];
  let buf = '', depth = 0, inStr = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (inStr) {
      buf += c;
      if (c === "'") {
        if (s[i + 1] === "'") { buf += s[++i]; } // escaped quote
        else inStr = false;
      }
      continue;
    }
    if (c === "'") { inStr = true; buf += c; continue; }
    if (c === '(') { depth++; buf += c; continue; }
    if (c === ')') { depth--; buf += c; continue; }
    if (c === ',' && depth === 0) { parts.push(buf); buf = ''; continue; }
    buf += c;
  }
  parts.push(buf);
  return parts;
}

/** Find index of the paren matching the `(` at openIdx, respecting quotes. */
function matchParen(s, openIdx) {
  let depth = 0, inStr = false;
  for (let i = openIdx; i < s.length; i++) {
    const c = s[i];
    if (inStr) { if (c === "'") { if (s[i + 1] === "'") i++; else inStr = false; } continue; }
    if (c === "'") inStr = true;
    else if (c === '(') depth++;
    else if (c === ')') { depth--; if (depth === 0) return i; }
  }
  return -1;
}

const unquoteIdent = (t) => t.trim().replace(/^"|"$/g, '');

/** Patch 1: quote unquoted `mj<Pascal>_<Field>.` view-join alias references. */
function quoteFkJoinAliasReferences(sql) {
  // Only lowercase-`mj`-prefixed PascalCase aliases (the converter's generated FK-join aliases).
  // Negative lookbehind on `"` avoids re-quoting; lookahead on `.` targets references, not the
  // already-quoted `AS "..."` definitions (which are followed by a newline, not a dot).
  return sql.replace(/(?<!")\b(mj[A-Z][A-Za-z0-9]*_[A-Za-z0-9]+)(?=\.)/g, '"$1"');
}

/**
 * Patch 2: fully comment out the live body left behind by the converter's incomplete skips.
 *  - `-- SKIPPED: trigger ...` — only the CREATE TRIGGER line is commented; the (often truncated)
 *    body stays live. These `__mj_UpdatedAt` triggers are regenerated by `mj codegen` on PostgreSQL.
 *  - `-- NOTE: unrecognized batch type (UNKNOWN) — passed through as-is` — the converter could not
 *    translate the following batch and emitted it verbatim. For T-SQL source these are invalid PG
 *    (e.g. the `IF @@ROWCOUNT <> 1 ... THROW` rowcount guards); the guarded DML itself is a separate,
 *    already-converted batch, so only the unrecognized guard is neutralized here.
 * Each block is commented up to its blank-line terminator (the SQL batch boundary).
 */
function neutralizeSkippedTriggers(sql) {
  const lines = sql.split('\n');
  const out = [];
  let inBlock = false;
  for (const line of lines) {
    if (/^--\s*SKIPPED:\s*trigger/i.test(line) ||
        /^--\s*NOTE:\s*unrecognized batch type.*passed through as-is/i.test(line)) {
      inBlock = true;
      out.push(line);
      continue;
    }
    if (inBlock) {
      // Blank / whitespace-only line terminates the broken block.
      if (line.trim() === '') {
        inBlock = false;
        out.push(line);
        continue;
      }
      // Comment out any live (non-comment) body line; leave existing comments intact.
      out.push(line.startsWith('--') ? line : `-- ${line}`);
      continue;
    }
    out.push(line);
  }
  return out.join('\n');
}

/**
 * Patch 3: positionally cast integer 0/1 -> FALSE/TRUE in INSERTs into MJ-core `__mj` boolean
 * columns. The converter emits native TRUE/FALSE for bizapps tables it sized from their CREATE TABLE,
 * but cannot see the core `__mj` table types, so it leaves bare 0/1 — which PostgreSQL refuses to
 * implicitly cast to boolean (and the catalog-level implicit cast is unavailable on managed PG/Aurora).
 */
function castCoreBooleanInserts(sql) {
  // Core schema is referenced either literally (`__mj`, in the baseline) or via the `${mjSchema}`
  // placeholder (in the CodeGen V-migrations) — match both.
  const re = /INSERT\s+INTO\s+(?:"?__mj"?|"?\$\{mjSchema\}"?)\."?([A-Za-z0-9_]+)"?\s*\(/gi;
  let out = '', last = 0, m;
  while ((m = re.exec(sql)) !== null) {
    const table = m[1];
    const boolCols = CORE_BOOL_COLS[table];
    const colOpen = re.lastIndex - 1; // index of the '(' after the column list
    const colClose = matchParen(sql, colOpen);
    if (colClose < 0) continue;
    const afterCols = sql.slice(colClose + 1);
    const vm = /^\s*VALUES\s*\(/i.exec(afterCols);
    if (!vm) continue;
    const valOpen = colClose + 1 + vm[0].length - 1;
    const valClose = matchParen(sql, valOpen);
    if (valClose < 0) continue;

    if (boolCols && boolCols.length) {
      const cols = splitTopLevel(sql.slice(colOpen + 1, colClose)).map(unquoteIdent);
      const vals = splitTopLevel(sql.slice(valOpen + 1, valClose));
      if (cols.length === vals.length) {
        const boolSet = new Set(boolCols);
        let touched = false;
        const newVals = vals.map((v, i) => {
          if (!boolSet.has(cols[i])) return v;
          const t = v.trim();
          if (t === '1') { touched = true; return v.replace('1', 'TRUE'); }
          if (t === '0') { touched = true; return v.replace('0', 'FALSE'); }
          return v;
        });
        if (touched) {
          out += sql.slice(last, valOpen + 1) + newVals.join(',') + sql.slice(valClose, valClose + 1);
          last = valClose + 1;
          re.lastIndex = valClose + 1;
          continue;
        }
      }
    }
    re.lastIndex = valClose + 1;
  }
  out += sql.slice(last);
  return out;
}

/**
 * Patch 4: cast `"boolCol" = 0|1` / `<> 0|1` predicate comparisons to FALSE/TRUE. The converter
 * casts boolean INSERT values but not boolean comparisons in WHERE/UPDATE clauses (PostgreSQL has
 * no implicit boolean=integer operator). Scoped to known boolean column names (MJ-core map ∪ the
 * bizapps table booleans) so integer columns that legitimately equal 0/1 are never touched.
 */
const BIZAPPS_BOOL_COLS = ['IsActive', 'IsDirectional', 'IsPrimary'];
const BOOL_NAMES = new Set([...Object.values(CORE_BOOL_COLS).flat(), ...BIZAPPS_BOOL_COLS]);
function castBooleanComparisons(sql) {
  return sql.replace(/"([A-Za-z0-9_]+)"(\s*(?:=|<>)\s*)([01])\b/g, (full, name, op, val) =>
    BOOL_NAMES.has(name) ? `"${name}"${op}${val === '1' ? 'TRUE' : 'FALSE'}` : full
  );
}

/**
 * Patch 5: quote unquoted schema-qualified references to mixed-case `__mj` core objects
 * (e.g. `__mj.vwGeneratedCodeCategories` -> `__mj."vwGeneratedCodeCategories"`). PostgreSQL folds
 * unquoted identifiers to lowercase, so an unquoted mixed-case core view/table reference resolves to
 * a non-existent lowercased relation. Only objects containing an uppercase letter are quoted;
 * already-quoted refs (`__mj."X"`) never match.
 */
function quoteCoreObjectRefs(sql) {
  return sql.replace(/\b__mj\.([A-Za-z_][A-Za-z0-9_]*)\b/g, (full, name) =>
    /[A-Z]/.test(name) ? `__mj."${name}"` : full
  );
}

/**
 * Patch 7: make view (re)creation idempotent across migrations. The converter wraps each view in a
 * `CREATE OR REPLACE VIEW` inside a self-healing DO-block, but `CREATE OR REPLACE` cannot rename or
 * reorder columns (PostgreSQL 42P16) — which a regeneration migration does when an upstream table
 * gains a column (e.g. Person.DisplayName reshapes vwPeople). We inject a `DROP VIEW IF EXISTS ...
 * CASCADE` before each view block so the create is always fresh. These base views are regenerated
 * authoritatively by `mj codegen` on PostgreSQL, and the bizapps base views have no inter-view
 * dependencies, so the CASCADE is safe. Idempotent: a DROP is injected at most once per block.
 */
function dropBeforeCreateViews(sql) {
  return sql.replace(
    /(DO \$do\$[\s\S]*?CREATE OR REPLACE VIEW\s+(__mj_BizAppsCommon)\."([^"]+)")/g,
    (full, block, schema, view) =>
      full.includes(`DROP VIEW IF EXISTS ${schema}."${view}" CASCADE`)
        ? full
        : `DROP VIEW IF EXISTS ${schema}."${view}" CASCADE;\n${block}`
  );
}

/**
 * Patch 8: cast boolean literals in named function-call arguments. The CodeGen "tolerant" CRUD
 * sprocs take boolean `<field>_Clear` flags; the converter passes them as integer `:= 1` / `:= 0`,
 * which PostgreSQL cannot match to the boolean parameter (yielding "function ... does not exist").
 * The `_Clear` suffix is the CodeGen convention for these boolean clear-flags, so it is a safe key.
 */
function castClearFlagArgs(sql) {
  return sql.replace(/(_Clear\s*:=\s*)([01])\b/g, (full, lhs, val) => `${lhs}${val === '1' ? 'TRUE' : 'FALSE'}`);
}

/**
 * Patch 9: defer seed blocks that call bizapps CRUD sprocs. On PostgreSQL the MJ install is
 * three-stage — `mj migrate` (DDL) -> `mj codegen` (creates the PG CRUD functions/views/triggers) ->
 * `mj sync push` (seeds reference data). The CodeGen-emitted Metadata_Sync migration seeds the
 * type tables by calling `__mj_BizAppsCommon."spCreate*"`, but those functions do not exist yet at
 * migrate time on PostgreSQL (they are produced later by codegen). The same seed data ships in
 * `metadata/` and is loaded by `mj sync push`, so these `DO $mj$ … END $mj$;` blocks are commented
 * out for PostgreSQL. Blocks that only call CORE `__mj."sp*"` functions (which already exist) are
 * left intact.
 */
function deferBizappsSprocSeedBlocks(sql) {
  return sql.replace(/DO \$mj\$[\s\S]*?END \$mj\$;/g, (block) => {
    const callsBizappsSproc = /PERFORM\s+"?__mj_BizAppsCommon"?\."sp(Create|Update|Delete)/i.test(block);
    if (!callsBizappsSproc) return block;
    if (block.split('\n').every((l) => l.startsWith('--'))) return block; // already deferred
    return block
      .split('\n')
      .map((l) => (l.startsWith('--') ? l : `-- ${l}`))
      .join('\n');
  });
}

/**
 * Patch 10: normalize the bizapps schema identifier to UNQUOTED, so PostgreSQL folds it to lowercase
 * consistently. This matches how `mj codegen` (and the MJServer runtime) generate schema references
 * on PostgreSQL — they emit the schema UNQUOTED (e.g. `__mj_BizAppsCommon."AddressType"`), which
 * folds to `__mj_bizappscommon`. If the migration created a mixed-case quoted schema, codegen's
 * regenerated views/sprocs would look for the lowercased schema and fail with "relation does not
 * exist". Table/column identifiers stay quoted (mixed case); only the SCHEMA identifier is unquoted.
 * Single-quoted string literals (`'__mj_BizAppsCommon'`, e.g. the `SchemaName` value and PL/pgSQL
 * `format('%I', ...)` constants) are untouched — those carry the canonical name in metadata and are
 * quoted correctly at runtime by `%I`.
 */
function normalizeBizappsSchemaUnquoted(sql) {
  return sql.replace(/"__mj_BizAppsCommon"/g, '__mj_BizAppsCommon');
}

const PATCHES = [
  ['quote FK-join alias references', quoteFkJoinAliasReferences],
  ['neutralize skipped triggers', neutralizeSkippedTriggers],
  ['cast core boolean INSERTs', castCoreBooleanInserts],
  ['cast boolean comparisons', castBooleanComparisons],
  ['quote core object refs', quoteCoreObjectRefs],
  ['drop-before-create views', dropBeforeCreateViews],
  ['cast _Clear flag args', castClearFlagArgs],
  ['defer bizapps sproc seed blocks', deferBizappsSprocSeedBlocks],
  ['normalize bizapps schema unquoted', normalizeBizappsSchemaUnquoted],
];

function main() {
  const files = readdirSync(PG_DIR).filter((f) => f.endsWith('.pg.sql'));
  let changed = 0;
  for (const f of files) {
    const p = join(PG_DIR, f);
    const before = readFileSync(p, 'utf8');
    let after = before;
    for (const [, fn] of PATCHES) after = fn(after);
    if (after !== before) {
      writeFileSync(p, after);
      changed++;
      console.log(`  finalized ${f}`);
    }
  }
  console.log(`pg-finalize: ${changed}/${files.length} file(s) patched (idempotent).`);
}

main();
