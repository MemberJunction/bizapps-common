---
"@mj-biz-apps/common-ng": patch
---

Classify People.PhotoURL and Organizations.LogoURL as EntityField.ExtendedType=Image and lock AutoUpdateExtendedType so CodeGen cannot revert them to URL. mj-entity-viewer and ng-base-forms then render thumbnails / image upload from metadata.
