---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-server": minor
"@mj-biz-apps/common-ng": minor
---

Offboarding: list and reassign what a departed user or employee still holds.

- Metadata: the `Offboarding Holdings` action category. Apps register `<App>: List Offboarding Holdings` and `<App>: Reassign Offboarding Holdings` actions in it; their metadata looks the category up by name, so this release must ship before theirs.
- `@mj-biz-apps/common-entities`: the shared contract (`OffboardingHolding`, `OffboardingSkip`, the category and DriverClass constants) and pure helpers to pair an app's actions, parse their outputs, group holdings by domain and plan a reassign.
- `@mj-biz-apps/common-ng`: an Offboarding tab in the Common app. Pick a leaver (inactive people first), see every app's open items grouped by domain, choose a successor per domain and reassign. Works with any number of registered apps, including none. The picked leaver is kept in the tab's `leaver` query parameter.
- `@mj-biz-apps/common-server`: when an `MJ: Employees` or `MJ: Users` record is saved from active to inactive, the List actions run and, if anything is held, the leaver's supervisor and every accounting CFO approver get a user notification. It listens to the entity save event, so it never blocks the save and does not subclass either entity.
