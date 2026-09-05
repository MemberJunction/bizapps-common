---
'@mj-biz-apps/common-activity-sync': minor
---

Activity Sync — `IncludeAttachments` had no reader, so a rule that asked for attachments got none and said nothing.

`ActivitySyncRule.IncludeAttachments` describes itself as *"1 = also pull attachments into ActivityFile
rows"*. `MaxAttachmentBytes` sits beside it. The `ActivityFile` table, its `Kind` value list
(Body / Attachment / Ics) and its base view are migrated and registered in metadata. **Nothing anywhere
read a line of it.** Fifth instance in this package of schema and documentation written ahead of the
wiring — and as with the others, every test passed because nothing exercised the unwired path.

**The decision is made where it can be made.** Rules are evaluated *after* the fetch, so "does this
item want its attachments?" is unanswerable while fetching. `NormalizedItem` now carries a cheap
`HasAttachments` flag straight from the provider payload, and the policy is resolved at write time
from the rule that actually decided the item. Listing attachments costs a call **per message**, so
that call is now paid only for items a rule both included and asked about.

**No rule means no attachments.** An item can be included by the KnownParticipant stage or a
provider-type default, and neither expresses an attachment choice. Defaulting to "fetch" there would
pull every attachment in a mailbox on the strength of a decision nobody made.

**Everything dropped is reported.** Silently omitting a signed contract because it exceeded a cap,
while reporting a successful sync, is the failure this package keeps being written against. Oversize
files are named individually; inline images are summarised by count so forty signature logos cannot
bury the one line that matters. A file whose size cannot be read is skipped rather than allowed while
a cap is in force — that gap would pass exactly the file the cap exists to stop. A cap of `0` reads as
"unset", not "keep nothing", because that is overwhelmingly what a zero in that column means.

**Inline attachments are dropped by default** — body furniture, already visible in the body, and
`ActivityFile.Kind` has a separate `Body`. Keeping them would fill file storage with one copy of a
corporate logo per email. Still reported, so a deployment that wants them can see what it is missing.

**The bytes are not moved yet, and that is now said out loud.** `ActivityFile.FileID` is a foreign key
into `__mj.File`, so storing an attachment needs MJ's `FileStorageEngine` and a configured
`FileStorageAccount` — every MJ storage driver is a remote service, and a host may legitimately have
none. `ActivityFileSink` is the seam a host fills, exactly as it fills the transport factory. With no
sink registered, an item whose rule asked for attachments produces an issue naming the item and both
ways out, instead of an activity quietly filed without them.

19 tests, each mutation-checked: fetching with no rule, ignoring the item's flag, reading a zero cap
as "keep nothing", keeping inline images, allowing an unmeasurable file past a cap, an off-by-one at
the cap boundary, ignoring `Fetch: false`, and suppressing or over-listing the skip report are all
caught. Verified end to end against the database: with the rule switched on, exactly one of five demo
items reported — the one whose payload says it has attachments.
