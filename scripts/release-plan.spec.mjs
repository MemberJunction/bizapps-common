/**
 * Ported from bizapps-forms (MemberJunction/bizapps-forms#177), package names adjusted for
 * bizapps-common.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { planRelease, publishablePackages } from './release-plan.mjs';

const REPO_ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

const PKGS = [
    { name: '@mj-biz-apps/common-entities', version: '5.47.0' },
    { name: '@mj-biz-apps/common-server', version: '5.47.0' },
];

// ── The state that made a re-run a silent green no-op ───────────────────────────────────────────
//
// MemberJunction/bizapps-forms#187's review. `changeset publish` publishes the unpublished set
// concurrently, so one package landing on npm while a sibling fails is a state it produces by design
// and expects a retry to finish. The gate this replaces asked only whether the ENTITIES package was
// published, and both `Publish to npm` and `Tag the release` hung off that one answer — so the retry
// skipped everything and reported success, leaving packages unpublished and no `v<version>` tag at
// all.

test('a partially published release still has work to do', () => {
    const plan = planRelease({
        packages: PKGS,
        published: { '@mj-biz-apps/common-entities': ['5.47.0'] },
        tagExists: false,
    });
    assert.equal(plan.publish, true, 'common-server is not on npm — the retry must publish it');
    assert.deepEqual(plan.unpublished, ['@mj-biz-apps/common-server']);
    assert.equal(plan.tag, true);
    assert.equal(plan.work, true);
});

// The other half of the same defect: everything published, but the tag push is what failed. The
// version is fully released and nothing records it, and check-release-seed-cadence.mjs reads the
// newest v* tag to decide what has shipped — so a missing tag fails the NEXT release.
test('a fully published release with no tag still has work to do', () => {
    const plan = planRelease({
        packages: PKGS,
        published: { '@mj-biz-apps/common-entities': ['5.47.0'], '@mj-biz-apps/common-server': ['5.47.0'] },
        tagExists: false,
    });
    assert.equal(plan.publish, false, 'nothing left to publish');
    assert.equal(plan.tag, true, 'but the tag is still missing');
    assert.equal(plan.work, true);
});

test('a finished release is a no-op', () => {
    const plan = planRelease({
        packages: PKGS,
        published: { '@mj-biz-apps/common-entities': ['5.47.0'], '@mj-biz-apps/common-server': ['5.47.0'] },
        tagExists: true,
    });
    assert.equal(plan.publish, false);
    assert.equal(plan.tag, false);
    assert.equal(plan.work, false);
});

test('an untouched version publishes everything', () => {
    const plan = planRelease({ packages: PKGS, published: {}, tagExists: false });
    assert.equal(plan.publish, true);
    assert.deepEqual(plan.unpublished, PKGS.map((p) => p.name));
    assert.equal(plan.tag, true);
});

test('a package published at other versions but not this one still needs publishing', () => {
    const plan = planRelease({
        packages: [PKGS[0]],
        published: { '@mj-biz-apps/common-entities': ['5.46.2', '5.46.3'] },
        tagExists: false,
    });
    assert.equal(plan.publish, true);
});

test('the version reported is the one being released', () => {
    assert.equal(planRelease({ packages: PKGS, published: {}, tagExists: false }).version, '5.47.0');
});

// ── Guard clauses ───────────────────────────────────────────────────────────────────────────────

// `fixed` in .changeset/config.json moves every @mj-biz-apps package together, so divergent
// versions mean the bump did not happen as a unit and there is no single version to tag.
test('divergent package versions throw rather than picking one', () => {
    assert.throws(
        () =>
            planRelease({
                packages: [
                    { name: '@mj-biz-apps/common-entities', version: '5.47.0' },
                    { name: '@mj-biz-apps/common-server', version: '5.46.3' },
                ],
                published: {},
                tagExists: false,
            }),
        /5\.47\.0.*5\.46\.3|version/s,
    );
});

test('an empty package list throws rather than reporting nothing to do', () => {
    assert.throws(() => planRelease({ packages: [], published: {}, tagExists: false }), /no publishable/i);
});

// ── Discovery ───────────────────────────────────────────────────────────────────────────────────

test('this repository discovers exactly its publishable packages', () => {
    const found = publishablePackages(REPO_ROOT);
    assert.ok(found.length >= 5, `expected the @mj-biz-apps packages, got ${found.length}`);
    for (const p of found) {
        assert.match(p.name, /^@mj-biz-apps\//, `${p.name} is not a publishable @mj-biz-apps package`);
        assert.ok(p.version, `${p.name} has no version`);
    }
});

test('a private package is not something to publish', () => {
    const names = publishablePackages(REPO_ROOT).map((p) => p.name);
    assert.ok(!names.includes('@mj-biz-apps/common-integration-tests'), 'packages/IntegrationTests is private: true');
});

// A fixture rather than the ambient repo, so this proves the FILTER itself rather than merely
// happening to be true of whatever bizapps-common's package set looks like today.
function scratchWorkspace(packages) {
    const root = mkdtempSync(path.join(tmpdir(), 'release-plan-'));
    for (const [dir, manifest] of Object.entries(packages)) {
        mkdirSync(path.join(root, 'packages', dir), { recursive: true });
        writeFileSync(path.join(root, 'packages', dir, 'package.json'), JSON.stringify(manifest, null, 2));
    }
    return root;
}

test('a workspace package marked private is excluded from the publishable set', () => {
    const root = scratchWorkspace({
        Public: { name: '@mj-biz-apps/public-pkg', version: '1.0.0' },
        Hidden: { name: '@mj-biz-apps/hidden-pkg', version: '1.0.0', private: true },
    });
    const names = publishablePackages(root).map((p) => p.name);
    assert.deepEqual(names, ['@mj-biz-apps/public-pkg']);
});
