---
'@mj-biz-apps/common-activity-sync': patch
---

Activity Sync — a calendar fixture, and the engine bug it immediately found.

`demo/graph-sample-events.json` is the calendar counterpart to the message fixture: six events
hand-built to the shape of Microsoft's published `event` resource, chosen to exercise decisions rather
than to look tidy — a recurring **occurrence** with a `seriesMasterId`, a cancellation, an
internal-only meeting for the `ParticipantScope` path, one event carrying attachments, and one whose
`timeZone` is a named non-UTC zone with no offset, which genuinely determines no instant. Fields the
mapper never reads are kept deliberately, so the fixture agrees with Microsoft rather than with us.

**Running it end to end found a real bug.** `RunConnections` drives a second calendar surface from the
same connection and the same type row, and `Configure` received `typeRow.DriverClass` on both passes.
So a host factory serving both surfaces was told `"Microsoft365"` for the calendar too: it built a
**mail** transport, fed Graph message payloads to the event mapper, and every one was dropped for
having no start time.

The failure mode is why it survived. The run reported `Success` with an empty calendar, which is
indistinguishable from a genuinely empty calendar — no error, no exception, nothing to investigate.
It surfaced the moment five real events arrived as five "no usable start time" skips.
`SurfaceDriverClass` now answers with the driver of the surface being run, from the `Kind` the plugin
already declares.

**Both fixtures are now covered by tests**, which they were not before: the message fixture was loaded
only by a demo script, so nothing stood behind it but plausible-looking output. A fixture nobody
asserts against drifts silently — a mapper quietly stops reading a field and the demo still prints a
green wall with one column now empty. Among other things these pin that the timezone sample is
*skipped*, so a later "fix" that guesses at a named zone fails here rather than filing meetings hours
from when they happened.

`engine-dry-run.mjs` gains `--fleet`, which drives `RunConnections` — the path the scheduled Action
uses, and the only one that reaches the calendar surface at all. Its recorded factory dispatches on
`DriverClass`, so each surface replays its own payloads.

Verified against the database: a fleet run writes 5 Email and 5 Meeting activities, with the sixth
event correctly skipped by name.
