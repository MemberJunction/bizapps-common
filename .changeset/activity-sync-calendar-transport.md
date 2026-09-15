---
'@mj-biz-apps/common-activity-sync': minor
'@mj-biz-apps/common-server': minor
---

Activity Sync — the calendar surface had no transport, so every calendar fetch returned nothing.

`MSGraphCalendarSyncProvider` declared a `GraphEventFetcher` seam that **nothing implemented**,
reachable only as the second constructor argument — and `MJGlobal.ClassFactory` builds plugins with
no arguments. Through the engine, every calendar fetch returned `Payloads: []` and logged "no
transport is wired". Exported, documented, typechecked and unreachable: exactly the state the message
surface was in before its transport landed, one surface over.

**It rides the same seam as mail rather than a parallel one.** `ActivityMessageTransport` is really
"fetch raw payloads for a mailbox", which is the calendar contract too, and the host factory now
dispatches on `DriverClass` to serve both. One connection, one `CredentialsRef`, one credential —
separate factories would let a connection read mail as one principal and calendar as another.

**There was nothing to wrap until now.** MJ's `MSGraphProvider` had no calendar API at all, and the
piece that would make one possible (`getGraphClient`, which owns token acquisition and the
credential-keyed client cache) is private. Building a Graph client here would have forked precisely
what `BaseActivitySyncProvider` says to wrap, so calendar retrieval was added to MJ first
(`GetEvents`) and this wraps it — with the same compile-time assertion the message reader uses, so
drift in MJ's signature breaks the BUILD rather than the first live call.

**One attestation, not two.** The same Exchange Application Access Policy scopes `Mail.Read` and
`Calendars.Read`, so the calendar provider reads the same `AllowLiveMailboxFetch` attestation. A
second switch would let someone record half a decision and believe they had scoped both.

**`IsLive` now follows the transport** instead of being hard-coded `true`. The engine refuses to write
`Source: 'Integration'` rows from a non-live provider, and that guard was worthless while a replayed
calendar run could claim to be live — the resulting rows would be indistinguishable from real ones.

**Three things a calendar read can do quietly, now said out loud:**

- *The window is a rolling lookback and never the watermark.* `/calendarView` refuses an unbounded
  request, so a bound is invented — and an invented bound nobody mentions reads as "we synced your
  calendar" when it means "we synced a month of it". It is said out loud on the first run, where
  somebody expects full history; the same bound applies on every later run.

  An earlier version of this branch passed the watermark as `StartDateTime`, which is a different
  quantity used as if it were the same one. `WatermarkBasisForKind('Calendar')` is `ObservationTime`
  — when we last LOOKED — and `StartDateTime` filters on the EVENT'S own time. So a meeting held
  last week but added to the calendar tomorrow starts before the watermark, falls outside the next
  run's window, and outside every later one, since each starts later still. Never read, on any run,
  no issue, `Success = true`. Retroactive additions and back-dated invitations are ordinary calendar
  behaviour. The same events are now re-read every run, which costs one de-duplication lookup each
  and writes nothing, while a missed event is unrecoverable.
- *Recurrence may not have been expanded.* A series master and a single occurrence look alike, so
  without this a weekly meeting is filed once, at whatever date the series began, and every
  downstream check still passes.
- *A capped read* may have left events in the window.

Cancelled events are fetched deliberately — `MapGraphEvent` already carries `Cancelled` through, and
dropping them at the transport would make that field dead code. The window reaches forward as well as
back, because `Activity.Status` includes `Scheduled`.

The dead `GraphEventFetcher` interface is removed: nothing implemented it, and keeping an unreachable
seam is the defect this change exists to end.

32 tests across the two packages, each mutation-checked — dropping the end bound, silencing the
lookback notice, discarding cancelled events, reading the normalized `Events` instead of `SourceData`,
omitting the recurrence warning, turning a Graph failure into an empty batch, hard-coding `IsLive`,
opening the gate, ignoring the attestation, and refusing to serve the calendar driver are all caught.
Restoring the watermark as the window start is caught too (`M-CW1`), which it was not when that bug
was live: the harness did not open this file at all, so every mutation aimed at it reported all-clear
by never reaching it.
