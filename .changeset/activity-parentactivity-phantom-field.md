---
'@mj-biz-apps/common-entities': minor
---

Activity: remove the phantom `ParentActivity` EntityField that made every Activity create fail.

`Activity` metadata carried a virtual field `ParentActivity` at sequence 24 that `vwActivities` does
not emit. MJ's save-capture is POSITIONAL — it declares one slot per EntityField and reads them back
by position from the base view — so metadata declared 34 slots against a 33-column view and every
create failed with `Column name or number of supplied values does not match table definition`.

**What that looked like in practice.** Activity Sync fetched, qualified, resolved identities and
threading correctly, then wrote nothing: `Failed: 5, Success: false`. The watermark is held on
failure, so it retried the same messages on every pass and never made progress. Nothing about the
message named the real cause.

This is the same defect `V202608261015` fixed for Activity Links and Activity Files, in the opposite
direction — that one added a virtual field the view HAD and metadata lacked (N slots against N+1
columns); this removes one metadata HAS and the view lacks.

**Why remove the field rather than add the column.** `ParentActivityID` is a self-referencing FK, and
for it CodeGen emits the hierarchy columns (`RootParentActivityID`, `ParentActivityIDDepth`/`Path`/
`IsLeaf`/`ChildCount`) rather than a plain related-name join. A migration that added the column would
be undone on the next CodeGen run. Verified: after a full `mj codegen` on a healed database, metadata
and view stay aligned at 33/33 and the field does not come back — which is also why this leaves
`IncludeRelatedEntityNameFieldInBaseView` alone rather than flipping a flag whose CodeGen behaviour
differs between this entity and `ActivityType` for reasons not established here.

**Guarded on the actual state, not on an ID.** The field is created by a CodeGen proc that mints a
fresh GUID per host, so an ID-only guard would match nothing on most databases — the trap that stalled
the migration chain in bizapps-orders#126. It matches on `(EntityID, Name)`, and acts only where
`vwActivities` genuinely lacks the column, so a database whose view does expose it is left untouched.
The migration ends by re-checking that no Activity field lacks a view column and throwing if one does,
because failing in the migration is far cheaper than failing on the next create.

All three paths exercised against a real database: the defect reproduced (`Failed: 5`, nothing
written), the migration applied (`Included: 5`, five Activities and seventeen links written), a second
and third application were clean no-ops, and with the column artificially present the migration
correctly declined to remove the field.
