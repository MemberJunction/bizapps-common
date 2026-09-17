/**
 * @fileoverview The resolve-and-hide rules behind `bizapps-related-chips`, kept out of the component.
 *
 * WHY THIS IS NOT IN THE COMPONENT. Everything here is a decision about whether a chip may be shown
 * at all — "is the app installed", "does the record still exist", "did the read fail or did it
 * succeed and find nothing" — and those are exactly the things that must be pinned by tests. A rule
 * declared inside an Angular component cannot be exercised without standing up DI, which this
 * package's node-environment vitest setup deliberately does not do. Same split as
 * `bizapps-contracts`' `source-record-candidates.ts`.
 *
 * The dependencies below are narrowed to the shape each function actually reads rather than taking
 * `IMetadataProvider` / `RunView`. `EntityInfo[]` and `RunViewResult` satisfy them structurally, so
 * the component passes the real objects while a test passes a literal.
 *
 * @module @mj-biz-apps/common-ng
 */
import { CompositeKey } from '@memberjunction/core';
import type { RecordNavigationEvent } from '@memberjunction/ng-base-forms';

/**
 * One relationship a record header offers to follow.
 *
 * Give it either a {@link RecordID} (the ordinary case — this record holds the id) or a
 * {@link Filter} (the reverse case — the other record holds the id, as with an Order whose Deal
 * points at it). A link with neither names nothing and is dropped.
 */
export interface BizAppsRelatedLink {
    /** Stable identity, used to track the chip and to correlate it back to the caller's own model. */
    Key: string;
    /**
     * Entity that owns the linked record, as a name — e.g. `'MJ_BizApps_Orders: Order Headers'`.
     *
     * An entity that is not in the catalog produces NO chip. That covers both "the app that owns
     * this record is not installed here" and "this user may not read it", and the two are
     * deliberately one outcome: the entity catalog is already permission-filtered, and a reader who
     * cannot open the record is no better served by a chip than one whose host never had the app.
     * `bizapps-sales`' `OrdersIsInstalled()` draws the same line for the same reason.
     */
    EntityName: string;
    /** Forward link: the linked record's primary key value, as held on the record being displayed. */
    RecordID?: string | null;
    /**
     * Reverse link: a filter that selects the linked record. The first row wins, so pass something
     * that identifies one record. Composed by the caller, which is the only party that knows the
     * other entity's column names.
     */
    Filter?: string;
    /** Names the relationship outright. Wins over {@link LabelPrefix}. */
    Label?: string;
    /**
     * Builds the label as `<prefix> <entity's singular name>` — "Source Deal", "Source Order".
     *
     * For a polymorphic link, where the caller knows the ROLE the other record plays but not which
     * entity fills it until the id is resolved. Hardcoding "Deal" is what this avoids.
     */
    LabelPrefix?: string;
    /** Font Awesome class for a small leading icon. Optional. */
    Icon?: string;
}

/** The part of `EntityInfo` a link needs. `EntityInfo` satisfies this. */
export interface RelatedLinkEntity {
    Name: string;
    BaseTableDisplayName: string;
    NameField: { Name: string } | null;
    PrimaryKeys: { Name: string }[];
}

/** The part of `RunViewResult` a link needs. `RunViewResult<Record<string, unknown>>` satisfies this. */
export interface RelatedLinkReadResult {
    Success: boolean;
    Results?: Record<string, unknown>[];
}

/** Reads one row for a link. The component supplies a provider-scoped `RunView`. */
export type RelatedLinkReader = (params: {
    EntityName: string;
    Fields: string[];
    ExtraFilter: string;
    MaxRows: number;
}) => Promise<RelatedLinkReadResult>;

/** A link that resolved to something openable. Anything that did not resolve is absent, not blank. */
export interface ResolvedRelatedChip {
    Key: string;
    /** What the relationship is: "Source Deal", "Order". */
    Label: string;
    /** The linked record's name. Empty ONLY when the record exists but could not be read — see below. */
    Name: string;
    Icon: string | null;
    EntityName: string;
    PrimaryKeyField: string;
    RecordID: string;
    /** Accessible name for the chip's button, composed once here so the template stays declarative. */
    AriaLabel: string;
}

/** Single-quote escaping for a value going into an `ExtraFilter`. */
function quote(value: string): string {
    return value.replace(/'/g, "''");
}

/** `true` for a value that actually names a record — not null, not undefined, not blank. */
function isPresent(value: string | null | undefined): value is string {
    return value !== null && value !== undefined && String(value).trim().length > 0;
}

/**
 * The filter that selects the linked record, or `null` when the link names nothing to select.
 *
 * A `RecordID` is preferred over a `Filter` when both are given: the caller holding the id is the
 * more direct statement of the same fact.
 */
export function FilterForRelatedLink(link: BizAppsRelatedLink, entity: RelatedLinkEntity): string | null {
    if (isPresent(link.RecordID)) {
        return `${PrimaryKeyFieldFor(entity)} = '${quote(String(link.RecordID).trim())}'`;
    }
    return isPresent(link.Filter) ? link.Filter.trim() : null;
}

/** The entity's primary key column, defaulting to `ID` as every other link in these apps does. */
export function PrimaryKeyFieldFor(entity: RelatedLinkEntity): string {
    return entity.PrimaryKeys?.[0]?.Name ?? 'ID';
}

/**
 * The chip's label: what the caller called it, else `<prefix> <entity>`, else the entity's own name.
 *
 * `BaseTableDisplayName` rather than `DisplayName` because a chip labels ONE record and the entity
 * name is plural — it is what turns a Deals link into "Source Deal" without guessing at plurals.
 */
export function LabelForRelatedLink(link: BizAppsRelatedLink, entity: RelatedLinkEntity): string {
    if (isPresent(link.Label)) {
        return link.Label.trim();
    }
    if (isPresent(link.LabelPrefix)) {
        return `${link.LabelPrefix.trim()} ${entity.BaseTableDisplayName}`;
    }
    return entity.BaseTableDisplayName;
}

/**
 * Resolve one link to a chip, or to `null` for "show nothing".
 *
 * ## The two rules this function exists to hold
 *
 * **A CHIP NEVER SHOWS A RAW ID.** The whole point of the row is that a reader recognises what they
 * are about to open. So the name is read from the entity's own name field, and an entity with no
 * name field produces no chip rather than a GUID wearing a label.
 *
 * **A CHIP THAT CANNOT NAVIGATE IS NOT RENDERED.** A link that goes nowhere is worse than an absent
 * one: it invites a click and spends the reader's trust. Five ways a link produces nothing — the
 * entity is not in the catalog, the entity has no name field, the link names neither a record nor a
 * filter, the read succeeded while matching zero rows, and the read was refused.
 *
 * ## Why a read that THREW is treated differently from one that FAILED or found nothing
 *
 * Three different facts, and the line between them is whether the server answered.
 *
 * **Zero rows from a successful read** means the record is not there — `bizapps-contracts` hit
 * exactly this with CTR-000026, whose hand-typed provenance pair names a row that does not exist,
 * and whose header rendered an "Open" button that navigated nowhere. No chip.
 *
 * **`Success: false`** is the server answering and refusing. In MJ that is the channel for a
 * permission denial as much as for a bad filter: `GraphQLDataProvider.InternalRunView` throws when
 * the transport fails and returns `Success: false` with an `ErrorMessage` when the request reached
 * the server and was turned down. A reader who may not read Orders would otherwise get an
 * "Order · Open" chip that navigates to a record that will not open — the dead link this component
 * exists to prevent. So a refusal produces NO chip.
 *
 * **A thrown read** means we do not know: the record may well exist and simply be unreachable this
 * moment. So a throw keeps the chip when we already hold the id to open — labelled, with "Open"
 * where the name would go — and drops it for a reverse link, where the throw also cost us the id.
 */
export async function ResolveRelatedChip(
    link: BizAppsRelatedLink,
    entities: RelatedLinkEntity[],
    read: RelatedLinkReader,
): Promise<ResolvedRelatedChip | null> {
    const entity = entities?.find((e) => e.Name === link.EntityName) ?? null;
    if (!entity) {
        return null;
    }

    const nameField = entity.NameField?.Name;
    if (!isPresent(nameField)) {
        return null;
    }

    const filter = FilterForRelatedLink(link, entity);
    if (!filter) {
        return null;
    }

    const pkField = PrimaryKeyFieldFor(entity);
    const label = LabelForRelatedLink(link, entity);

    try {
        const result = await read({
            EntityName: entity.Name,
            Fields: [pkField, nameField],
            ExtraFilter: filter,
            MaxRows: 1,
        });
        if (result?.Success === false) {
            return null;
        }
        const row = result?.Success ? result.Results?.[0] : undefined;
        if (result?.Success && !row) {
            return null;
        }
        if (!row) {
            return unreadableChip(link, entity, label, pkField);
        }
        const recordID = String(row[pkField] ?? link.RecordID ?? '');
        if (!isPresent(recordID)) {
            return null;
        }
        return chip(link, entity, label, pkField, recordID, String(row[nameField] ?? ''));
    } catch {
        return unreadableChip(link, entity, label, pkField);
    }
}

/**
 * The chip for a record we could not read but can still open — only possible when the link carried
 * the id itself. A reverse link has nothing left to open, so it renders nothing.
 */
function unreadableChip(
    link: BizAppsRelatedLink,
    entity: RelatedLinkEntity,
    label: string,
    pkField: string,
): ResolvedRelatedChip | null {
    return isPresent(link.RecordID) ? chip(link, entity, label, pkField, String(link.RecordID).trim(), '') : null;
}

function chip(
    link: BizAppsRelatedLink,
    entity: RelatedLinkEntity,
    label: string,
    pkField: string,
    recordID: string,
    name: string,
): ResolvedRelatedChip {
    return {
        Key: link.Key,
        Label: label,
        Name: name,
        Icon: link.Icon ?? null,
        EntityName: entity.Name,
        PrimaryKeyField: pkField,
        RecordID: recordID,
        AriaLabel: name ? `Open ${label} ${name}` : `Open ${label}`,
    };
}

/** The part of a `MouseEvent` that decides where a chip opens. `MouseEvent` satisfies this. */
export interface RelatedChipClick {
    ctrlKey: boolean;
    metaKey: boolean;
}

/**
 * The navigation event a chip click produces.
 *
 * Ctrl (Windows/Linux) and Cmd (macOS) both mean "new tab", which is the idiom MJ uses everywhere a
 * record link is clicked.
 *
 * `OpenInNewTab` is OMITTED rather than set to `false` on a plain click, and that is the whole of
 * what makes shift-click work. `NavigationService.shouldForceNewTab` returns `options.forceNewTab`
 * whenever it is `!== undefined` and only otherwise consults its global shift-key state, and
 * Explorer passes `forceNewTab: event.OpenInNewTab` straight through. An explicit `false` therefore
 * does not mean "no opinion" — it means "same tab", and it suppresses the shift detection outright.
 *
 * `CompositeKey.FromKeyValuePair` rather than `FromID`: the latter assumes the target's primary key
 * is literally called `ID`, which is true of these apps today and is not a thing a shared component
 * gets to assume.
 */
export function RelatedChipNavigation(chip: ResolvedRelatedChip, event: RelatedChipClick): RecordNavigationEvent {
    const navigation: RecordNavigationEvent = {
        Kind: 'record',
        EntityName: chip.EntityName,
        PrimaryKey: CompositeKey.FromKeyValuePair(chip.PrimaryKeyField, chip.RecordID),
    };
    if (event.ctrlKey || event.metaKey) {
        navigation.OpenInNewTab = true;
    }
    return navigation;
}
