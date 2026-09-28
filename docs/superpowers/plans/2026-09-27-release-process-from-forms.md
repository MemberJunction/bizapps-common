# Port bizapps-forms' Release Process to bizapps-common — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace common's direct-push `publish.yml` release with bizapps-forms' PR-based release process: *Prepare a release* dispatch → release PR into `main` → `publish.yml` publishes, tags, and opens a back-merge PR. Also bring the release-readiness gates for the once-per-release `Metadata_Sync`, and the docs that explain both.

**Architecture:** Plain-Node, stdlib-only scripts under `scripts/`, each with a `node --test` spec beside it. They are copied from `~/Projects/mj-dev/bizapps-forms` (the **source**, on `origin/next` @ `da86660`) and adapted to common. Three workflows call them: `release-prep.yml`, `publish.yml`, and `verify-release-app-token.yml`. The workflows authenticate as the org GitHub App (`vars.APP_CLIENT_ID` + `secrets.APP_PRIVATE_KEY`), which is already visible to this repo (verified with `gh api repos/MemberJunction/bizapps-common/actions/organization-secrets`). Nothing pushes to `main` or `next`.

**Tech Stack:** Node 24 (`node:test`, `node:child_process`, `node:fs`), GitHub Actions, changesets (`fixed: [["@mj-biz-apps/*"]]`, `baseBranch: next`), pnpm 10.

**Spec:** The source repo *is* the spec: `bizapps-forms/docs/release.md`, `bizapps-forms/migrations/README.md` (seed sections), and the files named in each task. Where common differs, this plan says so explicitly.

## Global Constraints

- Source path: `/Users/sohamdesai/Projects/mj-dev/bizapps-forms`. Read files there. **Never write** there, because it has uncommitted user work on another branch.
- Work on branch `chore/release-process-from-forms` in `/Users/sohamdesai/Projects/mj-dev/bizapps-common`. It tracks `origin/chore/release-process-from-forms`.
- Scripts are plain Node ESM (`.mjs`), stdlib only. That matches the source and common's `scripts/check-release-seed-coverage.mjs`.
- The version anchor is `packages/Entities/package.json` (`@mj-biz-apps/common-entities`). The MJ anchor is `@memberjunction/core` in its `peerDependencies`. Today `mj-app.json` holds `version: 5.46.3` and `mjVersionRange: ">=6.1.0-edge.6 <7.0.0"`.
- Published packages: every `packages/*/package.json` without `"private": true`. `@mj-biz-apps/common-integration-tests` is private.
- Schema: `__mj_BizAppsCommon` (source: `__mj_BizAppsForms`). Repo: `MemberJunction/bizapps-common`.
- Common has **no** `lint:migrations` or `lint:distribution` script. The release gates are only `check:release-seed` and `check:seed-cadence`. Do not invent the other two.
- Common has no forms widget. Drop every `validate-widget-bundle` / `forms-ng` step.
- In source prose, replace "seven required checks" with a statement true for common. Common's `main` ruleset has only `deletion` + `non_fast_forward`, and `next` has none (verified with `gh api repos/MemberJunction/bizapps-common/rules/branches/<b>`). Keep the GITHUB_TOKEN rationale: runs triggered by GITHUB_TOKEN events never start `changes.yml` or `build.yml`, so PRs would get no CI.
- Issue and PR numbers in the source (`#105`, `#177`, `#225`, …) are **bizapps-forms** history. When you keep one, write it as `MemberJunction/bizapps-forms#NNN`. Never leave a bare `#NNN` that would link to an unrelated common PR.
- After every task, `grep -rniE 'forms|BizAppsForms' <files touched>` returns only deliberate provenance mentions ("ported from bizapps-forms").
- No `git push` to `main`/`next` anywhere. The `lint:release-pushes` gate (Task 2) enforces this.
- Commit after each task: conventional message, footer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Do not use `--no-verify`, and do not amend.

## Review Focus

1. **Current repo state through the gates.** `check:seed-cadence` must FAIL today. `metadata/` has moved since `v5.46.3`, and the last seed is `V202609020500__v5.38.x__Metadata_Sync.sql`, which is already in a tag. That failure is correct, not a bug to "fix". Pinned in Task 1, Step 6.
2. **`mj-app.json` derivation must match today's file.** `node scripts/sync-app-version.mjs --check` passes on the unmodified repo. If it would rewrite the range, the derivation differs from the old publish.yml logic. Pinned in Task 1, Step 6.
3. **Private package excluded.** `release-plan.mjs` must not list `common-integration-tests` as a package to publish. Pinned in Task 3, Step 3.
4. **Old push path fully removed.** `ci/*.mjs` and the `commitpush`/`mergemain*` scripts are deleted, and `lint:release-pushes` passes. Re-adding a `git push origin main` line to any scanned file must fail it. Pinned in Task 2, Step 4.
5. **No leftover forms identifiers in workflows.** For example, `bizapps-forms.git`, `validate-widget-bundle.sh`, or `lint:distribution` in a gate list. Such a leftover would fail at release time, where no PR check sees it. Pinned in Task 4, Step 5.

---

### Task 1: Release-readiness seed gates + app-version sync

**Files:**
- Replace: `scripts/check-release-seed-coverage.mjs` with the source's version. Also create its spec: `scripts/check-release-seed-coverage.spec.mjs`.
- Create: `scripts/check-release-seed-cadence.mjs`, `scripts/check-release-seed-cadence.spec.mjs`.
- Create: `scripts/sync-app-version.mjs`, `scripts/sync-app-version.spec.mjs`.
- Modify: `package.json` scripts.

**Interfaces:**
- Produces the package.json scripts `check:release-seed`, `check:release-seed:test`, `check:seed-cadence`, `check:seed-cadence:test`, `sync-app-version:test`, and `"version": "changeset version && node scripts/sync-app-version.mjs"`. Task 3 runs these gates **by package.json script name**.
- `sync-app-version.mjs` keeps the source's CLI: no args writes `mj-app.json`, and `--check` exits 1 on drift. Tasks 3 and 4 call it with `--check`.

- [ ] **Step 1: Port the three specs first.** Copy each `*.spec.mjs` from source `scripts/`. Replace `BizAppsForms`→`BizAppsCommon` and forms package names → `@mj-biz-apps/common-*`. Any fixture that uses a forms version or MJ pin should use common's values (`5.46.3`, `^6.1.0-edge.6`).
- [ ] **Step 2: Run them. Expect failures.** Run `node --test scripts/check-release-seed-cadence.spec.mjs scripts/sync-app-version.spec.mjs scripts/check-release-seed-coverage.spec.mjs`. Cadence and sync should fail with "Cannot find module". Coverage may fail on any exported function common's current script lacks.
- [ ] **Step 3: Port the three implementations** with the same substitutions. Rewrite doc comments so they describe common: the Metadata_Sync generation recipe lives in `migrations/README.md` (Task 5). Keep the source's reasoning paragraphs (why not a PR gate, what a pass does not mean) and credit their origin as `MemberJunction/bizapps-forms#NNN`.
- [ ] **Step 4: Add the package.json scripts** listed under Interfaces. Put them next to the existing `check:published-mj`.
- [ ] **Step 5: Run the specs. Expect PASS.** Run `node --test scripts/*.spec.mjs`.
- [ ] **Step 6: Check them against the real repo (Review Focus 1–2).**
  - `pnpm run check:release-seed` → exit 1, listing about 14 files. That is today's known debt.
  - `pnpm run check:seed-cadence` → exit 1: "metadata moved, no seed". Record the output in the commit body.
  - `node scripts/sync-app-version.mjs --check` → exit 0, and `git diff --exit-code mj-app.json` is clean.
- [ ] **Step 7: Commit.** `feat(release): seed-readiness gates and mj-app.json version sync from bizapps-forms`

### Task 2: Retire the direct-push path; add the release-push gate

**Files:**
- Delete: `ci/commit_push.mjs`, `ci/merge_main.mjs`, `ci/merge_main_and_update_lock.mjs`. Also delete the `commitpush`, `mergemain`, and `mergemain:update-lock` scripts in `package.json`.
- Create: `scripts/check-release-pushes.mjs`, `scripts/check-release-pushes.spec.mjs`.
- Modify: `package.json`. Add `lint:release-pushes` and `lint:release-pushes:test`.
- Modify: `.github/workflows/build.yml`. Add a `release-tooling` job (details in Step 5).

**Interfaces:**
- `SCANNED_DIRS = ['.github/workflows', '.github/scripts', 'scripts', 'ci']`. Keep `ci` even though it is now deleted: it is the source's tripwire.

- [ ] **Step 1: Port the spec**, then run `node --test scripts/check-release-pushes.spec.mjs`. Expect FAIL (module missing).
- [ ] **Step 2: Port the implementation.** Also update its comment about `.claude/hooks/require-green-before-git.mjs`: common has no such hook, so say it is in bizapps-forms.
- [ ] **Step 3: Run `pnpm run lint:release-pushes`** before deleting `ci/`. It must FAIL and name the ci scripts and/or `publish.yml`. That shows the gate sees the real old path. Record the output.
- [ ] **Step 4: Delete `ci/` and the three package.json scripts.** Leave `publish.yml` unchanged for now; Task 4 rewrites it. If the gate still flags `publish.yml`, confirm the hits are only there. Then run `lint:release-pushes:test` → PASS. Add one spec case: a fixture file with `git push origin main` is flagged (Review Focus 4). Skip it if the ported spec already covers this.
- [ ] **Step 5: Add a `release-tooling` job to `build.yml`.** No install is needed:
  - Steps: `actions/checkout@v4` (`fetch-depth: 0`, `fetch-tags: true`, needed by the cadence/plan specs if they read git), `actions/setup-node@v4` node 24, `node --test scripts/*.spec.mjs`, `node scripts/check-release-pushes.mjs`.
  - Extend both `paths:` lists with `'scripts/**'`, `'.github/workflows/**'`, `'.github/scripts/**'`, and `'.changeset/**'`.
- [ ] **Step 6: Commit.** `chore(release): retire the push-to-main ci scripts; gate against reintroducing them`. The gate may fail on the old `publish.yml` until Task 4. If so, say that in the commit body. Do not weaken the gate.

### Task 3: `release-plan` and `release-prep` scripts

**Files:**
- Create: `scripts/release-plan.mjs`, `scripts/release-plan.spec.mjs`, `scripts/release-prep.mjs`, `scripts/release-prep.spec.mjs`.
- Modify: `package.json`. Add `"release:plan": "node scripts/release-prep.mjs --plan"`, `lint:release-plan:test`, and `lint:release-prep:test`.

**Interfaces:**
- Consumes the Task 1 script names.
- `release-prep.mjs` `GATE_MEANINGS` holds **exactly** two keys, `check:release-seed` and `check:seed-cadence`. Delete the source's `lint:migrations` and `lint:distribution` entries, and every spec expectation that names them.
- Produces the CLI modes used by `release-prep.yml`: `--plan` (read-only, exit 0), `--apply`, and any other flag the source workflow uses. Grep the source workflow for `release-prep.mjs` and `release-plan.mjs` and keep every flag it passes.

- [ ] **Step 1: Port both specs** with the substitutions. Adjust fixture package lists to common's. Run them. Expect FAIL (module missing).
- [ ] **Step 2: Port both implementations.** Rewrite comments that cite forms history the same way as Task 1.
- [ ] **Step 3: Add a spec case in `release-plan.spec.mjs`** (Review Focus 3): a workspace fixture where one package has `"private": true` is not listed. Skip it if the source already has this case.
- [ ] **Step 4: Run** `node --test scripts/*.spec.mjs` → PASS.
- [ ] **Step 5: Run `pnpm run release:plan`** against the real repo. Expect exit 0. It should report current `5.46.3`, one pending changeset computing to `5.47.0`, and blockers including the red seed gates. Paste the report into the commit body.
- [ ] **Step 6: Commit.** `feat(release): release:plan and release-prep — the preconditions and the bump, as testable code`

### Task 4: Workflows

**Files:**
- Create: `.github/workflows/release-prep.yml` and `.github/workflows/verify-release-app-token.yml`, both from the source.
- Replace: `.github/workflows/publish.yml` with the source's version, adapted.

- [ ] **Step 1: Port `release-prep.yml`.**
  - Substitute the repo name.
  - Fix the prose about required checks (see Global Constraints).
  - Keep `persist-credentials: false` and its comment (forms#226).
- [ ] **Step 2: Port `verify-release-app-token.yml`.** Every `bizapps-forms` becomes `bizapps-common`.
- [ ] **Step 3: Port `publish.yml`.**
  - Delete the widget-bundle step.
  - Keep common's validate-* steps. The scripts all exist in `.github/scripts/`; check each path the source calls with `ls`.
  - Before the two seed gates, run their self-tests with `node --test`, exactly as the source does.
  - Keep `workflow_dispatch` only if the source keeps it.
- [ ] **Step 4: Lint and gate.** Run `pnpm run lint:release-pushes` → PASS now. Run `actionlint` if it is installed (`command -v actionlint || brew list actionlint`). Otherwise parse every workflow with `node -e` using a YAML parser already in node_modules (`find node_modules -maxdepth 3 -name yaml -type d | head -1`). Failing that, use `ruby -ryaml -e 'YAML.load_file(ARGV[0])'`.
- [ ] **Step 5: Review Focus 5.** Run `grep -nE 'forms|widget|lint:distribution|lint:migrations|seven' .github/workflows/*.yml` → only deliberate provenance mentions. Also check that every `pnpm run X` / `npm run X` in the three workflows exists in `package.json`:
  ```bash
  for s in $(grep -ohE '(pnpm|npm) run [a-z:.-]+' .github/workflows/*.yml | awk '{print $3}' | sort -u); do jq -e --arg s "$s" '.scripts[$s]' package.json >/dev/null || echo "MISSING $s"; done
  ```
  Expected: no output.
- [ ] **Step 6: Commit.** `feat(release): PR-based release workflows — prepare, publish-and-backmerge, verify the App token`

### Task 5: Documentation

**Files:**
- Create: `docs/release.md`, adapted from the source. Change the step table to common's names. Drop the widget and seven-checks claims. Keep "Why it looks like this", reframed: common is adopting the design forms proved on `v0.11.0`. Keep the troubleshooting table.
- Create: `migrations/README.md`. Port only the seed sections of the source: "The loop, whenever you touch metadata/", "Regenerating the metadata seed", and the cadence explanation. Drop forms-only parts: the Form Respondent/RLS appendix, `lint:migrations`, `lint:distribution`, and the codegen-append convention. The recipe is:
  - Build a clean DB from the shipped chain, with MJ core plus common only. Common is the base app with no siblings.
  - Hold back unreleased seeds.
  - Run `npx mj sync push --dir metadata --ci`.
  - Apply the two substitutions from commit `326cc01`: `[${flyway:defaultSchema}]`→`[${mjSchema}]` on core SP calls, and `[__mj_BizAppsCommon]`→`[${flyway:defaultSchema}]`.
  - Save as a new `V<stamp>__v<ver>__Metadata_Sync.sql`, and include the `sync` blocks written back into `metadata/`.
  - Check on a clean install, then run `pnpm run check:release-seed && pnpm run check:seed-cadence`.
  - Run `pnpm run mj:migrate:convert` for the PG twin.
  - Include the table of shipped vs unreleased `Metadata_Sync` files, computed with the source's `git tag --list` loop run in common.
- Modify: `CLAUDE.md`, "Branching Model: next → main Release Flow". Replace the release-flow and rules bullets that describe publish.yml committing to `main` and pushing the lockfile to `next`. The new text covers:
  - one dispatch and two merges, with a link to `docs/release.md`;
  - nothing pushes to `main`/`next` (`lint:release-pushes`);
  - Metadata_Sync is release work (link to `migrations/README.md`);
  - `pnpm run release:plan`.
  Delete the "Never hand-author the chore: Update package-lock.json" rule, because that commit no longer exists. Keep the hotfix note, reworded for the back-merge PR.
- Modify: `README.md` and `docs/development.md`. Add a one-line pointer from their metadata-sync mention to `migrations/README.md`.

- [ ] **Step 1: Write the docs.** Check each command a doc names: `jq -e '.scripts["<name>"]' package.json`.
- [ ] **Step 2: Check links.** Every relative link in the new or changed docs must resolve (`ls` each target).
- [ ] **Step 3: Commit.** `docs(release): the release runbook and the Metadata_Sync recipe`

### Task 6: Whole-branch verification (controller, not a subagent)

- [ ] Run `node --test scripts/*.spec.mjs` → all pass.
- [ ] Run `pnpm run lint:release-pushes` → pass.
- [ ] Run `pnpm run release:plan` → exit 0 with the expected blockers.
- [ ] Run `pnpm run check:release-seed` and `check:seed-cadence` → both red, for the known reasons.
- [ ] Check that `mj-app.json` and `packages/*` are unchanged: `git diff origin/next --stat -- packages mj-app.json` is empty.
- [ ] Run `pnpm install --frozen-lockfile && pnpm run build:packages` → green. package.json changed, so confirm the lockfile is unaffected.
- [ ] Run a whole-branch code review with superpowers:requesting-code-review.
- [ ] Push, then open a **draft** PR into `next`.
