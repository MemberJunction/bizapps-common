---
"@mj-biz-apps/common-core-entities-server": minor
"@mj-biz-apps/common-server": minor
---

Server-side write guards on Activity data. An Activity's `LoggedByUserID` is always the user who saved it and cannot be changed afterwards (#395). An Activity Link can be saved only by a user who can read the record it links to (#396). Only an Owner-type user (or the System user) may create an Activity Sync Connection or change its `Mailbox`, `CredentialsRef`, `Provider`, provider type, owner, or `Settings` other than the calendar watermark (#392); hosts whose Developer or Integration users create connections need an Owner-type user to do it from this release on.

Organization search now matches the website domain: `Organizations.WebsiteDomain` is a user-search field with a starts-with predicate on its existing index, so typing "acme" finds `https://www.acme-widgets.example` (#329).
