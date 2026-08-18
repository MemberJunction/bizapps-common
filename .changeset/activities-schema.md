---
"@mj-biz-apps/common-entities": minor
---

Add Activity, ActivityType, ActivityLink, ActivityFile, ActivitySyncConnection, and ActivitySyncRule so Common can log interactions and control what a mailbox/calendar connection syncs. System activity types (Email, Call, Meeting, Note, SMS, Chat) are seeded via metadata, not SQL INSERTs.
