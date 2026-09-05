---
'@mj-biz-apps/common-activity-sync': minor
---

Activity Sync — deactivating a provider type did nothing, and no test file was ever typechecked.

`ActivitySyncProviderType.IsActive` had no reader anywhere: not on `ProviderTypeRow`, not in
`loadProviderType`'s `Fields` list, not in the run path. An administrator switching a connector type
off changed nothing — every connection pointing at it kept fetching mail and kept reporting success.

**It refuses rather than skipping quietly.** A connection that stops syncing while still showing
green is the failure this subsystem exists to make impossible, so an inactive type produces an issue
naming the type and lands in the connection's health stamp. It follows the shape already set by
"Connection X is not in its Active window" directly above it. The refusal is taken before any
provider is resolved and before any fetch, so it cannot be reached only through a driver lookup
failure, and no mailbox is read on the way to it.

**Absence keeps running.** The comparison is `=== false`, so a row loaded without the field still
syncs. Absence means the query did not ask for the column, and turning one trimmed `Fields` list into
a silent total halt of every sync is a worse failure than the one being guarded against. SQL `BIT`
arrives through `RunView` as a real JS boolean — measured against the database rather than assumed —
so the strict comparison is safe.

**The trap that caused it is now a test.** A field declared on `ProviderTypeRow` but absent from the
`Fields` list is `undefined` at runtime, so any check written against it silently never fires. That
is exactly how `IsActive` came to be ignored. The existing `SELECT *` tripwire now pins the interface
and the field list to each other and fails until a new column is added to both.

**Separately: the test suite was never typechecked.** `tsconfig.json` excludes
`src/**/__tests__/**` so test files never reach `dist` — correct for a published package — but
nothing else checked them either, and vitest transpiles through esbuild without typechecking. Six
errors were sitting in the suite, including a test constructing an `ExclusionRow` missing three
required fields. A `noEmit` config now covers everything, and `pnpm test` runs it before vitest,
which is the only hook available: CI runs `build`, `changes` and `publish`, and never the tests.

11 mutants added to the package harness (M-AC31–M-AC41); all 27 pass.
