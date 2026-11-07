---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-ng": minor
"@mj-biz-apps/common-server": minor
---

Consent per contact method, per purpose, optionally per requesting organization. A new `ConsentPurpose` lookup, ordered by `Sequence`, says what a consent is for, seeded with the generic Marketing and Transactional (apps add their own). `ContactMethodConsent` holds one current status (Not Specified, Opted In, Opted Out) per contact method, optional purpose and optional `RequestingOrganizationID`, so one email can say yes in general, no to newsletters, or yes to one organization and no to another. `ContactMethodConsentHistory` keeps one row per change: the status it set, when it took effect, its source (Web Form, Unsubscribe Link, Import, Staff or Other, default Staff), the specifics in `ConsentDetails`, and who recorded it. `ContactType` links to MJ's Communication Base Message Types so each type is known to be Email, Phone or SMS. `ContactMethodConsentEntity.Save` writes the history row with a direct status change, and `ContactPreferenceEngine` provides `CanContact`, `SetConsent` and `OptOutByValue`, each scoped by purpose and requesting organization, for Comms' send-time hook; an unknown purpose is refused. The contact method list shows a badge per consent with the history on hover and a General dropdown plus one per purpose on add and edit.
