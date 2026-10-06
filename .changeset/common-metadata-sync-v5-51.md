---
'@mj-biz-apps/common-entities': minor
---

The 5.51 Metadata_Sync ships what metadata/ added or changed since 5.48: the form layout (field categories, form sections and display names on 59 fields), the FieldCategoryInfo / FieldCategoryIcons entity settings, the three generated validators (ValidateEffectiveToAfterEffectiveFrom, ValidateCapturedContentAndEncryptionKeyCoexistence, ValidateExternalIdAndSourceSystemCoexistence) and the directory dashboard query's business-day people counts. Field-level security for People stays held back, as in 5.48. The seed is idempotent and safe on a host that already ran `mj sync push`.
