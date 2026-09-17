import { describe, it, expect } from 'vitest';
import {
    FilterForRelatedLink,
    LabelForRelatedLink,
    RelatedChipNavigation,
    ResolveRelatedChip,
    type BizAppsRelatedLink,
    type RelatedChipClick,
    type RelatedLinkEntity,
    type RelatedLinkReadResult,
    type ResolvedRelatedChip,
} from '../related-links';

/**
 * These pin the rules that decide whether a chip may be DRAWN, not the markup that draws it.
 *
 * Every one of them is silent when it regresses: a dead chip looks exactly like a live one until
 * somebody clicks it, and a GUID in place of a name looks like data rather than a bug.
 */

const DEALS: RelatedLinkEntity = {
    Name: 'MJ_BizApps_Sales: Deals',
    BaseTableDisplayName: 'Deal',
    NameField: { Name: 'DealName' },
    PrimaryKeys: [{ Name: 'ID' }],
};

const ORDERS: RelatedLinkEntity = {
    Name: 'MJ_BizApps_Orders: Order Headers',
    BaseTableDisplayName: 'Order Header',
    NameField: { Name: 'OrderNumber' },
    PrimaryKeys: [{ Name: 'OrderKey' }],
};

const CATALOG = [DEALS, ORDERS];

/** A reader that always answers the same way, and records what it was asked. */
function readerReturning(result: RelatedLinkReadResult, asked: { ExtraFilter?: string; Fields?: string[] } = {}) {
    return async (params: { EntityName: string; Fields: string[]; ExtraFilter: string; MaxRows: number }) => {
        asked.ExtraFilter = params.ExtraFilter;
        asked.Fields = params.Fields;
        return result;
    };
}

function throwingReader() {
    return async (): Promise<RelatedLinkReadResult> => {
        throw new Error('provider unreachable');
    };
}

const DEAL_LINK: BizAppsRelatedLink = {
    Key: 'source',
    EntityName: DEALS.Name,
    RecordID: 'D1',
    LabelPrefix: 'Source',
};

describe('a chip that cannot navigate is not rendered', () => {
    it('drops a link whose entity is not in the catalog — the app is not installed, or not readable', async () => {
        const chip = await ResolveRelatedChip(
            { Key: 'contract', EntityName: 'MJ_BizApps_Contracts: Contracts', RecordID: 'C1' },
            CATALOG,
            readerReturning({ Success: true, Results: [{ ID: 'C1', Name: 'CTR-1' }] }),
        );
        expect(chip).toBeNull();
    });

    it('drops a link to an entity with no name field — a chip may not fall back to an id', async () => {
        const nameless: RelatedLinkEntity = { ...DEALS, NameField: null };
        const chip = await ResolveRelatedChip(DEAL_LINK, [nameless], readerReturning({ Success: true, Results: [{}] }));
        expect(chip).toBeNull();
    });

    it('drops a link that names neither a record nor a filter', async () => {
        const chip = await ResolveRelatedChip(
            { Key: 'source', EntityName: DEALS.Name, RecordID: null },
            CATALOG,
            readerReturning({ Success: true, Results: [{ ID: 'D1', DealName: 'Acme' }] }),
        );
        expect(chip).toBeNull();
    });

    it('treats a blank RecordID as naming nothing', async () => {
        const chip = await ResolveRelatedChip(
            { Key: 'source', EntityName: DEALS.Name, RecordID: '   ' },
            CATALOG,
            readerReturning({ Success: true, Results: [{ ID: 'D1', DealName: 'Acme' }] }),
        );
        expect(chip).toBeNull();
    });

    it('drops a link whose read SUCCEEDED and matched nothing — the record is not there', async () => {
        const chip = await ResolveRelatedChip(DEAL_LINK, CATALOG, readerReturning({ Success: true, Results: [] }));
        expect(chip).toBeNull();
    });
});

describe('a read that threw is not the same as a record that is absent', () => {
    it('keeps a forward link when the read throws — the record may exist and merely be unreadable', async () => {
        const chip = await ResolveRelatedChip(DEAL_LINK, CATALOG, throwingReader());
        expect(chip).not.toBeNull();
        expect(chip?.RecordID).toBe('D1');
        expect(chip?.Name).toBe('');
        expect(chip?.Label).toBe('Source Deal');
    });

    it('keeps a forward link when the read reports failure without throwing', async () => {
        const chip = await ResolveRelatedChip(DEAL_LINK, CATALOG, readerReturning({ Success: false }));
        expect(chip?.RecordID).toBe('D1');
        expect(chip?.Name).toBe('');
    });

    it('drops a REVERSE link when the read throws — the throw also cost us the id to open', async () => {
        const chip = await ResolveRelatedChip(
            { Key: 'deal', EntityName: DEALS.Name, Filter: `OrderID = 'O1'` },
            CATALOG,
            throwingReader(),
        );
        expect(chip).toBeNull();
    });
});

describe('a chip never shows a raw id', () => {
    it('reads the name from the entity name field', async () => {
        const chip = await ResolveRelatedChip(
            DEAL_LINK,
            CATALOG,
            readerReturning({ Success: true, Results: [{ ID: 'D1', DealName: 'Acme renewal' }] }),
        );
        expect(chip?.Name).toBe('Acme renewal');
    });

    it('asks for the primary key and the name field, and nothing else', async () => {
        const asked: { Fields?: string[] } = {};
        await ResolveRelatedChip(
            { Key: 'order', EntityName: ORDERS.Name, RecordID: 'O1' },
            CATALOG,
            readerReturning({ Success: true, Results: [{ OrderKey: 'O1', OrderNumber: 'ORD-9' }] }, asked),
        );
        expect(asked.Fields).toEqual(['OrderKey', 'OrderNumber']);
    });

    it('takes the id back from the row, so a reverse link knows what it found', async () => {
        const chip = await ResolveRelatedChip(
            { Key: 'deal', EntityName: DEALS.Name, Filter: `OrderID = 'O1'` },
            CATALOG,
            readerReturning({ Success: true, Results: [{ ID: 'D7', DealName: 'Acme' }] }),
        );
        expect(chip?.RecordID).toBe('D7');
        expect(chip?.Name).toBe('Acme');
    });
});

describe('the filter', () => {
    it('selects on the entity primary key, not a hardcoded ID column', () => {
        expect(FilterForRelatedLink({ Key: 'o', EntityName: ORDERS.Name, RecordID: 'O1' }, ORDERS)).toBe(
            `OrderKey = 'O1'`,
        );
    });

    it("escapes single quotes so an id cannot break out of the literal", () => {
        expect(FilterForRelatedLink({ Key: 'd', EntityName: DEALS.Name, RecordID: "a'b" }, DEALS)).toBe(
            `ID = 'a''b'`,
        );
    });

    it('prefers a RecordID over a Filter when both are given', () => {
        expect(
            FilterForRelatedLink({ Key: 'd', EntityName: DEALS.Name, RecordID: 'D1', Filter: 'X = 1' }, DEALS),
        ).toBe(`ID = 'D1'`);
    });

    it('passes a reverse filter through untouched', () => {
        expect(FilterForRelatedLink({ Key: 'd', EntityName: DEALS.Name, Filter: `OrderID = 'O1'` }, DEALS)).toBe(
            `OrderID = 'O1'`,
        );
    });
});

describe('the label', () => {
    it('uses an explicit Label above everything else', () => {
        expect(LabelForRelatedLink({ Key: 'd', EntityName: DEALS.Name, Label: 'Won deal', LabelPrefix: 'Source' }, DEALS)).toBe(
            'Won deal',
        );
    });

    it('builds "<prefix> <singular entity>" from a LabelPrefix — "Source Deal"', () => {
        expect(LabelForRelatedLink({ Key: 'd', EntityName: DEALS.Name, LabelPrefix: 'Source' }, DEALS)).toBe('Source Deal');
    });

    it('follows the entity for a polymorphic link, so Orders reads "Source Order Header"', () => {
        expect(LabelForRelatedLink({ Key: 'd', EntityName: ORDERS.Name, LabelPrefix: 'Source' }, ORDERS)).toBe(
            'Source Order Header',
        );
    });

    it('falls back to the entity singular name when the caller names nothing', () => {
        expect(LabelForRelatedLink({ Key: 'd', EntityName: DEALS.Name }, DEALS)).toBe('Deal');
    });
});

describe('the accessible name', () => {
    it('names the record when it could be read', async () => {
        const chip = await ResolveRelatedChip(
            DEAL_LINK,
            CATALOG,
            readerReturning({ Success: true, Results: [{ ID: 'D1', DealName: 'Acme' }] }),
        );
        expect(chip?.AriaLabel).toBe('Open Source Deal Acme');
    });

    it('does not trail an empty name when the record could not be read', async () => {
        const chip = await ResolveRelatedChip(DEAL_LINK, CATALOG, throwingReader());
        expect(chip?.AriaLabel).toBe('Open Source Deal');
    });
});

describe('navigation', () => {
    const chip: ResolvedRelatedChip = {
        Key: 'order',
        Label: 'Order',
        Name: 'ORD-9',
        Icon: null,
        EntityName: ORDERS.Name,
        PrimaryKeyField: 'OrderKey',
        RecordID: 'O1',
        AriaLabel: 'Open Order ORD-9',
    };

    function mouse(modifiers: Partial<RelatedChipClick>): RelatedChipClick {
        return { ctrlKey: false, metaKey: false, ...modifiers };
    }

    it('opens in the current tab on a plain click', () => {
        expect(RelatedChipNavigation(chip, mouse({})).OpenInNewTab).toBe(false);
    });

    it('opens a new tab on ctrl-click', () => {
        expect(RelatedChipNavigation(chip, mouse({ ctrlKey: true })).OpenInNewTab).toBe(true);
    });

    it('opens a new tab on cmd-click, which is what a Mac user presses', () => {
        expect(RelatedChipNavigation(chip, mouse({ metaKey: true })).OpenInNewTab).toBe(true);
    });

    it('keys on the entity own primary key column rather than assuming "ID"', () => {
        const event = RelatedChipNavigation(chip, mouse({}));
        expect(event.Kind).toBe('record');
        expect(event.Kind === 'record' && event.PrimaryKey.KeyValuePairs).toEqual([
            { FieldName: 'OrderKey', Value: 'O1' },
        ]);
    });
});
