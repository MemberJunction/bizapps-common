---
"@mj-biz-apps/common-activity-sync": patch
"@mj-biz-apps/common-server": patch
---

Adds tag-to-log consent to Activity Sync. A connection whose `Settings` hold `{"Consent":{"Mode":"Tagged","Tag":"AIDP"}}` captures only email and meetings the mailbox owner tagged with that Outlook category, plus proven replies to a tagged message and the earlier messages a tagged reply names. Drafts, meeting invitations sent as mail, automatic replies, forwards and outbound replies to new recipients are never captured, internal-only threads stay excluded, and BCC is never written. Late tags are found by a sweep; a removed tag withdraws the capture (content and participant links purged, row kept). Connections without a `Consent` block behave exactly as before; a `Consent` block that cannot be read fails the run before the mailbox is read. Full reply support needs `@memberjunction/communication-ms-graph` with `ContextData.Expand`; without it only tagged items are captured.
