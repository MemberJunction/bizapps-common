---
'@mj-biz-apps/common-activity-sync': minor
---

Activity Sync — an exclusion could not be switched off, and one dated to lapse never lapsed.

`ActivitySyncExclusion` carries `IsEnabled`, `EffectiveFrom` and `EffectiveTo`. The qualification
cascade read none of the three. Same shape as the `CredentialsRef` and `InternalDomains` gaps:
columns written, migrated, documented, and consumed by nothing.

Two independent failures, both silent:

| set by an operator | intended | what actually happened |
|---|---|---|
| `IsEnabled = 0` | stop excluding this address | kept excluding, indefinitely |
| `EffectiveTo` in the past | the exclusion lapses | never lapsed |
| `EffectiveFrom` in the future | starts excluding later | excluded from the moment it was saved |

None of it is visible from the outside. The run reports success, `ActivitySyncRunDetail` records the
exclusion as matched, and the only symptom is mail that quietly never arrives — typically noticed
months after whoever set the date stopped watching for it. Rules honoured their own `IsEnabled` from
the first commit, so the two halves of one cascade disagreed about whether an off switch meant
anything.

**The window is matched against the item, not the wall clock.** `RuleRow.DateFrom`/`DateTo` are
already compared against `item.StartedAt` one stage later in the same cascade. Had an exclusion's
window meant "while this record is in force" instead, the same two dates would mean different things
one stage apart — a trap for whoever writes the second rule set. Item time also keeps a re-run
reproducible: `ActivitySyncRunDetail` exists to answer "which rule ate my message", and an answer
that moves with the clock is a narrative rather than evidence.

**Absence reads as enabled.** A row that does not carry `IsEnabled` still excludes. An exclusion
exists to stop something being ingested, so the missing-flag case has to fail in the direction that
keeps it stopped.

**The check lives in memory, not in `ExclusionsExtraFilter`.** One place decides, matching how rules
are handled — a SQL half and a TypeScript half would be two places to keep in agreement.

`ExclusionAppliesTo` is a pure exported function, so the three ways an exclusion can fail to apply
are testable without standing up a cascade. 16 tests, each mutation-checked (M-AC31–M-AC38): dropping
either bound, dropping the enabled check, reading absence as off, making either boundary exclusive,
abandoning the cascade instead of skipping one lapsed row, and judging by run time instead of item
time are all caught.
