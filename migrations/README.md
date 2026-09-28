# Migrations (SQL Server)

Skyway/Flyway-style migrations for the `__mj_BizAppsCommon` schema. Files follow
`VYYYYMMDDHHMM__v<ver>__<Description>.sql`. Apply locally with `pnpm run mj:migrate`. The
PostgreSQL twins live in [`../migrations-pg/`](../migrations-pg/); see
[`docs/postgresql.md`](../docs/postgresql.md).

**For metadata, this directory is the only thing that ships.** `mj-app.json` names a `metadata`
directory, but MJ's manifest schema is explicit that `metadata.directory` is a dev-time pointer the
install engine **never reads**. Seeding happens only through the files here. A record that exists
only because someone ran `mj sync push` on their laptop exists only on that laptop.

That is not hypothetical in this repo. 5.37.0 shipped the Activity Sync schema and engine with none
of the metadata that drives them (83 records across 8 files), because no `Metadata_Sync` carried
them. Every install step reported success and produced a feature that could not run. The fix was
`V202609020500__v5.38.x__Metadata_Sync.sql` (MemberJunction/bizapps-common#107).

The seed process below was ported from bizapps-forms.

## The loop, whenever you touch `metadata/`

```
your PR:      edit metadata/ (declarative JSON only)  →  commit  →  review
the release:  mj sync push against a clean DB  →  ONE consolidated Metadata_Sync  →  ship
```

**A feature PR carries no `Metadata_Sync` migration.** It carries the JSON: fields, `@lookup` /
`@file` / `@parent` references, a `primaryKey` UUID from `uuidgen`, and no `sync` block. The release
push writes the `sync` block back. The build engineer takes everything merged on `next` and generates
one consolidated seed for the release. This is MJ's model (`MJ/metadata/CLAUDE.md` §1b and §10). The
reason for it is drift: per-PR sync migrations duplicate the release step, produce many small files
instead of one per build, and diverge from what the real push emits.

`pnpm run check:release-seed` answers "what does the next seed still owe?" It walks every
`primaryKey` under `metadata/` and reports the ones that appear in no migration. It needs no database
and runs anywhere.

`pnpm run check:seed-cadence` asks whether the seed is the right one, in three parts:

- **At most one unreleased `Metadata_Sync`**: the release's own. Two or more means the per-PR loop
  came back.
- **Not zero when `metadata/` moved**: if any record file differs from the last release tag and no
  new seed exists, a seed is owed.
- **Not empty, and not older than `metadata/`**: the seed must hold SQL, and no record file may have
  changed after the seed's last commit. This is what catches a seed generated before a later metadata
  PR merged. It matters most for the records keyed by `@lookup:` instead of a UUID (73 of the 251
  here), which coverage has no id to check.

These see an **edited** record only by order: that a record moved after the last release and after
the seed. None of them reads the seed's SQL to confirm it carries the edit, so a seed committed after
an edit but generated without it still passes (`check-release-seed-cadence.spec.mjs` pins that
limitation). Step 5 below, replaying the chain on a clean database, is what proves content.

Both run in `release-prep.mjs` (so `pnpm run release:plan` shows them and **Prepare a release**
refuses on red) and again in `publish.yml` before anything is published or tagged. Neither runs on
feature PRs, because no feature PR can answer a question about a seed generated after it merges.
The release runbook is [`docs/release.md`](../docs/release.md).

**Add a NEW seed migration; never edit a shipped one.** Migrations are append-only history. A seed in
a release tag has been applied on hosts, and rewriting it changes what a database that already ran it
believes it ran. A seed that is in **no** release tag has reached no host, so it is still editable,
and the release folds it into the consolidated seed instead.

### Which `Metadata_Sync` files have shipped

Check it; don't recall it:

```bash
git tag --list 'v*' | while read t; do
  git ls-tree --name-only "$t" migrations/ | grep -i metadata_sync | sed "s/^/$t /"
done
```

As of `v5.46.3` (2026-09-28), that loop shows every seed here is shipped history:

| file | in a release tag? | what that means |
|---|---|---|
| `V202605141122__v5.29.x__Metadata_Sync.sql` | **yes**, `v5.29.0` through `v5.46.3` | append-only history. **Never rewrite or delete it.** |
| `V202608140800__v5.34.x__Metadata_Sync.sql` | **yes**, `v5.34.0` through `v5.46.3` | append-only history. |
| `V202608262255__v5.36.x__Metadata_Sync.sql` | **yes**, `v5.36.0` through `v5.46.3` | append-only history. |
| `V202609020500__v5.38.x__Metadata_Sync.sql` | **yes**, `v5.38.0` through `v5.46.3` | append-only history. The last seed generated. |

There is no unreleased seed, and `metadata/` has moved since `v5.46.3`, so both gates are red today
and the next release owes one. `pnpm run release:plan` lists the uncovered ids and the edited files.

**The `__v<ver>__` in a filename is descriptive, never a claim about which release ships the file.**
Flyway orders on the `V<timestamp>` prefix, and nothing reads the label. The file ships in whatever
version `changeset version` computes from the changesets pending at release time. Never infer a
release version from a migration filename.

> **Not the same family.** Other migrations here also write `__mj` rows, such as
> `V202608140700__v5.34.x__Layered_Base_Views_EntityFields.sql`. That is **CodeGen** metadata: the
> `Entity` / `EntityField` rows behind a schema change, not a seed push. It still ships in the feature
> migration that needs it. The seed cadence covers only records declared under `metadata/`.

## Regenerating the metadata seed

**Release work, done once per release by the build engineer.** You push against a database built from
the shipped chain and ship what comes out as one new delta file. The push logs only what changed:
`spCreate*` for records added since the last release, and `spUpdate*` for records edited.

Start by asking what the seed owes: `pnpm run release:plan`, or the two checks directly. An empty
coverage list does not mean there is nothing to generate. A record whose id already ships but whose
*body* changed (a `@file:` template, a reworded description) passes coverage silently. That is what
`check:seed-cadence` catches.

Common is the base app, so the generation database is **MJ core plus this repo's migrations only**.
There are no sibling apps to install first.

```bash
# 1. Build the generation database from the SHIPPED CHAIN, not from dev work. Start from an EMPTY
#    database (owned by sa, as clean-room-gate.yml creates it) and point DB_DATABASE at it.
#    Restoring a backup of your dev database is the tempting shortcut and the wrong one: a dev
#    database holds records no seed ever shipped, so the push diffs against rows a fresh install
#    does not have and emits spUpdate* calls that quietly match nothing there. No CI check detects
#    that. check:release-seed asks whether an id is NAMED by the shipped SQL, not whether the
#    statement naming it can replay on a host. Only a clean install proves that.
#
#    Install MJ core at the floor of mj-app.json's mjVersionRange (clean-room-gate.yml resolves the
#    tag the same way), then this app's chain:
pnpm exec mj migrate --tag v<mjVersionRange floor>
#
#    ⚠️ HOLD BACK EVERY UNRELEASED Metadata_Sync before the next command. `pnpm run mj:migrate` runs
#    whatever is in migrations/, including seed deltas no release tag carries (check:seed-cadence
#    names them). The records such a delta created already match metadata/, so the push would emit
#    NOTHING for them, and step 4 deletes the delta, leaving those ids named by no migration at all.
#    Move the files out of migrations/ first.
pnpm run mj:migrate

# 2. Push. Expect a small log: the records added or edited since the last release, and nothing else.
npx mj sync push --dir metadata --ci

# 3. The log lands in metadata/sql_logging/ (gitignored). TWO substitutions are REQUIRED before it
#    can ship, exactly as in V202609020500:
#      [${flyway:defaultSchema}]  ->  [${mjSchema}]               on every core SP call
#      [__mj_BizAppsCommon]       ->  [${flyway:defaultSchema}]   on this app's own SP calls
#    The first is a CORRECTION, not a rename. sqlLogging.formatAsMigration emits core stored-procedure
#    calls as ${flyway:defaultSchema}, which is right only for an app whose Flyway default schema IS
#    the core schema. Here it resolves to __mj_BizAppsCommon, so shipping the log verbatim calls
#    __mj_BizAppsCommon.spCreateAction and friends, which do not exist. The generator gets this
#    app's own procs backwards the other way: it leaves them as the literal schema name.

# 4. Save it as migrations/V<stamp>__v<ver>__Metadata_Sync.sql, a NEW file whose stamp sorts after
#    every migration on next (changes.yml rejects one that does not). Give it a header saying what it
#    was generated against, the push counts, the substitution counts, and why it exists; the header of
#    V202609020500 is the model. Commit the `sync` blocks the push wrote back into metadata/ with it.
#    Then DELETE any unreleased deltas you held back in step 1 (`git rm` them). The new seed carries
#    their records forward, and no release tag names them, so no host has run them.

# 5. Prove it on a database that has never seen your dev work: a second empty database, MJ core,
#    then the whole chain INCLUDING the new file. Replaying against the database you generated from
#    proves nothing, because it already has the records. These are clean-room-gate.yml's own steps:
sqlcmd -S "$DB_HOST,$DB_PORT" -U "$DB_USERNAME" -P "$DB_PASSWORD" -C -b -Q \
  "CREATE DATABASE [<proof db>]; ALTER AUTHORIZATION ON DATABASE::[<proof db>] TO [sa];"
DB_DATABASE=<proof db> pnpm exec mj migrate --tag v<mjVersionRange floor>
DB_DATABASE=<proof db> pnpm exec mj migrate --schema __mj_BizAppsCommon --dir ./migrations
DB_DATABASE=<proof db> pnpm run lint:entityfield-drift
#    Every command must exit 0. Then look for what the seed was generated to carry: SELECT a record
#    it creates (by its ID, or by the @lookup: key) and a field it updates, in <proof db>. clean-room-
#    gate.yml runs this same install on every PR, but it checks EntityField drift, not seeded content,
#    so this look is the only place the seed's content is confirmed before it ships.
#    Then the static gates, which read the files rather than the database:
pnpm run check:release-seed && pnpm run check:seed-cadence
#    Drop <proof db> when you are done.

# 6. The PostgreSQL twin (docs/postgresql.md):
pnpm run mj:migrate:convert
node scripts/pg-finalize.mjs
```

Ship it as an ordinary PR into `next` with a `minor` changeset (`changes.yml` requires one for any
migration). Then dispatch **Prepare a release** ([`docs/release.md`](../docs/release.md)).

**"From an empty database", "from the shipped chain" and "at the last released metadata level" are
three requirements, not one.** Provenance is what makes the delta replayable; the released metadata
level is what makes the delta *complete*. A database carrying records someone created by hand
produces a delta that updates rows a fresh install never had. A database that ran an unreleased seed
produces a delta missing that seed's records. Installing everything *except* the unreleased seeds
brings the schema to head while the records stay at the level the last release left them. That is
exactly the baseline the new seed has to carry forward.

**A fourth hazard runs the other direction: a migration that is not a seed can write over a record
`metadata/` also declares.** `mj sync push` only ever compares the database against `metadata/`. It
cannot tell "this differs because it is stale" from "this differs because a later migration
deliberately changed it". Either way it emits a statement putting the database back to what
`metadata/` says, and the generated seed sorts after the migration that made the change, so the seed
wins. bizapps-forms nearly shipped exactly that: a generated seed that would have reverted the
permission change a migration made for MemberJunction/bizapps-forms#138, caught only in review. The rule: **`metadata/` is the authority for every record it declares, so a migration
that writes such a record must update `metadata/` in the same change, or the next seed silently
reverts it.** No check catches this. Coverage compares ids, cadence checks files and their order, and this costs
neither anything.

## Cadence: one seed per release

This follows MJ, and bizapps-forms before this repo (MemberJunction/bizapps-forms#105). Forms used to
regenerate per feature, held there by a CI check comparing `metadata/` to a hash manifest. That check
was retired because it inferred "the seed ships this record" from the presence of a manifest key.
That is a silent pass in one direction: regenerate the manifest without regenerating the seed, and it
goes green while the record reaches no host.

What replaced it checks the property rather than a proxy (`check:release-seed`), plus the cadence
itself (`check:seed-cadence`), both run at the release rather than on every PR. MJ, bizapps-common and
bizapps-caliber all used to document their release seed step with no automated detection at all, and
common's 5.37.0 is what that costs. Here the release step is checked automatically, before the
release PR is even opened and again before anything is published or tagged.
