#!/usr/bin/env node
/**
 * check-entityfield-drift.mjs
 *
 * On a database built from this repo's migration chain, `__mj_BizAppsCommon` must have no
 * EntityField drift in either direction.
 *
 * ── WHY ─────────────────────────────────────────────────────────────────────────
 * A base view ships a column with no matching `__mj.EntityField` row. The view is correct; only
 * the metadata is missing. CodeGen then finds a column with no metadata and registers it — from
 * whichever Open App happens to run CodeGen against the shared database FIRST. The metadata a
 * host ends up with then depends on the order someone ran tooling in, not on what any repo ships.
 * Worse, the documented workflow in a sibling app is to capture CodeGen's output into a migration,
 * so an engineer following that recipe ships THIS app's metadata inside their own migration.
 *
 * The two sibling gates (check-migration-entityfield-sequence.mjs, check-migration-no-prune.mjs)
 * cannot see this: they scan migration TEXT, and this defect is the ABSENCE of text. It is only
 * visible against a built database. See #157, and #127 for the instance that motivated it.
 *
 * ── THE FOUR ASSERTIONS ─────────────────────────────────────────────────────────
 *   MISSING   A base-view column with no EntityField row — what a neighbour's CodeGen would
 *             INSERT. This is the primary detector and the one that reproduces #127.
 *   PHANTOM   An EntityField row with no base-view column — what CodeGen would DELETE.
 *   SEQUENCE  Per entity, sequences must be 1..N, distinct, no gaps. On a real pre-fix build the
 *             gaps ARE the missing fields: the install heal renumbers from the catalog, which
 *             counts the unmetadata'd columns, so the surviving rows take catalog ordinals and
 *             the absent ones leave holes. An independent witness to the same defect.
 *   BAND      No Sequence >= 100000, the MAX+100000+ordinal placeholder CodeGen emits on the
 *             generating database only.
 *
 * ── WHAT THE BUILD MUST BE ──────────────────────────────────────────────────────
 * Core `mj migrate -t <tag>`, then `mj migrate --schema __mj_BizAppsCommon --dir ./migrations`.
 * That app migrate ends with the Open App metadata heal, and running the check AFTER the heal is
 * deliberate: it is what a host actually gets, so a finding here is work genuinely left over for a
 * neighbour's CodeGen rather than something the standard install would have fixed. The heal does
 * not insert missing EntityField rows (spUpdateExistingEntityFieldsFromSchema only UPDATEs), which
 * is why MISSING survives it and stays the primary detector. The heal DOES run
 * spDeleteUnneededEntityFields and does renumber sequences, so PHANTOM, SEQUENCE and BAND are
 * steady-state assertions rather than primary detectors — they fire on drift the heal declines to
 * touch, e.g. anything its schema exclusions put out of scope.
 *
 * ── SCOPE ───────────────────────────────────────────────────────────────────────
 * `__mj_BizAppsCommon` only. Consumer blindness cuts both ways: this repo asserts its own schema
 * and says nothing about a neighbour's.
 *
 * Usage:
 *   node check-entityfield-drift.mjs                  # check DB_DATABASE
 *   node check-entityfield-drift.mjs --database <db>  # check a named database
 *   node check-entityfield-drift.mjs --self-test      # prove the detectors still fire
 *
 * Connection comes from DB_HOST / DB_PORT / DB_DATABASE / DB_USERNAME / DB_PASSWORD.
 * Exit codes: 0 clean, 1 drift found, 2 the check could not run.
 */

import { execFileSync, execSync } from 'node:child_process';

const RED = '\x1b[0;31m', GREEN = '\x1b[0;32m', YELLOW = '\x1b[0;33m', DIM = '\x1b[2m', NC = '\x1b[0m';

const APP_SCHEMA = argValue('--schema') || '__mj_BizAppsCommon';
const CORE_SCHEMA = argValue('--core-schema') || '__mj';
/** The placeholder band CodeGen writes on the generating database (MAX + 100000 + ordinal). */
const SEQUENCE_BAND = 100000;
/** Self-test fixture database. Dropped before and after; never a database anyone else owns. */
const SELF_TEST_DB = 'mj_bizappscommon_drift_selftest';

const host = process.env.DB_HOST || 'localhost';
const port = process.env.DB_PORT || '1433';
const user = process.env.DB_USERNAME || 'sa';
const password = process.env.DB_PASSWORD || '';

function argValue(flag) {
    const i = process.argv.indexOf(flag);
    return i === -1 ? undefined : process.argv[i + 1];
}

// ─── SQL text ─────────────────────────────────────────────────────────────────────────────────
// One builder per assertion, used verbatim by BOTH the real run and the self-test. A self-test
// that exercised a paraphrase of the query would prove nothing about the query that ships.

/** `[name]`, with embedded closing brackets doubled. */
function bracket(name) {
    return `[${name.replace(/]/g, ']]')}]`;
}

/** `N'literal'`, with embedded quotes doubled. */
function literal(value) {
    return `N'${value.replace(/'/g, "''")}'`;
}

function missingSQL(core, app) {
    return `SET NOCOUNT ON;
SELECT e.BaseTable, c.COLUMN_NAME
  FROM ${bracket(core)}.Entity e
  JOIN INFORMATION_SCHEMA.COLUMNS c
    ON c.TABLE_SCHEMA = e.SchemaName AND c.TABLE_NAME = e.BaseView
  LEFT JOIN ${bracket(core)}.EntityField ef
    ON ef.EntityID = e.ID AND ef.Name = c.COLUMN_NAME
 WHERE e.SchemaName = ${literal(app)} AND ef.ID IS NULL
 ORDER BY e.BaseTable, c.ORDINAL_POSITION;`;
}

function phantomSQL(core, app) {
    return `SET NOCOUNT ON;
SELECT e.BaseTable, ef.Name
  FROM ${bracket(core)}.Entity e
  JOIN ${bracket(core)}.EntityField ef ON ef.EntityID = e.ID
  LEFT JOIN INFORMATION_SCHEMA.COLUMNS c
    ON c.TABLE_SCHEMA = e.SchemaName AND c.TABLE_NAME = e.BaseView
   AND c.COLUMN_NAME = ef.Name
 WHERE e.SchemaName = ${literal(app)} AND c.COLUMN_NAME IS NULL
 ORDER BY e.BaseTable, ef.Name;`;
}

function sequenceSQL(core, app) {
    return `SET NOCOUNT ON;
SELECT e.BaseTable,
       CAST(COUNT(*) AS varchar(12)),
       CAST(MIN(ef.Sequence) AS varchar(12)),
       CAST(MAX(ef.Sequence) AS varchar(12)),
       CAST(COUNT(DISTINCT ef.Sequence) AS varchar(12))
  FROM ${bracket(core)}.Entity e
  JOIN ${bracket(core)}.EntityField ef ON ef.EntityID = e.ID
 WHERE e.SchemaName = ${literal(app)}
 GROUP BY e.BaseTable
HAVING MIN(ef.Sequence) <> 1
    OR MAX(ef.Sequence) <> COUNT(*)
    OR COUNT(DISTINCT ef.Sequence) <> COUNT(*)
 ORDER BY e.BaseTable;`;
}

function bandSQL(core, app) {
    return `SET NOCOUNT ON;
SELECT e.BaseTable, ef.Name, CAST(ef.Sequence AS varchar(12))
  FROM ${bracket(core)}.Entity e
  JOIN ${bracket(core)}.EntityField ef ON ef.EntityID = e.ID
 WHERE e.SchemaName = ${literal(app)} AND ef.Sequence >= ${SEQUENCE_BAND}
 ORDER BY e.BaseTable, ef.Name;`;
}

// ─── sqlcmd ───────────────────────────────────────────────────────────────────────────────────

function findSqlcmd() {
    for (const candidate of [
        'sqlcmd',
        '/opt/mssql-tools18/bin/sqlcmd',
        '/opt/mssql-tools/bin/sqlcmd',
        '/usr/local/bin/sqlcmd',
        '/opt/homebrew/bin/sqlcmd',
    ]) {
        try {
            execSync(`${candidate} -?`, { stdio: 'ignore' });
            return candidate;
        } catch {
            // try the next one
        }
    }
    return null;
}

const SQLCMD = findSqlcmd();
if (!SQLCMD) {
    console.error('::error::sqlcmd was not found in PATH or the standard locations.');
    process.exit(2);
}

/** Run `sql` against `database` and return raw stdout. Throws with the server's message. */
function exec(sql, database) {
    try {
        return execFileSync(
            SQLCMD,
            ['-S', `${host},${port}`, '-U', user, '-P', password, '-d', database,
             '-C', '-b', '-l', '30', '-h', '-1', '-W', '-s', '|', '-Q', sql],
            { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
        );
    } catch (err) {
        const detail = (err.stdout?.toString() || '') + (err.stderr?.toString() || '') || err.message;
        throw new Error(detail.trim());
    }
}

/**
 * Run a multi-batch script. `sqlcmd -Q` takes a single batch and does NOT honour `GO`, so the
 * separator is applied here — `CREATE SCHEMA` and `CREATE VIEW` each have to start one.
 */
function execScript(sql, database) {
    for (const batch of sql.split(/^[ \t]*GO[ \t]*$/im)) {
        if (batch.trim().length > 0) exec(batch, database);
    }
}

/** Rows as arrays of column strings. sqlcmd prints nothing for an empty result set. */
function rows(sql, database) {
    return exec(sql, database)
        .split('\n')
        .map((line) => line.trimEnd())
        .filter((line) => line.length > 0 && !/^-+(\|-+)*$/.test(line))
        .map((line) => line.split('|').map((cell) => cell.trim()));
}

// ─── The check ────────────────────────────────────────────────────────────────────────────────

/**
 * All four assertions against one database. Returns a flat list of findings; empty means clean.
 * Findings carry `kind` so the self-test can assert on the exact set, not just the count.
 */
function runChecks(database, core = CORE_SCHEMA, app = APP_SCHEMA) {
    const findings = [];

    for (const [table, column] of rows(missingSQL(core, app), database)) {
        findings.push({
            kind: 'MISSING', table, detail: column,
            message: `${app}.${table}: base view column ${column} has no EntityField row`,
        });
    }
    for (const [table, name] of rows(phantomSQL(core, app), database)) {
        findings.push({
            kind: 'PHANTOM', table, detail: name,
            message: `${app}.${table}: EntityField ${name} has no base view column`,
        });
    }
    for (const [table, n, min, max, distinct] of rows(sequenceSQL(core, app), database)) {
        findings.push({
            kind: 'SEQUENCE', table, detail: `${n}/${min}/${max}/${distinct}`,
            message: `${app}.${table}: ${n} EntityField rows but sequences run ${min}..${max} `
                + `with ${distinct} distinct values (expected 1..${n}, all distinct)`,
        });
    }
    for (const [table, name, sequence] of rows(bandSQL(core, app), database)) {
        findings.push({
            kind: 'BAND', table, detail: name,
            message: `${app}.${table}: EntityField ${name} has Sequence ${sequence} `
                + `(>= ${SEQUENCE_BAND}, a CodeGen placeholder that is only valid on the database that emitted it)`,
        });
    }

    return findings;
}

function report(findings, database) {
    if (findings.length === 0) {
        console.log(`${GREEN}✓${NC} ${database}: no EntityField drift in ${APP_SCHEMA} `
            + `${DIM}(missing, phantom, sequence, band all clean)${NC}`);
        return 0;
    }

    console.error(`\n${RED}✗ ${findings.length} EntityField drift finding(s) in ${APP_SCHEMA} `
        + `on ${database}:${NC}\n`);
    for (const finding of findings) {
        console.error(`::error::[${finding.kind}] ${finding.message}`);
    }
    console.error(`
${YELLOW}What this means${NC}
  This repo is shipping metadata work for a neighbouring Open App's CodeGen run to do. Whichever
  app runs CodeGen against a shared host first will write these rows — into ITS migration, in ITS
  release. Ship them from here instead: resolve the entity by natural key (SchemaName + BaseTable,
  never a captured literal), guard each insert on the natural key, evaluate Sequence at apply time
  (never a literal), then assert the end state and THROW rather than report success.
`);
    return 1;
}

// ─── Self-test ────────────────────────────────────────────────────────────────────────────────
// A gate nobody has watched fail is indistinguishable from one that returns pass. This builds a
// throwaway database carrying one instance of each defect, runs the SHIPPING queries against it,
// asserts the exact finding set, then repairs each defect and asserts silence.

/** Four entities, one defect each, so a detector that stops firing cannot hide behind another. */
const FIXTURE_DIRTY = `
CREATE SCHEMA [__mj];
GO
CREATE SCHEMA [${APP_SCHEMA}];
GO
CREATE TABLE [__mj].[Entity] (
    ID uniqueidentifier NOT NULL PRIMARY KEY,
    SchemaName nvarchar(255) NOT NULL,
    BaseTable nvarchar(255) NOT NULL,
    BaseView nvarchar(255) NOT NULL
);
CREATE TABLE [__mj].[EntityField] (
    ID uniqueidentifier NOT NULL PRIMARY KEY,
    EntityID uniqueidentifier NOT NULL,
    Name nvarchar(255) NOT NULL,
    Sequence int NOT NULL
);
GO
-- MISSING: the view carries a column the metadata never got (the shape of #127).
CREATE TABLE [${APP_SCHEMA}].[Widget] (ID int, Name nvarchar(50), ParentIDPath nvarchar(50));
GO
CREATE VIEW [${APP_SCHEMA}].[vwWidgets] AS SELECT ID, Name, ParentIDPath FROM [${APP_SCHEMA}].[Widget];
GO
-- PHANTOM: the metadata carries a field the view dropped.
CREATE TABLE [${APP_SCHEMA}].[Gadget] (ID int, Name nvarchar(50));
GO
CREATE VIEW [${APP_SCHEMA}].[vwGadgets] AS SELECT ID, Name FROM [${APP_SCHEMA}].[Gadget];
GO
-- SEQUENCE: metadata and view agree, but the numbering has a hole.
CREATE TABLE [${APP_SCHEMA}].[Sprocket] (ID int, Name nvarchar(50), Extra nvarchar(50));
GO
CREATE VIEW [${APP_SCHEMA}].[vwSprockets] AS SELECT ID, Name, Extra FROM [${APP_SCHEMA}].[Sprocket];
GO
-- BAND: a captured MAX+100000 placeholder (which also leaves the numbering non-contiguous).
CREATE TABLE [${APP_SCHEMA}].[Doohickey] (ID int, Name nvarchar(50));
GO
CREATE VIEW [${APP_SCHEMA}].[vwDoohickeys] AS SELECT ID, Name FROM [${APP_SCHEMA}].[Doohickey];
GO
INSERT INTO [__mj].[Entity] (ID, SchemaName, BaseTable, BaseView) VALUES
 ('11111111-1111-1111-1111-111111111111', N'${APP_SCHEMA}', N'Widget',    N'vwWidgets'),
 ('22222222-2222-2222-2222-222222222222', N'${APP_SCHEMA}', N'Gadget',    N'vwGadgets'),
 ('33333333-3333-3333-3333-333333333333', N'${APP_SCHEMA}', N'Sprocket',  N'vwSprockets'),
 ('44444444-4444-4444-4444-444444444444', N'${APP_SCHEMA}', N'Doohickey', N'vwDoohickeys');
INSERT INTO [__mj].[EntityField] (ID, EntityID, Name, Sequence) VALUES
 ('aaaaaaa1-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', N'ID',      1),
 ('aaaaaaa1-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', N'Name',    2),
 ('bbbbbbb1-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', N'ID',      1),
 ('bbbbbbb1-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', N'Name',    2),
 ('bbbbbbb1-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', N'GoneAway', 3),
 ('ccccccc1-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', N'ID',      1),
 ('ccccccc1-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', N'Name',    2),
 ('ccccccc1-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', N'Extra',   4),
 ('ddddddd1-0000-0000-0000-000000000001', '44444444-4444-4444-4444-444444444444', N'ID',      1),
 ('ddddddd1-0000-0000-0000-000000000002', '44444444-4444-4444-4444-444444444444', N'Name', 100001);
GO
`;

/** Repair every seeded defect. The same queries must now return nothing. */
const FIXTURE_REPAIR = `
INSERT INTO [__mj].[EntityField] (ID, EntityID, Name, Sequence)
 VALUES ('aaaaaaa1-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', N'ParentIDPath', 3);
DELETE FROM [__mj].[EntityField] WHERE Name = N'GoneAway';
UPDATE [__mj].[EntityField] SET Sequence = 3 WHERE ID = 'ccccccc1-0000-0000-0000-000000000003';
UPDATE [__mj].[EntityField] SET Sequence = 2 WHERE ID = 'ddddddd1-0000-0000-0000-000000000002';
GO
`;

/** Every finding the dirty fixture must produce, as `KIND table detail`. */
const EXPECTED_DIRTY = [
    'MISSING Widget ParentIDPath',
    'PHANTOM Gadget GoneAway',
    'SEQUENCE Doohickey 2/1/100001/2',
    'SEQUENCE Sprocket 3/1/4/3',
    'BAND Doohickey Name',
].sort();

function dropSelfTestDb() {
    exec(`IF DB_ID(${literal(SELF_TEST_DB)}) IS NOT NULL
          BEGIN
              ALTER DATABASE ${bracket(SELF_TEST_DB)} SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
              DROP DATABASE ${bracket(SELF_TEST_DB)};
          END`, 'master');
}

function selfTest() {
    console.log(`Running check-entityfield-drift self-test ${DIM}(via ${SQLCMD}, fixture database `
        + `${SELF_TEST_DB})${NC}...`);

    dropSelfTestDb();
    exec(`CREATE DATABASE ${bracket(SELF_TEST_DB)};`, 'master');

    try {
        execScript(FIXTURE_DIRTY, SELF_TEST_DB);

        const dirty = runChecks(SELF_TEST_DB).map((f) => `${f.kind} ${f.table} ${f.detail}`).sort();
        if (JSON.stringify(dirty) !== JSON.stringify(EXPECTED_DIRTY)) {
            console.error(`${RED}Self-test failed: the detectors did not report the seeded defects.${NC}`);
            console.error(`  expected: ${JSON.stringify(EXPECTED_DIRTY, null, 2)}`);
            console.error(`  actual:   ${JSON.stringify(dirty, null, 2)}`);
            return 1;
        }
        console.log(`${GREEN}✓${NC} all four detectors fired on the seeded defects `
            + `${DIM}(${dirty.length} findings)${NC}`);

        execScript(FIXTURE_REPAIR, SELF_TEST_DB);

        const repaired = runChecks(SELF_TEST_DB);
        if (repaired.length !== 0) {
            console.error(`${RED}Self-test failed: the repaired fixture still reports drift.${NC}`);
            for (const finding of repaired) console.error(`  ${finding.kind}: ${finding.message}`);
            return 1;
        }
        console.log(`${GREEN}✓${NC} all four detectors went quiet once the fixture was repaired`);
    } finally {
        dropSelfTestDb();
    }

    console.log(`${GREEN}✓ check-entityfield-drift self-test passed${NC}`);
    return 0;
}

// ─── Entry point ──────────────────────────────────────────────────────────────────────────────

try {
    if (process.argv.includes('--self-test')) {
        process.exit(selfTest());
    }

    const database = argValue('--database') || process.env.DB_DATABASE;
    if (!database) {
        console.error('::error::No database to check. Pass --database <name> or set DB_DATABASE.');
        process.exit(2);
    }

    console.log(`Checking ${APP_SCHEMA} EntityField drift on ${database} ${DIM}(via ${SQLCMD})${NC}`);
    process.exit(report(runChecks(database), database));
} catch (err) {
    console.error(`::error::The check could not run: ${err.message}`);
    process.exit(2);
}
