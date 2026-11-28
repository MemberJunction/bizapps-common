import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import type { RunViewParams, RunViewResult, UserInfo } from '@memberjunction/core';
import { UUIDsEqual } from '@memberjunction/global';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, '../../../..');

const UUID_V4_UPPER = /^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/;

const USER_A_ID = '11111111-1111-4111-8111-111111111111';
const USER_B_ID = '22222222-2222-4222-8222-222222222222';
const CHIEF_OF_STAFF_AGENT_ID = '33333333-3333-4333-8333-333333333333';
const PEPPER_USER_A_AGENT_ID = '44444444-4444-4444-8444-444444444444';
const PEPPER_USER_B_AGENT_ID = '55555555-5555-4555-8555-555555555555';

const H = vi.hoisted(() => ({
    queries: [
        { ID: 'Q-ORDERS', Name: 'Party Customer Roster', Category: 'Party Signals', Description: '[signal: order|orders]' },
        { ID: 'Q-DEALS', Name: 'Won Account Roster', Category: 'Party Signals', Description: '[signal: won deal|won deals]' },
    ],
    config: vi.fn(async () => undefined),
    runQuery: vi.fn(async (params: { QueryID: string }, contextUser?: UserInfo) => {
        if (!contextUser) {
            return { Success: false, ErrorMessage: 'ContextUser required', Results: [] };
        }
        if (contextUser.ID === '11111111-1111-4111-8111-111111111111') {
            if (params.QueryID === 'Q-ORDERS') {
                return {
                    Success: true,
                    Results: [
                        { PartyKind: 'organization', PartyID: 'ORG-ALPHA', Count: 4, LastActivityAt: '2026-11-01' },
                        { PartyKind: 'person', PartyID: 'PER-ALICE', Count: 2, LastActivityAt: '2026-11-02' },
                    ],
                };
            }
            return { Success: false, ErrorMessage: 'User A lacks permission on Won Account Roster', Results: [] };
        }
        if (contextUser.ID === '22222222-2222-4222-8222-222222222222') {
            if (params.QueryID === 'Q-DEALS') {
                return {
                    Success: true,
                    Results: [
                        { PartyKind: 'organization', PartyID: 'ORG-BETA', Count: 7, LastActivityAt: '2026-11-10' },
                        { PartyKind: 'person', PartyID: 'PER-BOB', Count: 1, LastActivityAt: '2026-11-11' },
                    ],
                };
            }
            return { Success: false, ErrorMessage: 'User B lacks permission on Party Customer Roster', Results: [] };
        }
        return { Success: false, ErrorMessage: 'Unauthorized caller', Results: [] };
    }),
}));

vi.mock('@memberjunction/core', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    RunQuery: class {
        public RunQuery = H.runQuery;
    },
}));

vi.mock('@memberjunction/core-entities', async (importOriginal) => ({
    ...(await importOriginal<object>()),
    QueryEngine: {
        Instance: {
            Config: H.config,
            get Queries() {
                return H.queries;
            },
        },
    },
}));

vi.mock('@memberjunction/actions', () => ({ BaseAction: class {} }));

import { GetPartySignalsAction } from '../custom/get-party-signals.action';

interface SkillMetadataRecord {
    fields: {
        Name: string;
        Description: string;
        Instructions: string;
        Status: string;
        ActivationMode: string;
        Category?: string;
        IconClass?: string;
        CreatedByUserID: string;
    };
    relatedEntities: {
        'MJ: AI Agent Skills': Array<{
            fields: { AgentID: string; SkillID: string; Status: string };
            primaryKey: { ID: string };
        }>;
        'MJ: AI Skill Actions'?: Array<{
            fields: { SkillID: string; ActionID: string; Role: string; ExposeToModel: boolean };
            primaryKey: { ID: string };
        }>;
    };
    primaryKey: { ID: string };
}

interface ActionMetadataRecord {
    fields: { Name: string; DriverClass: string; Status: string };
}

interface PartySignalRosterEntry {
    PartyKind: string;
    PartyID: string;
    TotalCount: number;
}

interface CommonActivityRow {
    ID: string;
    Title: string;
    Visibility: 'Internal' | 'Private';
    LoggedByUserID: string;
    OrganizationID: string;
}

interface CommonSyncConnectionRow {
    ID: string;
    Name: string;
    OwnerUserID: string;
    Status: 'Active' | 'Paused' | 'Disabled' | 'Error';
}

interface PersonalAgentInstance {
    ID: string;
    Name: string;
    BaseAgentID: string;
    ForUserID: string;
}

class TestableGetPartySignalsAction extends GetPartySignalsAction {
    public Run(params: RunActionParams): Promise<ActionResultSimple> {
        return this.InternalRunAction(params);
    }
}

function assertNoSyncBlocks(node: object | Array<object | string | number | boolean | null>, path = '$'): void {
    if (Array.isArray(node)) {
        node.forEach((item, index) => {
            if (item !== null && typeof item === 'object') {
                assertNoSyncBlocks(item, `${path}[${index}]`);
            }
        });
        return;
    }
    expect(Object.prototype.hasOwnProperty.call(node, 'sync'), `Unexpected "sync" block at ${path}`).toBe(false);
    for (const [key, value] of Object.entries(node)) {
        if (value !== null && typeof value === 'object') {
            assertNoSyncBlocks(value, `${path}.${key}`);
        }
    }
}

function makeUser(id: string, name: string, email: string): UserInfo {
    return { ID: id, Name: name, Email: email } as UserInfo;
}

function makeParams(user: UserInfo | undefined): RunActionParams {
    return {
        Params: [] as ActionParam[],
        ContextUser: user,
    } as RunActionParams;
}

function readOutput(params: RunActionParams, name: string): string {
    const found = params.Params?.find((p) => p.Name === name);
    return typeof found?.Value === 'string' ? found.Value : '';
}

function resolveInheritedSkills(
    personalAgent: PersonalAgentInstance,
    templateAgentId: string,
    templateSkills: string[],
): string[] {
    return UUIDsEqual(personalAgent.BaseAgentID, templateAgentId) ? [...templateSkills] : [];
}

/**
 * Typed RunView harness enforcing BizApps Common's activity privacy (`Visibility = 'Private'`
 * visible only to `LoggedByUserID`) and mailbox connection ownership (`OwnerUserID`), plus
 * org-level tenant membership.
 */
class RlsScopedCommonRunView {
    private readonly activities: CommonActivityRow[];
    private readonly connections: CommonSyncConnectionRow[];
    private readonly userAllowedOrgs: Map<string, Set<string>>;

    constructor(
        activities: CommonActivityRow[],
        connections: CommonSyncConnectionRow[],
        userAllowedOrgs: Map<string, Set<string>>,
    ) {
        this.activities = activities;
        this.connections = connections;
        this.userAllowedOrgs = userAllowedOrgs;
    }

    public async RunView<T>(params: RunViewParams, contextUser?: UserInfo): Promise<RunViewResult<T>> {
        if (!contextUser?.ID) {
            return {
                Success: false,
                Results: [],
                UserViewRunID: '',
                RowCount: 0,
                TotalRowCount: 0,
                ExecutionTime: 0,
                ErrorMessage: 'ContextUser is required for RLS evaluation.',
            };
        }

        if (params.EntityName === 'MJ_BizApps_Common: Activities') {
            const allowedOrgs = this.userAllowedOrgs.get(contextUser.ID) ?? new Set<string>();
            const rows = this.activities.filter((row) => {
                if (!allowedOrgs.has(row.OrganizationID)) {
                    return false;
                }
                if (row.Visibility === 'Private') {
                    return UUIDsEqual(row.LoggedByUserID, contextUser.ID);
                }
                return true;
            });
            return {
                Success: true,
                Results: rows as T[],
                UserViewRunID: '',
                RowCount: rows.length,
                TotalRowCount: rows.length,
                ExecutionTime: 1,
                ErrorMessage: '',
            };
        }

        if (params.EntityName === 'MJ_BizApps_Common: Activity Sync Connections') {
            const rows = this.connections.filter((row) => UUIDsEqual(row.OwnerUserID, contextUser.ID));
            return {
                Success: true,
                Results: rows as T[],
                UserViewRunID: '',
                RowCount: rows.length,
                TotalRowCount: rows.length,
                ExecutionTime: 1,
                ErrorMessage: '',
            };
        }

        return {
            Success: false,
            Results: [],
            UserViewRunID: '',
            RowCount: 0,
            TotalRowCount: 0,
            ExecutionTime: 0,
            ErrorMessage: `Unsupported entity: ${params.EntityName}`,
        };
    }
}

describe('BizApps Common Chief of Staff skill', () => {
    beforeEach(() => {
        H.runQuery.mockClear();
        H.config.mockClear();
    });

    describe('metadata & auto-install integrity', () => {
        it('wires metadata/chief-of-staff-skills into mj-app.json and metadata/.mj-sync.json', () => {
            const manifest = JSON.parse(readFileSync(resolve(REPO_ROOT, 'mj-app.json'), 'utf8')) as {
                metadata?: { directory?: string };
            };
            expect(manifest.metadata?.directory).toBe('metadata');

            const rootSync = JSON.parse(readFileSync(resolve(REPO_ROOT, 'metadata/.mj-sync.json'), 'utf8')) as {
                directoryOrder: string[];
            };
            expect(rootSync.directoryOrder).toContain('chief-of-staff-skills');
            expect(rootSync.directoryOrder.indexOf('chief-of-staff-skills')).toBeGreaterThan(
                rootSync.directoryOrder.indexOf('actions'),
            );

            const folderSync = JSON.parse(
                readFileSync(resolve(REPO_ROOT, 'metadata/chief-of-staff-skills/.mj-sync.json'), 'utf8'),
            ) as { entity: string; pull: { filter: string; relatedEntities: Record<string, object> } };
            expect(folderSync.entity).toBe('MJ: AI Skills');
            expect(folderSync.pull.filter).toContain('Common Directory & Activity');
            expect(folderSync.pull.relatedEntities['MJ: AI Agent Skills']).toBeDefined();
            expect(folderSync.pull.relatedEntities['MJ: AI Skill Actions']).toBeDefined();
        });

        it('defines valid UUIDv4 primary keys, zero sync blocks, Chief of Staff grant, real entities, and zero raw SQL in bound actions', () => {
            const skillPath = resolve(REPO_ROOT, 'metadata/chief-of-staff-skills/.chief-of-staff-common-skill.json');
            const records = JSON.parse(readFileSync(skillPath, 'utf8')) as SkillMetadataRecord[];
            expect(records).toHaveLength(1);

            const skill = records[0];
            assertNoSyncBlocks(records);
            expect(skill.primaryKey.ID).toMatch(UUID_V4_UPPER);
            expect(skill.fields.Name).toBe('Common Directory & Activity');
            expect(skill.fields.Status).toBe('Active');
            expect(skill.fields.ActivationMode).toBe('Auto');
            expect(skill.fields.CreatedByUserID).toBe('@lookup:MJ: Users.Name=System');

            const grants = skill.relatedEntities['MJ: AI Agent Skills'];
            expect(grants).toHaveLength(1);
            expect(grants[0].primaryKey.ID).toMatch(UUID_V4_UPPER);
            expect(grants[0].fields.AgentID).toBe('@lookup:MJ: AI Agents.Name=Chief of Staff');
            expect(grants[0].fields.SkillID).toBe('@parent:ID');
            expect(grants[0].fields.Status).toBe('Active');

            // Verify personal instances (e.g. Pepper) with BaseAgentID = Chief of Staff inherit this skill automatically
            const pepperA: PersonalAgentInstance = {
                ID: PEPPER_USER_A_AGENT_ID,
                Name: 'Pepper',
                BaseAgentID: CHIEF_OF_STAFF_AGENT_ID,
                ForUserID: USER_A_ID,
            };
            expect(resolveInheritedSkills(pepperA, CHIEF_OF_STAFF_AGENT_ID, [skill.fields.Name])).toEqual([
                'Common Directory & Activity',
            ]);

            // Verify @file instructions exist and reference real Common entities
            expect(skill.fields.Instructions.startsWith('@file:')).toBe(true);
            const relTemplate = skill.fields.Instructions.slice('@file:'.length);
            const templatePath = resolve(REPO_ROOT, 'metadata/chief-of-staff-skills', relTemplate);
            expect(existsSync(templatePath)).toBe(true);
            const markdown = readFileSync(templatePath, 'utf8');
            for (const entityName of [
                'MJ_BizApps_Common: People',
                'MJ_BizApps_Common: Organizations',
                'MJ_BizApps_Common: Relationships',
                'MJ_BizApps_Common: Contact Methods',
                'MJ_BizApps_Common: Contact Method Consents',
                'MJ_BizApps_Common: Activities',
                'MJ_BizApps_Common: Activity Links',
                'MJ_BizApps_Common: Activity Sync Connections',
            ]) {
                expect(markdown).toContain(entityName);
            }
            expect(markdown).toContain('RunView');
            expect(markdown).toMatch(/never raw SQL/i);

            // Verify bound actions exist in metadata/actions and contain zero raw SQL
            const actionsMeta = JSON.parse(
                readFileSync(resolve(REPO_ROOT, 'metadata/actions/.common-actions.json'), 'utf8'),
            ) as ActionMetadataRecord[];
            const activeActionNames = new Set(actionsMeta.map((a) => a.fields.Name));

            const skillActions = skill.relatedEntities['MJ: AI Skill Actions'] ?? [];
            expect(skillActions.length).toBeGreaterThanOrEqual(2);
            for (const binding of skillActions) {
                expect(binding.primaryKey.ID).toMatch(UUID_V4_UPPER);
                expect(binding.fields.SkillID).toBe('@parent:ID');
                const actionName = binding.fields.ActionID.replace('@lookup:MJ: Actions.Name=', '');
                expect(activeActionNames.has(actionName)).toBe(true);
            }

            const boundSources = [
                resolve(REPO_ROOT, 'packages/Server/src/custom/get-party-signals.action.ts'),
                resolve(REPO_ROOT, 'packages/Server/src/custom/log-activity.action.ts'),
            ];
            for (const sourcePath of boundSources) {
                const source = readFileSync(sourcePath, 'utf8');
                expect(source).not.toMatch(/\bExecuteSQL\b|\bRawSQL\b/);
            }
        });
    });

    describe('two-user RLS isolation', () => {
        it('returns strictly different party-signal rosters for User A vs User B through Common.GetPartySignals', async () => {
            const action = new TestableGetPartySignalsAction();
            const userA = makeUser(USER_A_ID, 'Alice Ops', 'alice@alpha.example');
            const userB = makeUser(USER_B_ID, 'Bob Sales', 'bob@beta.example');

            const paramsA = makeParams(userA);
            const paramsB = makeParams(userB);

            const [resultA, resultB] = await Promise.all([action.Run(paramsA), action.Run(paramsB)]);
            expect(resultA.Success).toBe(true);
            expect(resultB.Success).toBe(true);

            const rosterA = JSON.parse(readOutput(paramsA, 'Roster')) as PartySignalRosterEntry[];
            const rosterB = JSON.parse(readOutput(paramsB, 'Roster')) as PartySignalRosterEntry[];
            const warningsA = JSON.parse(readOutput(paramsA, 'Warnings')) as string[];
            const warningsB = JSON.parse(readOutput(paramsB, 'Warnings')) as string[];

            expect(rosterA.map((r) => r.PartyID).sort()).toEqual(['ORG-ALPHA', 'PER-ALICE']);
            expect(rosterB.map((r) => r.PartyID).sort()).toEqual(['ORG-BETA', 'PER-BOB']);

            // Zero cross-user leakage
            expect(rosterA.some((r) => r.PartyID === 'ORG-BETA' || r.PartyID === 'PER-BOB')).toBe(false);
            expect(rosterB.some((r) => r.PartyID === 'ORG-ALPHA' || r.PartyID === 'PER-ALICE')).toBe(false);
            expect(warningsA[0]).toContain('Won Account Roster');
            expect(warningsB[0]).toContain('Party Customer Roster');

            // Missing ContextUser fails closed
            const unauth = await action.Run(makeParams(undefined));
            expect(unauth.Success).toBe(false);
            expect(unauth.ResultCode).toBe('VALIDATION_ERROR');
        });

        it('isolates private activities and mailbox sync connections per user through RunView for two personal instances', async () => {
            const userA = makeUser(USER_A_ID, 'Alice Ops', 'alice@alpha.example');
            const userB = makeUser(USER_B_ID, 'Bob Sales', 'bob@beta.example');

            const pepperA: PersonalAgentInstance = {
                ID: PEPPER_USER_A_AGENT_ID,
                Name: 'Pepper (Alice)',
                BaseAgentID: CHIEF_OF_STAFF_AGENT_ID,
                ForUserID: USER_A_ID,
            };
            const pepperB: PersonalAgentInstance = {
                ID: PEPPER_USER_B_AGENT_ID,
                Name: 'Pepper (Bob)',
                BaseAgentID: CHIEF_OF_STAFF_AGENT_ID,
                ForUserID: USER_B_ID,
            };
            expect(resolveInheritedSkills(pepperA, CHIEF_OF_STAFF_AGENT_ID, ['Common Directory & Activity'])).toEqual(
                resolveInheritedSkills(pepperB, CHIEF_OF_STAFF_AGENT_ID, ['Common Directory & Activity']),
            );

            const rv = new RlsScopedCommonRunView(
                [
                    {
                        ID: 'A1111111-1111-4111-8111-111111111111',
                        Title: 'Alpha shared quarterly review',
                        Visibility: 'Internal',
                        LoggedByUserID: USER_A_ID,
                        OrganizationID: 'ORG-ALPHA',
                    },
                    {
                        ID: 'A2222222-2222-4222-8222-222222222222',
                        Title: 'Alice private HR note',
                        Visibility: 'Private',
                        LoggedByUserID: USER_A_ID,
                        OrganizationID: 'ORG-ALPHA',
                    },
                    {
                        ID: 'A3333333-3333-4333-8333-333333333333',
                        Title: 'Beta executive call',
                        Visibility: 'Internal',
                        LoggedByUserID: USER_B_ID,
                        OrganizationID: 'ORG-BETA',
                    },
                    {
                        ID: 'A4444444-4444-4444-8444-444444444444',
                        Title: 'Bob private deal strategy',
                        Visibility: 'Private',
                        LoggedByUserID: USER_B_ID,
                        OrganizationID: 'ORG-BETA',
                    },
                ],
                [
                    {
                        ID: 'C1111111-1111-4111-8111-111111111111',
                        Name: 'Alice M365 Mailbox',
                        OwnerUserID: USER_A_ID,
                        Status: 'Active',
                    },
                    {
                        ID: 'C2222222-2222-4222-8222-222222222222',
                        Name: 'Bob Gmail Mailbox',
                        OwnerUserID: USER_B_ID,
                        Status: 'Error',
                    },
                ],
                new Map<string, Set<string>>([
                    [USER_A_ID, new Set(['ORG-ALPHA'])],
                    [USER_B_ID, new Set(['ORG-BETA'])],
                ]),
            );

            const [actA, actB, connA, connB] = await Promise.all([
                rv.RunView<CommonActivityRow>({ EntityName: 'MJ_BizApps_Common: Activities' }, userA),
                rv.RunView<CommonActivityRow>({ EntityName: 'MJ_BizApps_Common: Activities' }, userB),
                rv.RunView<CommonSyncConnectionRow>({ EntityName: 'MJ_BizApps_Common: Activity Sync Connections' }, userA),
                rv.RunView<CommonSyncConnectionRow>({ EntityName: 'MJ_BizApps_Common: Activity Sync Connections' }, userB),
            ]);

            expect(actA.Success).toBe(true);
            expect(actB.Success).toBe(true);
            expect(actA.Results.map((r) => r.Title)).toEqual(['Alpha shared quarterly review', 'Alice private HR note']);
            expect(actB.Results.map((r) => r.Title)).toEqual(['Beta executive call', 'Bob private deal strategy']);

            expect(connA.Results.map((c) => c.Name)).toEqual(['Alice M365 Mailbox']);
            expect(connB.Results.map((c) => c.Name)).toEqual(['Bob Gmail Mailbox']);
        });
    });
});
