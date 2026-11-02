---
"@mj-biz-apps/common-entities": minor
"@mj-biz-apps/common-server": minor
"@mj-biz-apps/common-ng": minor
---

Companies can now keep a register of approved sender addresses. A new `Company Sender Identities`
entity stores, per MJ Company, the mailboxes and domains the company may send email from, with at
most one default mailbox. `@mj-biz-apps/common-entities` exports `IsSenderAllowedForCompany`,
`DefaultSenderForCompany` and `SenderDomain`, pure functions that consuming apps call before they
write a `From:` header. A company with no rows is refused, never given a deployment-wide default.
Addresses are stored trimmed and lower-cased, and malformed addresses are refused on save in the
browser and on the server alike. The Company record in Explorer gains an "Email senders" panel to
add a mailbox or domain, set the default and remove a row. This release adds a migration.
