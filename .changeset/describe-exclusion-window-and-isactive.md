---
"@mj-biz-apps/common-entities": minor
---

Describe the four Activity Sync switches an operator sets: `ActivitySyncExclusion.IsEnabled`, `EffectiveFrom`, `EffectiveTo` and `ActivitySyncProviderType.IsActive` were all created without a column description. The one that needed saying is the exclusion window, because the same feature carries the opposite convention a few fields away — `ActivitySyncConnection.StartAt`/`EndAt` are evaluated against the clock, while the exclusion window is matched against the message's own timestamp, so setting `EffectiveFrom` to today does not mean "from now on".

Written as `MS_Description` extended properties rather than as an `EntityField.Description` update, because `spUpdateExistingEntityFieldsFromSchema` mirrors the column comment over `EntityField.Description` whenever `AutoUpdateDescription = 1`, which these rows default to; a direct update would have been reverted by the next `R__RefreshMetadata`. The migration also mirrors the four properties into `EntityField` itself, reading them back out of the catalog so the two cannot drift, since that repeatable only re-runs when its own checksum changes.

The next CodeGen run will add the matching `* * Description:` docblock lines and GraphQL `@Field` descriptions for these four fields; those generated files are not in this changeset.
