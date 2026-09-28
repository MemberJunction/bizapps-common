# Cutting a release

One dispatch and two merges. Both pull requests are opened for you, and nothing is ever pushed to
`main` or `next`: not by you, and not by a workflow. That constraint is the shape of the design, not a
limitation worked around (see [Why it looks like this](#why-it-looks-like-this)).

| Step | Who | What |
|---|---|---|
| 0. Prep the seed | you, once per release | the consolidated `Metadata_Sync`. It needs a database, so no workflow can do it |
| 1. Dispatch **Prepare a release** | you, one click | `release-prep.yml` cuts `release/vX.Y.Z` from `next`, bumps, and opens the PR into `main` |
| 2. Review and merge that PR | you | the only place the version and the CHANGELOGs get human eyes |
| 3. **Build and Publish** | `publish.yml`, on the merge | builds, publishes to npm, tags `vX.Y.Z`, opens the back-merge PR |
| 4. Merge the back-merge PR | you | `chore/backmerge-vX.Y.Z` carries `main` back into `next` |

---

## Is a release even due?

```bash
pnpm run release:plan
```

It is read-only, runs on any checkout, and always exits 0. It reports the current version, how many
changesets are pending and what version they compute to, the release branch name, whether the tree
is clean, whether `main` is contained in `next`, and whether the two release-readiness gates pass
(`check:release-seed`, `check:seed-cadence`). Then it lists every blocker between you and a release.

It runs the same code the workflow runs (`scripts/release-prep.mjs --plan`), so it cannot drift from
what actually happens. Run it whenever you want to know where things stand. It writes nothing.

## 0. Prep: the metadata seed

**This is the one part of a release no workflow will do for you.** Generating the consolidated
`Metadata_Sync` needs a database with MJ core and this app's migrations installed, and no CI runner
has one. The recipe is in [`migrations/README.md`](../migrations/README.md). Read it there; it is not
duplicated here.

`pnpm run release:plan` tells you whether a seed is owed. `check:release-seed` and
`check:seed-cadence` both appear on its `gates` line, and a red one is a blocker that stops step 1
before anything is written. The seed lands on `next` through an ordinary PR, with a `minor`
changeset, like any other migration.

**Before the first release on this process, and after any long gap**, dispatch **Verify the release
App token** once (Actions → *Verify the release App token*). It is read-only, takes under a minute,
and confirms that the credential steps 1 and 3 depend on is live. The App credential
(`vars.APP_CLIENT_ID` + `secrets.APP_PRIVATE_KEY`, both org-level) has not yet been exercised in this
repository. A revoked or misconfigured App is otherwise invisible until a release is half done, which
is how MJ's `v6.1.0-edge.6` went.

## 1. Dispatch "Prepare a release"

Actions → **Prepare a release** → *Run workflow*. Set `dry_run: true` first if you want to see the
plan without anything being written.

The workflow always checks out `next`, whatever branch you dispatch from. It refuses, before writing
anything, if:

- the working tree it checked out is not clean;
- there are no changesets, or none declares a bump level;
- `check:release-seed` or `check:seed-cadence` is red;
- the computed version is already tagged, or already on npm;
- `main` is not contained in `next` (the previous release's back-merge PR is still open);
- a `release/vX.Y.Z` branch already exists on the remote.

Each refusal names what to do about it.

Otherwise it cuts `release/vX.Y.Z` from the tip of `next` and runs `pnpm run version` (changesets,
then `scripts/sync-app-version.mjs` for `mj-app.json`). It updates the lockfile, checks that the
result matches its prediction, commits, pushes the branch as the App, and opens the pull request into
`main`. The PR body lists the changesets being consumed.

**The version is not yours to choose.** Changesets computes it from the pending changesets, and the
workflow asserts that the result matches its own prediction. Nothing downstream second-guesses it, so
if the version is wrong the fix is a changeset, not an edit.

> A migration filename's `__v<ver>__` segment is **not** a claim about which release ships it.
> Flyway orders on the `V<timestamp>` prefix and nothing reads the label. Do not infer a version from
> one. See [`migrations/README.md`](../migrations/README.md).

## 2. Review and merge the release PR

`changes.yml` and `clean-room-gate.yml` run on it, because the App-authored push started them.
(`build.yml` triggers only on PRs into `next`, so it has already run on every change this release
carries.) **No check is required on `main`:** its ruleset list is empty, so GitHub will let you merge
before these finish, or while they are red. Wait for them and read them. This is the only point where
a human looks at the computed version and the CHANGELOGs before any of it is permanent.

The full diff against `main` spans everything since the last release, so review the bump instead.
It is the part a human can actually judge:

```bash
git fetch origin
git diff --name-only origin/next origin/release/vX.Y.Z
```

That should list the consumed `.changeset/*.md`, every `packages/*/package.json` and
`packages/*/CHANGELOG.md` (the `fixed` group bumps all of them, including the private
`common-integration-tests`), `pnpm-lock.yaml` and `mj-app.json`. It should list **nothing** under
`migrations/`, `metadata/` or any `src/`.

Merge it with a **merge commit**.

## 3. Publishing happens by itself

The merge pushes to `main`, which triggers **Build and Publish** (`publish.yml`). It builds, runs the
release-readiness checks, publishes to npm, pushes the `vX.Y.Z` tag, and opens the back-merge pull
request.

Every gate sits before `Publish to npm`, so a failure costs a re-run and nothing has been published.
Four are worth knowing by name:

- **`The bump has to have happened before this branch was merged`** fails if any `.changeset/*.md`
  is still present, because that means step 1 never ran and publishing would republish the current
  version.
- **`What is there to release?`** (`scripts/release-plan.mjs`) asks two questions separately: is any
  package missing this version from npm, and is the `vX.Y.Z` tag absent? Each answer gates its own
  step. So **re-running the workflow after a partial failure finishes the job** instead of reporting
  a green no-op. It does nothing, and says so, only when the version is both fully published and
  tagged.
- **`Enforce schema-change version policy`** fails if `migrations/` changed since the last `v*` tag
  but the version moved only by a patch. Fix it by redoing step 1 with a `minor` changeset.
- **Release readiness**: the two seed checks. They run here and in step 1, never on a feature PR,
  because no feature PR can answer a question about a seed generated after it merges.

**A manual dispatch publishes only from `main`.** `workflow_dispatch` re-runs the publish, but the
`Publish to npm`, `Tag the release` and back-merge steps are gated on
`github.ref == 'refs/heads/main'`, so dispatching it against a `release/*` branch (or any other ref)
builds and checks and publishes, tags and opens nothing. That branch has not been reviewed yet.

**A green run means the automation did its job.** A red run means one of two things, and the failed
step tells you which:

- **A step up to `Tag the release` failed**: a gate, the build, `changeset publish` itself, or the
  tag push. None, some or all of it is on npm, and the tag does not exist. Fix the cause and re-run
  the workflow; `release-plan.mjs` asks *publish* and *tag* separately, so the re-run finishes the job.
- **Only the back-merge pull request could not be opened.** The release is published and tagged, and
  no one is tracking the outstanding merge, so a human is needed. A re-run is safe: it publishes and
  tags nothing twice and retries only the back-merge. If it fails again, read the failed step
  (**Verify the release App token** diagnoses a credential problem) or open the back-merge by hand
  (step 4).

## 4. Merge the back-merge PR

`chore/backmerge-vX.Y.Z → next`, opened for you in step 3. It carries the release merge commit and
the version bump back to `next`. `build.yml` and `changes.yml` run on it.

Merge it with a **merge commit** — never squash or rebase. Either rewrites `main`'s commits into new
ones, so `main`'s tip is still not an ancestor of `next` and **Prepare a release** keeps refusing
after you believe you fixed it. If that already happened, open a fresh `main → next` PR and merge it
with a merge commit.

This is not bookkeeping. Skipping it costs **this** release nothing and quietly breaks the **next**
one. The one ruleset here (on `next`) does not require a branch to be up to date with its base (no
`strict`), so GitHub would merge a release PR cut from a `next` that never received the last bump, and that PR would revert the
already-published version on `main`. The guard is in step 1 instead: `release-prep.mjs` refuses to
cut a release while `main` is not an ancestor of `next`, and names this pull request when it does.

---

## Keeping `mj-app.json` in sync between releases

`mj-app.json` is checked on every PR **into `next`** that could move it out of sync, not only at
release: `build.yml` runs on any such PR touching `mj-app.json` or `packages/**`, and its
`release-tooling` job runs `scripts/sync-app-version.spec.mjs`, which fails if the manifest's
`mjVersionRange` disagrees with the `@memberjunction/core` pin in `packages/Entities/package.json`.
`build.yml` does not run on PRs into `main` (the release PR, a hotfix), so there the only check is
`publish.yml`'s `sync-app-version.mjs --check`, after the merge and before anything is published. So a PR that changes that pin
must run

```bash
node scripts/sync-app-version.mjs
```

and commit the updated `mj-app.json`. Do **not** run `pnpm run version` for this: it also consumes
every pending changeset and bumps every package, which is release work (step 1), not PR work.

## Why it looks like this

**Common is adopting a design that bizapps-forms proved first.** The workflows and scripts here were
ported from bizapps-forms, where the same design shipped `v0.11.0` end to end on 2026-09-15. Common's
previous release path had `publish.yml` run `changeset version` on `main`, commit the bump back to
`main`, then merge `main` into `next` and push a `chore: Update package-lock.json with vX.Y.Z
dependencies` commit. That path is gone: the `ci/` push scripts are deleted, and
`pnpm run lint:release-pushes` (in `build.yml`'s `release-tooling` job) fails any workflow or script
that pushes to `main` or `next`.

**Why an App token.** GitHub deliberately does not start workflow runs from events authored with
`GITHUB_TOKEN`. A branch or pull request created with the default token would never get
`changes.yml`, `clean-room-gate.yml` or `build.yml` runs, so it would reach review with no CI at all.
The automation therefore needs an identity that is not `GITHUB_TOKEN`. This repository has no PAT. It
has `vars.APP_CLIENT_ID` + `secrets.APP_PRIVATE_KEY`, an App already installed org-wide and used by
MJ core for the same reason.

**The App is never a bypass.** It pushes only `release/*`, and it opens the two pull requests. The
back-merge branch and the tag are pushed by `publish.yml` with `GITHUB_TOKEN` (as
`github-actions[bot]`): its checkout persists that credential, and a persisted credential outranks the
App token in a remote URL (MemberJunction/bizapps-forms#229). Common's only ruleset targets the default branch (`next`) with `deletion` and
`non_fast_forward`; `main` has no rules at all. Neither release branch pattern is covered. Check it
rather than trusting this paragraph:

```bash
gh api repos/MemberJunction/bizapps-common/rules/branches/next          # → deletion, non_fast_forward
gh api repos/MemberJunction/bizapps-common/rules/branches/main          # → []
gh api repos/MemberJunction/bizapps-common/rules/branches/release%2Fv0  # → []
```

Nothing here asks for an exception to anything. The two remote writes made with `GITHUB_TOKEN` are
the `chore/backmerge-*` branch push, which no ruleset covers, and the `vX.Y.Z` tag push; tags are
outside every ruleset. What the App credential buys in `publish.yml` is the back-merge PR itself: an
App-opened PR starts its CI, where a `GITHUB_TOKEN`-opened one would not.

**Common has not hit the failure this design was built for, and adopts it anyway.** In bizapps-forms,
required status checks on `main` and `next` made every push from CI unsatisfiable by construction
(MemberJunction/bizapps-forms#177): checks are evaluated against the check runs present on the SHA
being *introduced*, and a push introduces a SHA the remote has never seen. Common has no required
checks today, so its old push path still worked. Adopting the design now means adding a required
check later breaks nothing, and the release PR gets CI, which a push never did.

**Why there is still a human merge, twice.** MJ built a one-click release button, never dispatched
it, and deleted it, because every release carries prep that must be *reviewed*. A metadata-sync
migration is permanent, append-only history. What is automated is the mechanical part: computing the
version, writing the commit, opening the pull requests. What stays human is the judgement.

**What the first run in bizapps-forms found.** Two defects surfaced on that first execution, both in
the release machinery rather than the product, and both invisible to PR checks because neither fires
on a pull request into `next`:

- MemberJunction/bizapps-forms#225: a forms-only PR gate diffed from the pull request's base, which
  for a release PR is `main`, hundreds of commits back. Common has no equivalent gate on PRs into
  `main`.
- MemberJunction/bizapps-forms#226: `actions/checkout` defaults to `persist-credentials: true`, which
  writes an `extraheader` carrying `GITHUB_TOKEN` into the local git config. That header outranks
  credentials embedded in a remote's URL, so the release branch was pushed as `github-actions[bot]`
  rather than as the App, and was refused with a 403. `release-prep.yml` here does not persist a
  credential. `publish.yml` still must, because it pushes the tag through `origin`
  (MemberJunction/bizapps-forms#229).

Expect the first run in common to find something similar. Nothing in either failure reached npm: both
stopped before `Publish to npm`, which is what every gate sitting ahead of it is for.

## When something goes wrong

| Symptom | What it means |
|---|---|
| A step fails to mint the App token | Dispatch **Verify the release App token**. It is read-only and names which half is broken. |
| Publish run is red with an open `chore/backmerge-v*` PR | Not the back-merge: that step stops as soon as a PR is open. Some other step failed on this run (a gate, the build, `changeset publish`); read it. |
| Some packages appear published and others do not, right after a green run | **Wait three minutes and look again before doing anything.** npm's packument is eventually consistent: after bizapps-forms `v0.11.0` the registry served the new version for one package and the old one for four, and converged over about three minutes. Read the `Publish to npm` step's output (`changeset publish` names every package it published) and trust that over the registry. |
| Some packages genuinely did not publish (the step's output says so, or they are still absent well after the run) | `changeset publish` works concurrently and expects a retry. Re-run the workflow. `release-plan.mjs` asks *publish* and *tag* separately, so the re-run finishes the job instead of reporting a green no-op. |
| A push in the release path is refused with a 403 naming `github-actions[bot]` | The push used the ambient token, not the App, whatever its remote URL says: `actions/checkout`'s persisted `extraheader` outranks URL credentials. See MemberJunction/bizapps-forms#226 and MemberJunction/bizapps-forms#229. |
| The back-merge branch exists at an unexpected SHA | The workflow refuses to force-push over it, because someone may have resolved conflicts there. Delete the branch or open the PR by hand. |
| **Prepare a release** refuses because `main` is not contained in `next` | The previous release's `chore/backmerge-v<prev>` PR is unmerged, or was never opened. Merge it with a merge commit (or branch it from `main`'s tip and open it by hand), then re-dispatch. If it was squash- or rebase-merged, open a fresh `main → next` PR and merge it with a merge commit. |
| `release:plan` says the seed is owed | Step 0. [`migrations/README.md`](../migrations/README.md). |
