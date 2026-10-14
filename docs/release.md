# Cutting a release

bizapps-common uses the open-app release pipeline shared by every bizapp (reference: bizapps-issues).
Releasing is **one merge**. The pull requests are opened for you, and the back-merge merges itself.
Full procedure for every open app: the **Publishing an Open App** SOP.

| Step | Who | What happens |
| --- | --- | --- |
| 1. Changesets land on `next` | you, in each feature PR | `pnpm exec changeset`; a migration or metadata change needs at least `minor` |
| 2. **Version Packages** PR | `version.yml`, on every push to `next` | one PR from `changeset-release/main` into **`main`**: every package bumped, CHANGELOGs, `mj-app.json` synced, lockfile refreshed. It refreshes itself as `next` moves |
| 3. Review and merge it | you | the `rr:` gates, `build`, and this repo's `repo: release seed` run on it. That merge is the release |
| 4. Publish | `publish.yml`, on the merge | builds, publishes to npm over OIDC, tags `vX.Y.Z` only if something shipped, then opens and merges a `release-back-merge/vX.Y.Z` PR into `next` |

There is no separate `next` → `main` PR to open, and nothing to dispatch.

## 0. Before merging the Version Packages PR: the metadata seed

PRs carry declarative JSON under `metadata/`; one consolidated `Metadata_Sync` migration is generated
per release from a clean database ([`migrations/README.md`](../migrations/README.md)). Two checks hold
the release to that, and both now run **on the Version Packages PR** (`repo: release seed` in
`.github/workflows/repo-checks.yml`), before the merge rather than after it:

- `pnpm run check:release-seed`: every `primaryKey` under `metadata/` appears in a shipped migration.
- `pnpm run check:seed-cadence`: the release ships one consolidated seed, not a pile of per-PR deltas.

Run them locally first if you want the answer sooner. If either is red, generate the seed on `next`;
the Version Packages PR refreshes itself.

## Keeping `mj-app.json` in sync between releases

`scripts/sync-app-version.spec.mjs` runs on every PR (`repo: guards`) and fails if the manifest's
`mjVersionRange` disagrees with the `@memberjunction/core` pin in `packages/Entities/package.json`. A PR
that changes that pin must run `node scripts/sync-app-version.mjs` and commit the updated
`mj-app.json`. At release, `version:prepare` syncs the manifest's `version` and range as well.

## Common's own checks

Besides the shared door and gate checks, `repo-checks.yml` runs this repo's checks: mutation anchors,
the script and harness specs, the release-push gate (no workflow or script may push straight to
`main` or `next`), and the release seed checks above. `clean-room-gate.yml` and `mutants.yml` are
unchanged.

## When something goes wrong

| Symptom | Fix |
| --- | --- |
| No Version Packages PR | No changeset is pending, so there is nothing to release. Otherwise read the `version.yml` run. |
| `rr: minor bump` red | Migrations or metadata under a patch: add a `minor` changeset on `next`. |
| `rr: pg counterparts` red | A migration since the last release has no `migrations-pg/` counterpart: add it on `next`. |
| `repo: release seed` red | Generate the consolidated `Metadata_Sync` on `next` (step 0). |
| Publish run red after "Released" | The back-merge could not merge; the error names the PR. Merge it by hand. |
| `rr: release base current` red | The previous release's back-merge has not landed. Merge it, then re-run. |

To check the App credential the pipeline uses, run **Verify the release App token** (manual dispatch,
read-only).
