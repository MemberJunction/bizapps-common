# Activity Sync: tag-to-log consent (design, as built)

## Problem
A connection captures an email or meeting when any participant matches a stored ContactMethod
(`KnownParticipantStage`). A dry run of 18 edge cases logged a personal note to a contact who is also a
friend, a personal legal matter, mail the owner had tagged "Personal", a Private calendar event, an unsent
draft and an out-of-office reply. A mailbox cannot tell a quote from a dinner invitation to the same person.

## Decision
A per-connection consent mode, in `ActivitySyncConnection.Settings` (no migration):

```json
{ "Consent": { "Mode": "Tagged", "Tag": "AIDP", "WithdrawWindowDays": 30 } }
```

- `KnownContact` (the default when there is no `Consent` block) keeps today's behaviour.
- `Tagged`: an item is captured only when the mailbox owner applied the Outlook category, or it is a
  proven reply to, or an earlier message named by, a tagged message in the same mailbox. This is the
  Dynamics 365 "Tracked to Dynamics 365" model.
- A block that is present but unreadable (an unknown mode, a blank tag, Settings that are not JSON) fails
  the run before the mailbox is read. It never falls back to the broadest mode.

## Prior art
- Dynamics 365: applying the category tracks the item, and removing it untracks it. Replies are correlated
  by InReplyTo, then a tracking token, then ConversationIndex.
- Gong: excludes Personal/Private sensitivity, personal webmail and internal-only threads, and applies
  exclusions retroactively.
- Salesforce EAC: header-only capture. HubSpot: never-log lists. Weflow: an exclusion applies to the whole thread.

## Cascade on a Tagged connection (`consent-stages.ts`)
1. `ConsentBlock`: blocks drafts, meeting invitations sent as mail (`eventMessage`), and automatic replies
   (`PidTagMessageClass` `IPM.Note.Rules.*Template*`).
2. `Exclusions`: the never-log list. A tag does not outrank it.
3. `Rules`, exclude-only: internal-only threads, date windows. An Include rule is read as undecided,
   because a broad match is not consent.
4. `Consent`: the tag, or a proven reply or ancestor. A proven reply marked Personal/Private/Confidential
   is excluded; a tagged one is the owner's call. Everything else is excluded with the reason "Not
   tagged", or "Not tagged; a known contact is on it". That reason alone gives the count of missed
   mail, with no content stored.

## Proof of continuation (`consent.ts`)
Proof is the RFC reply headers (`In-Reply-To` 0x1042, `References` 0x1039), read as
`singleValueExtendedProperties`, naming a consented Message-ID. `conversationId` is never proof.
- An outbound forward is never a continuation.
- An outbound reply that adds a To/Cc recipient is not a continuation either.
- An inbound reply may come from a new address (a customer writing from a phone).
- Replies settle in rounds, so a reply to a reply is proven by the first one.

## Identity
On a Tagged connection, the ExternalID is the RFC Message-ID (mail) or the iCalUId (meetings). Both are
stable across mailboxes and folder moves, so two ADs on one thread produce one Activity. Immutable Graph
ids are not needed. BCC participants are never written.

### Switching a connection from KnownContact to Tagged (rollout note)
A KnownContact connection files mail under Graph's per-mailbox `id`. The writer de-duplicates on
SourceSystem + ExternalID only. So an email the connection filed BEFORE the switch gets a second
Activity if it is tagged afterwards, or brought in as a proven reply or an ancestor of a tagged message.
The first row keeps its links and notes and is not withdrawn by a later untag (withdrawal follows the
Tagged row). New mail is not affected, and a connection created as Tagged never has this.

This is documented and not fixed here. A fix must find the old row by Message-ID inside the stored
payload and then decide whether an unconsented capture may be adopted as a consented one; that is a
consent decision and a data change to shipped rows, not a de-duplication detail. Before switching a
connection that already has history, expect duplicates for re-tagged old threads, or start a new
connection for the mailbox. Pinned by `consent.test.ts` ("one email, two keys").

## Late tags and withdrawal (`consent-intake.ts`)
- **Sweep.** Each mail pass also reads `categories/any(c:c eq '<tag>') and lastModifiedDateTime ge
  <SweptThrough>`. `SweptThrough` is kept in Settings and moves to the newest `lastModifiedDateTime` seen.
- **Ancestors.** Earlier messages that a tagged reply names, and that are not in hand, are read by Message-ID.
- **Withdraw.** Tagged captures in the window are re-read: mail by Message-ID, meetings from the calendar
  window the run already read. A capture is withdrawn only when the item was read and its tag is gone.
  An item that is missing is kept and reported. The proven replies in that thread are withdrawn with it,
  unless another tagged item in the thread remains.
- **What withdrawal does.** The Activity row is kept for deal links, notes and holds. Its title becomes
  "(withdrawn by the mailbox owner)". Its description and details are cleared, it becomes Private, its
  participant links are deleted, and its ExternalID becomes `withdrawn:<activity id>`, so a later re-tag
  files the item afresh. The re-check is capped at 500 items per run, and the run reports when the cap binds.

## Consent is per connection (after review)
`consent-store.ts` holds the reads and the one write.

- **Where consent lives.** A mailbox's consent to a message is its **latest Consent-stage run detail** for
  that message's ExternalID, on its own connection's runs: `Included` or `Duplicate` grant, and `Excluded`
  ends it. The link is the ExternalID, because `CK_ActivitySyncRunDetail_ActivityOnlyWhenIncluded` keeps
  ActivityID off duplicates. So two ADs on one email are one Activity with two independent consents.
- **When a mailbox's consent ends**, the run records an `Excluded` Consent detail. The shared Activity is
  withdrawn only when no other mailbox still consents.
- **Every read is for one surface** (activity type `Email` or `Meeting`).
- **Withdrawal** windows on consent time, not message time. It re-reads every candidate in batches of 10
  and refuses a cut-off re-read. A proven capture follows its own `Via` chain and is kept if it is tagged now.
- **Proof.** Only items no block, exclusion or Exclude rule stops (`ConsentEligible`) can prove a reply or
  name an ancestor. A Private reply proves nothing further. `References` is read oldest first, so the
  direct parent survives the 20-reference cap.
- **The late-tag sweep** reads `[from, to)` windows. A window whose page came back full is read again
  with Graph's largest page (`$top` 1000), and halved if that is full too. It moves its position only
  past windows read completely, starts 10 minutes before the recorded position (our clock against
  Exchange's), and on a first run records the newest change it read. A late tag also reads its
  conversation, so replies already behind the watermark can be proven.
- **One exception: a crowded instant** (second review). A window already one second wide that still
  fills the largest page cannot be narrowed. The first version stopped there, the position never moved,
  and every later late tag on the connection was lost. The sweep now keeps what that page returned,
  reports the instant and that the rest may have been missed, and continues. Those items are not
  captured, which fails closed; tagging one again lets a later run read it. A sweep makes at most 48
  requests, and says so when it stops short and whether its position moved.
- **Retention.** A Tagged connection never retains the content of items it excluded, whatever
  `SkippedContentPolicy` says.

## Transport
`ActivitySourceQuery.Lookup` (`Tagged` | `MessageIds`) carries both reads through the existing fetch
path. `GraphCommunicationTransport` sends them as `ContextData.Filter`, which MJ already forwards, and
asks for the extended properties with `ContextData.Expand`. **MJ change:** `MSGraphProvider.GetMessages`
must send `ContextData.Expand` as `$expand`. Without it, no reply can be proven and the run says so: only
tagged items are captured, which fails closed.

## Verification
- ActivitySync unit tests: 449.
- Server unit tests: 116.
- IntegrationTests unit tests: 16.
- MJ MSGraph unit tests: 119, including 3 new for `$expand`.
- Live sandbox: `activity-sync` 17/17 (AS-C1–C5 new) and the default suite 29/29, each run twice.
- Two planted engine bugs were caught by AS-C1–C3, and a planted MJ bug by the `$expand` tests.

## Checked on a real Exchange Online mailbox (2026-11-17, delegated Graph Explorer)
- **Adding and removing a category moves `lastModifiedDateTime` and the etag** (20:28:43 tagged, 20:31:59
  untagged, 20:32:53 re-tagged). `changeKey` came back as the same placeholder on every message, so
  it is not used.
- **`categories/any(c:c eq 'AIDP') and lastModifiedDateTime ge ...`** ran on a full mailbox with no
  restriction error and returned exactly the tagged items.
- **The Inbox and Sent Items copies of one email** have different Graph `id`s, carry their tags
  separately, and share one `internetMessageId`.
- **A reply's `In-Reply-To` and `References`** hold the original's Message-ID. Sensitivity is `0` and the
  message class is `IPM.Note`.
- **Graph returns `Integer 0x36` and `String 0x1a` when asked for `0x0036` and `0x001A`.** The first
  version compared ids as text and would never have read sensitivity or message class on live mail.
  Ids are now compared as type plus number, and the fixtures carry the returned form.

## Still to check
- App-only access (needs IT's app registration). The data is the same; only the permission differs.
- Tagging from Outlook mobile.
- Categories on calendarView occurrences of a tagged series.

## Access
Use Exchange RBAC for Applications with a management scope (it replaces Application Access Policies).
Do not consent the tenant-wide Entra Mail.Read grant, which would override the scope.
