---
'@mj-biz-apps/common-entities': minor
---

Say on `ActivitySyncRunDetail.CapturedContent` that rotating its encryption key makes existing rows unreadable.

The column already described its own contract — *"Ciphertext, always … Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row"* — which reads like a promise the value stays readable. It does not survive a key rotation, and the operator who turns retention on is the person who needs to know that before the rows exist rather than after.

`RotateEncryptionKeyAction` finds what to re-encrypt by enumerating `MJ: Entity Fields` with `EncryptionKeyID = '<key>' AND Encrypt = 1`. This column is encrypted by calling the engine directly rather than by declaring the field — the same decision that keeps the crypto out of `common-activity-sync` — so rotation never sees it. The stored envelope, `$ENC$<keyId>$<algorithm>$<iv>$<ciphertext>[$<authTag>]`, records which key opened a value but not which version of it, so nothing in the row says it was written under an earlier one. Rotation reports success, skips these rows, and the next read of them fails.

Live operational data is re-encrypted as part of a rotation, which is why this has not bitten anything before. An audit archive is the one kind of column where the read comes years after the write.

Written as an `MS_Description` extended property rather than an `EntityField.Description` update, because `spUpdateExistingEntityFieldsFromSchema` mirrors the column comment over `EntityField.Description` whenever `AutoUpdateDescription = 1`, which this row took by default; a direct update would be reverted by the next `R__RefreshMetadata`. The migration also mirrors the property into `EntityField` itself, reading it back out of the catalog so the two cannot drift, since that repeatable only re-runs when its own checksum changes.

The underlying platform gap is tracked as MemberJunction/MJ#4580. Nothing in this repo works around it: recording a key version in the envelope, or giving rotation a way to see hand-encrypted columns, are both platform decisions.

The next CodeGen run will carry the new text into the generated entity docblock and the GraphQL field description; those files are not in this changeset.
