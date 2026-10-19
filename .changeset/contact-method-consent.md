---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-ng": minor
"@mj-biz-apps/common-server": minor
---

Consent per contact method. `ContactMethod.ConsentStatus` (NotSpecified, OptedIn, OptedOut) holds the current consent for each email or phone, and the new `ContactConsentHistory` table keeps one row per change: the status it set, when it took effect, where it came from and who recorded it. `ContactType` links to MJ's Communication Base Message Types so each type is known to be Email, Phone or SMS. `ContactMethodEntity.Save` writes the history row with a direct status change, and `ContactPreferenceEngine` provides `CanContact`, `SetConsent` and `OptOutByValue` for Comms' send-time hook. The contact method list shows a consent badge with hover history and a Consent dropdown on add and edit.
