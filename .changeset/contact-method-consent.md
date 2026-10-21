---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-ng": minor
"@mj-biz-apps/common-server": minor
---

Consent per contact method, per purpose, optionally per organization. A new `ConsentPurpose` lookup (Marketing, Transactional, Fundraising, Surveys to start) says what a consent is for; `ContactConsent` holds one current status (NotSpecified, OptedIn, OptedOut) per contact method, purpose and optional organization, so one email can say yes to receipts and no to newsletters, or yes to one organization and no to another; `ContactConsentHistory` keeps one row per change: the status it set, when it took effect, where it came from and who recorded it. `ContactType` links to MJ's Communication Base Message Types so each type is known to be Email, Phone or SMS. `ContactConsentEntity.Save` writes the history row with a direct status change, and `ContactPreferenceEngine` provides `CanContact`, `SetConsent` and `OptOutByValue`, each scoped by purpose and organization, for Comms' send-time hook. The contact method list shows a badge per consent with the history on hover and a dropdown per purpose on add and edit.
