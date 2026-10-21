---
'@mj-biz-apps/common-entities': minor
'@mj-biz-apps/common-ng': minor
---

Fast party lookup for Person and Organization foreign keys.

A migration adds two stored, indexed computed columns: `Person.EmailDomain` (the lower-cased text after the `@` of Email) and `Organization.WebsiteDomain` (the lower-cased host of Website, without scheme, `www.` or path). Two metadata queries, `Common: Party Lookup People` and `Common: Party Lookup Organizations`, prefix-match indexed base-table columns (TOP 20, no count). The new `bizapps-party-field` component (`PartyFieldComponent`) lists nothing until two characters are typed, then searches by last name, display name, email or email domain for people, and by name, legal name or website domain for organizations. Apps whose foreign key points at a subtype pass their own query with the same contract: columns `ID`, `Name`, `Detail`; parameters `Term` and `Domain`.
