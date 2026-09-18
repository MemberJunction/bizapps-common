/*
  Say on the column that key rotation does not reach captured content.

  WHY. `ActivitySyncRunDetail.CapturedContent` already describes its own contract -- "Ciphertext,
  always ... Encrypted through MJ's EncryptionEngine against an MJ: Encryption Keys row" -- and that
  reads like a promise the value stays readable. It does not survive a key rotation, and the operator
  who switches retention on is the person who needs to know before the rows exist rather than after.

  WHAT IS ACTUALLY BROKEN, upstream rather than here. `RotateEncryptionKeyAction` finds what to
  re-encrypt by enumerating `MJ: Entity Fields` with `EncryptionKeyID = '<key>' AND Encrypt = 1`.
  This column is encrypted by calling the engine directly rather than by declaring the field, which
  is the same decision that keeps the crypto out of `common-activity-sync`, so rotation never sees
  it. And the envelope -- `$ENC$<keyId>$<algorithm>$<iv>$<ciphertext>[$<authTag>]` -- records WHICH
  KEY but not WHICH VERSION, so nothing in the value says it was written under an earlier one.
  Rotation reports success, skips these rows, and the next read of them fails.

  Live operational data is re-encrypted as part of a rotation, which is why this has not bitten
  anything before. An audit archive is the one kind of column where the read comes years after the
  write. Tracked upstream as MemberJunction/MJ#4580; nothing in this repo should work around it.

  WHY AN EXTENDED PROPERTY AND NOT AN EntityField UPDATE. `EntityField.Description` is a mirror, not
  a place to write: `spUpdateExistingEntityFieldsFromSchema`, which `R__RefreshMetadata` runs, does

      ef.Description = IIF(fr.AutoUpdateDescription=1, fr.SQLDescription, ef.Description)

  and `AutoUpdateDescription` defaults to 1, which this row took. A bare UPDATE would be reverted by
  the next refresh. `MS_Description` on the column is the durable source; EntityField follows it.

  The EntityField statement at the bottom exists only for TIMING -- `R__RefreshMetadata` is a Flyway
  repeatable and re-runs when its own checksum changes, which this migration does not touch, so
  without it the text would sit in the catalog until some unrelated change happened to trigger a
  refresh. It reads the value back out of the property just written rather than repeating the
  literal, so the two cannot drift.

  Metadata only: no table is created or altered, and no data in any Activity Sync table is touched.
  CodeGen output is deliberately absent -- a description reaches the generated entity docblock and
  the GraphQL field description on the next CodeGen run, and hand-writing an approximation of that
  emit only creates a phantom diff for whoever runs it next.
*/

---------------------------------------------------------------------------
-- ActivitySyncRunDetail.CapturedContent
---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
      AND minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRunDetail]'), N'CapturedContent', 'ColumnId')
      AND name = N'MS_Description'
      AND class = 1  -- column, not an index or the table itself
)
    EXEC sp_dropextendedproperty
        @name = N'MS_Description',
        @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
        @level1type = N'TABLE',  @level1name = N'ActivitySyncRunDetail',
        @level2type = N'COLUMN', @level2name = N'CapturedContent';
GO

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Ciphertext, always — never plaintext, whatever the policy. Present only when the effective SkippedContentPolicy allows retention, and always paired with the EncryptionKeyID that opens it (CK_ActivitySyncRunDetail_ContentKey). Encrypted through MJ''s EncryptionEngine against an MJ: Encryption Keys row; this app never implements its own crypto. ROTATING THAT KEY MAKES EXISTING ROWS UNREADABLE: rotation re-encrypts only fields declared with Encrypt = 1, this column is encrypted by calling the engine directly, and the stored value records which key opened it but not which version — so a rotation skips these rows silently and the next read of them fails. Retain content here only for as long as the key behind it will not be rotated, or rotate with a plan for this column. Tracked upstream as MemberJunction/MJ#4580.',
    @level0type = N'SCHEMA', @level0name = N'${flyway:defaultSchema}',
    @level1type = N'TABLE',  @level1name = N'ActivitySyncRunDetail',
    @level2type = N'COLUMN', @level2name = N'CapturedContent';
GO

---------------------------------------------------------------------------
-- Mirror it into EntityField now, rather than waiting for whichever later
-- deploy happens to re-run R__RefreshMetadata.
--
-- CROSS APPLY, not LEFT JOIN, on purpose: if the property is somehow absent
-- the row simply does not update. Writing NULL over a description is the one
-- outcome this statement must not be able to produce.
---------------------------------------------------------------------------
UPDATE ef
SET ef.[Description]    = CONVERT(NVARCHAR(MAX), ep.[value]),
    ef.[__mj_UpdatedAt] = GETUTCDATE()
FROM [${mjSchema}].[EntityField] ef
CROSS APPLY (
    SELECT x.[value]
    FROM sys.extended_properties x
    WHERE x.major_id = OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRunDetail]')
      AND x.minor_id = COLUMNPROPERTY(OBJECT_ID(N'[${flyway:defaultSchema}].[ActivitySyncRunDetail]'), N'CapturedContent', 'ColumnId')
      AND x.[name] = N'MS_Description'
      AND x.class = 1
) ep
WHERE ef.[ID] = '7905d4d1-557e-4693-92a9-8cd497d793cd';
GO
