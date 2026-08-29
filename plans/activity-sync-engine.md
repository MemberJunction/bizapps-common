# Activity Sync Engine — Design & Build Plan

**Status:** design agreed, build not started
**Owner:** BizApps Common
**Created:** 2026-08-29

---

## 1. What this is

A purpose-built ingestion engine in **bizapps-common** that fills the Activity spine
(`Activity` / `ActivityLink` / `ActivityFile`) from external sources — mailboxes, calendars, SMS,
WhatsApp, social feeds — through a **provider plugin model**, and lets downstream apps contribute
extra links **in-process and inside the same transaction** without Common knowing they exist.

Three things it must be true of, in priority order:

1. **A message that should not be captured is never persisted.** Qualification runs before the
   write, not after it.
2. **A new source is a new package, not a migration to Common.** Provider identity is data.
3. **A downstream app can enrich an Activity atomically** without Common naming it.

---

## 2. Why not the MJ Integration Engine

The Integration Engine is the right tool for syncing external *business objects* into MJ entities,
and its plugin distribution model (connector = Open App + `@memberjunction/connector-<name>`,
resolved by `DriverClass` through `MJGlobal.ClassFactory`) is the model this design imitates.

It is the wrong tool for this job, for reasons of **shape**, not quality:

| Integration Engine assumes | Activity ingestion has |
|---|---|
| A discoverable external schema | A mailbox — nothing to introspect |
| A primary key to classify (`SoftPKClassifier`) | A provider message id, known up front |
| DDL to generate for the target | A fixed target schema that already ships |
| One external object → **one** MJ entity row | One message → **a small graph**: `Activity` + N `ActivityLink` |
| Records land in MJ, then are processed | A **pre-write** privacy gate |

The last two are disqualifying rather than inconvenient.

**The graph write.** `CK_ActivityLink_Target` is an exclusive-or: a link carries either
`EntityID` + `RecordID` or `IdentityKind` + `IdentityValue`, never both. Choosing the target
conditionally, per participant, is not something a field map with a transform pipeline expresses.

**The privacy gate.** In the Integration Engine, rows are fetched and written, and only then can
anything else act on them. The only exclusions it supports are **field-level**
(`ResolveExcludedSourceNames`, from a connector's `SyncDirective`); there is no row-level "do not
sync this record" rule anywhere in it. For a mailbox that inverts the requirement — the body would
be persisted before the rule that says it should not have been.

We adopt its **plugin distribution pattern** and reject its **write model**.

### Why not `MJ: Record Processes` for the gate either

`RecordSetProcessor` is the natural home for "run rules and an LLM over a set of records," and its
four work types (`FieldRules` / `Action` / `Agent` / `Infer`) are exactly the escalation vocabulary
this design needs. But `RecordRef` is `{ EntityID, RecordID, Record? }` — **it can only iterate
records that already exist.** Ingestion's entire job is deciding what becomes a record.

Record Processes remains the right tool for a different, real job we should keep in view:
**re-processing Activities that already exist** — re-running classification after a rule change,
backfilling a new derived field across the last quarter. Not the gate.

---

## 3. Pipeline

```
                    ┌────────────────────── no transaction open ───────────────────┐
 ActivitySyncJob ──▶│  Fetch          provider.Fetch(query)  →  NormalizedItem[]         │
   (Scheduled Job)  │  Normalize      provider maps its payload into the common shape    │
                    │  Qualify        rules cascade; LLM only for the ambiguous band     │
                    └──────────────────────────────────────────────────────┘
                                                │  survivors only
                    ┌───────────────── BEGIN TRANSACTION (per item) ─────────────────┐
                    │  Resolve        participant address → Person / Organization        │
                    │  Write          Activity + ActivityLink (resolved XOR unresolved)  │
                    │  Extensions     registered extensions run IN-STREAM                │
                    └─────────────────────── COMMIT ─────────────────────────┘
                                                │
                                          advance watermark
```

**Two ordering rules, both load-bearing:**

- **No model call inside a transaction.** Qualification — including any LLM stage — completes
  before `BEGIN`. This is fine at ten messages and catastrophic at ten thousand.
- **No model call before the deterministic filter.** A message whose participants match no known
  contact is discarded having been read only by a string comparison. Inference is only ever
  reached by items that already passed a cheap, local test. This is inherited from the sales
  implementation and is the single most important rule in the design.

---

## 4. Schema changes

### 4.1 `ActivitySyncProviderType` — provider identity becomes data

Today `CK_ActivitySyncConnection_Provider CHECK (Provider IN ('Microsoft365','Gmail','Zoom','Generic'))`
makes every new provider a **migration to Common** — the exact consumer coupling this app exists to
avoid, and vocabulary-as-code rather than vocabulary-as-data.

Replaced by a lookup table on the same pattern as every other type table in the family:

| Column | Notes |
|---|---|
| `ID` | |
| `Code` | stable key, e.g. `Microsoft365`, `Gmail`, `Twilio.SMS`, `LinkedIn` |
| `Name`, `Description`, `IconClass` | display |
| `DriverClass` | the `@RegisterClass(BaseActivitySyncProvider, '<DriverClass>')` key |
| `SupportedKinds` | JSON, e.g. `["Message","Calendar"]` |
| `DefaultQualificationPolicy` | `Exclude` \| `Include` — what an `Undecided` verdict means for this provider |
| `IsActive`, `IsSystem` | |

`ActivitySyncConnection.Provider` (NVARCHAR) becomes `ActivitySyncProviderTypeID` (FK). The four
existing codes seed as metadata rows, not as `INSERT`s in the migration.

**Migration note:** this is a breaking column change on a published entity. Per the
Publish-Then-No-Breaking-Changes policy, it lands as *additive* — add `ActivitySyncProviderTypeID`
nullable, backfill from `Provider`, keep `Provider` in place and deprecated, drop the CHECK. A
later major removes the old column.

### 4.2 `ActivitySyncExtension` — the extension registry

Common ships the **table**; each consumer app ships its own **rows**.

| Column | Notes |
|---|---|
| `ID` | |
| `Name`, `Description` | |
| `DriverClass` | `@RegisterClass(BaseActivitySyncExtension, 'Sales.DealLinker')` |
| `ActivitySyncConnectionID` | nullable — null means "all connections" |
| `ActivitySyncProviderTypeID` | nullable — scope to one provider type |
| `Sequence` | **required.** Deterministic order; two extensions adding links must not race |
| `FailurePolicy` | `Skip` (default) \| `Abort` |
| `TimeoutMS` | cap; an extension holds the write transaction open |
| `IsEnabled`, `LastError`, `LastRunAt` | operator surface |

Registration is deliberately **two-part**, matching `DriverClass` everywhere else in MJ:
`@RegisterClass` carries the code, the metadata row *enables and configures* it per host. Metadata
alone cannot carry code; code alone cannot be configured per deployment.

---

## 5. `BaseActivitySyncProvider`

A **base class**, not an interface, so shared behaviour lives once and subclasses fill in only what
is genuinely provider-specific.

**The base class owns** (subclasses do not reimplement, and mostly cannot break):

- The fetch loop, the `Limit` cap, and batch assembly.
- **The watermark.** Subclasses report `HighWatermark` on the batch; the base decides whether to
  advance it. Two rules the sales implementation learned and that belong here as *behaviour*, not
  as advice:
  - A **calendar** source must never advance on `max(StartedAt)` — a meeting's start is routinely
    in the future, so one December event pins the watermark to December and the calendar silently
    stops ingesting, permanently and with no error. Calendar sources advance on ingest time.
  - **Never advance past a failure.** A *discarded* item has been seen to a conclusion and the
    watermark may pass it; a *failed* one has not, and because most sources have no date filter,
    anything the watermark passes can never be re-fetched. Losing it is permanent.
- Credential resolution via the MJ Credentials engine (`CredentialsRef`) — secrets never in the row.
- `LastSyncAt` / `LastError` / `Status` maintenance on the connection.
- Issue collection: a partial batch is reported, never thrown away.

**Subclasses implement** (abstract):

```
abstract Kind: 'Message' | 'Calendar' | 'Social' | 'Chat'
abstract ProviderTypeCode: string          // matches ActivitySyncProviderType.Code
abstract FetchRaw(query): Promise<RawBatch>
abstract Normalize(raw): NormalizedItem[]
abstract ComputeHighWatermark(items): Date | null
```

**Hooks subclasses may override** (all no-op by default):

```
OnBeforeFetch / OnAfterFetch
OnBeforeNormalize / OnAfterNormalize
OnBeforeQualify / OnAfterQualify
OnBeforeWrite / OnAfterWrite
OnError
```

Providers wrap existing MJ plumbing rather than reimplementing transport: MJ Communication
providers for Gmail and MSGraph (`GetMessages`, `GetSingleMessage`, `SearchMessages`, and
`CreateSubscription` / `ParseNotification` where push is available), Twilio for SMS and WhatsApp,
and MJ Actions for social feeds. The provider's job is to speak that transport in this engine's
vocabulary.

---

## 6. Qualification cascade

Ordered stages, each returning **decide or defer**:

```
type QualificationVerdict = {
    Decision: 'Include' | 'Exclude' | 'Undecided';
    Reason: string;          // always populated, including on Include
    StageName: string;
    Confidence?: number;
}
```

Stage order, cheapest and most certain first:

1. **Sync rules** — `ActivitySyncRule` as it already exists: ordered `Include`/`Exclude`,
   direction, date window, folders, domains, subject matching.
2. **Known-participant test** — an exact `ContactMethod` address match. Never a domain match: a
   domain rule captures every internal message and a customer's entire company, and it *reads as
   working* while putting private correspondence on a deal timeline.
3. **Inference** — an MJ AI Prompt, reached only by items the earlier stages left `Undecided`, and
   only when the connection enables it. Records the `AIPromptRunID` for trace.

**The abstention rule:** a stage that is not confident returns `Undecided` rather than guessing.
If the chain ends `Undecided`, the provider type's `DefaultQualificationPolicy` decides — and for
anything mailbox-shaped that default is **Exclude**. Fail closed.

> **On reusing `pk-classifier`:** we copy the *pattern*, not the code. Its cascade — convention →
> naming heuristic → statistical sampling → one-shot LLM, *returning no candidate when nothing is
> confident enough* — is the right shape and the right honesty. Its stages are about identifying a
> primary key from schema metadata; none of them transfer. The transferable asset is the contract
> above plus the discipline of explicit abstention.

---

## 7. Extensions

```
abstract class BaseActivitySyncExtension {
    abstract Enrich(context: ActivityWriteContext): Promise<void>;
}
```

`ActivityWriteContext` carries the saved `Activity`, its links so far, the `NormalizedItem`, the
resolved parties, the connection, and the ambient transaction.

**Four rules, decided rather than discovered:**

1. **Ordering is explicit.** `Sequence`, ascending. No implicit registration order.
2. **Failure defaults to `Skip`,** with the error recorded on the run and the extension's
   `LastError`. `Abort` is available and is opt-in. The activity is worth more than the
   enrichment, and one buggy consumer app must not be able to halt ingestion for every app on the
   host.
3. **Timeouts are enforced,** because an extension holds the write transaction open.
4. **Extensions enrich; they never veto.** Qualification is the engine's job and has already run.
   If an extension could reject an activity, whether a message is captured would depend on which
   apps happen to be installed — precisely the coupling this design exists to prevent.

Consumer blindness holds: the interface and the table live in Common and reference only Common
types; `Sales.DealLinker` is a class in the sales package and a row in sales' metadata. A host
without sales installed has no row and no binding.

---

## 8. What migrates from bizapps-sales

Sales built roughly 80% of this against these exact entities. This is a promotion, not a rewrite.

| Sales today (`packages/CoreEntitiesServer/src/activities/`) | Destination |
|---|---|
| `ActivitySource.ts` (the port) | → `BaseActivitySyncProvider` (Common) |
| `MSGraphActivitySource`, `MSGraphCalendarSource`, `GraphMessageMapper` | → Common provider plugin |
| `ImportedGraphActivitySource`, `FixtureActivitySource` | → Common (fixture provider is how this is tested) |
| `RelevanceFilter` | → qualification stage 2 (Common) |
| `ActivityWriterService` | → Common writer |
| `ActivityIngestService`, `ActivitySyncJob` | → `ActivitySyncEngine` (Common) |
| `ActivityReader` | → Common (or stays; it is a read model) |
| **`DealMatcher`** | → **stays in sales**, re-expressed as `Sales.DealLinker` extension |
| `Sales.SyncActivities` action + hourly ScheduledJob | → Common ships the action; sales' row retires |

Sales' integration checks AC1–AC13 are the acceptance suite. They were written against this
behaviour and should move with it, minus the deal-specific ones which stay in sales to cover the
extension.

**Sequencing:** Common ships first and sales' removal PR follows. They cannot land together —
sales cannot delete code whose replacement is not yet published.

---

## 9. Engine

`ActivitySyncEngine extends BaseEngine<ActivitySyncEngine>` — metadata load and cache of provider
types, connections, rules and extension registrations, with `@RegisterForStartup`, `EnsureLoaded`,
and cross-server cache invalidation inherited rather than written.

Scheduling stays MJ's: a `MJ: Scheduled Jobs` row invoking an Action, exactly as sales does today
(`ConcurrencyMode: Skip` — two runs racing to advance one watermark can leave it *behind* where
the earlier run reached; `MissedRunPolicy: RunOnce` — with no date filter on most fetches, ten
catch-up runs make ten identical requests).

### On borrowing the watermark helper from Integration

Considered and **rejected**. The valuable part is not code — it is ~30 lines plus the two rules in
§5, which belong in the base class as enforced behaviour rather than as a utility a provider
might forget to call. Taking `@memberjunction/integration-engine` as a dependency to get it would
re-introduce the coupling this whole design rejects, and Integration's watermark is a *table*
keyed to `CompanyIntegrationEntityMap` — the storage does not transfer; we already have
`ActivitySyncConnection.LastSyncAt`.

If a genuinely shared abstraction emerges later, extract a small `@memberjunction/sync-watermark`
that Integration also adopts. Do not do that speculatively.

---

## 10. Known risk this design does not solve

`MSGraphProvider` authenticates with `ClientSecretCredential` — **app-only auth**. An app-only
`Mail.Read` grant is tenant-wide: it reads every mailbox in the tenant, not one. Scoping it needs
an Exchange **Application Access Policy** binding the app registration to a security group, which
is a tenant-admin action that has not been performed.

Nothing in this plan changes that. The Graph provider ships refusing to fetch unless explicitly
allowed, and the fixture provider is how the engine is exercised until the policy exists.

---

## 11. Phases

| Phase | Work | Blocked on |
|---|---|---|
| **P0** | This document | — |
| **P1** | Migration: `ActivitySyncProviderType`, `ActivitySyncExtension`, additive FK, drop CHECK | a database for CodeGen |
| **P2** | CodeGen + generated entities; metadata seeds for the four provider types | P1 |
| **P3** | `BaseActivitySyncProvider`, qualification cascade, `BaseActivitySyncExtension` contracts | — (pure types; no new entities) |
| **P4** | `ActivitySyncEngine`, writer, resolver | P2 |
| **P5** | Graph + fixture providers ported from sales | P4 |
| **P6** | Sales: `Sales.DealLinker` extension; delete migrated code; retire its ScheduledJob row | Common published |

---

## 12. Open questions

1. **Body storage.** `ActivityFile` joins to MJ Files. Full bodies, headers-and-snippet, or a
   per-connection setting? Cost, privacy and discovery all pull differently.
2. **`Activity.Visibility` default** is `Internal`. For a synced personal mailbox that is almost
   certainly wrong — should a synced activity default `Private` and be promoted deliberately?
3. **Composes with #46 / #47.** Those record that People grants UI read on names, emails and DOB,
   and that on BCSaaS hosts UI is every authenticated user. Ingestion turns directory exposure
   into *correspondence* exposure. This must be settled before the first real mailbox lands in a
   host database.
4. **Dedupe key across mailboxes.** A Graph message id is not stable across mailboxes, so the same
   thread ingested from two connections yields two rows. Is that correct (two people's records) or
   a defect?
