import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { BaseEntity, BaseEntityResult, CompositeKey, RunView, type UserInfo } from '@memberjunction/core';
import { CALENDAR_WATERMARK_SETTING } from '@mj-biz-apps/common-activity-sync';
import {
    ActivityEntityServer,
    ActivityLinkEntityServer,
    ActivitySyncConnectionEntityServer,
    CALENDAR_WATERMARK_KEY,
    ChangedRoutingFields,
    KeyMatchesPrimaryKeys,
    SettingsWithoutWatermark,
    SYSTEM_USER_ID,
} from '@mj-biz-apps/common-core-entities-server';

/**
 * The server-side write guards on Activities (#395), Activity Links (#396) and Activity Sync
 * Connections (#392).
 *
 * The entities are built with `Object.create` and their state is pinned with own properties, so
 * each test drives `Save()` without metadata or a database: the base save and the stored-row read
 * (`RunView`) are spies.
 */

const OWNER = { ID: '11111111-1111-1111-1111-111111111111', Type: 'Owner' } as UserInfo;
const INTEGRATION = { ID: '22222222-2222-2222-2222-222222222222', Type: 'User' } as UserInfo;
const OTHER_ID = '33333333-3333-3333-3333-333333333333';
const PEOPLE_ID = '44444444-4444-4444-4444-444444444444';
const RECORD_ID = '55555555-5555-5555-5555-555555555555';

type Pinned = Record<string, unknown>;

/** Builds an entity of `cls` whose fields and BaseEntity state are the given own properties. */
function make<T extends BaseEntity>(cls: { prototype: T }, state: Pinned): { entity: T; results: BaseEntityResult[] } {
    const entity = Object.create(cls.prototype) as T;
    const results: BaseEntityResult[] = [];
    const pinned: Pinned = {
        EntityInfo: { Name: 'Test Entity', PrimaryKeys: [{ Name: 'ID' }] },
        PrimaryKey: CompositeKey.FromKeyValuePair('ID', '66666666-6666-6666-6666-666666666666'),
        RunViewProviderToUse: {},
        RegisterResultHistoryEntry: (r: BaseEntityResult) => results.push(r),
        GetFieldByName: () => ({ NotLoaded: false }),
        ...state,
    };
    for (const [name, value] of Object.entries(pinned)) {
        Object.defineProperty(entity, name, { value, writable: true, configurable: true });
    }
    return { entity, results };
}

let baseSave: ReturnType<typeof vi.spyOn>;
let runView: ReturnType<typeof vi.spyOn>;

function storedRow(row: Pinned | null): void {
    runView.mockResolvedValue({ Success: row !== null, Results: row ? [row] : [] });
}

beforeEach(() => {
    baseSave = vi.spyOn(BaseEntity.prototype, 'Save').mockResolvedValue(true);
    runView = vi.spyOn(RunView.prototype, 'RunView');
    storedRow(null);
});

afterEach(() => vi.restoreAllMocks());

describe('Activity: LoggedByUserID is the saving user (#395)', () => {
    it('stamps the saving user on a create, over whatever the caller sent', async () => {
        const { entity } = make(ActivityEntityServer, { IsSaved: false, ActiveUser: INTEGRATION, LoggedByUserID: OTHER_ID });
        expect(await entity.Save()).toBe(true);
        expect(entity.LoggedByUserID).toBe(INTEGRATION.ID);
        expect(baseSave).toHaveBeenCalledOnce();
    });

    it('refuses an update that changes LoggedByUserID, compared with the stored row', async () => {
        storedRow({ LoggedByUserID: INTEGRATION.ID });
        const { entity, results } = make(ActivityEntityServer, { IsSaved: true, ActiveUser: INTEGRATION, LoggedByUserID: OTHER_ID });
        expect(await entity.Save()).toBe(false);
        expect(results[0].Message).toMatch(/LoggedByUserID cannot be changed/);
        expect(baseSave).not.toHaveBeenCalled();
    });

    it('allows an update that keeps LoggedByUserID, whatever its case', async () => {
        storedRow({ LoggedByUserID: INTEGRATION.ID.toLowerCase() });
        const { entity } = make(ActivityEntityServer, { IsSaved: true, ActiveUser: INTEGRATION, LoggedByUserID: INTEGRATION.ID.toUpperCase() });
        expect(await entity.Save()).toBe(true);
    });

    it('refuses an update when the stored row cannot be read', async () => {
        const { entity } = make(ActivityEntityServer, { IsSaved: true, ActiveUser: INTEGRATION, LoggedByUserID: INTEGRATION.ID });
        expect(await entity.Save()).toBe(false);
    });

    it('refuses a save with no user', async () => {
        const { entity } = make(ActivityEntityServer, { IsSaved: false, ActiveUser: null, LoggedByUserID: OTHER_ID });
        expect(await entity.Save()).toBe(false);
        expect(baseSave).not.toHaveBeenCalled();
    });
});

describe('Activity Link: the saving user must be able to read the target (#396)', () => {
    function link(state: Pinned) {
        return make(ActivityLinkEntityServer, {
            IsSaved: false,
            ActiveUser: INTEGRATION,
            ProviderToUse: { Entities: [{ ID: PEOPLE_ID, Name: 'People', PrimaryKeys: [{ Name: 'ID' }] }] },
            ...state,
        });
    }

    it('saves when the target comes back for the saving user', async () => {
        storedRow({ ID: RECORD_ID });
        const { entity } = link({ EntityID: PEOPLE_ID, RecordID: RECORD_ID });
        expect(await entity.Save()).toBe(true);
        const [params, user] = runView.mock.calls[0];
        expect(params).toMatchObject({ EntityName: 'People', ExtraFilter: `ID='${RECORD_ID}'` });
        expect(user).toBe(INTEGRATION);
    });

    it('refuses when the target does not come back (missing or not readable)', async () => {
        const { entity, results } = link({ EntityID: PEOPLE_ID, RecordID: RECORD_ID });
        expect(await entity.Save()).toBe(false);
        expect(results[0].Message).toMatch(/do not have access/);
        expect(baseSave).not.toHaveBeenCalled();
    });

    it('refuses an unknown target entity without reading anything', async () => {
        const { entity } = link({ EntityID: OTHER_ID, RecordID: RECORD_ID });
        expect(await entity.Save()).toBe(false);
        expect(runView).not.toHaveBeenCalled();
    });

    it('refuses a RecordID that names a column other than the primary key', async () => {
        const { entity } = link({ EntityID: PEOPLE_ID, RecordID: `Email|x||ID|${RECORD_ID}` });
        expect(await entity.Save()).toBe(false);
        expect(runView).not.toHaveBeenCalled();
    });

    it('skips the check for an unresolved identity link', async () => {
        const { entity } = link({ EntityID: null, RecordID: null });
        expect(await entity.Save()).toBe(true);
        expect(runView).not.toHaveBeenCalled();
    });

    it('checks the stored target on an update that did not load it', async () => {
        runView
            .mockResolvedValueOnce({ Success: true, Results: [{ EntityID: PEOPLE_ID, RecordID: RECORD_ID }] })
            .mockResolvedValueOnce({ Success: true, Results: [] });
        const { entity } = link({ IsSaved: true, EntityID: null, RecordID: null, GetFieldByName: () => ({ NotLoaded: true }) });
        expect(await entity.Save()).toBe(false);
        expect(runView).toHaveBeenCalledTimes(2);
    });

    it('KeyMatchesPrimaryKeys accepts exactly the primary key columns', () => {
        expect(KeyMatchesPrimaryKeys(CompositeKey.FromKeyValuePair('id', RECORD_ID), ['ID'])).toBe(true);
        expect(KeyMatchesPrimaryKeys(CompositeKey.FromKeyValuePair('Email', 'x'), ['ID'])).toBe(false);
        expect(KeyMatchesPrimaryKeys(CompositeKey.FromKeyValuePair('ID', ''), ['ID'])).toBe(false);
    });
});

describe('Activity Sync Connection: only an administrator changes routing (#392)', () => {
    const stored = {
        Mailbox: 'shared@example.test',
        CredentialsRef: 'cred-1',
        Provider: 'Microsoft365',
        OwnerUserID: INTEGRATION.ID,
        ActivitySyncProviderTypeID: null,
        Settings: '{"StoreBody":"Snippet","CalendarLastSyncAt":"2026-11-01T00:00:00.000Z"}',
    };

    function connection(state: Pinned) {
        return make(ActivitySyncConnectionEntityServer, { IsSaved: true, ActiveUser: INTEGRATION, ...stored, ...state });
    }

    it('refuses a create by a non-administrator', async () => {
        const { entity, results } = connection({ IsSaved: false });
        expect(await entity.Save()).toBe(false);
        expect(results[0].Message).toMatch(/Only an administrator/);
    });

    it('allows a create by an Owner-type user and by the System user', async () => {
        expect(await connection({ IsSaved: false, ActiveUser: OWNER }).entity.Save()).toBe(true);
        const system = { ID: SYSTEM_USER_ID.toLowerCase(), Type: 'User' } as UserInfo;
        expect(await connection({ IsSaved: false, ActiveUser: system }).entity.Save()).toBe(true);
        expect(runView).not.toHaveBeenCalled();
    });

    it('refuses a non-administrator re-pointing Mailbox, even if the client claims it unchanged', async () => {
        storedRow(stored);
        const { entity, results } = connection({ Mailbox: 'ceo@example.test' });
        expect(await entity.Save()).toBe(false);
        expect(results[0].Message).toMatch(/change Mailbox/);
        expect(baseSave).not.toHaveBeenCalled();
    });

    it('refuses a non-administrator taking ownership', async () => {
        storedRow(stored);
        expect(await connection({ OwnerUserID: OTHER_ID }).entity.Save()).toBe(false);
    });

    it('allows the sync engine status and watermark writes', async () => {
        storedRow(stored);
        const { entity } = connection({
            Settings: '{"CalendarLastSyncAt":"2026-11-03T00:00:00.000Z","StoreBody":"Snippet"}',
        });
        expect(await entity.Save()).toBe(true);
    });

    it('refuses when the stored row cannot be read', async () => {
        expect(await connection({}).entity.Save()).toBe(false);
    });

    it('ChangedRoutingFields names each changed routing column', () => {
        const changed = ChangedRoutingFields(
            { ...stored, CredentialsRef: 'cred-2', OwnerUserID: INTEGRATION.ID.toLowerCase(), Settings: '{"StoreBody":"Full"}' },
            stored,
        );
        expect(changed).toEqual(['CredentialsRef', 'Settings']);
    });

    it('SettingsWithoutWatermark ignores only the watermark and key order', () => {
        expect(SettingsWithoutWatermark('{"CalendarLastSyncAt":"x"}')).toBeNull();
        expect(SettingsWithoutWatermark('{"b":1,"a":2}')).toBe(SettingsWithoutWatermark('{"a":2,"b":1}'));
        expect(SettingsWithoutWatermark('not json')).toBe('not json');
    });

    it('uses the same watermark key the sync engine writes', () => {
        expect(CALENDAR_WATERMARK_KEY).toBe(CALENDAR_WATERMARK_SETTING);
    });
});
