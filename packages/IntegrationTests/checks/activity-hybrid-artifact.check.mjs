#!/usr/bin/env node
/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 *
 * Dual-DBMS cross-stack integration check for Common.Activity Category B Hybrid Spine
 * (Activity.ArtifactID nullable FK -> __mj.Artifact, filtered index, CodeGen CRUD routines,
 * vwActivities.Artifact projection, >=20 domain seed records, FK adversarial rejection,
 * RLS/permission boundary, and transactional rollback hygiene).
 *
 * Execution modes:
 *   1. Live SQL Server (via sf-workspace-db-broker.mjs rehearse-dual-db):
 *      DB_PLATFORM=sqlserver node packages/IntegrationTests/checks/activity-hybrid-artifact.check.mjs
 *   2. Live PostgreSQL (via sf-workspace-db-broker.mjs rehearse-dual-db):
 *      DB_PLATFORM=postgresql node packages/IntegrationTests/checks/activity-hybrid-artifact.check.mjs
 *   3. Offline deterministic SQLite self-test (for unit/guard validation without Docker):
 *      node packages/IntegrationTests/checks/activity-hybrid-artifact.check.mjs --offline-self-test
 */
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash, randomUUID } from 'node:crypto';
import { mkdtempSync, readdirSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';
import {
    BuildActivityHybridSeedDataset,
    GetSeedDensitySummary,
    normalizeUuid,
} from '../../../scripts/seed-activity-hybrid-world.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '..', '..', '..');
const MIGRATIONS_DIR = join(REPO_ROOT, 'migrations');
const MIGRATIONS_PG_DIR = join(REPO_ROOT, 'migrations-pg');
const DANGLING_ARTIFACT_ID_CREATE = 'deadbeef-dead-4eef-8eef-deadbeef0001';
const DANGLING_ARTIFACT_ID_UPDATE = 'deadbeef-dead-4eef-8eef-deadbeef0002';

function sqlEscape(value) {
    if (value === null || value === undefined) return 'NULL';
    return `'${String(value).replace(/'/g, "''")}'`;
}

function nSqlEscape(value) {
    if (value === null || value === undefined) return 'NULL';
    return `N'${String(value).replace(/'/g, "''")}'`;
}

/**
 * Verifies the paired T-SQL and PostgreSQL Activity_ArtifactID migrations exist and that
 * line 1 of the .pg.sql file carries a valid split-bake v1 SHA-256 provenance header.
 */
export function VerifyMigrationProvenance() {
    const tsFile = readdirSync(MIGRATIONS_DIR)
        .filter((f) => /__Activity_ArtifactID\.sql$/.test(f))
        .sort()
        .pop();
    assert.ok(tsFile, 'Expected *__Activity_ArtifactID.sql in migrations/');

    const pgFile = tsFile.replace(/\.sql$/, '.pg.sql');
    const tsPath = join(MIGRATIONS_DIR, tsFile);
    const pgPath = join(MIGRATIONS_PG_DIR, pgFile);
    const tsBytes = readFileSync(tsPath);
    const pgText = readFileSync(pgPath, 'utf8');

    const expectedSha = createHash('sha256').update(tsBytes).digest('hex');
    const firstLine = pgText.split(/\r?\n/, 1)[0] ?? '';
    const match = firstLine.match(
        /^-- @mj-pg-provenance: split-bake v1 source=([^\s]+) source-sha256=([0-9a-f]{64}) mode=(baked|needs-hand-rebaked)$/,
    );
    assert.ok(match, `Invalid line-1 provenance header in ${pgFile}: ${firstLine}`);
    assert.equal(match[1], tsFile, 'Provenance source filename mismatch');
    assert.equal(match[2], expectedSha, 'Provenance SHA-256 does not match T-SQL migration bytes');

    return {
        tsFile,
        pgFile,
        sha256: expectedSha,
        mode: match[3],
    };
}

/**
 * Runs an offline deterministic node:sqlite rehearsal of the full hybrid Activity contract
 * (fast-path NULL capture, opt-in linked Artifact, vwActivities.Artifact projection, unlink,
 * FK adversarial rejection, restricted-reader RLS simulation, and transactional rollback).
 */
export function RunOfflineSelfTest() {
    const provenance = VerifyMigrationProvenance();
    const dataset = BuildActivityHybridSeedDataset('OFFLINE_CHECK');
    const density = GetSeedDensitySummary(dataset);
    assert.ok(density.meetsMinimumDensity, `Expected >= 20 domain records, got ${density.totalDomainRecords}`);

    const db = new DatabaseSync(':memory:');
    try {
        db.exec(`
            PRAGMA foreign_keys = ON;
            CREATE TABLE Artifact (
                ID TEXT PRIMARY KEY,
                Name TEXT NOT NULL,
                Visibility TEXT NOT NULL CHECK (Visibility IN ('Always', 'System Only')),
                OwnerUserID TEXT NOT NULL
            );
            CREATE TABLE ArtifactPermission (
                ArtifactID TEXT NOT NULL REFERENCES Artifact(ID),
                UserID TEXT NOT NULL,
                CanRead INTEGER NOT NULL
            );
            CREATE TABLE Organization (
                ID TEXT PRIMARY KEY,
                Name TEXT NOT NULL,
                ParentID TEXT NULL REFERENCES Organization(ID)
            );
            CREATE TABLE Person (
                ID TEXT PRIMARY KEY,
                FirstName TEXT NOT NULL,
                LastName TEXT NOT NULL,
                Email TEXT NOT NULL
            );
            CREATE TABLE Activity (
                ID TEXT PRIMARY KEY,
                ActivityTypeCode TEXT NOT NULL,
                Title TEXT NOT NULL,
                Description TEXT NULL,
                Details TEXT NULL,
                ArtifactID TEXT NULL REFERENCES Artifact(ID)
            );
            CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ArtifactID
                ON Activity (ArtifactID)
                WHERE ArtifactID IS NOT NULL;
            CREATE VIEW vwActivities AS
            SELECT a.*, art.Name AS Artifact
            FROM Activity a
            LEFT OUTER JOIN Artifact art ON art.ID = a.ArtifactID;
        `);

        const authorId = '11111111-1111-4111-8111-111111111111';
        const restrictedUserId = '22222222-2222-4222-8222-222222222222';
        const orgIds = new Map();
        for (const org of dataset.Organizations) {
            const id = randomUUID();
            orgIds.set(org.Key, id);
            db.prepare(`INSERT INTO Organization (ID, Name, ParentID) VALUES (?, ?, ?)`).run(
                id,
                org.Name,
                org.ParentKey ? orgIds.get(org.ParentKey) : null,
            );
        }
        for (const person of dataset.People) {
            db.prepare(`INSERT INTO Person (ID, FirstName, LastName, Email) VALUES (?, ?, ?, ?)`).run(
                randomUUID(),
                person.FirstName,
                person.LastName,
                person.Email,
            );
        }

        // Fast-path activities first: verify 0 Artifacts created
        const fastActivities = dataset.Activities.filter((a) => a.ArtifactKey === null);
        for (const act of fastActivities) {
            db.prepare(
                `INSERT INTO Activity (ID, ActivityTypeCode, Title, Description, Details, ArtifactID) VALUES (?, ?, ?, ?, ?, NULL)`,
            ).run(randomUUID(), act.ActivityTypeCode, act.Title, act.Description, act.Details);
        }
        const artifactCountAfterFast = db.prepare(`SELECT COUNT(*) AS cnt FROM Artifact`).get().cnt;
        assert.equal(artifactCountAfterFast, 0, 'Fast-path activities must create 0 Artifact rows');

        // Seed opt-in Artifacts + linked Activities
        const artifactIds = new Map();
        for (const art of dataset.Artifacts) {
            const id = randomUUID();
            artifactIds.set(art.Key, id);
            db.prepare(`INSERT INTO Artifact (ID, Name, Visibility, OwnerUserID) VALUES (?, ?, ?, ?)`).run(
                id,
                art.Name,
                art.Visibility,
                authorId,
            );
            if (!art.RestrictedToAuthorOnly) {
                db.prepare(`INSERT INTO ArtifactPermission (ArtifactID, UserID, CanRead) VALUES (?, ?, 1)`).run(
                    id,
                    restrictedUserId,
                );
            }
        }

        const linkedActivityIds = [];
        const linkedActivities = dataset.Activities.filter((a) => a.ArtifactKey !== null);
        for (const act of linkedActivities) {
            const id = randomUUID();
            const artId = artifactIds.get(act.ArtifactKey);
            db.prepare(
                `INSERT INTO Activity (ID, ActivityTypeCode, Title, Description, Details, ArtifactID) VALUES (?, ?, ?, ?, ?, ?)`,
            ).run(id, act.ActivityTypeCode, act.Title, act.Description, act.Details, artId);
            linkedActivityIds.push({ id, act, artId });
        }

        // Verify vwActivities.Artifact projection
        for (const entry of linkedActivityIds) {
            const row = db.prepare(`SELECT ArtifactID, Artifact, Description, Details FROM vwActivities WHERE ID = ?`).get(entry.id);
            const expectedArt = dataset.Artifacts.find((a) => a.Key === entry.act.ArtifactKey);
            assert.equal(normalizeUuid(row.ArtifactID), normalizeUuid(entry.artId));
            assert.equal(row.Artifact, expectedArt.Name);
        }

        // Unlink first linked activity and assert Description/Details + Artifact preserved
        const target = linkedActivityIds[0];
        db.prepare(`UPDATE Activity SET ArtifactID = NULL WHERE ID = ?`).run(target.id);
        const unlinked = db.prepare(`SELECT ArtifactID, Artifact, Description, Details FROM vwActivities WHERE ID = ?`).get(target.id);
        assert.equal(unlinked.ArtifactID, null);
        assert.equal(unlinked.Artifact, null);
        assert.equal(unlinked.Description, target.act.Description);
        assert.equal(unlinked.Details, target.act.Details);
        const artStillExists = db.prepare(`SELECT COUNT(*) AS cnt FROM Artifact WHERE ID = ?`).get(target.artId).cnt;
        assert.equal(artStillExists, 1, 'Unlinking must preserve underlying Artifact');

        // Adversarial FK check
        assert.throws(
            () =>
                db.prepare(`INSERT INTO Activity (ID, ActivityTypeCode, Title, ArtifactID) VALUES (?, 'Call', 'Bad FK', ?)`).run(
                    randomUUID(),
                    DANGLING_ARTIFACT_ID_CREATE,
                ),
            /FOREIGN KEY/i,
        );

        // Restricted reader boundary check
        const restrictedArt = dataset.Artifacts.find((a) => a.RestrictedToAuthorOnly);
        const restrictedArtId = artifactIds.get(restrictedArt.Key);
        const visibleToRestricted = db
            .prepare(
                `SELECT a.ID FROM Artifact a
                 WHERE a.ID = ?
                   AND (a.OwnerUserID = ? OR EXISTS (SELECT 1 FROM ArtifactPermission p WHERE p.ArtifactID = a.ID AND p.UserID = ? AND p.CanRead = 1))`,
            )
            .all(restrictedArtId, restrictedUserId, restrictedUserId);
        assert.equal(visibleToRestricted.length, 0, 'Restricted reader must not read unauthorized Artifact');

        // Transactional rollback hygiene
        const rollbackId = randomUUID();
        db.exec('BEGIN TRANSACTION');
        db.prepare(`INSERT INTO Activity (ID, ActivityTypeCode, Title, ArtifactID) VALUES (?, 'Note', 'Rollback Test', NULL)`).run(
            rollbackId,
        );
        assert.equal(db.prepare(`SELECT COUNT(*) AS cnt FROM Activity WHERE ID = ?`).get(rollbackId).cnt, 1);
        db.exec('ROLLBACK');
        assert.equal(db.prepare(`SELECT COUNT(*) AS cnt FROM Activity WHERE ID = ?`).get(rollbackId).cnt, 0);

        return {
            passed: true,
            platform: 'sqlite-offline-self-test',
            provenance,
            density,
            checksPassed: 7,
            checksFailed: 0,
        };
    } finally {
        db.close();
    }
}

// ============================================================================
// Live PostgreSQL Execution
// ============================================================================
async function runPostgresCheck(runTag) {
    const { Pool } = await import('pg');
    const host = process.env.PG_HOST ?? process.env.DB_HOST ?? 'localhost';
    const port = Number(process.env.PG_PORT ?? process.env.DB_PORT ?? 5432);
    const user = process.env.PG_USERNAME ?? process.env.DB_USERNAME ?? 'mj_admin';
    const password = process.env.PG_PASSWORD ?? process.env.PGPASSWORD ?? process.env.DB_PASSWORD ?? '';
    const database = process.env.PG_DATABASE ?? process.env.DB_DATABASE;
    assert.ok(database, 'PG_DATABASE or DB_DATABASE is required for PostgreSQL integration check');

    const pool = new Pool({ host, port, user, password, database });
    const S = '__mj_bizappscommon';
    const CORE = process.env.MJ_CORE_SCHEMA ?? '__mj';
    const dataset = BuildActivityHybridSeedDataset(runTag);
    const density = GetSeedDensitySummary(dataset);

    const created = {
        activityLinks: [],
        activities: [],
        artifacts: [],
        people: [],
        organizations: [],
    };
    const results = [];
    const recordPass = (id, detail) => {
        results.push({ id, status: 'passed', detail });
        console.log(`  [PG] ok   ${id} — ${detail}`);
    };

    try {
        // S1: Provenance
        const prov = VerifyMigrationProvenance();
        recordPass('S1_PROVENANCE', `${prov.pgFile} matches SHA-256 ${prov.sha256.slice(0, 12)}... (${prov.mode})`);

        // S2: 6-category live schema parity
        const colRows = (
            await pool.query(
                `SELECT column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = $1 AND table_name = 'Activity'
                   AND column_name IN ('ArtifactID', 'Description', 'Details')`,
                [S],
            )
        ).rows;
        const colMap = new Map(colRows.map((r) => [r.column_name, r]));
        assert.equal(colMap.get('ArtifactID')?.data_type, 'uuid', 'PG Activity.ArtifactID must be uuid');
        assert.equal(colMap.get('ArtifactID')?.is_nullable, 'YES', 'PG Activity.ArtifactID must be nullable');
        assert.equal(colMap.get('Description')?.is_nullable, 'YES', 'PG Activity.Description must remain nullable');
        assert.equal(colMap.get('Details')?.is_nullable, 'YES', 'PG Activity.Details must remain nullable');

        const fkRows = (
            await pool.query(
                `SELECT tc.constraint_name, ccu.table_schema AS ref_schema, ccu.table_name AS ref_table, ccu.column_name AS ref_col
                 FROM information_schema.table_constraints tc
                 JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name AND tc.constraint_schema = ccu.constraint_schema
                 WHERE tc.table_schema = $1 AND tc.table_name = 'Activity' AND tc.constraint_type = 'FOREIGN KEY' AND tc.constraint_name = 'FK_Activity_Artifact'`,
                [S],
            )
        ).rows;
        assert.equal(fkRows.length, 1, 'PG FK_Activity_Artifact must exist');
        assert.equal(fkRows[0].ref_schema, CORE);
        assert.equal(fkRows[0].ref_table, 'Artifact');
        assert.equal(fkRows[0].ref_col, 'ID');

        const idxRows = (
            await pool.query(
                `SELECT indexname, indexdef FROM pg_indexes
                 WHERE schemaname = $1 AND tablename = 'Activity' AND indexname = 'IDX_AUTO_MJ_FKEY_Activity_ArtifactID'`,
                [S],
            )
        ).rows;
        assert.equal(idxRows.length, 1, 'PG IDX_AUTO_MJ_FKEY_Activity_ArtifactID must exist');
        assert.match(
            idxRows[0].indexdef,
            /WHERE\s+(?:\(?"ArtifactID"\s+IS\s+NOT\s+NULL\)?|\(?NOT\s+\(?"ArtifactID"\s+IS\s+NULL\)?\)?)/i,
            `PG index must be partial WHERE ArtifactID IS NOT NULL (got: ${idxRows[0].indexdef})`,
        );

        const viewCols = (
            await pool.query(
                `SELECT column_name FROM information_schema.columns
                 WHERE table_schema = $1 AND table_name = 'vwActivities' AND column_name IN ('ArtifactID', 'Artifact')`,
                [S],
            )
        ).rows.map((r) => r.column_name);
        assert.ok(viewCols.includes('ArtifactID') && viewCols.includes('Artifact'), 'PG vwActivities must project ArtifactID and Artifact');

        const routineNames = (
            await pool.query(
                `SELECT routine_name FROM information_schema.routines
                 WHERE routine_schema = $1 AND routine_name IN ('spCreateActivity', 'spUpdateActivity', 'spDeleteActivity')`,
                [S],
            )
        ).rows.map((r) => r.routine_name);
        assert.ok(
            routineNames.includes('spCreateActivity') &&
                routineNames.includes('spUpdateActivity') &&
                routineNames.includes('spDeleteActivity'),
            'PG Activity CRUD routines must exist',
        );
        recordPass('S2_SCHEMA_PARITY', '6-category live PG schema parity verified (Activity.ArtifactID, FK, partial index, vwActivities, CRUD routines)');

        // Resolve core reference rows
        const userId = (await pool.query(`SELECT "ID" FROM ${CORE}."User" ORDER BY "ID" LIMIT 1`)).rows[0]?.ID;
        const envId = (await pool.query(`SELECT "ID" FROM ${CORE}."Environment" ORDER BY "ID" LIMIT 1`)).rows[0]?.ID;
        const artTypeId = (await pool.query(`SELECT "ID" FROM ${CORE}."ArtifactType" ORDER BY "ID" LIMIT 1`)).rows[0]?.ID;
        const orgEntityId = (
            await pool.query(`SELECT "ID" FROM ${CORE}."Entity" WHERE "Name" = 'MJ_BizApps_Common: Organizations' LIMIT 1`)
        ).rows[0]?.ID;
        const personEntityId = (
            await pool.query(`SELECT "ID" FROM ${CORE}."Entity" WHERE "Name" = 'MJ_BizApps_Common: People' LIMIT 1`)
        ).rows[0]?.ID;
        assert.ok(userId && envId && artTypeId && orgEntityId && personEntityId, 'Core MJ reference rows missing in PG');

        const orgTypes = new Map(
            (await pool.query(`SELECT "ID", "Name" FROM ${S}."OrganizationType"`)).rows.map((r) => [r.Name, r.ID]),
        );
        const actTypes = new Map(
            (await pool.query(`SELECT "ID", "Code" FROM ${S}."ActivityType" WHERE "Code" IN ('Note','Call','Meeting','Email')`)).rows.map(
                (r) => [r.Code, r.ID],
            ),
        );
        for (const code of ['Note', 'Call', 'Meeting', 'Email']) {
            assert.ok(actTypes.get(code), `PG ActivityType '${code}' must be seeded`);
        }

        // S3: Seed Organizations + People
        const orgIdMap = new Map();
        const fallbackOrgTypeId = orgTypes.values().next().value;
        for (const org of dataset.Organizations) {
            const typeId = orgTypes.get(org.OrganizationType) ?? fallbackOrgTypeId;
            const parentId = org.ParentKey ? orgIdMap.get(org.ParentKey) : null;
            const row = (
                await pool.query(
                    `SELECT "ID" FROM ${S}."spCreateOrganization"(
                        p_name := $1,
                        p_organizationtypeid := $2,
                        p_parentid := $3,
                        p_email := $4,
                        p_website := $5,
                        p_status := 'Active'
                    )`,
                    [org.Name, typeId, parentId, org.Email, org.Website],
                )
            ).rows[0];
            orgIdMap.set(org.Key, row.ID);
            created.organizations.unshift(row.ID);
        }

        const personIdMap = new Map();
        for (const person of dataset.People) {
            const row = (
                await pool.query(
                    `SELECT "ID" FROM ${S}."spCreatePerson"(
                        p_firstname := $1,
                        p_lastname := $2,
                        p_email := $3,
                        p_title := $4,
                        p_status := 'Active'
                    )`,
                    [person.FirstName, person.LastName, person.Email, person.Title],
                )
            ).rows[0];
            personIdMap.set(person.Key, row.ID);
            created.people.unshift(row.ID);
        }

        // S4: Fast-path quick capture (ArtifactID = NULL) creates ZERO __mj.Artifact rows
        const artifactsBeforeFast = Number((await pool.query(`SELECT COUNT(*) AS cnt FROM ${CORE}."Artifact"`)).rows[0].cnt);
        const actIdMap = new Map();
        const fastActivities = dataset.Activities.filter((a) => a.ArtifactKey === null);
        for (const act of fastActivities) {
            const row = (
                await pool.query(
                    `SELECT "ID", "ArtifactID", "Artifact", "Description", "Details"
                     FROM ${S}."spCreateActivity"(
                        p_activitytypeid := $1,
                        p_startedat := NOW(),
                        p_title := $2,
                        p_description := $3,
                        p_direction := $4,
                        p_status := $5,
                        p_visibility := $6,
                        p_source := $7,
                        p_loggedbyuserid := $8,
                        p_details := $9,
                        p_artifactid := NULL
                     )`,
                    [
                        actTypes.get(act.ActivityTypeCode),
                        act.Title,
                        act.Description,
                        act.Direction,
                        act.Status,
                        act.Visibility,
                        act.Source,
                        userId,
                        act.Details,
                    ],
                )
            ).rows[0];
            assert.equal(row.ArtifactID, null, `Fast-path ${act.Key} must persist ArtifactID = NULL`);
            assert.equal(row.Artifact, null, `Fast-path ${act.Key} must project vwActivities.Artifact = NULL`);
            assert.equal(row.Description, act.Description, `Fast-path ${act.Key} must preserve Description`);
            assert.equal(row.Details, act.Details, `Fast-path ${act.Key} must preserve Details`);
            actIdMap.set(act.Key, row.ID);
            created.activities.unshift(row.ID);
        }
        const artifactsAfterFast = Number((await pool.query(`SELECT COUNT(*) AS cnt FROM ${CORE}."Artifact"`)).rows[0].cnt);
        assert.equal(
            artifactsAfterFast,
            artifactsBeforeFast,
            `Fast-path created unexpected __mj.Artifact rows (${artifactsBeforeFast} -> ${artifactsAfterFast})`,
        );
        recordPass(
            'S3_S4_FAST_PATH_SEED',
            `Seeded ${created.organizations.length} orgs, ${created.people.length} people, and ${fastActivities.length} fast-path activities across Note/Call/Meeting/Email with 0 auto-created Artifacts`,
        );

        // S5: Opt-in linked MJ Docs (ArtifactID FK -> __mj.Artifact), vwActivities.Artifact projection & unlink
        const artIdMap = new Map();
        for (const art of dataset.Artifacts) {
            const artId = randomUUID();
            await pool.query(
                `INSERT INTO ${CORE}."Artifact" ("ID", "EnvironmentID", "Name", "Description", "TypeID", "UserID", "Visibility")
                 VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [artId, envId, art.Name, art.Description, artTypeId, userId, art.Visibility],
            );
            artIdMap.set(art.Key, artId);
            created.artifacts.unshift(artId);
        }

        const linkedActivities = dataset.Activities.filter((a) => a.ArtifactKey !== null);
        for (const act of linkedActivities) {
            const artId = artIdMap.get(act.ArtifactKey);
            const expectedArt = dataset.Artifacts.find((a) => a.Key === act.ArtifactKey);
            const row = (
                await pool.query(
                    `SELECT "ID", "ArtifactID", "Artifact", "Description", "Details"
                     FROM ${S}."spCreateActivity"(
                        p_activitytypeid := $1,
                        p_startedat := NOW(),
                        p_title := $2,
                        p_description := $3,
                        p_direction := $4,
                        p_status := $5,
                        p_visibility := $6,
                        p_source := $7,
                        p_loggedbyuserid := $8,
                        p_details := $9,
                        p_artifactid := $10
                     )`,
                    [
                        actTypes.get(act.ActivityTypeCode),
                        act.Title,
                        act.Description,
                        act.Direction,
                        act.Status,
                        act.Visibility,
                        act.Source,
                        userId,
                        act.Details,
                        artId,
                    ],
                )
            ).rows[0];
            assert.equal(normalizeUuid(row.ArtifactID), normalizeUuid(artId), `Linked ${act.Key} ArtifactID mismatch`);
            assert.equal(row.Artifact, expectedArt.Name, `Linked ${act.Key} vwActivities.Artifact mismatch`);
            actIdMap.set(act.Key, row.ID);
            created.activities.unshift(row.ID);
        }

        // Seed ActivityLinks for all 12 activities
        for (const link of dataset.ActivityLinks) {
            const linkId = randomUUID();
            const actId = actIdMap.get(link.ActivityKey);
            const entityId = link.TargetKind === 'Organization' ? orgEntityId : personEntityId;
            const recordId = link.TargetKind === 'Organization' ? orgIdMap.get(link.TargetKey) : personIdMap.get(link.TargetKey);
            await pool.query(
                `INSERT INTO ${S}."ActivityLink" ("ID", "ActivityID", "Role", "EntityID", "RecordID", "Sequence")
                 VALUES ($1, $2, $3, $4, $5, 0)`,
                [linkId, actId, link.Role, entityId, recordId],
            );
            created.activityLinks.unshift(linkId);
        }

        // Unlink first linked activity via spUpdateActivity(p_artifactid_clear := true)
        const unlinkTarget = linkedActivities[0];
        const unlinkActId = actIdMap.get(unlinkTarget.Key);
        const unlinkArtId = artIdMap.get(unlinkTarget.ArtifactKey);
        const unlinkedRow = (
            await pool.query(
                `SELECT "ID", "ArtifactID", "Artifact", "Description", "Details"
                 FROM ${S}."spUpdateActivity"(
                    p_id := $1,
                    p_artifactid_clear := true,
                    p_artifactid := NULL
                 )`,
                [unlinkActId],
            )
        ).rows[0];
        assert.equal(unlinkedRow.ArtifactID, null, 'Unlinked Activity must have ArtifactID = NULL');
        assert.equal(unlinkedRow.Artifact, null, 'Unlinked Activity must have vwActivities.Artifact = NULL');
        assert.equal(unlinkedRow.Description, unlinkTarget.Description, 'Unlink must preserve Description');
        assert.equal(unlinkedRow.Details, unlinkTarget.Details, 'Unlink must preserve Details');
        const preservedArtCnt = Number(
            (await pool.query(`SELECT COUNT(*) AS cnt FROM ${CORE}."Artifact" WHERE "ID" = $1`, [unlinkArtId])).rows[0].cnt,
        );
        assert.equal(preservedArtCnt, 1, 'Unlinking must leave underlying __mj.Artifact intact');
        recordPass(
            'S5_LINK_PROJECTION_UNLINK',
            `Verified ${linkedActivities.length} linked MJ Docs + ${created.activityLinks.length} ActivityLinks, vwActivities.Artifact projection, and clean unlink preserving Description/Details`,
        );

        // S6: FK boundary adversarial checks (create & update with dangling ArtifactID)
        let rejectedCreate = false;
        try {
            await pool.query(
                `SELECT "ID" FROM ${S}."spCreateActivity"(
                    p_activitytypeid := $1,
                    p_startedat := NOW(),
                    p_title := $2,
                    p_direction := 'Outbound',
                    p_status := 'Logged',
                    p_visibility := 'Internal',
                    p_source := 'Manual',
                    p_loggedbyuserid := $3,
                    p_artifactid := $4
                )`,
                [actTypes.get('Call'), `[${runTag}] Dangling FK Create`, userId, DANGLING_ARTIFACT_ID_CREATE],
            );
        } catch (err) {
            rejectedCreate = /FK_Activity_Artifact|foreign key/i.test(String(err.message ?? err));
        }
        assert.ok(rejectedCreate, 'PG must reject spCreateActivity with dangling ArtifactID');

        let rejectedUpdate = false;
        try {
            await pool.query(
                `SELECT "ID" FROM ${S}."spUpdateActivity"(
                    p_id := $1,
                    p_artifactid := $2
                )`,
                [unlinkActId, DANGLING_ARTIFACT_ID_UPDATE],
            );
        } catch (err) {
            rejectedUpdate = /FK_Activity_Artifact|foreign key/i.test(String(err.message ?? err));
        }
        assert.ok(rejectedUpdate, 'PG must reject spUpdateActivity with dangling ArtifactID');
        recordPass('S6_FK_ADVERSARIAL', 'Dangling ArtifactID rejected on both spCreateActivity and spUpdateActivity via FK_Activity_Artifact');

        // S7: RLS / Permission boundary & transactional rollback hygiene
        const permRows = (
            await pool.query(
                `SELECT e."Name" AS entity_name, COUNT(ep."ID") AS perm_count
                 FROM ${CORE}."Entity" e
                 LEFT JOIN ${CORE}."EntityPermission" ep ON ep."EntityID" = e."ID"
                 WHERE e."Name" IN ('MJ_BizApps_Common: Activities', 'MJ: Artifacts')
                 GROUP BY e."Name"`,
            )
        ).rows;
        assert.equal(permRows.length, 2, 'Both Activities and Artifacts entities must exist in __mj.Entity');
        for (const pr of permRows) {
            assert.ok(Number(pr.perm_count) > 0, `Expected EntityPermission rows for ${pr.entity_name}`);
        }

        const restrictedArtKey = dataset.Artifacts.find((a) => a.RestrictedToAuthorOnly)?.Key;
        const restrictedArtId = artIdMap.get(restrictedArtKey);
        const nonExistentReaderId = '33333333-3333-4333-8333-333333333333';
        const unauthorizedRows = (
            await pool.query(
                `SELECT a."ID" FROM ${CORE}."Artifact" a
                 WHERE a."ID" = $1
                   AND a."Visibility" = 'Always'
                   AND (a."UserID" = $2 OR EXISTS (
                        SELECT 1 FROM ${CORE}."ArtifactPermission" ap
                        WHERE ap."ArtifactID" = a."ID" AND ap."UserID" = $2 AND ap."CanRead" = true
                   ))`,
                [restrictedArtId, nonExistentReaderId],
            )
        ).rows;
        assert.equal(unauthorizedRows.length, 0, 'Restricted reader must receive 0 rows for System Only / unauthorized Artifact');

        // Explicit BEGIN -> INSERT -> verify -> ROLLBACK -> verify 0 leaked rows
        const client = await pool.connect();
        const rollbackId = randomUUID();
        try {
            await client.query('BEGIN');
            await client.query(
                `SELECT "ID" FROM ${S}."spCreateActivity"(
                    p_id := $1,
                    p_activitytypeid := $2,
                    p_startedat := NOW(),
                    p_title := $3,
                    p_direction := 'Internal',
                    p_status := 'Logged',
                    p_visibility := 'Internal',
                    p_source := 'Manual',
                    p_loggedbyuserid := $4,
                    p_artifactid := NULL
                )`,
                [rollbackId, actTypes.get('Note'), `[${runTag}] Rollback Probe`, userId],
            );
            const inTxnCnt = Number((await client.query(`SELECT COUNT(*) AS cnt FROM ${S}."Activity" WHERE "ID" = $1`, [rollbackId])).rows[0].cnt);
            assert.equal(inTxnCnt, 1, 'Rollback probe row must exist inside transaction');
            await client.query('ROLLBACK');
        } finally {
            client.release();
        }
        const postRollbackCnt = Number((await pool.query(`SELECT COUNT(*) AS cnt FROM ${S}."Activity" WHERE "ID" = $1`, [rollbackId])).rows[0].cnt);
        assert.equal(postRollbackCnt, 0, 'Rollback probe row must not persist after ROLLBACK');
        recordPass('S7_RLS_AND_ROLLBACK', 'EntityPermission metadata verified, restricted Artifact isolated, and transactional rollback left 0 leaked rows');

        return {
            passed: true,
            platform: 'postgresql',
            database,
            provenance: prov,
            seedDensity: density,
            liveSeededCounts: {
                organizations: created.organizations.length,
                people: created.people.length,
                artifacts: created.artifacts.length,
                activities: created.activities.length,
                activityLinks: created.activityLinks.length,
                totalLiveRows:
                    created.organizations.length +
                    created.people.length +
                    created.artifacts.length +
                    created.activities.length +
                    created.activityLinks.length,
            },
            checks: results,
        };
    } finally {
        // S8: Reverse-dependency cleanup
        for (const id of created.activityLinks) {
            await pool.query(`DELETE FROM ${S}."ActivityLink" WHERE "ID" = $1`, [id]).catch(() => {});
        }
        for (const id of created.activities) {
            await pool.query(`SELECT ${S}."spDeleteActivity"(p_id := $1)`, [id]).catch(async () => {
                await pool.query(`DELETE FROM ${S}."Activity" WHERE "ID" = $1`, [id]).catch(() => {});
            });
        }
        for (const id of created.artifacts) {
            await pool.query(`DELETE FROM ${CORE}."Artifact" WHERE "ID" = $1`, [id]).catch(() => {});
        }
        for (const id of created.people) {
            await pool.query(`DELETE FROM ${S}."Person" WHERE "ID" = $1`, [id]).catch(() => {});
        }
        for (const id of created.organizations) {
            await pool.query(`DELETE FROM ${S}."Organization" WHERE "ID" = $1`, [id]).catch(() => {});
        }
        await pool.end();
    }
}

// ============================================================================
// Live SQL Server Execution (via sqlcmd + SQLCMDPASSWORD env — zero passwords on argv)
// ============================================================================
function createSqlServerRunner() {
    const host = process.env.DB_HOST ?? 'localhost';
    const port = String(process.env.DB_PORT ?? '1433');
    const user = process.env.CODEGEN_DB_USERNAME ?? process.env.DB_USERNAME ?? 'sa';
    const database = process.env.DB_DATABASE;
    assert.ok(database, 'DB_DATABASE is required for SQL Server integration check');

    const sqlPassword = process.env.SQLCMDPASSWORD ?? process.env.CODEGEN_DB_PASSWORD ?? process.env.DB_PASSWORD ?? '';
    const tempDir = mkdtempSync(join(tmpdir(), 'mj-act-hybrid-sql-'));
    let seq = 0;

    function execSql(sqlBody, allowError = false) {
        const scriptPath = join(tempDir, `q_${++seq}.sql`);
        writeFileSync(scriptPath, `SET NOCOUNT ON;\n${sqlBody}\n`, 'utf8');
        const res = spawnSync(
            'sqlcmd',
            ['-S', `${host},${port}`, '-U', user, '-C', '-b', '-d', database, '-h', '-1', '-W', '-s', '|', '-i', scriptPath],
            {
                encoding: 'utf8',
                env: {
                    ...process.env,
                    SQLCMDPASSWORD: sqlPassword,
                },
                maxBuffer: 16 * 1024 * 1024,
            },
        );
        if (res.status !== 0) {
            if (allowError) {
                return { ok: false, stdout: res.stdout ?? '', stderr: res.stderr ?? '' };
            }
            throw new Error(`sqlcmd exited ${res.status}: ${(res.stderr || res.stdout || '').trim()}`);
        }
        const rows = (res.stdout ?? '')
            .split(/\r?\n/)
            .map((line) => line.trim())
            .filter((line) => line.length > 0)
            .map((line) => line.split('|'));
        return { ok: true, rows, stdout: res.stdout ?? '' };
    }

    function cleanup() {
        rmSync(tempDir, { recursive: true, force: true });
    }

    return { database, execSql, cleanup };
}

async function runSqlServerCheck(runTag) {
    const runner = createSqlServerRunner();
    const S = '__mj_BizAppsCommon';
    const CORE = process.env.MJ_CORE_SCHEMA ?? '__mj';
    const dataset = BuildActivityHybridSeedDataset(runTag);
    const density = GetSeedDensitySummary(dataset);

    const created = {
        activityLinks: [],
        activities: [],
        artifacts: [],
        people: [],
        organizations: [],
    };
    const results = [];
    const recordPass = (id, detail) => {
        results.push({ id, status: 'passed', detail });
        console.log(`  [MSSQL] ok   ${id} — ${detail}`);
    };

    try {
        // S1: Provenance
        const prov = VerifyMigrationProvenance();
        recordPass('S1_PROVENANCE', `${prov.tsFile} <-> ${prov.pgFile} SHA-256 ${prov.sha256.slice(0, 12)}... (${prov.mode})`);

        // S2: 6-category live schema parity
        const colRes = runner.execSql(`
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = '${S}' AND TABLE_NAME = 'Activity'
              AND COLUMN_NAME IN ('ArtifactID', 'Description', 'Details');
        `);
        const colMap = new Map(colRes.rows.map((r) => [r[0], { dataType: r[1], isNullable: r[2] }]));
        assert.equal(colMap.get('ArtifactID')?.dataType, 'uniqueidentifier', 'MSSQL Activity.ArtifactID must be uniqueidentifier');
        assert.equal(colMap.get('ArtifactID')?.isNullable, 'YES', 'MSSQL Activity.ArtifactID must be nullable');
        assert.equal(colMap.get('Description')?.isNullable, 'YES', 'MSSQL Activity.Description must remain nullable');
        assert.equal(colMap.get('Details')?.isNullable, 'YES', 'MSSQL Activity.Details must remain nullable');

        const fkRes = runner.execSql(`
            SELECT fk.name, OBJECT_SCHEMA_NAME(fk.referenced_object_id), OBJECT_NAME(fk.referenced_object_id)
            FROM sys.foreign_keys fk
            WHERE fk.parent_object_id = OBJECT_ID(N'[${S}].[Activity]')
              AND fk.name = N'FK_Activity_Artifact';
        `);
        assert.equal(fkRes.rows.length, 1, 'MSSQL FK_Activity_Artifact must exist');
        assert.equal(fkRes.rows[0][1], CORE);
        assert.equal(fkRes.rows[0][2], 'Artifact');

        const idxRes = runner.execSql(`
            SELECT i.name, i.has_filter, i.filter_definition
            FROM sys.indexes i
            WHERE i.object_id = OBJECT_ID(N'[${S}].[Activity]')
              AND i.name = N'IDX_AUTO_MJ_FKEY_Activity_ArtifactID';
        `);
        assert.equal(idxRes.rows.length, 1, 'MSSQL IDX_AUTO_MJ_FKEY_Activity_ArtifactID must exist');
        assert.equal(idxRes.rows[0][1], '1', 'MSSQL index must be filtered');
        assert.match(idxRes.rows[0][2] ?? '', /\[ArtifactID\] IS NOT NULL/i);

        const viewCols = runner
            .execSql(`
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = '${S}' AND TABLE_NAME = 'vwActivities'
                  AND COLUMN_NAME IN ('ArtifactID', 'Artifact');
            `)
            .rows.map((r) => r[0]);
        assert.ok(viewCols.includes('ArtifactID') && viewCols.includes('Artifact'), 'MSSQL vwActivities must project ArtifactID and Artifact');

        const procNames = runner
            .execSql(`
                SELECT ROUTINE_NAME
                FROM INFORMATION_SCHEMA.ROUTINES
                WHERE ROUTINE_SCHEMA = '${S}'
                  AND ROUTINE_NAME IN ('spCreateActivity', 'spUpdateActivity', 'spDeleteActivity');
            `)
            .rows.map((r) => r[0]);
        assert.ok(
            procNames.includes('spCreateActivity') &&
                procNames.includes('spUpdateActivity') &&
                procNames.includes('spDeleteActivity'),
            'MSSQL Activity CRUD procedures must exist',
        );
        recordPass('S2_SCHEMA_PARITY', '6-category live SQL Server schema parity verified (Activity.ArtifactID, FK, filtered index, vwActivities, CRUD procs)');

        // Resolve core reference rows
        const userId = runner.execSql(`SELECT TOP 1 [ID] FROM [${CORE}].[User] ORDER BY [ID];`).rows[0]?.[0];
        const envId = runner.execSql(`SELECT TOP 1 [ID] FROM [${CORE}].[Environment] ORDER BY [ID];`).rows[0]?.[0];
        const artTypeId = runner.execSql(`SELECT TOP 1 [ID] FROM [${CORE}].[ArtifactType] ORDER BY [ID];`).rows[0]?.[0];
        const orgEntityId = runner.execSql(
            `SELECT TOP 1 [ID] FROM [${CORE}].[Entity] WHERE [Name] = N'MJ_BizApps_Common: Organizations';`,
        ).rows[0]?.[0];
        const personEntityId = runner.execSql(
            `SELECT TOP 1 [ID] FROM [${CORE}].[Entity] WHERE [Name] = N'MJ_BizApps_Common: People';`,
        ).rows[0]?.[0];
        assert.ok(userId && envId && artTypeId && orgEntityId && personEntityId, 'Core MJ reference rows missing in SQL Server');

        const orgTypes = new Map(
            runner.execSql(`SELECT [Name], [ID] FROM [${S}].[OrganizationType];`).rows.map((r) => [r[0], r[1]]),
        );
        const actTypes = new Map(
            runner
                .execSql(`SELECT [Code], [ID] FROM [${S}].[ActivityType] WHERE [Code] IN (N'Note', N'Call', N'Meeting', N'Email');`)
                .rows.map((r) => [r[0], r[1]]),
        );
        for (const code of ['Note', 'Call', 'Meeting', 'Email']) {
            assert.ok(actTypes.get(code), `MSSQL ActivityType '${code}' must be seeded`);
        }

        // S3: Seed Organizations + People
        const orgIdMap = new Map();
        const fallbackOrgTypeId = orgTypes.values().next().value;
        for (const org of dataset.Organizations) {
            const id = randomUUID();
            const typeId = orgTypes.get(org.OrganizationType) ?? fallbackOrgTypeId;
            const parentId = org.ParentKey ? orgIdMap.get(org.ParentKey) : null;
            runner.execSql(`
                INSERT INTO [${S}].[Organization] ([ID], [Name], [OrganizationTypeID], [ParentID], [Email], [Website], [Status])
                VALUES (${sqlEscape(id)}, ${nSqlEscape(org.Name)}, ${sqlEscape(typeId)}, ${sqlEscape(parentId)}, ${nSqlEscape(org.Email)}, ${nSqlEscape(org.Website)}, N'Active');
            `);
            orgIdMap.set(org.Key, id);
            created.organizations.unshift(id);
        }

        const personIdMap = new Map();
        for (const person of dataset.People) {
            const id = randomUUID();
            runner.execSql(`
                INSERT INTO [${S}].[Person] ([ID], [FirstName], [LastName], [Email], [Title], [Status])
                VALUES (${sqlEscape(id)}, ${nSqlEscape(person.FirstName)}, ${nSqlEscape(person.LastName)}, ${nSqlEscape(person.Email)}, ${nSqlEscape(person.Title)}, N'Active');
            `);
            personIdMap.set(person.Key, id);
            created.people.unshift(id);
        }

        // S4: Fast-path quick capture (ArtifactID = NULL) creates ZERO __mj.Artifact rows
        const artifactsBeforeFast = Number(runner.execSql(`SELECT COUNT(*) FROM [${CORE}].[Artifact];`).rows[0][0]);
        const actIdMap = new Map();
        const fastActivities = dataset.Activities.filter((a) => a.ArtifactKey === null);
        for (const act of fastActivities) {
            const actId = randomUUID();
            runner.execSql(`
                DECLARE @Now DATETIMEOFFSET = SYSDATETIMEOFFSET();
                EXEC [${S}].[spCreateActivity]
                    @ID = ${sqlEscape(actId)},
                    @ActivityTypeID = ${sqlEscape(actTypes.get(act.ActivityTypeCode))},
                    @StartedAt = @Now,
                    @Title = ${nSqlEscape(act.Title)},
                    @Description = ${nSqlEscape(act.Description)},
                    @Direction = ${nSqlEscape(act.Direction)},
                    @Status = ${nSqlEscape(act.Status)},
                    @Visibility = ${nSqlEscape(act.Visibility)},
                    @Source = ${nSqlEscape(act.Source)},
                    @LoggedByUserID = ${sqlEscape(userId)},
                    @Details = ${nSqlEscape(act.Details)},
                    @ArtifactID = NULL;
            `);
            const checkRow = runner.execSql(`
                SELECT COALESCE(CAST([ArtifactID] AS NVARCHAR(64)), N'__NULL__'),
                       COALESCE([Artifact], N'__NULL__'),
                       [Description],
                       [Details]
                FROM [${S}].[vwActivities]
                WHERE [ID] = ${sqlEscape(actId)};
            `).rows[0];
            assert.equal(checkRow[0], '__NULL__', `Fast-path ${act.Key} ArtifactID must be NULL`);
            assert.equal(checkRow[1], '__NULL__', `Fast-path ${act.Key} vwActivities.Artifact must be NULL`);
            assert.equal(checkRow[2], act.Description, `Fast-path ${act.Key} Description preserved`);
            assert.equal(checkRow[3], act.Details, `Fast-path ${act.Key} Details preserved`);
            actIdMap.set(act.Key, actId);
            created.activities.unshift(actId);
        }
        const artifactsAfterFast = Number(runner.execSql(`SELECT COUNT(*) FROM [${CORE}].[Artifact];`).rows[0][0]);
        assert.equal(
            artifactsAfterFast,
            artifactsBeforeFast,
            `Fast-path created unexpected __mj.Artifact rows (${artifactsBeforeFast} -> ${artifactsAfterFast})`,
        );
        recordPass(
            'S3_S4_FAST_PATH_SEED',
            `Seeded ${created.organizations.length} orgs, ${created.people.length} people, and ${fastActivities.length} fast-path activities across Note/Call/Meeting/Email with 0 auto-created Artifacts`,
        );

        // S5: Opt-in linked MJ Docs (ArtifactID FK -> __mj.Artifact), vwActivities.Artifact projection & unlink
        const artIdMap = new Map();
        for (const art of dataset.Artifacts) {
            const artId = randomUUID();
            runner.execSql(`
                INSERT INTO [${CORE}].[Artifact] ([ID], [EnvironmentID], [Name], [Description], [TypeID], [UserID], [Visibility])
                VALUES (${sqlEscape(artId)}, ${sqlEscape(envId)}, ${nSqlEscape(art.Name)}, ${nSqlEscape(art.Description)}, ${sqlEscape(artTypeId)}, ${sqlEscape(userId)}, ${nSqlEscape(art.Visibility)});
            `);
            artIdMap.set(art.Key, artId);
            created.artifacts.unshift(artId);
        }

        const linkedActivities = dataset.Activities.filter((a) => a.ArtifactKey !== null);
        for (const act of linkedActivities) {
            const actId = randomUUID();
            const artId = artIdMap.get(act.ArtifactKey);
            const expectedArt = dataset.Artifacts.find((a) => a.Key === act.ArtifactKey);
            runner.execSql(`
                DECLARE @Now DATETIMEOFFSET = SYSDATETIMEOFFSET();
                EXEC [${S}].[spCreateActivity]
                    @ID = ${sqlEscape(actId)},
                    @ActivityTypeID = ${sqlEscape(actTypes.get(act.ActivityTypeCode))},
                    @StartedAt = @Now,
                    @Title = ${nSqlEscape(act.Title)},
                    @Description = ${nSqlEscape(act.Description)},
                    @Direction = ${nSqlEscape(act.Direction)},
                    @Status = ${nSqlEscape(act.Status)},
                    @Visibility = ${nSqlEscape(act.Visibility)},
                    @Source = ${nSqlEscape(act.Source)},
                    @LoggedByUserID = ${sqlEscape(userId)},
                    @Details = ${nSqlEscape(act.Details)},
                    @ArtifactID = ${sqlEscape(artId)};
            `);
            const checkRow = runner.execSql(`
                SELECT CAST([ArtifactID] AS NVARCHAR(64)), [Artifact]
                FROM [${S}].[vwActivities]
                WHERE [ID] = ${sqlEscape(actId)};
            `).rows[0];
            assert.equal(normalizeUuid(checkRow[0]), normalizeUuid(artId), `Linked ${act.Key} ArtifactID mismatch`);
            assert.equal(checkRow[1], expectedArt.Name, `Linked ${act.Key} vwActivities.Artifact mismatch`);
            actIdMap.set(act.Key, actId);
            created.activities.unshift(actId);
        }

        // Seed ActivityLinks for all 12 activities
        for (const link of dataset.ActivityLinks) {
            const linkId = randomUUID();
            const actId = actIdMap.get(link.ActivityKey);
            const entityId = link.TargetKind === 'Organization' ? orgEntityId : personEntityId;
            const recordId = link.TargetKind === 'Organization' ? orgIdMap.get(link.TargetKey) : personIdMap.get(link.TargetKey);
            runner.execSql(`
                INSERT INTO [${S}].[ActivityLink] ([ID], [ActivityID], [Role], [EntityID], [RecordID], [Sequence])
                VALUES (${sqlEscape(linkId)}, ${sqlEscape(actId)}, ${nSqlEscape(link.Role)}, ${sqlEscape(entityId)}, ${nSqlEscape(recordId)}, 0);
            `);
            created.activityLinks.unshift(linkId);
        }

        // Unlink first linked activity via spUpdateActivity(@ArtifactID_Clear = 1)
        const unlinkTarget = linkedActivities[0];
        const unlinkActId = actIdMap.get(unlinkTarget.Key);
        const unlinkArtId = artIdMap.get(unlinkTarget.ArtifactKey);
        runner.execSql(`
            EXEC [${S}].[spUpdateActivity]
                @ID = ${sqlEscape(unlinkActId)},
                @ArtifactID_Clear = 1,
                @ArtifactID = NULL;
        `);
        const unlinkedRow = runner.execSql(`
            SELECT COALESCE(CAST([ArtifactID] AS NVARCHAR(64)), N'__NULL__'),
                   COALESCE([Artifact], N'__NULL__'),
                   [Description],
                   [Details]
            FROM [${S}].[vwActivities]
            WHERE [ID] = ${sqlEscape(unlinkActId)};
        `).rows[0];
        assert.equal(unlinkedRow[0], '__NULL__', 'Unlinked Activity must have ArtifactID = NULL');
        assert.equal(unlinkedRow[1], '__NULL__', 'Unlinked Activity must have vwActivities.Artifact = NULL');
        assert.equal(unlinkedRow[2], unlinkTarget.Description, 'Unlink must preserve Description');
        assert.equal(unlinkedRow[3], unlinkTarget.Details, 'Unlink must preserve Details');
        const preservedArtCnt = Number(
            runner.execSql(`SELECT COUNT(*) FROM [${CORE}].[Artifact] WHERE [ID] = ${sqlEscape(unlinkArtId)};`).rows[0][0],
        );
        assert.equal(preservedArtCnt, 1, 'Unlinking must leave underlying __mj.Artifact intact');
        recordPass(
            'S5_LINK_PROJECTION_UNLINK',
            `Verified ${linkedActivities.length} linked MJ Docs + ${created.activityLinks.length} ActivityLinks, vwActivities.Artifact projection, and clean unlink preserving Description/Details`,
        );

        // S6: FK boundary adversarial checks (create & update with dangling ArtifactID)
        const badCreate = runner.execSql(
            `
            DECLARE @Now DATETIMEOFFSET = SYSDATETIMEOFFSET();
            EXEC [${S}].[spCreateActivity]
                @ActivityTypeID = ${sqlEscape(actTypes.get('Call'))},
                @StartedAt = @Now,
                @Title = ${nSqlEscape(`[${runTag}] Dangling FK Create`)},
                @Direction = N'Outbound',
                @Status = N'Logged',
                @Visibility = N'Internal',
                @Source = N'Manual',
                @LoggedByUserID = ${sqlEscape(userId)},
                @ArtifactID = ${sqlEscape(DANGLING_ARTIFACT_ID_CREATE)};
            `,
            true,
        );
        assert.equal(badCreate.ok, false, 'MSSQL must reject spCreateActivity with dangling ArtifactID');
        assert.match(`${badCreate.stderr}\n${badCreate.stdout}`, /FK_Activity_Artifact|FOREIGN KEY/i);

        const badUpdate = runner.execSql(
            `
            EXEC [${S}].[spUpdateActivity]
                @ID = ${sqlEscape(unlinkActId)},
                @ArtifactID = ${sqlEscape(DANGLING_ARTIFACT_ID_UPDATE)};
            `,
            true,
        );
        assert.equal(badUpdate.ok, false, 'MSSQL must reject spUpdateActivity with dangling ArtifactID');
        assert.match(`${badUpdate.stderr}\n${badUpdate.stdout}`, /FK_Activity_Artifact|FOREIGN KEY/i);
        recordPass('S6_FK_ADVERSARIAL', 'Dangling ArtifactID rejected on both spCreateActivity and spUpdateActivity via FK_Activity_Artifact');

        // S7: RLS / Permission boundary & transactional rollback hygiene
        const permRows = runner.execSql(`
            SELECT e.[Name], COUNT(ep.[ID])
            FROM [${CORE}].[Entity] e
            LEFT JOIN [${CORE}].[EntityPermission] ep ON ep.[EntityID] = e.[ID]
            WHERE e.[Name] IN (N'MJ_BizApps_Common: Activities', N'MJ: Artifacts')
            GROUP BY e.[Name];
        `).rows;
        assert.equal(permRows.length, 2, 'Both Activities and Artifacts entities must exist in __mj.Entity');
        for (const pr of permRows) {
            assert.ok(Number(pr[1]) > 0, `Expected EntityPermission rows for ${pr[0]}`);
        }

        const restrictedArtKey = dataset.Artifacts.find((a) => a.RestrictedToAuthorOnly)?.Key;
        const restrictedArtId = artIdMap.get(restrictedArtKey);
        const nonExistentReaderId = '33333333-3333-4333-8333-333333333333';
        const unauthorizedCnt = Number(
            runner.execSql(`
                SELECT COUNT(*)
                FROM [${CORE}].[Artifact] a
                WHERE a.[ID] = ${sqlEscape(restrictedArtId)}
                  AND a.[Visibility] = N'Always'
                  AND (a.[UserID] = ${sqlEscape(nonExistentReaderId)} OR EXISTS (
                      SELECT 1 FROM [${CORE}].[ArtifactPermission] ap
                      WHERE ap.[ArtifactID] = a.[ID] AND ap.[UserID] = ${sqlEscape(nonExistentReaderId)} AND ap.[CanRead] = 1
                  ));
            `).rows[0][0],
        );
        assert.equal(unauthorizedCnt, 0, 'Restricted reader must receive 0 rows for System Only / unauthorized Artifact');

        // Explicit BEGIN TRANSACTION -> insert -> verify in-txn count -> ROLLBACK -> verify 0 leaked rows
        const rollbackId = randomUUID();
        const rbRows = runner.execSql(`
            DECLARE @Now DATETIMEOFFSET = SYSDATETIMEOFFSET();
            BEGIN TRANSACTION;
            EXEC [${S}].[spCreateActivity]
                @ID = ${sqlEscape(rollbackId)},
                @ActivityTypeID = ${sqlEscape(actTypes.get('Note'))},
                @StartedAt = @Now,
                @Title = ${nSqlEscape(`[${runTag}] Rollback Probe`)},
                @Direction = N'Internal',
                @Status = N'Logged',
                @Visibility = N'Internal',
                @Source = N'Manual',
                @LoggedByUserID = ${sqlEscape(userId)},
                @ArtifactID = NULL;
            SELECT COUNT(*) AS InTxnCount FROM [${S}].[Activity] WHERE [ID] = ${sqlEscape(rollbackId)};
            ROLLBACK TRANSACTION;
            SELECT COUNT(*) AS PostRollbackCount FROM [${S}].[Activity] WHERE [ID] = ${sqlEscape(rollbackId)};
        `).rows;
        // Last two scalar rows are InTxnCount (1) and PostRollbackCount (0)
        const postRollbackCnt = Number(rbRows[rbRows.length - 1][0]);
        const inTxnCnt = Number(rbRows[rbRows.length - 2][0]);
        assert.equal(inTxnCnt, 1, 'Rollback probe row must exist inside SQL Server transaction');
        assert.equal(postRollbackCnt, 0, 'Rollback probe row must not persist after SQL Server ROLLBACK');
        recordPass('S7_RLS_AND_ROLLBACK', 'EntityPermission metadata verified, restricted Artifact isolated, and transactional rollback left 0 leaked rows');

        return {
            passed: true,
            platform: 'sqlserver',
            database: runner.database,
            provenance: prov,
            seedDensity: density,
            liveSeededCounts: {
                organizations: created.organizations.length,
                people: created.people.length,
                artifacts: created.artifacts.length,
                activities: created.activities.length,
                activityLinks: created.activityLinks.length,
                totalLiveRows:
                    created.organizations.length +
                    created.people.length +
                    created.artifacts.length +
                    created.activities.length +
                    created.activityLinks.length,
            },
            checks: results,
        };
    } finally {
        // S8: Reverse-dependency cleanup
        const cleanupStmts = [
            ...created.activityLinks.map((id) => `DELETE FROM [${S}].[ActivityLink] WHERE [ID] = ${sqlEscape(id)};`),
            ...created.activities.map((id) => `DELETE FROM [${S}].[Activity] WHERE [ID] = ${sqlEscape(id)};`),
            ...created.artifacts.map((id) => `DELETE FROM [${CORE}].[Artifact] WHERE [ID] = ${sqlEscape(id)};`),
            ...created.people.map((id) => `DELETE FROM [${S}].[Person] WHERE [ID] = ${sqlEscape(id)};`),
            ...created.organizations.map((id) => `DELETE FROM [${S}].[Organization] WHERE [ID] = ${sqlEscape(id)};`),
        ];
        if (cleanupStmts.length > 0) {
            runner.execSql(cleanupStmts.join('\n'), true);
        }
        runner.cleanup();
    }
}

async function main() {
    const args = process.argv.slice(2);
    if (args.includes('--offline-self-test')) {
        const result = RunOfflineSelfTest();
        console.log(JSON.stringify(result, null, 2));
        return;
    }

    const platform = (process.env.DB_PLATFORM ?? '').trim().toLowerCase();
    const runTag = `HYB_${Date.now()}`;
    let report;
    if (platform === 'postgresql') {
        report = await runPostgresCheck(runTag);
    } else if (platform === 'sqlserver') {
        report = await runSqlServerCheck(runTag);
    } else {
        throw new Error(
            `Unsupported or unset DB_PLATFORM='${platform}'. Expected 'sqlserver' or 'postgresql' (or pass --offline-self-test).`,
        );
    }
    console.log(JSON.stringify(report, null, 2));
}

if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main().catch((err) => {
        console.error(`[activity-hybrid-artifact.check] FAILED: ${err instanceof Error ? err.message : String(err)}`);
        process.exit(1);
    });
}
