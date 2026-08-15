# Adopting MJ's Entity Action workflow extensions

> **Status:** Tracking doc — nothing to build here yet.
> **Upstream:** MemberJunction/MJ **[#3408](https://github.com/MemberJunction/MJ/pull/3408)** · [design plan](https://github.com/MemberJunction/MJ/blob/claude/sales-deal-management-app-ueporb/plans/entity-action-workflow-extensions.md)
> **Blocked on:** that PR merging *and* its engine work landing (the PR ships schema + plan only).

---

## 1. What is changing in MJ core

`EntityAction` — MJ's generalized hook for running an Action off an entity's
create / update / delete / validate — is becoming the **workflow-hook substrate for every app on
the platform**, so no app needs to invent its own.

It already does more than its schema suggests, and this is worth knowing regardless of this PR:

| Invocation | Where it fires | Semantics |
|---|---|---|
| `Validate` | `OnValidateBeforeSave` | **A real blocking gate** — a non-`Success` result fails the save |
| `Before*` | `OnBeforeSaveExecute` | Awaited, result discarded (cannot veto) |
| `After*` | `OnAfterSaveExecute` | Fire-and-forget |

And because **`Execute Agent` is just an Action**, any binding can already run an agent — a
deterministic **flow agent** (visual editor, `Action`/`Prompt`/`Sub-Agent`/`ForEach`/`While` steps,
per-step retry and error behaviour) or a **loop agent** where judgement is genuinely needed. The
house shape is a flow agent with a `Sub-Agent` step calling a loop agent.

**What #3408 adds:**

- **`EntityAction.ScopeEntityID` + `ScopeRecordID`** — bind a workflow to *one configuration record*
  rather than to every record of an entity. This is the important one: it means **no app ever grows
  a column per type per event**, and a configuration record can surface "the workflows bound to me"
  as a real relationship instead of something buried in filter code.
- **`EntityAction.Sequence`** — deterministic ordering when several bindings share an event.
- **`EntityActionParam.ValueType = 'Entity Object Data'`** — passes `entity.GetAll()` instead of the
  live `BaseEntity`. Use it for anything that serializes, above all `Execute Agent`'s `Data` payload:
  a `BaseEntity` serializes to `{}` because its fields are getters, so the agent silently receives
  an empty payload with no error anywhere.
- Two seeded reusable `ActionFilter`s — **"field changed"** and **"field changed *to* value"** — so
  transition detection stops being hand-rolled. Without them `AfterUpdate` fires on *every* update,
  and "status *is* X" instead of "status *changed to* X" re-fires on every later save.
- `After*` routed through `QueueManager` so failures are durable and retryable rather than logged
  and swallowed.

**Authoring is pure metadata** — `metadata/entity-actions/`, with `relatedEntities` for invocations,
filters and params. No schema and no code in the consuming app.

---

## 2. What this means for BizApps Common

Common is the substrate every other app builds on, so its interest is twofold.

**As a consumer:** identity lifecycle events are genuinely useful hook points — a person created, an
organization merged, a relationship started or ended.

**As a provider:** the **Activity spine** planned for this repo (see the Sales & Contracts plan in
`new-products/sales-deal-management/plans/01-common-activity.md`) pairs unusually well with
`EntityAction`. `Common.LogActivity` is an Action, so **any app can write to the unified timeline
declaratively** — bind `AfterCreate`/`AfterUpdate` on any entity to `LogActivity` and that record's
lifecycle shows up on the person's or organization's timeline with no code.

That combination is worth calling out in the Activity work: the spine plus a core hook mechanism
means timeline population becomes a configuration exercise rather than an integration in every app.

## 3. Suggested bindings

| Entity + invocation | Scope | Work | Purpose |
|---|---|---|---|
| `Person` · `AfterCreate` | — (global) | Action → `Common.LogActivity` | Seed the timeline at the moment identity is created |
| `Person` · `AfterUpdate` (lifecycle/status changed) | — | Flow agent | Downstream reaction to identity state changes |
| `Organization` · `AfterUpdate` (status changed) | an `OrganizationType` | Action | Notify owners of account-status changes |
| `Relationship` · `AfterCreate` / `AfterUpdate` (ended) | a `RelationshipType` | Action | Employment / affiliation changes that other apps care about |
| **any entity in any app** · `AfterCreate` | that app's type record | Action → `Common.LogActivity` | The generic pattern — timeline population as configuration |

## 4. Notes specific to this repo

**`Common.LogActivity` should take `'Entity Object Data'`, not `'Entity Object'`.** If the Action
serializes its input at any point — and it will, if it is ever routed through a queue or an agent —
a `BaseEntity` yields `{}`. Worth stating in the Action's own parameter documentation so nobody
reaches for the wrong one.

**Do not build a workflow subsystem here.** An earlier iteration of the Sales & Contracts design
proposed a `WorkflowEventType` / `WorkflowBinding` / `WorkflowRun` trio in this repo. It was
withdrawn once the `EntityAction` implementation was read properly: it would have been a parallel
universe next to a working core feature. Recording it so the idea does not get re-proposed.

---

## 5. What to do now

**Nothing.** This is a tracking doc so the idea is not lost and so this repo's plans reflect where
workflow hooks are going. When #3408 merges and its engine work lands:

1. Confirm the bindings in §3 are still the right ones.
2. Author them as metadata under `metadata/entity-actions/`.
3. Build the flow agents they dispatch to.
4. Delete this file, or fold it into the repo's main plan.

## 6. Two rules to carry into the design

- **Synchronous bindings should be Actions, never agents.** `Validate` and `Before*` run inside the
  caller's transaction. A loop agent's duration is unbounded and holding a transaction open for it
  is not acceptable. Agents belong on `After*`, which is async.
- **A flow agent should create human work and finish** — it should not hold a run open waiting for
  a person. Use `MJ: AI Agent Requests` when the answer resumes the same run (minutes to hours), and
  a **bizapps-tasks** Task when it is durable, assignable work someone owns (days to weeks).

---
_Generated by [Claude Code](https://claude.ai/code)_
