import '@angular/compiler';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
    CompositeKey,
    IMetadataProvider,
    Metadata,
    RunView,
    RunViewParams,
    RunViewResult,
    TransactionGroupBase,
    TransactionVariable,
    UserInfo,
} from '@memberjunction/core';
import {
    ArtifactMetadataEngine,
    MJArtifactEntity,
    MJArtifactVersionEntity,
    UserInfoEngine,
} from '@memberjunction/core-entities';
import { NormalizeUUID } from '@memberjunction/global';
import type { FormNavigationEvent } from '@memberjunction/ng-base-forms';
import type { NavigationService } from '@memberjunction/ng-shared';
import { CommonEngine, type mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import {
    ARTIFACT_BADGE_FIELDS,
    ActivityArtifactBadgeComponent,
    ActivityComposerComponent,
    ActivityContentPanel,
    CollectDistinctValidArtifactIDs,
    CommonActivitiesPageComponent,
    ExpandActivityToArtifact,
    LinkExistingArtifactToActivity,
    LoadActivityArtifactsByIDs,
    MJ_ARTIFACT_ENTITIES,
    OpenLinkedArtifact,
    ResolveActivityArtifactBadge,
    SaveQuickActivity,
    SearchLinkableArtifacts,
    StripActivityMarkdownExcerpt,
    UnlinkArtifactFromActivity,
    type ActivityArtifactSummary,
    type ActivityDashboardRow,
} from '../public-api';

const ACTIVITY_TYPE_NOTE_ID = '3569BFCA-CF4D-4F3A-ADE8-FE29F2F30A65';
const ACTIVITY_TYPE_CALL_ID = '09233D7A-5A96-4F39-B2BF-177D8B55B220';
const ACTIVITY_TYPE_MEETING_ID = '40E239B0-20C0-4A12-8014-D82EBCE240DC';
const ACTIVITY_TYPE_EMAIL_ID = '5C0674D6-A07B-447B-8755-66BE48B38303';
const ARTIFACT_TYPE_MD_ID = '11111111-2222-3333-4444-555555555555';
const ARTIFACT_ID_1 = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE1';
const ARTIFACT_ID_2 = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE2';
const ARTIFACT_ID_MISSING = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE9';
const ACTIVITY_ID_1 = '99999999-8888-7777-6666-555555555551';
const ACTIVITY_ID_2 = '99999999-8888-7777-6666-555555555552';
const ACTIVITY_ID_3 = '99999999-8888-7777-6666-555555555553';
const USER_ID_1 = '77777777-6666-5555-4444-333333333333';

interface MockActivityRecord {
    ID: string;
    ActivityTypeID: string;
    ActivityType: string;
    Title: string;
    Description: string | null;
    Details: string | null;
    Direction: 'Inbound' | 'Internal' | 'Outbound';
    Status: 'Cancelled' | 'Completed' | 'Failed' | 'Logged' | 'Scheduled';
    Outcome: 'Bounced' | 'Connected' | 'Interested' | 'LeftVoicemail' | 'NoAnswer' | 'NoShow' | 'NotInterested' | null;
    Location: string | null;
    StartedAt: Date;
    EndedAt: Date | null;
    Source: 'Integration' | 'Manual' | 'System';
    SourceSystem: string | null;
    LoggedByUser: string | null;
    ArtifactID: string | null;
    Artifact: string | null;
    IsSaved: boolean;
    TransactionGroup: TransactionGroupBase | null;
    LatestResult: { CompleteMessage: string } | null;
    NewRecord: ReturnType<typeof vi.fn>;
    Load: ReturnType<typeof vi.fn>;
    Save: ReturnType<typeof vi.fn>;
    Delete: ReturnType<typeof vi.fn>;
}

interface MockArtifactRecord {
    ID: string;
    Name: string;
    TypeID: string;
    Visibility: 'Always' | 'System Only';
    Description: string | null;
    UserID: string;
    TransactionGroup: TransactionGroupBase | null;
    LatestResult: { CompleteMessage: string } | null;
    NewRecord: ReturnType<typeof vi.fn>;
    Save: ReturnType<typeof vi.fn>;
    Delete: ReturnType<typeof vi.fn>;
}

interface MockArtifactVersionRecord {
    ID: string;
    ArtifactID: string;
    VersionNumber: number;
    Name: string;
    Content: string | null;
    ContentMode: string;
    UserID: string;
    TransactionGroup: TransactionGroupBase | null;
    LatestResult: { CompleteMessage: string } | null;
    NewRecord: ReturnType<typeof vi.fn>;
    Save: ReturnType<typeof vi.fn>;
    Delete: ReturnType<typeof vi.fn>;
}

function createMockActivity(overrides: Partial<MockActivityRecord> = {}): MockActivityRecord {
    const rec: MockActivityRecord = {
        ID: ACTIVITY_ID_1,
        ActivityTypeID: ACTIVITY_TYPE_NOTE_ID,
        ActivityType: 'Note',
        Title: 'Renewal discovery call',
        Description: 'Discussed Q4 renewal pricing and rollout dates.',
        Details: JSON.stringify({ CallDurationSec: 420 }),
        Direction: 'Outbound',
        Status: 'Logged',
        Outcome: 'Connected',
        Location: null,
        StartedAt: new Date('2026-11-26T15:00:00Z'),
        EndedAt: null,
        Source: 'Manual',
        SourceSystem: null,
        LoggedByUser: 'Alex Rivera',
        ArtifactID: null,
        Artifact: null,
        IsSaved: true,
        TransactionGroup: null,
        LatestResult: null,
        NewRecord: vi.fn(),
        Load: vi.fn().mockResolvedValue(true),
        Save: vi.fn().mockResolvedValue(true),
        Delete: vi.fn().mockResolvedValue(true),
        ...overrides,
    };
    return rec;
}

function createMockArtifact(overrides: Partial<MockArtifactRecord> = {}): MockArtifactRecord {
    return {
        ID: ARTIFACT_ID_1,
        Name: '',
        TypeID: '',
        Visibility: 'Always',
        Description: null,
        UserID: '',
        TransactionGroup: null,
        LatestResult: null,
        NewRecord: vi.fn(),
        Save: vi.fn().mockResolvedValue(true),
        Delete: vi.fn().mockResolvedValue(true),
        ...overrides,
    };
}

function createMockArtifactVersion(overrides: Partial<MockArtifactVersionRecord> = {}): MockArtifactVersionRecord {
    return {
        ID: 'BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF',
        ArtifactID: '',
        VersionNumber: 1,
        Name: '',
        Content: null,
        ContentMode: 'Text',
        UserID: '',
        TransactionGroup: null,
        LatestResult: null,
        NewRecord: vi.fn(),
        Save: vi.fn().mockResolvedValue(true),
        Delete: vi.fn().mockResolvedValue(true),
        ...overrides,
    };
}

interface MockProviderHarness {
    provider: IMetadataProvider;
    requestedEntities: string[];
    runViewCalls: RunViewParams[];
    runViewsCalls: RunViewParams[][];
    activityRecord: MockActivityRecord;
    artifactRecord: MockArtifactRecord;
    versionRecord: MockArtifactVersionRecord;
    tgVariables: TransactionVariable[];
    tgSubmit: ReturnType<typeof vi.fn>;
}

function createProviderHarness(options?: {
    activity?: MockActivityRecord;
    artifact?: MockArtifactRecord;
    version?: MockArtifactVersionRecord;
    supportsTransactionGroup?: boolean;
    tgSubmitResult?: boolean;
    runViewHandler?: (params: RunViewParams) => RunViewResult<ActivityArtifactSummary | ActivityDashboardRow>;
    runViewsHandler?: (paramsList: RunViewParams[]) => RunViewResult<ActivityArtifactSummary>[];
    canReadArtifacts?: boolean;
}): MockProviderHarness {
    const requestedEntities: string[] = [];
    const runViewCalls: RunViewParams[] = [];
    const runViewsCalls: RunViewParams[][] = [];
    const activityRecord = options?.activity ?? createMockActivity();
    const artifactRecord = options?.artifact ?? createMockArtifact();
    const versionRecord = options?.version ?? createMockArtifactVersion();
    const tgVariables: TransactionVariable[] = [];
    const tgSubmit = vi.fn().mockResolvedValue(options?.tgSubmitResult ?? true);

    const mockUser = { ID: USER_ID_1, Name: 'Alex Rivera', Email: 'alex@example.com' } as UserInfo;

    const mockTg = {
        AddVariable: vi.fn((variable: TransactionVariable) => {
            tgVariables.push(variable);
        }),
        Submit: tgSubmit,
    } as TransactionGroupBase;

    const providerObj: Partial<IMetadataProvider> & {
        RunView: (params: RunViewParams) => Promise<RunViewResult<ActivityArtifactSummary | ActivityDashboardRow>>;
        RunViews: (paramsList: RunViewParams[]) => Promise<RunViewResult<ActivityArtifactSummary>[]>;
    } = {
        CurrentUser: mockUser,
        EntityByName: (name: string) =>
            ({
                Name: name,
                GetUserPermisions: () => ({
                    CanRead: name === MJ_ARTIFACT_ENTITIES.Artifact ? options?.canReadArtifacts ?? true : true,
                    CanCreate: true,
                    CanUpdate: true,
                    CanDelete: true,
                }),
            }) as ReturnType<IMetadataProvider['EntityByName']>,
        GetEntityObject: vi.fn(async (entityName: string) => {
            requestedEntities.push(entityName);
            if (entityName === 'MJ_BizApps_Common: Activities') {
                return activityRecord as mjBizAppsCommonActivityEntity;
            }
            if (entityName === MJ_ARTIFACT_ENTITIES.Artifact) {
                return artifactRecord as MJArtifactEntity;
            }
            if (entityName === MJ_ARTIFACT_ENTITIES.ArtifactVersion) {
                return versionRecord as MJArtifactVersionEntity;
            }
            throw new Error(`Unexpected entity requested in test: ${entityName}`);
        }) as IMetadataProvider['GetEntityObject'],
        RunView: vi.fn(async (params: RunViewParams) => {
            runViewCalls.push(params);
            if (options?.runViewHandler) {
                return options.runViewHandler(params);
            }
            return {
                Success: true,
                Results: [],
                UserView: null,
                RowCount: 0,
                TotalRowCount: 0,
                ExecutionTime: 1,
                ErrorMessage: '',
            };
        }),
        RunViews: vi.fn(async (paramsList: RunViewParams[]) => {
            runViewsCalls.push(paramsList);
            if (options?.runViewsHandler) {
                return options.runViewsHandler(paramsList);
            }
            return paramsList.map(() => ({
                Success: true,
                Results: [],
                UserView: null,
                RowCount: 0,
                TotalRowCount: 0,
                ExecutionTime: 1,
                ErrorMessage: '',
            }));
        }),
    };

    if (options?.supportsTransactionGroup !== false) {
        providerObj.CreateTransactionGroup = vi.fn().mockResolvedValue(mockTg);
    }

    const provider = providerObj as IMetadataProvider;

    vi.spyOn(RunView, 'FromMetadataProvider').mockReturnValue({
        RunView: providerObj.RunView,
        RunViews: providerObj.RunViews,
    } as RunView);

    return {
        provider,
        requestedEntities,
        runViewCalls,
        runViewsCalls,
        activityRecord,
        artifactRecord,
        versionRecord,
        tgVariables,
        tgSubmit,
    };
}

describe('Common.Activity Hybrid MJ Doc UI & Fast-Path Capture', () => {
    beforeEach(() => {
        vi.restoreAllMocks();
        vi.spyOn(UserInfoEngine.Instance, 'GetSetting').mockReturnValue(undefined);
        vi.spyOn(UserInfoEngine.Instance, 'SetSettingDebounced').mockImplementation(() => undefined);
        vi.spyOn(ArtifactMetadataEngine.Instance, 'FindArtifactType').mockReturnValue({
            ID: ARTIFACT_TYPE_MD_ID,
            Name: 'Markdown Document',
        } as ReturnType<typeof ArtifactMetadataEngine.Instance.FindArtifactType>);
    });

    afterEach(() => {
        vi.restoreAllMocks();
    });

    describe('Fast-path <2s Activity quick capture (ArtifactID = null)', () => {
        it('persists quick Note, Call, Meeting, and Email activities with null ArtifactID and NEVER creates an MJ: Artifacts record', async () => {
            const cases: Array<{ label: string; typeId: string; dir: 'Internal' | 'Outbound' | 'Inbound' }> = [
                { label: 'Note', typeId: ACTIVITY_TYPE_NOTE_ID, dir: 'Internal' },
                { label: 'Call', typeId: ACTIVITY_TYPE_CALL_ID, dir: 'Outbound' },
                { label: 'Meeting', typeId: ACTIVITY_TYPE_MEETING_ID, dir: 'Internal' },
                { label: 'Email', typeId: ACTIVITY_TYPE_EMAIL_ID, dir: 'Inbound' },
            ];

            for (const item of cases) {
                const harness = createProviderHarness();
                const res = await SaveQuickActivity(
                    {
                        ActivityTypeID: item.typeId,
                        Title: `Quick ${item.label} follow-up`,
                        Description: `Concise ${item.label} notes captured in <2s`,
                        Direction: item.dir,
                    },
                    harness.provider,
                );

                expect(res.Success).toBe(true);
                expect(harness.activityRecord.ArtifactID).toBeNull();
                expect(harness.activityRecord.Description).toBe(`Concise ${item.label} notes captured in <2s`);
                expect(harness.requestedEntities).toEqual(['MJ_BizApps_Common: Activities']);
                expect(harness.requestedEntities).not.toContain(MJ_ARTIFACT_ENTITIES.Artifact);
                expect(harness.requestedEntities).not.toContain(MJ_ARTIFACT_ENTITIES.ArtifactVersion);
                expect(harness.runViewCalls).toHaveLength(0);
                expect(harness.runViewsCalls).toHaveLength(0);
            }
        });

        it('ActivityComposerComponent submits fast-path quick capture with ArtifactID = null and zero MJ: Artifacts calls', async () => {
            const harness = createProviderHarness();
            vi.spyOn(CommonEngine.Instance, 'GetActivityTypeByCode').mockReturnValue(undefined);
            vi.spyOn(CommonEngine.Instance, 'GetActivityTypeByName').mockReturnValue(undefined);

            const composer = new ActivityComposerComponent();
            composer.Provider = harness.provider;
            composer.SelectType('Call');
            composer.Title = 'Called Jane about renewal';
            composer.Description = 'She confirmed budget approval for Q1.';

            const emitted: Array<{ ArtifactID: string | null; TypeLabel: string }> = [];
            composer.ActivityCreated.subscribe((ev) => {
                emitted.push({ ArtifactID: ev.Activity.ArtifactID, TypeLabel: ev.ActivityTypeLabel });
            });

            const ok = await composer.Submit();
            expect(ok).toBe(true);
            expect(emitted).toEqual([{ ArtifactID: null, TypeLabel: 'Call' }]);
            expect(harness.requestedEntities).toEqual(['MJ_BizApps_Common: Activities']);
            expect(harness.artifactRecord.Save).not.toHaveBeenCalled();
            expect(harness.runViewCalls).toHaveLength(0);
            expect(harness.runViewsCalls).toHaveLength(0);
            // Form resets cleanly for next <2s capture
            expect(composer.Title).toBe('');
            expect(composer.Description).toBe('');
            expect(composer.SelectedArtifact).toBeNull();
        });

        it('short-circuits Artifact RunView completely when zero visible Activity items have a non-null ArtifactID', async () => {
            const rows: ActivityDashboardRow[] = [
                {
                    ID: ACTIVITY_ID_1,
                    Title: 'Quick note',
                    Description: 'No doc attached',
                    StartedAt: '2026-11-26T15:00:00Z',
                    EndedAt: null,
                    Direction: 'Internal',
                    Status: 'Logged',
                    Outcome: null,
                    Location: null,
                    ActivityTypeID: ACTIVITY_TYPE_NOTE_ID,
                    ActivityType: 'Note',
                    Source: 'Manual',
                    SourceSystem: null,
                    LoggedByUser: 'Alex Rivera',
                    ArtifactID: null,
                    Artifact: null,
                    __mj_CreatedAt: '2026-11-26T15:00:00Z',
                },
                {
                    ID: ACTIVITY_ID_2,
                    Title: 'Quick call',
                    Description: 'Connected with buyer',
                    StartedAt: '2026-11-26T14:00:00Z',
                    EndedAt: null,
                    Direction: 'Outbound',
                    Status: 'Logged',
                    Outcome: 'Connected',
                    Location: null,
                    ActivityTypeID: ACTIVITY_TYPE_CALL_ID,
                    ActivityType: 'Call',
                    Source: 'Manual',
                    SourceSystem: null,
                    LoggedByUser: 'Alex Rivera',
                    ArtifactID: null,
                    Artifact: null,
                    __mj_CreatedAt: '2026-11-26T14:00:00Z',
                },
            ];

            const harness = createProviderHarness({
                runViewHandler: () => ({
                    Success: true,
                    Results: rows,
                    UserView: null,
                    RowCount: rows.length,
                    TotalRowCount: rows.length,
                    ExecutionTime: 2,
                    ErrorMessage: '',
                }),
            });

            const page = new CommonActivitiesPageComponent(undefined, null, undefined);
            page.Provider = harness.provider;
            await page.LoadActivities();

            // Exactly 1 RunView for Activities, ZERO RunViews for MJ: Artifacts
            expect(harness.runViewCalls).toHaveLength(1);
            expect(harness.runViewCalls[0].EntityName).toBe('MJ_BizApps_Common: Activities');
            expect(harness.runViewsCalls).toHaveLength(0);
            expect(page.GetArtifactBadge(rows[0])).toEqual({ Status: 'none' });
        });
    });

    describe('Batched RunView hydration & graceful degradation', () => {
        it('deduplicates distinct ArtifactIDs case-insensitively and queries canonical MJ: Artifacts with minimal Fields', async () => {
            expect(
                CollectDistinctValidArtifactIDs([
                    null,
                    undefined,
                    '',
                    'not-a-uuid',
                    ARTIFACT_ID_1,
                    ARTIFACT_ID_1.toLowerCase(),
                    ARTIFACT_ID_2,
                ]),
            ).toEqual([ARTIFACT_ID_1, ARTIFACT_ID_2]);

            const harness = createProviderHarness({
                runViewsHandler: () => [
                    {
                        Success: true,
                        Results: [
                            { ID: ARTIFACT_ID_1.toLowerCase(), Name: 'Q4 Executive Brief', Type: 'Markdown Document' },
                            { ID: ARTIFACT_ID_2, Name: 'Renewal Proposal', Type: 'Markdown Document' },
                        ],
                        UserView: null,
                        RowCount: 2,
                        TotalRowCount: 2,
                        ExecutionTime: 3,
                        ErrorMessage: '',
                    },
                ],
            });

            const map = await LoadActivityArtifactsByIDs(
                [null, ARTIFACT_ID_1, ARTIFACT_ID_1.toLowerCase(), ARTIFACT_ID_2, ARTIFACT_ID_MISSING],
                harness.provider,
            );

            expect(harness.runViewsCalls).toHaveLength(1);
            expect(harness.runViewsCalls[0]).toHaveLength(1);
            const query = harness.runViewsCalls[0][0];
            expect(query.EntityName).toBe('MJ: Artifacts');
            expect(query.ResultType).toBe('simple');
            expect(query.CacheLocal).toBe(false);
            expect(query.Fields).toEqual([...ARTIFACT_BADGE_FIELDS]);
            // Deduplicated: ARTIFACT_ID_1 appears only once in ExtraFilter
            const occurrences = (query.ExtraFilter ?? '').split(ARTIFACT_ID_1).length - 1;
            expect(occurrences).toBe(1);

            // Resolved badge matches regardless of UUID casing
            expect(ResolveActivityArtifactBadge(ARTIFACT_ID_1.toUpperCase(), map)).toEqual({
                Status: 'resolved',
                ArtifactID: ARTIFACT_ID_1.toUpperCase(),
                Name: 'Q4 Executive Brief',
                TypeLabel: 'Markdown Document',
            });

            // Missing/deleted/restricted Artifact degrades gracefully with fallback badge state
            expect(ResolveActivityArtifactBadge(ARTIFACT_ID_MISSING, map)).toEqual({
                Status: 'unavailable',
                ArtifactID: ARTIFACT_ID_MISSING,
                FallbackLabel: 'Linked MJ Doc (Unavailable)',
            });
        });

        it('degrades gracefully with zero console.error calls when RunViews fails or user lacks read permission', async () => {
            const consoleErrSpy = vi.spyOn(console, 'error').mockImplementation(() => undefined);

            const deniedHarness = createProviderHarness({ canReadArtifacts: false });
            const deniedMap = await LoadActivityArtifactsByIDs([ARTIFACT_ID_1], deniedHarness.provider);
            expect(deniedMap.size).toBe(0);
            expect(deniedHarness.runViewsCalls).toHaveLength(0);

            const errorHarness = createProviderHarness({
                runViewsHandler: () => {
                    throw new Error('Network unavailable');
                },
            });
            const errorMap = await LoadActivityArtifactsByIDs([ARTIFACT_ID_1], errorHarness.provider);
            expect(errorMap.size).toBe(0);
            expect(ResolveActivityArtifactBadge(ARTIFACT_ID_1, errorMap)).toEqual({
                Status: 'unavailable',
                ArtifactID: ARTIFACT_ID_1,
                FallbackLabel: 'Linked MJ Doc (Unavailable)',
            });
            expect(consoleErrSpy).not.toHaveBeenCalled();
        });
    });

    describe('Opt-in Link, Expand (TransactionGroup & rollback), Unlink, and NavigationService', () => {
        it('supports opt-in searching and linking an existing MJ Doc without altering Description or Details', async () => {
            const existingDocs: ActivityArtifactSummary[] = [
                { ID: ARTIFACT_ID_1, Name: 'Board Deck Brief', Type: 'Markdown Document', Description: '### Agenda\n**Key items**' },
            ];
            const harness = createProviderHarness({
                runViewHandler: () => ({
                    Success: true,
                    Results: existingDocs,
                    UserView: null,
                    RowCount: 1,
                    TotalRowCount: 1,
                    ExecutionTime: 1,
                    ErrorMessage: '',
                }),
            });

            const found = await SearchLinkableArtifacts('Board', harness.provider);
            expect(found).toHaveLength(1);
            expect(harness.runViewCalls[0].EntityName).toBe('MJ: Artifacts');
            expect(harness.runViewCalls[0].ResultType).toBe('simple');

            const originalDesc = harness.activityRecord.Description;
            const originalDetails = harness.activityRecord.Details;
            const linked = await LinkExistingArtifactToActivity(
                harness.activityRecord as mjBizAppsCommonActivityEntity,
                ARTIFACT_ID_1,
                { saveNow: true, artifactName: 'Board Deck Brief' },
            );

            expect(linked.Success).toBe(true);
            expect(harness.activityRecord.ArtifactID).toBe(ARTIFACT_ID_1);
            expect(harness.activityRecord.Description).toBe(originalDesc);
            expect(harness.activityRecord.Details).toBe(originalDetails);
        });

        it('opt-in expands an Activity into a linked MJ Doc atomically via TransactionGroup', async () => {
            const harness = createProviderHarness({ supportsTransactionGroup: true, tgSubmitResult: true });
            const originalDesc = harness.activityRecord.Description;
            const originalDetails = harness.activityRecord.Details;

            const result = await ExpandActivityToArtifact(
                harness.activityRecord as mjBizAppsCommonActivityEntity,
                { Provider: harness.provider },
            );

            expect(result.Success).toBe(true);
            expect(result.ArtifactID).toBe(ARTIFACT_ID_1);
            expect(harness.tgSubmit).toHaveBeenCalledTimes(1);
            expect(harness.tgVariables).toHaveLength(3);
            expect(harness.tgVariables[0].Type).toBe('Define');
            expect(harness.tgVariables[1].Type).toBe('Use');
            expect(harness.tgVariables[2].Type).toBe('Use');
            expect(harness.activityRecord.ArtifactID).toBe(ARTIFACT_ID_1);
            expect(harness.activityRecord.Description).toBe(originalDesc);
            expect(harness.activityRecord.Details).toBe(originalDetails);
            expect(harness.artifactRecord.TransactionGroup).toBeNull();
            expect(harness.versionRecord.TransactionGroup).toBeNull();
            expect(harness.activityRecord.TransactionGroup).toBeNull();
        });

        it('rolls back cleanly when TransactionGroup.Submit() fails so Activity.ArtifactID stays null', async () => {
            const harness = createProviderHarness({ supportsTransactionGroup: true, tgSubmitResult: false });

            const result = await ExpandActivityToArtifact(
                harness.activityRecord as mjBizAppsCommonActivityEntity,
                { Provider: harness.provider },
            );

            expect(result.Success).toBe(false);
            expect(result.RolledBack).toBe(true);
            expect(harness.activityRecord.ArtifactID).toBeNull();
        });

        it('deletes newly created Artifact and Version via compensating rollback if Activity.Save() fails without TransactionGroup', async () => {
            const failingActivity = createMockActivity({
                ArtifactID: null,
                Save: vi.fn().mockResolvedValue(false),
                LatestResult: { CompleteMessage: 'Activity concurrency failure' },
            });
            const harness = createProviderHarness({
                activity: failingActivity,
                supportsTransactionGroup: false,
            });

            const result = await ExpandActivityToArtifact(
                failingActivity as mjBizAppsCommonActivityEntity,
                { Provider: harness.provider },
            );

            expect(result.Success).toBe(false);
            expect(result.RolledBack).toBe(true);
            expect(failingActivity.ArtifactID).toBeNull();
            expect(harness.versionRecord.Delete).toHaveBeenCalledTimes(1);
            expect(harness.artifactRecord.Delete).toHaveBeenCalledTimes(1);
        });

        it('unlinks MJ Doc by setting ArtifactID = null while strictly preserving Description and Details', async () => {
            const linkedActivity = createMockActivity({
                ArtifactID: ARTIFACT_ID_1,
                Description: 'Keep these meeting notes intact!',
                Details: JSON.stringify({ MeetingURL: 'https://meet.example.com/abc' }),
            });
            const result = await UnlinkArtifactFromActivity(linkedActivity as mjBizAppsCommonActivityEntity, {
                saveNow: true,
            });

            expect(result.Success).toBe(true);
            expect(linkedActivity.ArtifactID).toBeNull();
            expect(linkedActivity.Description).toBe('Keep these meeting notes intact!');
            expect(linkedActivity.Details).toBe(JSON.stringify({ MeetingURL: 'https://meet.example.com/abc' }));
        });

        it('ActivityContentPanel supports link, expand, unlink, and NavigationService open', async () => {
            const activity = createMockActivity({ ArtifactID: null });
            const harness = createProviderHarness({ activity, supportsTransactionGroup: true, tgSubmitResult: true });
            const openArtifact = vi.fn();
            const navStub = { OpenArtifact: openArtifact } as NavigationService;

            const panel = new ActivityContentPanel(undefined, navStub);
            panel.Provider = harness.provider;
            panel.Record = activity as mjBizAppsCommonActivityEntity;
            panel.ngOnInit();

            // Initially unlinked, zero MJ: Artifacts RunView calls
            expect(panel.ArtifactBadge).toEqual({ Status: 'none' });
            expect(harness.runViewsCalls).toHaveLength(0);

            // Opt-in expand
            const expanded = await panel.ExpandToArtifact();
            expect(expanded).toBe(true);
            expect(panel.ArtifactBadge.Status).toBe('resolved');

            // Clicking badge navigates via NavigationService.OpenArtifact
            panel.OnOpenLinkedDoc({ ArtifactID: ARTIFACT_ID_1, Name: 'Renewal discovery call' });
            expect(openArtifact).toHaveBeenCalledWith(ARTIFACT_ID_1, 'Renewal discovery call');

            // Unlink preserves Description and resets badge
            const unlinked = await panel.UnlinkArtifact();
            expect(unlinked).toBe(true);
            expect(activity.ArtifactID).toBeNull();
            expect(activity.Description).toBe('Discussed Q4 renewal pricing and rollout dates.');
            expect(panel.ArtifactBadge).toEqual({ Status: 'none' });
        });

        it('navigates via NavigationService.OpenArtifact, OpenEntityRecord, or FormNavigationEvent fallback', () => {
            const openArtifact = vi.fn();
            const openEntityRecord = vi.fn();
            const formNavEvents: FormNavigationEvent[] = [];

            expect(
                OpenLinkedArtifact(ARTIFACT_ID_1, 'Exec Brief', { OpenArtifact: openArtifact } as NavigationService),
            ).toBe(true);
            expect(openArtifact).toHaveBeenCalledWith(ARTIFACT_ID_1, 'Exec Brief');

            expect(
                OpenLinkedArtifact(ARTIFACT_ID_2, 'Spec Doc', { OpenEntityRecord: openEntityRecord } as NavigationService),
            ).toBe(true);
            expect(openEntityRecord).toHaveBeenCalledWith(
                'MJ: Artifacts',
                expect.objectContaining({ KeyValuePairs: CompositeKey.FromID(ARTIFACT_ID_2).KeyValuePairs }),
            );

            expect(
                OpenLinkedArtifact(ARTIFACT_ID_1, 'Exec Brief', null, (ev) => formNavEvents.push(ev)),
            ).toBe(true);
            expect(formNavEvents).toHaveLength(1);
            expect(formNavEvents[0].Kind).toBe('record');
            expect(formNavEvents[0].EntityName).toBe('MJ: Artifacts');

            // Badge component emits OpenDoc and UnlinkDoc cleanly
            const badge = new ActivityArtifactBadgeComponent();
            badge.Badge = { Status: 'resolved', ArtifactID: ARTIFACT_ID_1, Name: 'Exec Brief', TypeLabel: 'Markdown Document' };
            const opened: Array<{ ArtifactID: string; Name: string }> = [];
            const unlinked: string[] = [];
            badge.OpenDoc.subscribe((ev) => opened.push(ev));
            badge.UnlinkDoc.subscribe((id) => unlinked.push(id));

            const clickEv = { stopPropagation: vi.fn() } as MouseEvent;
            badge.OnOpen(clickEv);
            badge.OnUnlink(clickEv);
            expect(opened).toEqual([{ ArtifactID: ARTIFACT_ID_1, Name: 'Exec Brief' }]);
            expect(unlinked).toEqual([ARTIFACT_ID_1]);
        });

        it('strips raw Markdown syntax from Activity card excerpts so feed cards never leak raw Markdown', () => {
            const raw = '### Executive Summary\n**Action Items:**\n- Review `contract.pdf`\n> Approved by [VP Finance](https://example.com)\n```ts\nconst x = 1;\n```';
            const clean = StripActivityMarkdownExcerpt(raw);
            expect(clean).not.toContain('###');
            expect(clean).not.toContain('**');
            expect(clean).not.toContain('```');
            expect(clean).not.toContain('](');
            expect(clean).toContain('Executive Summary');
            expect(clean).toContain('Action Items:');
            expect(clean).toContain('VP Finance');
        });

        it('CommonActivitiesPageComponent hydrates mixed linked/unlinked rows and opens linked MJ Doc via NavigationService', async () => {
            const rows: ActivityDashboardRow[] = [
                {
                    ID: ACTIVITY_ID_1,
                    Title: 'Quarterly Business Review',
                    Description: '### QBR Notes\n**Key takeaway:** expansion ready',
                    StartedAt: '2026-11-26T16:00:00Z',
                    EndedAt: null,
                    Direction: 'Outbound',
                    Status: 'Completed',
                    Outcome: 'Interested',
                    Location: 'Zoom',
                    ActivityTypeID: ACTIVITY_TYPE_MEETING_ID,
                    ActivityType: 'Meeting',
                    Source: 'Manual',
                    SourceSystem: null,
                    LoggedByUser: 'Alex Rivera',
                    ArtifactID: ARTIFACT_ID_1,
                    Artifact: 'Q4 Executive Brief',
                    __mj_CreatedAt: '2026-11-26T16:00:00Z',
                },
                {
                    ID: ACTIVITY_ID_2,
                    Title: 'Restricted Doc Call',
                    Description: 'Linked to restricted doc',
                    StartedAt: '2026-11-26T15:00:00Z',
                    EndedAt: null,
                    Direction: 'Inbound',
                    Status: 'Logged',
                    Outcome: null,
                    Location: null,
                    ActivityTypeID: ACTIVITY_TYPE_CALL_ID,
                    ActivityType: 'Call',
                    Source: 'Manual',
                    SourceSystem: null,
                    LoggedByUser: 'Alex Rivera',
                    ArtifactID: ARTIFACT_ID_MISSING,
                    Artifact: null,
                    __mj_CreatedAt: '2026-11-26T15:00:00Z',
                },
                {
                    ID: ACTIVITY_ID_3,
                    Title: 'Quick follow-up note',
                    Description: 'No doc attached',
                    StartedAt: '2026-11-26T14:00:00Z',
                    EndedAt: null,
                    Direction: 'Internal',
                    Status: 'Logged',
                    Outcome: null,
                    Location: null,
                    ActivityTypeID: ACTIVITY_TYPE_NOTE_ID,
                    ActivityType: 'Note',
                    Source: 'Manual',
                    SourceSystem: null,
                    LoggedByUser: 'Alex Rivera',
                    ArtifactID: null,
                    Artifact: null,
                    __mj_CreatedAt: '2026-11-26T14:00:00Z',
                },
            ];

            const harness = createProviderHarness({
                runViewHandler: () => ({
                    Success: true,
                    Results: rows,
                    UserView: null,
                    RowCount: rows.length,
                    TotalRowCount: rows.length,
                    ExecutionTime: 2,
                    ErrorMessage: '',
                }),
                runViewsHandler: () => [
                    {
                        Success: true,
                        Results: [{ ID: ARTIFACT_ID_1, Name: 'Q4 Executive Brief', Type: 'Markdown Document' }],
                        UserView: null,
                        RowCount: 1,
                        TotalRowCount: 1,
                        ExecutionTime: 2,
                        ErrorMessage: '',
                    },
                ],
            });

            const openArtifact = vi.fn();
            const page = new CommonActivitiesPageComponent(
                undefined,
                null,
                { OpenArtifact: openArtifact } as NavigationService,
            );
            page.Provider = harness.provider;

            await page.LoadActivities();
            expect(harness.runViewsCalls).toHaveLength(1);
            expect(page.HydratedArtifacts.get(NormalizeUUID(ARTIFACT_ID_1))?.Name).toBe('Q4 Executive Brief');

            expect(page.GetArtifactBadge(rows[0])).toEqual({
                Status: 'resolved',
                ArtifactID: ARTIFACT_ID_1,
                Name: 'Q4 Executive Brief',
                TypeLabel: 'Markdown Document',
            });
            expect(page.GetArtifactBadge(rows[1])).toEqual({
                Status: 'unavailable',
                ArtifactID: ARTIFACT_ID_MISSING,
                FallbackLabel: 'Linked MJ Doc (Unavailable)',
            });
            expect(page.GetArtifactBadge(rows[2])).toEqual({ Status: 'none' });

            // Card excerpt never leaks raw Markdown
            const excerpt = page.FormatCardExcerpt(rows[0].Description);
            expect(excerpt).toBe('QBR Notes Key takeaway: expansion ready');
            expect(excerpt).not.toContain('###');
            expect(excerpt).not.toContain('**');

            // Clicking badge opens linked MJ Doc via NavigationService
            page.OnOpenLinkedDoc({ ArtifactID: ARTIFACT_ID_1, Name: 'Q4 Executive Brief' });
            expect(openArtifact).toHaveBeenCalledWith(ARTIFACT_ID_1, 'Q4 Executive Brief');
        });
    });

    describe('Provider ambient fallback safety', () => {
        it('uses Metadata.Provider when explicit provider is omitted', async () => {
            const harness = createProviderHarness();
            const prevProvider = Metadata.Provider;
            Metadata.Provider = harness.provider;
            try {
                const res = await SaveQuickActivity({
                    ActivityTypeID: ACTIVITY_TYPE_NOTE_ID,
                    Title: 'Ambient provider note',
                    Description: 'Saved without explicit provider arg',
                    Direction: 'Internal',
                });
                expect(res.Success).toBe(true);
                expect(harness.activityRecord.ArtifactID).toBeNull();
            } finally {
                Metadata.Provider = prevProvider;
            }
        });
    });
});
