# Adopting MJ's Entity Action workflow extensions

> **Status:** ✅ **Built — Common's side shipped** (2026-08-30). `Common.LogActivity` wraps the one
> `ActivityWriter`; the §5 bindings, their filters and the lifecycle flow agent are authored under
> `metadata/`. What remains is downstream: sales picks up §6, and the optional upstream ask in §9.
> **Upstream:** MemberJunction/MJ **[#3408](https://github.com/MemberJunction/MJ/pull/3408)** — merged.
> **Verified in the MJ tree** (2026-08-30): `EntityAction.ScopeEntityID` / `ScopeRecordID` /
> `Sequence` / `RunMode` and `EntityActionParam.ValueType = 'Entity Object Data'` are in the
> generated ORM; `packages/Actions/Base/src/EntityActionScopeResolver.ts` (with tests) and
> `DurableEntityActionSubmitter.ts` exist; after-hooks dispatch from
> `GenericDatabaseProvider.HandleEntityActions` with `OnAfterSaveExecute` deliberately un-awaited.

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

Two mechanics worth knowing, verified in the engine: `RunMode` only affects `After*` (it is
silently ignored on `Validate`/`Before*`, which cannot be deferred without changing whether the
save succeeds), and a FAILED durable submission **falls back to running inline** with the reason
logged — durability replaces execution, never the gates (scope and filters still evaluate first).

### 2.2 Parameter logging has a hard rule and a flag

Params of `ValueType` `'Entity Object'` or `'Entity Object Data'` are **never** written to
`ActionExecutionLog.Params`, regardless of any setting. Separately, a per-param flag suppresses
logging for values that carry records, credentials or personal data — the `Data` payload of
`Execute Agent` being the named example. When logging is suppressed the log keeps the parameter's
name, its type and a redaction marker, never the value.

The flag is **`LogValue`**: `ActionParam.LogValue` (bit, default 1) at the definition, with an
optional per-binding override `EntityActionParam.LogValue` (NULL inherits; 0 suppresses; it cannot
re-enable what the hard rule suppresses). `Common.LogActivity` sets `LogValue = 0` on
`Description`, `Details`, `RecordData`, `LinkFields` and `Links` — Common's bindings carry identity
data by definition. The same redaction governs the durable path's `Task.InputPayload`.

### 2.3 The two reusable `ActionFilter`s were never seeded — the *vocabulary* shipped instead

The plan called for two seeded filters — **"field changed"** and **"field changed *to* value"** — so
transition detection stops being hand-rolled.

**Resolved 2026-08-30, definitively: no seed rows exist upstream.** A full search of MJ's
`migrations/**` and `metadata/**` finds every `INSERT INTO [ActionFilter]` inside CodeGen's
`spCreateActionFilter` proc bodies, none as data; no `metadata/action-filters/` directory exists;
the seeding step in MJ's own plan (`plans/entity-action-workflow-extensions.md`) was never executed.

What DID ship is better than the seeds alone: a documented **runtime vocabulary** inside
`ActionFilter.Code` (`packages/Actions/Engine/README.md`, implemented in
`EntityChangeContext.ts`) — `ActionFilterContext.DidFieldChange(field)`,
`DidFieldChangeToValue(field, value)` (loose compare), plus `OldValues` / `NewValues`. So a
transition filter is one honest line, not hand-rolled diffing. Three behaviours to design around:
**a create reports no changes** (`DidFieldChange` is false on insert — never attach a transition
filter to an `AfterCreate`-only binding); **evaluation is fail-closed** (a filter that throws or is
unresolvable prevents the run, and the prevented run still logs); and the change context is built
before the first `await`, so it genuinely sees the transition.

Common now ships the two reusable rows itself, in `metadata/action-filters/`:
*"Common: Status field changed in this save"* and *"Common: Status field changed to Ended in this
save"*. See §9 for the remaining (optional) upstream ask.

---

## 3. What this means for Common

Common is the substrate every other app builds on, so its interest is twofold.

**As a consumer:** identity lifecycle events are genuine hook points — a person created, an
organization merged, a relationship started or ended.

**As a provider:** the Activity spine — **shipped** (`Activity`, `ActivityLink`, `ActivityFile`,
plus the Activity Sync Engine, bizapps-common#93/#94) — pairs unusually well with `EntityAction`.
`Common.LogActivity` is an Action, so **any app can write to the unified timeline declaratively**:
bind `AfterCreate`/`AfterUpdate` on any entity to `LogActivity` and that record's lifecycle appears
on the person's or organization's timeline with no code in the consuming app.

Timeline population becomes a **configuration exercise** instead of an integration in every app.

### 3.1 ✅ The keystone exists now

**`Common.LogActivity` shipped**: the action class is
`packages/Server/src/custom/log-activity.action.ts` (a thin shell), its parsing is
`packages/ActivitySync/src/manual-log.ts` (pure, tested), and its Action record with params and
result codes is `metadata/actions/.common-actions.json`. Timeline entries of this kind carry the
new `SystemEvent` activity type (`metadata/activity-types/`).

Beyond the plan's minimum it gained two conveniences that make bindings self-sufficient:
- **`EventKey`** — per-record idempotency for one-per-record events: `ExternalID` becomes
  `EntityName|RecordID|EventKey` (SourceSystem defaults to `EntityAction`), so a durable retry
  cannot double-log an `AfterCreate` seed entry. Deliberately NOT used on status-change bindings,
  where every transition belongs on the timeline.
- **`LinkFields`** — declarative link routing: `[{ Field, EntityName, Role }]` reads FKs from
  `RecordData` and links the records they point at, which is how a Relationship's activity lands on
  the person's and organization's timelines rather than only on the relationship row.

### 3.2 `LogActivity` **wraps** `ActivityWriter` — one writer, two entry points ✅

#93 changed this design question. The Activity Sync engine writes activities through
`ActivityWriter`, which owns:

- dedupe on `(SourceSystem, ExternalID)`
- `Visibility = 'Private'` on synced rows (the column default stays `Internal`, which is right for a
  manually logged activity and wrong for a synced one)
- the unresolved-`ActivityLink` rule — an unmatched address gets a link with
  `IdentityKind`/`IdentityValue`, and **never invents a `Person`**
- extension dispatch **inside** the write transaction

As built: `ActivityWriter.WriteManual` is a second public entry point over the **same transactional
core** (`writeWithLinks`), same dedupe, same link writer. The manual path defaults
`Visibility = 'Internal'`, stamps no connection, refuses `Source = 'Integration'` (that word belongs
to the sync engine), and does **not** dispatch sync extensions — those fire on ingest, not on a
record being logged (§8). The declarative path and the ingest path cannot drift, because there is
nothing to drift: one writer.

### 3.3 The parameter trap, stated in `LogActivity`'s own docs ✅

`LogActivity` takes **`'Entity Object Data'`**, never `'Entity Object'`. If the Action serializes
its input at any point — and it will, once routed through a queue or an agent — a `BaseEntity`
yields `{}`, because its fields are getters rather than enumerable own properties. Silently, with no
error. The rule is stated on the `RecordData` param's description, in the parser's module header,
and repeated as a comment on every `Entity Object Data` binding in `metadata/entity-actions/`.

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

Mechanics verified in `EntityActionScopeResolver`: both scope columns are all-or-nothing (a CHECK
plus entity validation enforce it), the default resolver walks the subject's single FK to the scope
entity (`Organization.OrganizationTypeID`, `Relationship.RelationshipTypeID` — both unambiguous),
and everything **fails closed** — zero or multiple candidate FKs, an unknown scope entity, or a
missing subject record all mean "does not apply."

## 5. Shipped bindings — Common ✅

Authored in `metadata/entity-actions/.common-entity-actions.json`, with deliberate `Sequence`
values (§7) and `Status: Active` set explicitly at every level — Entity Action, invocation and
filter all default to `Pending`, and a `Pending` anything silently never fires.

| Entity + invocation | Scope | Work | `RunMode` | Purpose |
|---|---|---|---|---|
| `People` · `AfterCreate` | — (global) | Action → `Common.LogActivity` (`EventKey=AfterCreate`) | Durable | Seed the timeline at the moment identity is created |
| `People` · `AfterUpdate` + *Status changed* filter | — | `Execute Agent` → **Person Lifecycle Changed** flow agent | Durable | Downstream reaction to identity state changes |
| `Organizations` · `AfterUpdate` + *Status changed* filter | `OrganizationType` **Corporation** | Action → `Common.LogActivity` (Description ← new Status) | Durable | Account-status changes land on the organization's timeline |
| `Relationships` · `AfterCreate` | `RelationshipType` **Employee** | Action → `Common.LogActivity` (+`LinkFields` routing) | Durable | Employment started — on the person's AND organization's timelines |
| `Relationships` · `AfterUpdate` + *Status → Ended* filter | `RelationshipType` **Employee** | Action → `Common.LogActivity` (+`LinkFields` routing) | Durable | Employment ended — the transition, exactly once |
| **any entity in any app** · `AfterCreate` | that app's type record | Action → `Common.LogActivity` | Durable | The generic pattern — timeline population as configuration |

Notes on the as-built shape:
- The last row is the **pattern**, not a record here — it is what consuming apps author in their own
  `metadata/entity-actions/`, exactly as the five above are authored.
- `Relationships` is TWO records, not one with two invocations, because the *ended* filter must
  never see the `AfterCreate` firing — a create reports no changes, and the fail-closed filter
  would prevent the seed entry (§2.3).
- The scoped rows demonstrate §4 against real seeded type records (`Corporation`,
  `Employee`). Hosts re-scope or add rows per type — that is the point.
- "Notify the owners" from the original sketch is deliberately NOT hard-wired here: Common has no
  owner concept on `Organization` (consumer blindness — Common must not name its consumers). The
  extension point for notification is the flow agent seam: point a binding's `AgentName` at your
  own agent, or add steps to `Person Lifecycle Changed`.

Every row is `Durable` deliberately: each one writes a durable record, and losing it silently is
not acceptable (§2.1).

## 6. Proposed bindings — Sales

Three candidates that fit sales' existing rules rather than working around them. **Still sales'
work, gated on this PR (see §10) — nothing below ships from Common.**

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

With §2.3 resolved, this is now configuration: author the deal-shaped filter rows with
`ActionFilterContext.DidFieldChangeToValue(...)`, the same one-liner shape as Common's two, in
sales' own metadata.

### 6.3 The close lock stays in code — and here is the trap

`DealEntityServer.Save()` enforcing `DealStatusType.LocksDeal` is **correct as code** and should stay
there: it is a synchronous, blocking invariant that must hold for an Action, an agent and a raw
`BaseEntity.Save()` alike.

If anyone later moves it to an `EntityAction`, it must be bound to **`Validate`** — the real gate.
Binding it to `Before*` **silently removes the lock**, because `Before*` is awaited and its result
discarded. Recorded here because the two read as interchangeable and are not.

---

## 7. Rules carried into the design — and where each landed

- **`RunMode` is a decision, not a default.** Every shipped binding says `Durable` explicitly, with
  the reason in its `Comments` (§2.1).
- **Synchronous bindings are Actions, never agents.** `Validate` and `Before*` run inside the
  caller's transaction; a loop agent's duration is unbounded and holding a transaction open for it is
  not acceptable. Agents belong on `After*`. The one agent binding shipped is `AfterUpdate`.
- **A flow agent creates human work and finishes** — it does not hold a run open waiting for a
  person. `MJ: AI Agent Requests` when the answer resumes the same run (minutes to hours); a
  **bizapps-tasks** Task when it is durable, assignable work someone owns (days to weeks).
  `Person Lifecycle Changed` records the transition and completes; hosts add steps for their own
  reactions.
- **Set `Sequence` deliberately.** Once several apps bind to `People.AfterCreate`, order is
  observable. Common's rows use 10/20 per entity; consuming apps should slot theirs consciously
  rather than inheriting insertion order.
- **`'Entity Object Data'` for anything that serializes** (§3.3) — every `RecordData`/`Data`
  binding, commented at the binding site.

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

The same boundary is why `ActivityWriter.WriteManual` does not dispatch extensions: a declaratively
logged activity is not an ingested item.

---

## 9. Upstream question — answered, with one optional ask left

**Do the two reusable `ActionFilter`s exist upstream? No** (§2.3 — verified against the MJ tree
2026-08-30, migrations and metadata both). What exists upstream, and is the genuinely reusable
piece, is the `ActionFilterContext` vocabulary — so per-app filter rows are one-line predicates,
not hand-rolled transition detection. Common ships its two in `metadata/action-filters/` and §6.2
proceeds the same way in sales.

The **optional** remaining ask for the MJ team: seed generic filter rows in core so apps stop
minting near-identical "Status changed" rows. Low urgency — `ActionFilter` has no parameters, so a
generic row can only hard-code a field name anyway; the per-app rows are honest about that.

## 10. What was done (and what remains)

1. ✅ **`Common.LogActivity`** wrapping `ActivityWriter` (§3.1, §3.2) — action + parser + writer
   entry point + Action metadata, with tests.
2. ✅ **§9 resolved** — no upstream seeds; the vocabulary shipped; Common authors its own rows
   (§2.3). Optional core-seeding ask recorded above.
3. ✅ **§5 bindings** authored under `metadata/entity-actions/`, with `metadata/action-filters/`
   and the `SystemEvent` activity type.
4. ✅ **The flow agent** they dispatch to — `Person Lifecycle Changed`, `metadata/agents/`.
5. ⏳ **Sales picks up §6** now that 1–3 are in place (bizapps-sales work, tracked there).
6. ✅ This file updated to the as-built record rather than deleted — §6 and the §7/§8 rules govern
   work that has not landed yet, and the trap documentation (§2, §3.3, §6.3) is the part most worth
   keeping findable.

Remember the release-path rule: `metadata/` is the dev-time source of truth and reaches a host only
inside a regenerated `*Metadata_Sync.sql` migration at release — a merged `metadata/` change is not
"done" for customers until a release carries it.

---

## Recorded so it is not re-proposed

**Do not build a workflow subsystem here.** An earlier iteration of the Sales & Contracts design
proposed a `WorkflowEventType` / `WorkflowBinding` / `WorkflowRun` trio in this repo. It was withdrawn
once the `EntityAction` implementation was read properly: it would have been a parallel universe next
to a working core feature.
