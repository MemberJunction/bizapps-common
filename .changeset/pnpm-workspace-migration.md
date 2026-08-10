---
"@mj-biz-apps/common-entities": patch
---

Migrate the workspace from npm to pnpm, and release the peer-range fix from #51.

No published package's code, types, metadata or migrations change — this is a
build-tooling change plus a dependency-range correction, which is why it is a patch.

**pnpm migration.** `packageManager` moves to `pnpm@10.33.0`, `package-lock.json` is
replaced by `pnpm-lock.yaml`, the npm `overrides` block moves to `pnpm.overrides`, and
CI installs with `pnpm install --frozen-lockfile`. Two workspace settings are
load-bearing and mirror MJ core: `linkWorkspacePackages: true` (pnpm 10 defaults it
false, which resolves this repo's exact-pinned internal packages from the registry
instead of linking them locally) and an `onlyBuiltDependencies` allowlist (pnpm 10 runs
no dependency build scripts without one).

pnpm's non-hoisted layout also surfaced one latent defect: `apps/MJAPI` runs `vitest run`
but never declared `vitest` anywhere in the repo, so it had been resolving from a hoisted
transitive copy. It is now declared. That app is private and unpublished, so this does
not affect consumers.

**Why this ships #51.** The peer-range fix merged to `next` without a changeset, so it
had no path to npm. This release carries it: every `@memberjunction/*` peer across the
five published packages moves from an exact `6.1.0-edge.0` pin to `^6.1.0-edge.0`.

That matters for consumers. An exact peer pin says "this build and no other", so a
consumer on `6.1.0-edge.1` — which is the rest of the estate — had a mismatch. Under npm
with `legacy-peer-deps` the mismatch was silently ignored; under pnpm it is satisfied by
installing a **second copy** of ~100 MemberJunction packages. Two `@memberjunction/global`
instances means two `MJGlobal` singletons and a split `ClassFactory` registry: it compiles
cleanly and fails at runtime. A caret on a prerelease matches other prereleases sharing
the same major.minor.patch, so `^6.1.0-edge.0` is satisfied by an existing edge.1 copy and
the duplicate disappears.

Consumers on a MemberJunction 6.x line should take this release and will need no
`overrides` workaround to deduplicate MJ.
