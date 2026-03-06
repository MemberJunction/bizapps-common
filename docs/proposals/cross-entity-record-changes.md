# Proposal: Cross-Entity Record Changes in MemberJunction

## Summary

When a user views a Person record and changes their primary address via an inline widget, the change is saved to the `AddressLink` entity — not to `Person`. MemberJunction's `RecordChange` audit system faithfully logs this against `AddressLink`, but from the user's perspective, they just changed "this person's address." The change doesn't appear in the Person's record change history.

This proposal introduces **Related Entity Change Tracking** — metadata-driven configuration that lets the Record Changes UI aggregate changes from related entities into a unified timeline.

## The Problem

### User Experience Gap

Consider a Person form with inline CRUD widgets for addresses, contact methods, and relationships. A user:

1. Opens John Smith's Person record
2. Sets a new primary address via the Address widget
3. Adds a mobile phone via the Contact Methods widget
4. Opens the Record Changes dialog for John Smith
5. **Sees nothing** — because no fields on the Person entity itself changed

The changes exist in the system (logged against AddressLink and ContactMethod), but they're invisible from the Person's perspective. This breaks the user's mental model — they made changes "to this person" and expect to see them.

### Current Architecture

MemberJunction's `RecordChange` system works per-entity:

```
RecordChange
├── EntityID        → which entity type
├── RecordID        → which specific record
├── ChangedAt       → when
├── ChangesJSON     → field-level diffs
├── FullRecordJSON  → snapshot
└── Status
```

The `ng-record-changes` component calls `GetRecordChanges(entityName, primaryKey)` and shows a timeline for that single entity. There's no mechanism to include changes from related entities.

### Why This Matters Beyond UI

- **Compliance & Audit**: Regulated industries need a complete change trail for a "person" or "organization," including their addresses, contacts, and relationships
- **Data Quality**: Understanding the full history of changes helps identify data issues
- **User Trust**: When users make changes and can't find them in the history, they lose confidence in the system

## Proposed Solution

### 1. Entity Settings Metadata: `RecordChangesRelatedEntities`

Add a new JSON field to the Entity Settings metadata that declares which related entities' changes should be surfaced in the Record Changes UI:

```json
{
  "RecordChangesRelatedEntities": [
    {
      "RelatedEntityName": "MJ.BizApps.Common: Address Links",
      "JoinField": "RecordID",
      "JoinEntityFilter": "EntityID",
      "DisplayLabel": "Addresses",
      "Icon": "fa-map-marker-alt"
    },
    {
      "RelatedEntityName": "MJ.BizApps.Common: Contact Methods",
      "JoinField": "PersonID",
      "DisplayLabel": "Contact Methods",
      "Icon": "fa-address-book"
    },
    {
      "RelatedEntityName": "MJ.BizApps.Common: Relationships",
      "JoinField": "FromPersonID",
      "DisplayLabel": "Relationships",
      "Icon": "fa-handshake",
      "AdditionalJoinFields": ["ToPersonID"]
    }
  ]
}
```

#### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `RelatedEntityName` | string | The full entity name of the related entity |
| `JoinField` | string | The FK field on the related entity that references the parent record's ID |
| `JoinEntityFilter` | string? | For polymorphic links (like AddressLink), the field that holds the parent entity ID. When present, the query also filters on `EntityID = <parent entity's ID>` |
| `AdditionalJoinFields` | string[]? | Additional FK fields to check (OR logic). For bidirectional relationships where the parent could be on either side |
| `DisplayLabel` | string | Human-readable category label for the timeline |
| `Icon` | string? | Icon class for the timeline group |

### 2. Enhanced `GetRecordChanges` API

Extend the existing `GetRecordChanges` method (or add a companion `GetRecordChangesWithRelated`) that:

1. Fetches the entity's own RecordChanges (existing behavior)
2. Reads `RecordChangesRelatedEntities` from Entity Settings
3. For each related entity config, queries RecordChanges where:
   - `EntityID` matches the related entity
   - The changed record's `JoinField` value matches the parent record's ID
   - If `JoinEntityFilter` is specified, also filters on that field
4. Returns a merged, chronologically-sorted timeline

```typescript
interface RelatedRecordChange extends RecordChange {
    /** Which related entity category this change belongs to */
    RelatedEntityLabel: string;
    RelatedEntityIcon?: string;
    /** The related entity's name (e.g., "Address Links") */
    SourceEntityName: string;
}

// New method signature
static GetRecordChangesWithRelated(
    entityName: string,
    primaryKey: CompositeKey,
    includeRelated?: boolean,  // default true
    provider?: IEntityDataProvider | null
): Promise<(RecordChange | RelatedRecordChange)[]>;
```

### 3. Enhanced Record Changes UI

The `ng-record-changes` component would:

1. Check if the entity has `RecordChangesRelatedEntities` configured
2. If so, call the enhanced API to get the merged timeline
3. Display related changes with visual differentiation:
   - Group or tag by `DisplayLabel` (e.g., "Addresses", "Contact Methods")
   - Show the related entity icon
   - Use a slightly different styling (e.g., indented, different color accent) to distinguish from direct field changes
4. Add a filter toggle: "Show related changes" (on by default)

#### Timeline Example

```
─── Mar 6, 2026 ───────────────────────────────
  📍 Addresses    Primary address changed to "123 Main St, Austin, TX"
                  Set as primary (was: "456 Oak Ave, Dallas, TX")

  📞 Contacts     Added Mobile Phone: (512) 555-0199
                  Set as primary

─── Mar 5, 2026 ───────────────────────────────
  ✏️ Person       Status changed from "Inactive" to "Active"
                  Email changed to "john@example.com"

  🤝 Relationships  Added relationship: "Employee of Acme Corp"
```

### 4. Implementation Phases

**Phase 1: Metadata & API** (Core framework)
- Add `RecordChangesRelatedEntities` to Entity Settings schema
- Implement `GetRecordChangesWithRelated` in the data provider layer
- No UI changes yet — just the data capability

**Phase 2: UI Enhancement** (Angular)
- Update `ng-record-changes` to read the metadata and call the enhanced API
- Add timeline grouping and filtering
- Visual differentiation for related vs. direct changes

**Phase 3: Configuration Tooling** (Optional)
- Add Entity Settings UI for configuring related entities
- Auto-suggest based on FK relationships in the schema

## Design Considerations

### Performance

The main concern is query fan-out. For a Person with 3 related entity configs, we'd run 4 queries (1 own + 3 related). Mitigations:
- Run related queries in parallel
- Add a date range filter to limit scope
- Cache the Entity Settings metadata (already cached by MJ)
- Consider a denormalized `RelatedRecordChange` table if performance becomes an issue at scale

### Polymorphic Links

The `AddressLink` pattern (EntityID + RecordID) requires special handling. The `JoinEntityFilter` field handles this — when querying RecordChanges for AddressLink records related to a Person, we need to find AddressLink records where `RecordID = <personId> AND EntityID = <Person entity's ID>`.

This requires a two-step lookup:
1. Find AddressLink RecordIDs matching the parent
2. Query RecordChanges for those AddressLink RecordIDs

### Bidirectional Relationships

The `Relationship` entity has `FromPersonID` and `ToPersonID`. A change to a relationship where Person X is the `ToPersonID` should still appear in Person X's timeline. The `AdditionalJoinFields` array handles this with OR logic.

### Change Description Quality

RecordChange stores `ChangesJSON` with field-level diffs. For related entities, the raw field names may not be user-friendly. The `DisplayLabel` provides context, but ideally the changes description would be entity-aware:

- Instead of: `IsPrimary changed from false to true`
- Show: `Set as primary address`

This could be handled by entity-specific change formatters (a separate enhancement).

## Alternatives Considered

### 1. Server-Side Triggers

Touch the parent entity's `__mj_UpdatedAt` when related records change, creating a synthetic RecordChange entry. **Rejected** because:
- Pollutes the parent entity's actual change history
- Doesn't capture *what* changed in the related entity
- Creates misleading audit trails

### 2. Custom Activity Log Entity

Create a separate `ActivityLog` entity that records cross-entity events. **Deferred** because:
- Requires custom logging in every save operation
- Duplicates data already captured by RecordChange
- The metadata-driven approach reuses existing infrastructure

### 3. Client-Side Aggregation Only

Have the UI component query multiple entities' RecordChanges and merge them. **Partially adopted** — the UI does the merging, but having the metadata in Entity Settings makes it declarative and reusable across any UI that shows record history.

## Impact

- **Entity Settings schema**: Add one JSON field
- **Core API**: Add one new method (or extend existing)
- **Angular**: Enhance one existing component
- **No breaking changes** — existing `GetRecordChanges` behavior is unchanged
- **Opt-in** — only entities with `RecordChangesRelatedEntities` configured get the enhanced behavior
