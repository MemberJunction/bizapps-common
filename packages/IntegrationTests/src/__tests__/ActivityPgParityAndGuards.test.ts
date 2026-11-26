/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 *
 * Deterministic dual-dialect PostgreSQL parity, seed density, cross-stack check
 * registration, and governance guard suite for Common.Activity Category B Hybrid Spine.
 */
import { createHash } from 'node:crypto';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { IntegrationCheckRegistry } from '@memberjunction/testing-integration/registry';
import {
    BuildActivityHybridSeedDataset,
    GetSeedDensitySummary,
} from '../../../../scripts/seed-activity-hybrid-world.mjs';
import {
    RunOfflineSelfTest,
    VerifyMigrationProvenance,
} from '../../checks/activity-hybrid-artifact.check.mjs';
import '../index.js';
import {
    GetActivityHybridWorldFixtures,
    SummarizeActivityHybridWorld,
} from '../world/activity-hybrid-world.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '..', '..', '..', '..');
const MIGRATIONS_DIR = join(REPO_ROOT, 'migrations');
const MIGRATIONS_PG_DIR = join(REPO_ROOT, 'migrations-pg');

function findMigration(dir: string, pattern: RegExp): string {
    const match = readdirSync(dir)
        .filter((file) => pattern.test(file))
        .sort()
        .pop();
    if (!match) {
        throw new Error(`No migration matching ${pattern} in ${dir}`);
    }
    return match;
}

describe('Common.Activity Dual-Dialect PG Parity, Seed Density & Governance Guards', () => {
    describe('6-category SQL Server <-> PostgreSQL schema parity & split-bake v1 provenance', () => {
        const tsFile = findMigration(MIGRATIONS_DIR, /__Activity_ArtifactID\.sql$/);
        const pgFile = findMigration(MIGRATIONS_PG_DIR, /__Activity_ArtifactID\.pg\.sql$/);
        const tsRaw = readFileSync(join(MIGRATIONS_DIR, tsFile), 'utf8');
        const pgRaw = readFileSync(join(MIGRATIONS_PG_DIR, pgFile), 'utf8');
        const tsFlat = tsRaw.replace(/\s+/g, ' ');
        const pgFlat = pgRaw.replace(/\s+/g, ' ');

        it('validates line-1 split-bake v1 SHA-256 provenance header against live T-SQL source bytes', () => {
            const prov = VerifyMigrationProvenance();
            const expectedSha = createHash('sha256').update(readFileSync(join(MIGRATIONS_DIR, tsFile))).digest('hex');

            expect(prov.tsFile).toBe(tsFile);
            expect(prov.pgFile).toBe(pgFile);
            expect(prov.sha256).toBe(expectedSha);
            expect(['baked', 'needs-hand-rebaked']).toContain(prov.mode);
        });

        it('achieves 6-category migration object parity (tables, columns, constraints, views, routines, filtered index)', () => {
            // 1. Table & nullable ArtifactID column (additive only; zero drops/renames/narrowings)
            expect(tsFlat).toContain('ALTER TABLE [${flyway:defaultSchema}].[Activity] ADD [ArtifactID] UNIQUEIDENTIFIER NULL;');
            expect(pgFlat).toMatch(/ALTER TABLE __mj_bizappscommon\."Activity"\s+ADD COLUMN "ArtifactID" UUID NULL/i);
            expect(tsFlat).not.toMatch(/\bDROP\s+COLUMN\b/i);
            expect(tsFlat).not.toMatch(/\bsp_rename\b/i);
            expect(tsFlat).not.toMatch(/\bALTER\s+COLUMN\b/i);
            expect(pgFlat).not.toMatch(/\bDROP\s+COLUMN\b/i);

            // 2. Constraint parity (FK_Activity_Artifact -> __mj.Artifact(ID))
            expect(tsFlat).toContain(
                'ADD CONSTRAINT [FK_Activity_Artifact] FOREIGN KEY ([ArtifactID]) REFERENCES [${mjSchema}].[Artifact]([ID]);',
            );
            expect(pgFlat).toMatch(
                /ADD CONSTRAINT "FK_Activity_Artifact"\s+FOREIGN KEY \("ArtifactID"\) REFERENCES (?:"?\$\{mjSchema\}"?|"?__mj"?)\."Artifact"\s*\(\s*"ID"\s*\)/i,
            );

            // 3. Filtered / partial index parity
            expect(tsFlat).toContain(
                'CREATE NONCLUSTERED INDEX [IDX_AUTO_MJ_FKEY_Activity_ArtifactID] ON [${flyway:defaultSchema}].[Activity] ([ArtifactID]) WHERE [ArtifactID] IS NOT NULL;',
            );
            expect(pgFlat).toMatch(
                /CREATE INDEX(?:\s+IF NOT EXISTS)? "IDX_AUTO_MJ_FKEY_Activity_ArtifactID"\s+ON __mj_bizappscommon\."Activity"\s*\("ArtifactID"\)\s*WHERE\s*(?:\(?"ArtifactID" IS NOT NULL\)?|NOT "ArtifactID" IS NULL)/i,
            );

            // 4. Column description parity (MS_Description <-> COMMENT ON COLUMN)
            expect(tsFlat).toContain("@level1name = N'Activity'");
            expect(tsFlat).toContain("@level2name = N'ArtifactID'");
            expect(pgFlat).toContain('COMMENT ON COLUMN __mj_bizappscommon."Activity"."ArtifactID"');

            // 5. View parity (vwActivities exposing ArtifactID + Artifact projection)
            expect(tsFlat).toContain('CREATE VIEW [${flyway:defaultSchema}].[vwActivities]');
            expect(tsFlat).toContain('MJArtifact_ArtifactID.[Name] AS [Artifact]');
            expect(pgFlat).toMatch(/CREATE OR REPLACE VIEW "?__mj_bizappscommon"?\."vwActivities"/i);
            expect(pgFlat).toMatch(/AS "Artifact"/);

            // 6. Routine parity (spCreateActivity, spUpdateActivity, spDeleteActivity + zero prune)
            for (const routine of ['spCreateActivity', 'spUpdateActivity', 'spDeleteActivity']) {
                expect(tsRaw).toContain(routine);
                expect(pgRaw).toContain(routine);
            }
            expect(tsRaw).not.toMatch(/spDeleteUnneededEntityFields/i);
            expect(pgRaw).not.toMatch(/spDeleteUnneededEntityFields/i);
        });
    });

    describe('Real-world multi-entity domain seed density (>= 20 records)', () => {
        it('provides >= 20 referentially intact domain records in scripts/seed-activity-hybrid-world.mjs', () => {
            const dataset = BuildActivityHybridSeedDataset('UNIT_VERIFY');
            const summary = GetSeedDensitySummary(dataset);

            expect(summary.meetsMinimumDensity).toBe(true);
            expect(summary.totalDomainRecords).toBeGreaterThanOrEqual(20);
            expect(summary.countsByCategory.organizations).toBeGreaterThanOrEqual(4);
            expect(summary.countsByCategory.people).toBeGreaterThanOrEqual(6);
            expect(summary.countsByCategory.rolePermissions).toBeGreaterThanOrEqual(3);
            expect(summary.countsByCategory.artifacts).toBeGreaterThanOrEqual(3);
            expect(summary.countsByCategory.activitiesFastPathNullArtifact).toBeGreaterThanOrEqual(4);
            expect(summary.countsByCategory.activitiesLinkedArtifact).toBeGreaterThanOrEqual(3);
            expect(summary.activityTypesCovered).toEqual(['Call', 'Email', 'Meeting', 'Note']);

            // Verify referential integrity across all fixtures
            const orgKeys = new Set(dataset.Organizations.map((o) => o.Key));
            const personKeys = new Set(dataset.People.map((p) => p.Key));
            const artifactKeys = new Set(dataset.Artifacts.map((a) => a.Key));
            for (const act of dataset.Activities) {
                expect(orgKeys.has(act.OrgKey)).toBe(true);
                expect(personKeys.has(act.PersonKey)).toBe(true);
                if (act.ArtifactKey !== null) {
                    expect(artifactKeys.has(act.ArtifactKey)).toBe(true);
                }
            }
        });

        it('keeps typed IntegrationTests world fixtures synchronized with >= 20 records across all 4 core Activity types', () => {
            const fixtures = GetActivityHybridWorldFixtures('UNIT_WORLD');
            const summary = SummarizeActivityHybridWorld(fixtures);

            expect(summary.TotalDomainRecords).toBeGreaterThanOrEqual(20);
            expect(summary.FastPathActivitiesCount).toBeGreaterThanOrEqual(4);
            expect(summary.LinkedActivitiesCount).toBeGreaterThanOrEqual(3);
            expect([...summary.ActivityTypesCovered].sort()).toEqual(['Call', 'Email', 'Meeting', 'Note']);
        });
    });

    describe('Cross-stack integration check registration & offline behavioral execution', () => {
        it('registers activities.A7 hybrid ArtifactID check in IntegrationCheckRegistry', () => {
            const activityChecks = IntegrationCheckRegistry.Instance.GetBundle('activities');
            const hybridCheck = activityChecks.find((c) => c.Id === 'activities.A7');
            expect(hybridCheck).toBeDefined();
            expect(hybridCheck?.RequiresMutation).toBe(true);
        });

        it('passes full offline cross-stack self-test (fast path, link/unlink, FK adversarial rejection, RLS boundary, rollback)', () => {
            const result = RunOfflineSelfTest();
            expect(result.passed).toBe(true);
            expect(result.checksFailed).toBe(0);
            expect(result.checksPassed).toBeGreaterThanOrEqual(7);
            expect(result.density.totalDomainRecords).toBeGreaterThanOrEqual(20);
        });
    });

    describe('Governance, rubric documentation, release-lines, and changeset guards', () => {
        it('documents the MJ Docs vs. MJ: Comments vs. Quick Notes rubric in CLAUDE.md and AGENTS.md', () => {
            const claudeMd = readFileSync(join(REPO_ROOT, 'CLAUDE.md'), 'utf8');
            const agentsMd = readFileSync(join(REPO_ROOT, 'AGENTS.md'), 'utf8');

            for (const doc of [claudeMd, agentsMd]) {
                expect(doc).toContain('MJ Docs (MJ: Artifacts) vs. MJ: Comments vs. Quick Notes');
                expect(doc).toContain('Category B');
                expect(doc).toContain('ArtifactID');
            }
        });

        it('registers the v6.3.x Activity_ArtifactID migration as edge-only in release-lines.json and ships a minor changeset', () => {
            const tsFile = findMigration(MIGRATIONS_DIR, /__Activity_ArtifactID\.sql$/);
            const releaseLines = JSON.parse(readFileSync(join(REPO_ROOT, 'release-lines.json'), 'utf8')) as {
                next?: { edgeOnlyMigrations?: string[] };
            };
            expect(releaseLines.next?.edgeOnlyMigrations ?? []).toContain(tsFile);

            const changesetDir = join(REPO_ROOT, '.changeset');
            const changesetFiles = readdirSync(changesetDir).filter(
                (f) => f.endsWith('.md') && f !== 'README.md',
            );
            const hasActivityArtifactMinor = changesetFiles.some((f) => {
                const body = readFileSync(join(changesetDir, f), 'utf8');
                return (
                    body.includes('ArtifactID') &&
                    /^["']?@mj-biz-apps\/common-entities["']?:\s*minor\s*$/m.test(body)
                );
            });
            expect(hasActivityArtifactMinor).toBe(true);
        });

        it('syncs the Living Specification under .mj/specs/add-additive-nullable-artifactid-fk-on-common-activity-hybrid-no/', () => {
            const specDir = join(
                REPO_ROOT,
                '.mj',
                'specs',
                'add-additive-nullable-artifactid-fk-on-common-activity-hybrid-no',
            );
            expect(existsSync(join(specDir, 'spec.md'))).toBe(true);
            const specText = readFileSync(join(specDir, 'spec.md'), 'utf8');
            expect(specText).toContain('ArtifactID');
            expect(specText).toContain('DefaultNavItems');
            expect(specText).toContain('Category B');
        });
    });
});
