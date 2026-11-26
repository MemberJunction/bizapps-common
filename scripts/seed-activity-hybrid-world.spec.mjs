import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
    BuildActivityHybridSeedDataset,
    GetSeedDensitySummary,
    normalizeUuid,
} from './seed-activity-hybrid-world.mjs';

test('BuildActivityHybridSeedDataset produces >= 20 referentially intact domain records across Note, Call, Meeting, and Email', () => {
    const dataset = BuildActivityHybridSeedDataset('SPEC_TEST');
    const summary = GetSeedDensitySummary(dataset);

    assert.equal(summary.meetsMinimumDensity, true);
    assert.ok(summary.totalDomainRecords >= 20, `expected >= 20 domain records, got ${summary.totalDomainRecords}`);
    assert.deepEqual(summary.activityTypesCovered, ['Call', 'Email', 'Meeting', 'Note']);
    assert.ok(summary.countsByCategory.organizations >= 4);
    assert.ok(summary.countsByCategory.people >= 6);
    assert.ok(summary.countsByCategory.rolePermissions >= 3);
    assert.ok(summary.countsByCategory.artifacts >= 3);
    assert.ok(summary.countsByCategory.activitiesFastPathNullArtifact >= 4);
    assert.ok(summary.countsByCategory.activitiesLinkedArtifact >= 3);

    const orgKeys = new Set(dataset.Organizations.map((o) => o.Key));
    const personKeys = new Set(dataset.People.map((p) => p.Key));
    const artifactKeys = new Set(dataset.Artifacts.map((a) => a.Key));
    for (const act of dataset.Activities) {
        assert.ok(orgKeys.has(act.OrgKey), `unknown OrgKey ${act.OrgKey}`);
        assert.ok(personKeys.has(act.PersonKey), `unknown PersonKey ${act.PersonKey}`);
        if (act.ArtifactKey !== null) {
            assert.ok(artifactKeys.has(act.ArtifactKey), `unknown ArtifactKey ${act.ArtifactKey}`);
        }
    }
});

test('normalizeUuid normalizes mixed-case SQL Server and PostgreSQL UUIDs', () => {
    assert.equal(
        normalizeUuid('AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA'),
        normalizeUuid('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
    );
    assert.equal(normalizeUuid(null), '');
});
