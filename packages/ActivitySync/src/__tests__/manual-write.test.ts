import { describe, expect, it, vi } from 'vitest';
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

// One activity already exists under ('EntityAction', 'seen-before') so the dedupe path is real.
vi.mock('@memberjunction/core', () => ({
    RunView: class {
        public async RunView(params: { ExtraFilter?: string }) {
            if (params.ExtraFilter?.startsWith('Code =')) {
                return { Success: true, Results: [{ ID: 'type-1' }] };
            }
            if (params.ExtraFilter?.includes(`ExternalID = 'seen-before'`)) {
                return { Success: true, Results: [{ ID: 'existing-activity' }] };
            }
            return { Success: true, Results: [] };
        }
    },
    LogError: () => undefined,
}));

import { ActivityWriter, ValidateManualActivityInput, type WriteManualActivityInput } from '../writer.js';

const PEOPLE = 'MJ_BizApps_Common: People';
const USER = { ID: 'user-1' } as UserInfo;
// writeLink rejects any RecordID that is not a UUID, so fixtures must use real-shaped ids.
const PERSON_UUID = 'aaaaaaaa-1111-2222-3333-444444444444';
const OTHER_UUID = 'bbbbbbbb-1111-2222-3333-444444444444';

function input(overrides: Partial<WriteManualActivityInput> = {}): WriteManualActivityInput {
    return {
        TypeCode: 'SystemEvent',
        Title: 'Person created',
        StartedAt: new Date('2026-08-30T10:00:00Z'),
        Links: [{ Role: 'Regarding', EntityName: PEOPLE, RecordID: PERSON_UUID }],
        ...overrides,
    };
}

interface FakeRow {
    [key: string]: unknown;
    NewRecord: () => void;
    Save: () => Promise<boolean>;
}

/** A minimal transactional provider: records saved rows and whether the txn committed/rolled back. */
function fakeProvider() {
    const state = {
        committed: false,
        rolledBack: false,
        activities: [] as FakeRow[],
        links: [] as FakeRow[],
    };
    let nextID = 0;
    const provider = {
        Entities: [
            { Name: PEOPLE, ID: 'entity-people' },
            { Name: 'MJ_BizApps_Common: Organizations', ID: 'entity-orgs' },
        ],
        BeginEntityTransaction: async () => ({
            Commit: async () => {
                state.committed = true;
            },
            Rollback: async () => {
                state.rolledBack = true;
            },
        }),
        GetEntityObject: async (entityName: string) => {
            const row: FakeRow = {
                NewRecord: () => undefined,
                Save: async () => {
                    row.ID = `row-${++nextID}`;
                    return true;
                },
            };
            if (entityName.endsWith('Activity Links')) state.links.push(row);
            else state.activities.push(row);
            return row;
        },
    } as unknown as IMetadataProvider;
    return { provider, state };
}

describe('ActivityWriter.WriteManual', () => {
    it('reports validation problems without touching the provider', async () => {
        const { provider, state } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(
            input({ TypeCode: '', Title: ' ', Links: [{ Role: 'Regarding' }] }),
            provider,
            USER,
        );
        expect(result.Success).toBe(false);
        expect(result.Issues).toContain('TypeCode is required.');
        expect(result.Issues).toContain('Title is required.');
        expect(result.Issues.join(' ')).toMatch(/Link 1 must carry either/);
        expect(state.activities).toHaveLength(0);
    });

    it('writes the activity with manual defaults and its links, then commits', async () => {
        const { provider, state } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(
            input({
                Links: [
                    { Role: 'Regarding', EntityName: PEOPLE, RecordID: PERSON_UUID },
                    { Role: 'Participant', IdentityKind: 'Email', IdentityValue: 'a@b.test' },
                    // duplicate of the first (case-insensitive) — must be deduped, same as the sync path
                    { Role: 'Participant', EntityName: PEOPLE, RecordID: PERSON_UUID.toUpperCase() },
                ],
            }),
            provider,
            USER,
        );

        expect(result.Issues).toEqual([]);
        expect(result.Success).toBe(true);
        expect(state.committed).toBe(true);
        expect(state.rolledBack).toBe(false);

        const activity = state.activities[0];
        expect(activity.ActivityTypeID).toBe('type-1');
        expect(activity.Visibility).toBe('Internal'); // the manual default — never the sync path's 'Private'
        expect(activity.Source).toBe('Manual');
        expect(activity.Status).toBe('Logged');
        expect(activity.Direction).toBe('Internal');
        expect(activity.LoggedByUserID).toBe('user-1');
        expect(activity.ActivitySyncConnectionID).toBeUndefined(); // no connection on a manual log

        expect(state.links).toHaveLength(2);
        expect(state.links[0].EntityID).toBe('entity-people');
        expect(state.links[0].RecordID).toBe(PERSON_UUID);
        expect(state.links[0].Sequence).toBe(1);
        expect(state.links[1].IdentityKind).toBe('Email');
        expect(state.links[1].IdentityValue).toBe('a@b.test');
        expect(state.links[1].Sequence).toBe(2);
    });

    it('honours explicit Visibility / Source / Status overrides', async () => {
        const { provider, state } = fakeProvider();
        await new ActivityWriter().WriteManual(
            input({ Visibility: 'Private', Source: 'System', Status: 'Completed', Links: [] }),
            provider,
            USER,
        );
        expect(state.activities[0].Visibility).toBe('Private');
        expect(state.activities[0].Source).toBe('System');
        expect(state.activities[0].Status).toBe('Completed');
    });

    it('is idempotent on SourceSystem + ExternalID — a repeat reports AlreadyPresent and writes nothing', async () => {
        const { provider, state } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(
            input({ SourceSystem: 'EntityAction', ExternalID: 'seen-before' }),
            provider,
            USER,
        );
        expect(result.Success).toBe(true);
        expect(result.AlreadyPresent).toBe(true);
        expect(result.ActivityID).toBe('existing-activity');
        expect(state.activities).toHaveLength(0);
    });

    it('rolls back when a link targets an entity the provider does not know', async () => {
        const { provider, state } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(
            input({ Links: [{ Role: 'Regarding', EntityName: 'No Such Entity', RecordID: OTHER_UUID }] }),
            provider,
            USER,
        );
        expect(result.Success).toBe(false);
        expect(result.Issues.join(' ')).toMatch(/Link could not be written/);
        expect(state.rolledBack).toBe(true);
        expect(state.committed).toBe(false);
    });

    it('rolls back when a link carries a RecordID that is not a UUID', async () => {
        const { provider, state } = fakeProvider();
        const result = await new ActivityWriter().WriteManual(
            input({ Links: [{ Role: 'Regarding', EntityName: PEOPLE, RecordID: `x'; DROP TABLE Activity;--` }] }),
            provider,
            USER,
        );
        expect(result.Success).toBe(false);
        expect(result.Issues.join(' ')).toMatch(/must be a UUID/);
        expect(state.rolledBack).toBe(true);
        expect(state.committed).toBe(false);
        expect(state.links.every((l) => l.RecordID === undefined)).toBe(true);
    });

    it('refuses a provider that cannot open a transaction', async () => {
        const provider = {
            GetEntityObject: async () => {
                throw new Error('should not write');
            },
        } as IMetadataProvider;
        const result = await new ActivityWriter().WriteManual(input(), provider, USER);
        expect(result.Success).toBe(false);
        expect(result.Issues[0]).toMatch(/cannot open a transaction/);
    });
});

describe('ValidateManualActivityInput', () => {
    it('enforces the SourceSystem-with-ExternalID pairing and date ordering', () => {
        const issues = ValidateManualActivityInput(
            input({
                ExternalID: 'key-without-system',
                EndedAt: new Date('2026-08-30T09:00:00Z'), // before StartedAt
                Links: [],
            }),
        );
        expect(issues).toContain('SourceSystem is required when ExternalID is set.');
        expect(issues).toContain('EndedAt must be on or after StartedAt.');
    });

    it('a link carrying both shapes is as invalid as one carrying neither', () => {
        const issues = ValidateManualActivityInput(
            input({
                Links: [
                    {
                        Role: 'Regarding',
                        EntityName: PEOPLE,
                        RecordID: 'x',
                        IdentityKind: 'Email',
                        IdentityValue: 'a@b.test',
                    },
                ],
            }),
        );
        expect(issues.join(' ')).toMatch(/Link 1 must carry either/);
    });
});
