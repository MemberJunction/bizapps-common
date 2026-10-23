---
"@mj-biz-apps/common-entities": minor
---

Adds a resolver between MemberJunction users and People, exported from `@mj-biz-apps/common-entities` (browser-safe, so Angular and server code can both use it). `People.LinkedUserID` has been deprecated since 5.33.0; a platform now binds a user to a Person through an IS-A subtype of People and records it on the user's `LinkedEntityID` / `LinkedEntityRecordID`. The resolver reads that link first and falls back to `LinkedUserID` for users without one.

- `ResolvePersonIDForUser` and `ResolvePersonIDsForUsers`: user to Person, with an optional `ActiveOnly` filter on Person status.
- `ResolveUserIDForPerson` and `ResolveUserIDsForPeople`: Person to user, active users first when several link one Person.
- `IsPeopleEntity` and `LinkedPersonRecordID`: the checks the resolvers use, for callers that already hold the user record.

Lookups throw on a failed read, so a caller can tell an error from a missing link. Apps that copied their own `person-user-link.ts` can switch to this export once they raise their common floor (#254).
