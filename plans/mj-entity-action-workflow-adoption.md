# Adopting MJ's Entity Action workflow extensions

> **Status:** ✅ **Unblocked — ready to build.** Was a tracking doc; the upstream work has landed.
> **Upstream:** MemberJunction/MJ **[#3408](https://github.com/MemberJunction/MJ/pull/3408)** — merged.
> **Verified in the MJ tree** (2026-08-30): `EntityAction.ScopeEntityID` / `ScopeRecordID` /
> `Sequence` and `EntityActionParam.ValueType = 'Entity Object Data'` are in the generated ORM;
> `packages/Actions/Base/src/EntityActionScopeResolver.ts` (with tests) and
> `DurableEntityActionSubmitter.ts` exist.

---

## 1. What `EntityAction` is

MJ's generalized hook for running an Action off an entity's create / update / delete / validate —
the workflow-hook substrate for every app on the platform, so no app invents its own.

The invocation semantics matter more than the schema suggests, and **getting them backwards fails
silently**:

| Invocation | Where it fires | Semantics |
|---|---|---|
| `Validate` | `OnValidateBeforeSave` | **A real blocking gate** — a non-`Success` result fails the save |
| `Before*` | `OnBeforeSaveExecute` | Awaited, **result discarded — cannot veto** |
| `After*` | `OnAfterSaveExecute` | Asynchronous; see `RunMode` in §2 |

Because **`Execute Agent` is just an Action**, any binding can run an agent — a deterministic **flow
agent** (visual editor, `Action`/`Prompt`/`Sub-Agent`/`ForEach`/`While` steps, per-step retry) or a
**loop agent** where judgement is genuinely needed. The house shape is a flow agent with a
`Sub-Agent` step calling a loop agent.

**Authoring is pure metadata** — `metadata/entity-actions/`, with `relatedEntities` for invocations,
filters and params. No schema and no code in the consuming app.

---

## 2. Three things shipped differently from the original plan

Each one changes a design decision, so they are worth reading before authoring anything.

### 2.1 Durability is **opt-in**, not automatic

The original plan said `After*` would be routed through `QueueManager` so failures became durable.
What shipped is **`EntityAction.RunMode: 'Inline' | 'Durable'`, defaulting to `Inline`**, with the
durable path behind `DurableEntityActionSubmitter`. The submitter's own header gives the reasoning:
durability costs a Task row per dispatch, a dispatcher hop of latency, and it persists the action's
parameters at rest — charging every installation for that silently would be a large unasked-for
change.

**The consequence is the part to internalise:** an `After*` binding left at the default is
**fire-and-forget — a failure is logged and swallowed.** Anything that must not be lost needs
`RunMode = 'Durable'` set deliberately, per binding.

> This is the same defect shape the Activity Sync review spent an evening on: a failure that is
> indistinguishable from success at the call site. Treat `RunMode` as a required decision when
> authoring, never a default to inherit.

### 2.2 Parameter logging has a hard rule and a flag

Params of `ValueType` `'Entity Object'` or `'Entity Object Data'` are **never** written to
`ActionExecutionLog.Params`, regardless of any setting. Separately, a per-param flag suppresses
logging for values that carry records, credentials or personal data — the `Data` payload of
`Execute Agent` being the named example. When logging is suppressed the log keeps the parameter's
name, its type and a redaction marker, never the value.

Relevant here because Common's bindings carry identity data by definition.

### 2.3 The two reusable `ActionFilter`s could not be found

The plan called for two seeded filters — **"field changed"** and **"field changed *to* value"** — so
transition detection stops being hand-rolled.

**Searched and did not find them** (2026-08-30): no `metadata/**/*.json` in MJ references
`ActionFilter`, and the only `INSERT INTO [ActionFilter]` occurrences in `migrations/` are inside
CodeGen's `spCreateActionFilter` bodies, not seed data. This is a "could not find", not a proof of
absence — **verify upstream before relying on them.**

It matters because without them, `AfterUpdate` fires on **every** update, and a filter written as
"status *is* X" rather than "status *changed to* X" re-fires on every later save. Every app would
hand-roll the same detection, which is the duplication the filters exist to prevent. See §9.

---

## 3. What this means for Common

Common is the substrate every other app builds on, so its interest is twofold.

**As a consumer:** identity lifecycle events are genuine hook points — a person created, an
organization merged, a relationship started or ended.

**As a provider:** the Activity spine — **now shipped** (`Activity`, `ActivityLink`, `ActivityFile`,
plus the Activity Sync Engine, bizapps-common#93) — pairs unusually well with `EntityAction`.
`Common.LogActivity` is an Action, so **any app can write to the unified timeline declaratively**:
bind `AfterCreate`/`AfterUpdate` on any entity to `LogActivity` and that record's lifecycle appears
on the person's or organization's timeline with no code in the consuming app.

Timeline population becomes a **configuration exercise** instead of an integration in every app.

### 3.1 ⚠️ The keystone does not exist yet

**There is no `Common.LogActivity` Action**, and this repo has no `metadata/actions/` or
`metadata/entity-actions/` directory at all. Every binding proposed below depends on it. It is the
first deliverable, not one of several.

### 3.2 `LogActivity` must **wrap** `ActivityWriter`, not reimplement it

#93 changed this design question. The Activity Sync engine writes activities through
`ActivityWriter`, which owns:

- dedupe on `(SourceSystem, ExternalID)`
- `Visibility = 'Private'` on synced rows (the column default stays `Internal`, which is right for a
  manually logged activity and wrong for a synced one)
- the unresolved-`ActivityLink` rule — an unmatched address gets a link with
  `IdentityKind`/`IdentityValue`, and **never invents a `Person`**
- extension dispatch **inside** the write transaction

If `LogActivity` writes its own rows instead of calling that writer, the declarative path and the
ingest path drift: two visibility defaults, two link conventions, two dedupe stories, and no error
anywhere when they disagree. **One writer, two entry points.**

### 3.3 The parameter trap, still worth stating in `LogActivity`'s own docs

`LogActivity` must take **`'Entity Object Data'`**, never `'Entity Object'`. If the Action serializes
its input at any point — and it will, once routed through a queue or an agent — a `BaseEntity`
yields `{}`, because its fields are getters rather than enumerable own properties. Silently, with no
error.

---

## 4. The sleeper feature: `ScopeRecordID` × the type tables

`ScopeEntityID` + `ScopeRecordID` bind a workflow to **one configuration record** rather than to
every record of an entity. `NULL` means "applies to every record" — unscoped bindings always apply.

This is the important one, and it lands squarely on how these apps are already built:

- **Common** has five type tables: `ActivityType`, `ContactType`, `OrganizationType`,
  `RelationshipType`, `AddressType`.
- **Sales** has ten, and an explicit rule — *domain vocabulary is DATA, never code* — that already
  forbids branching on names and puts **behaviour flags** on type rows (`DealStatusType.IsWon`,
  `.LocksDeal`, `DealRole.IsOwnerRole`).

`ScopeRecordID` extends that principle **from flags to workflows**. "When an Organization of type X
changes status, notify the owners" becomes a row attached to that `OrganizationType` — and the type
record can surface *the workflows bound to me* as a real relationship instead of something buried in
filter code. No app ever grows a column per type per event.

For sales this needs no new concept taught: it is the rule the app already lives by, one level up.

---

## 5. Proposed bindings — Common

| Entity + invocation | Scope | Work | `RunMode` | Purpose |
|---|---|---|---|---|
| `People` · `AfterCreate` | — (global) | Action → `Common.LogActivity` | Durable | Seed the timeline at the moment identity is created |
| `People` · `AfterUpdate` (lifecycle changed) | — | Flow agent | Durable | Downstream reaction to identity state changes |
| `Organizations` · `AfterUpdate` (status changed) | an `OrganizationType` | Action | Durable | Notify owners of account-status changes |
| `Relationships` · `AfterCreate` / ended | a `RelationshipType` | Action | Durable | Employment / affiliation changes other apps care about |
| **any entity in any app** · `AfterCreate` | that app's type record | Action → `Common.LogActivity` | Durable | The generic pattern — timeline population as configuration |

Every row above is `Durable` deliberately: each one either writes a durable record or notifies a
human, and neither is acceptable to lose silently (§2.1).

## 6. Proposed bindings — Sales

Three candidates that fit sales' existing rules rather than working around them.

### 6.1 `Deal.Amount` staleness — automate the refresh without computing money

Sales caches `Deal.Amount` with `AmountIsComputed` / `AmountComputedAt` / `AmountSourceHash`, so the
hash fingerprints the line set and the UI can say *"stale, reprice"*.

An `AfterUpdate` binding on `DealLine` can dispatch an Action that calls **`Orders.PreviewOrder`** and
stamps the returned values. **Rule #1 survives intact** — sales still never multiplies, discounts,
prorates or rounds; it asks and records. The binding automates *when* to ask.

`RunMode = 'Durable'`. A swallowed failure here is a silently stale forecast, which is worse than a
visible error.

### 6.2 `DealStageEvent` transitions — the textbook filter case

Stage transitions are exactly "field changed *to* value", and `DealStageEvent` is append-only
provenance that stamps `AmountAtTransition` / `ProbabilityAtTransition`.

This is the binding most dependent on §9 resolving. Hand-rolling the detection per app is the same
shape as the guards sales' own `CLAUDE.md` records being outgrown twice.

### 6.3 The close lock stays in code — and here is the trap

`DealEntityServer.Save()` enforcing `DealStatusType.LocksDeal` is **correct as code** and should stay
there: it is a synchronous, blocking invariant that must hold for an Action, an agent and a raw
`BaseEntity.Save()` alike.

If anyone later moves it to an `EntityAction`, it must be bound to **`Validate`** — the real gate.
Binding it to `Before*` **silently removes the lock**, because `Before*` is awaited and its result
discarded. Recorded here because the two read as interchangeable and are not.

---

## 7. Rules to carry into the design

- **`RunMode` is a decision, not a default.** Anything that must not be lost is `Durable` (§2.1).
- **Synchronous bindings are Actions, never agents.** `Validate` and `Before*` run inside the
  caller's transaction; a loop agent's duration is unbounded and holding a transaction open for it is
  not acceptable. Agents belong on `After*`.
- **A flow agent creates human work and finishes** — it does not hold a run open waiting for a
  person. `MJ: AI Agent Requests` when the answer resumes the same run (minutes to hours); a
  **bizapps-tasks** Task when it is durable, assignable work someone owns (days to weeks).
- **Set `Sequence` deliberately.** Once several apps bind to `People.AfterCreate`, order is
  observable. Expressible now — so express it rather than inheriting insertion order.
- **`'Entity Object Data'` for anything that serializes** (§3.3).

---

## 8. Two mechanisms, deliberately not merged

`Sales.DealLinker` is an **Activity Sync extension**; the bindings above are **EntityActions**. They
will look mergeable to someone eventually. They are not:

| | Activity Sync extension | EntityAction |
|---|---|---|
| Fires on | an item being ingested | an entity's save lifecycle |
| Runs | **inside** the engine's write transaction | `Validate`/`Before*` in-transaction, `After*` async |
| Purpose | enrich the activity being written, atomically | react to a record changing |
| Registered via | `ActivitySyncExtension` rows | `EntityAction` rows |

The extension exists so an activity and its attribution commit as **one atomic fact** — an activity
that commits without its deal link is observably unattributed until a second transaction catches up.
An `AfterCreate` EntityAction cannot give that guarantee. Keep both.

---

## 9. Open question for upstream

**Do the two reusable `ActionFilter`s exist?** ("field changed", "field changed to value" — §2.3.)

- If **yes**: point at them here, and §6.2 proceeds as configuration.
- If **no**: this is a genuine upstream ask, not something to hand-roll per app. Every consumer of
  `AfterUpdate` needs the same transition detection, and MJ core is where it belongs.

## 10. What to do now

1. **Build `Common.LogActivity`** wrapping `ActivityWriter` (§3.1, §3.2). Everything else waits on it.
2. **Resolve §9** with the MJ team.
3. Author the §5 bindings as metadata under `metadata/entity-actions/` — a directory this repo does
   not have yet.
4. Build the flow agents they dispatch to.
5. Sales picks up §6 once 1–3 are in place.
6. Delete this file, or fold it into the repo's main plan.

---

## Recorded so it is not re-proposed

**Do not build a workflow subsystem here.** An earlier iteration of the Sales & Contracts design
proposed a `WorkflowEventType` / `WorkflowBinding` / `WorkflowRun` trio in this repo. It was withdrawn
once the `EntityAction` implementation was read properly: it would have been a parallel universe next
to a working core feature.
