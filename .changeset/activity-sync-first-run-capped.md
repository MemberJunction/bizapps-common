---
'@mj-biz-apps/common-activity-sync': patch
---

Activity Sync — a first run that filled its page silently lost every message older than it.

`Capped` required `query.Since`, so it could never be true on a first sync. That left the run most
likely to overflow a page as the only one with no protection:

1. no date bound is sent, so Graph returns the newest `Limit` messages;
2. `ResolveHighWatermark` takes the newest of those for a Message surface;
3. the next run asks for everything **after** it;
4. every message older than that first page is permanently below the watermark, unread.

The run reported `Success`, wrote its activities, and raised no issue. A mailbox with more history
than one page lost all of it, invisibly.

The previous behaviour was deliberate — a test asserted it, on the reasoning that a first sync "has no
watermark to strand mail behind". That does not survive contact with a real mailbox. There is no
watermark *before* the run; the run **creates** one, and that is what does the stranding. The test is
reversed, with the reasoning recorded so nobody re-derives the original conclusion.

`Capped` is now simply "the page came back full", which also withholds the watermark upstream — that
is what actually prevents the loss. The issue text distinguishes a first run from an incremental one,
because the remedy differs: raise the limit, or re-run until it drains.

**The replay transport had the same hole, and it was found by auditing this branch against itself.**
`RecordedMessageTransport` kept `capped && !!query.Since` after the live path dropped it, with a
comment claiming parity with the live path and a test asserting the first-run case was safe "because
there is no watermark to strand anything behind" — the reasoning this note had already rejected,
still sitting two files away. Nothing enforces the order of a recording: a newest-first one truncated
to `Limit` returns the newest N and withholds the oldest, and an uncapped run then computes a
watermark from what it did return. It reaches past the fixture because that mark is durable and the
transport behind it is swappable, so a host that replays a truncated recording and later points the
same connection at live mail skips real messages on a fixture's say-so. Now `Capped: capped`, with
the newest-first case reproduced in a test rather than argued about.

What that does NOT fix is stated in the file rather than left to be rediscovered: `slice(0, Limit)`
is positional and the window is applied downstream, so a truncated replay re-takes the same first N
payloads on every run. A recording longer than `Limit` cannot be replayed in full in any order,
capped or not — measured. The flag keeps that from becoming a false watermark in the database; giving
the fixture transport real paging is a separate change, and the Issues already name the shortfall on
every run.

**Found by running the engine against a real mailbox.** Every recorded fixture is smaller than the
limit, so no replayed test could ever produce a full page. This is the second defect today that only
a live run could surface, after MJ's undeclared `accountEmail`.

Also: `demo/graph-sample-messages.json` is now **validated against live payloads**. Twenty-five real
messages were compared field-name by field-name — never by value — and three real fields were missing:
`conversationIndex`, `flag`, and a populated `replyTo` (it had always been `[]`, so its nested shape
had never appeared, and MJ's own `GetMessages` derives its normalized `To` from `replyTo[0]`). All
three are added; the fixture and live payloads now agree exactly, 48 field paths to 48.
