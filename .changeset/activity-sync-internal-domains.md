---
'@mj-biz-apps/common-activity-sync': minor
---

Activity Sync — `InternalDomains` had no reader, so every participant rule silently inverted.

`ActivitySyncRuleSet.InternalDomains` describes itself as "Required for any rule using
ParticipantScope", `participants.ts` names it as where the list lives, and the migration that created
it explains why it exists at all. `ActivitySyncEngine` passed a hard-coded `[]` into every
qualification context and never read the column. Same shape as the `CredentialsRef` gap: written,
documented, migrated, and consumed by nothing.

**An empty list is not a disabled feature — it is an inverted one.** `ClassifyParticipants` counts an
address as Internal only when its domain appears in the list, so with an empty list every participant
is External:

| scope | intended | what actually happened |
|---|---|---|
| `HasExternal` / `AllExternal` | threads with an outside party | matched **everything**, internal chatter included |
| `AllInternal` / `HasInternal` | internal-only traffic | matched **nothing** |
| `Mixed` | both present | could never match |

So a rule set written to keep internal mail out of the sync included all of it, while reading as a
working filter. On a real mailbox that is the difference between filing a customer thread and filing
everything the user has ever received.

**Malformed fails the run rather than degrading to empty.** A typo in the column would otherwise
become "sync everything", silently — the worst possible reading of a config error. "Internal" is a
property of the deployment, so guessing it is worse than refusing.

**A scoped rule with no domains now says so.** Absent `InternalDomains` is legitimate — plenty of
rule sets never test participants — so it is a reported issue rather than a refusal, naming how many
rules are affected and what to set. Silence there was what made the original defect invisible.

Parsing and the warning are pure functions in `participants.ts` (`ParseInternalDomains`,
`ParticipantScopeWarning`), testable without standing up a RunView. 21 tests, each mutation-checked:
degrading a malformed list to empty, accepting a non-array, dropping the case/`@` normalisation that
keeps the list comparable with the addresses it is matched against, losing de-duplication, silencing
the warning, and treating `Any` as a participant test are all caught.
