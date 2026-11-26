/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type {
    EntityFieldState,
    EntityInfo,
    EntitySaveOptions,
    IEntityDataProvider,
    IRunViewProvider,
    RunViewParams,
    RunViewResult,
    UserInfo,
} from '@memberjunction/core';
import { MJGlobal, NormalizeUUID, UUIDsEqual } from '@memberjunction/global';

type FieldPrimitive = string | number | boolean | Date | null;

interface StoredActivityRow {
    ID: string;
    ActivityTypeID: string;
    StartedAt: Date;
    EndedAt: Date | null;
    Title: string;
    Description: string | null;
    Direction: 'Inbound' | 'Internal' | 'Outbound';
    Status: 'Cancelled' | 'Completed' | 'Failed' | 'Logged' | 'Scheduled';
    Outcome: 'Bounced' | 'Connected' | 'Interested' | 'LeftVoicemail' | 'NoAnswer' | 'NoShow' | 'NotInterested' | null;
    Visibility: 'Internal' | 'Private';
    Source: 'Integration' | 'Manual' | 'System';
    LoggedByUserID: string;
    Details: string | null;
    ArtifactID: string | null;
}

class FakeEntityField {
    public readonly Name: string;
    public readonly CodeName: string;
    public OldValue: FieldPrimitive = null;
    public Value: FieldPrimitive = null;
    public NotLoaded = false;

    constructor(name: string, initial: FieldPrimitive = null) {
        this.Name = name;
        this.CodeName = name;
        this.OldValue = initial;
        this.Value = initial;
    }

    public get Dirty(): boolean {
        return this.Value !== this.OldValue;
    }

    public GetState(): EntityFieldState {
        return {
            Value: this.Value,
            OldValue: this.OldValue,
            NeverSet: false,
            NotLoaded: this.NotLoaded,
            WrittenAfterNotLoaded: false,
        };
    }

    public RestoreState(state: EntityFieldState): void {
        this.Value = state.Value as FieldPrimitive;
        this.OldValue = state.OldValue as FieldPrimitive;
        this.NotLoaded = state.NotLoaded;
    }
}

interface EntityRecordLike {
    EntityInfo: EntityInfo;
}

interface TestActivityProvider extends IEntityDataProvider, IRunViewProvider {
    ProviderType: ProviderType;
    CurrentUser?: UserInfo;
    GetEntityObject<T>(entityName: string, contextUser?: UserInfo): Promise<T>;
    SaveEntityRecord(entity: EntityRecordLike): Promise<boolean>;
    DeleteEntityRecord(entity: EntityRecordLike): Promise<boolean>;
    RunView<T>(params: RunViewParams, contextUser?: UserInfo): Promise<RunViewResult<T>>;
}

const hoisted = vi.hoisted(() => ({
    nextId: 1,
}));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();

    class FakeBaseEntity {
        public EntityInfo: EntityInfo;
        public Fields: FakeEntityField[] = [];
        public IsSaved = false;
        public ProviderToUse: TestActivityProvider | null = null;
        public RunViewProviderToUse: IRunViewProvider | null = null;
        public ContextCurrentUser: UserInfo | undefined = undefined;
        public readonly ResultHistory: InstanceType<typeof actual.BaseEntityResult>[] = [];

        constructor(entityInfo?: EntityInfo, provider?: TestActivityProvider | null) {
            this.EntityInfo = entityInfo ?? ({ Name: 'FakeEntity' } as EntityInfo);
            if (provider) {
                this.ProviderToUse = provider;
                this.RunViewProviderToUse = provider;
            }
        }

        protected DeclareRelatedRecords<T>(_opts: object): { Items: T[] } {
            return { Items: [] };
        }

        public get Dirty(): boolean {
            return this.Fields.some((f) => f.Dirty);
        }

        public GetFieldByName(name: string): FakeEntityField | undefined {
            return this.Fields.find((f) => f.Name === name);
        }

        protected Get(name: string): FieldPrimitive {
            return this.GetFieldByName(name)?.Value ?? null;
        }

        protected Set(name: string, value: FieldPrimitive): void {
            let field = this.GetFieldByName(name);
            if (!field) {
                field = new FakeEntityField(name, null);
                this.Fields.push(field);
            }
            field.Value = value;
        }

        public NewRecord(): boolean {
            this.IsSaved = false;
            for (const f of this.Fields) {
                f.Value = null;
                f.OldValue = null;
            }
            return true;
        }

        public async LoadFromData(
            values: Record<string, FieldPrimitive>,
            replaceOldValues = false,
        ): Promise<boolean> {
            this.Fields = Object.entries(values).map(([k, v]) => new FakeEntityField(k, v));
            if (replaceOldValues) {
                this.IsSaved = true;
            }
            return true;
        }

        public Validate(): InstanceType<typeof actual.ValidationResult> {
            const result = new actual.ValidationResult();
            result.Success = true;
            return result;
        }

        public async Save(_options?: EntitySaveOptions): Promise<boolean> {
            const val = this.Validate();
            if (!val.Success) {
                return false;
            }
            if (!this.ProviderToUse) {
                return true;
            }
            const ok = await this.ProviderToUse.SaveEntityRecord(this);
            if (ok) {
                this.IsSaved = true;
                for (const f of this.Fields) {
                    f.OldValue = f.Value;
                }
            }
            return ok;
        }

        public async Delete(): Promise<boolean> {
            if (!this.ProviderToUse) {
                return true;
            }
            const ok = await this.ProviderToUse.DeleteEntityRecord(this);
            if (ok) {
                this.IsSaved = false;
            }
            return ok;
        }
    }

    return {
        ...actual,
        BaseEntity: FakeBaseEntity,
    };
});

import { BaseEntity, ProviderType } from '@memberjunction/core';
import {
    LoadGeneratedEntities,
    mjBizAppsCommonActivityEntity,
    mjBizAppsCommonActivitySchema,
    type mjBizAppsCommonActivityEntityType,
} from '../index.js';

const ACTIVITIES_ENTITY_NAME = 'MJ_BizApps_Common: Activities';
const ARTIFACTS_ENTITY_NAME = 'MJ: Artifacts';

const USER_ID = '11111111-1111-4111-8111-111111111111';
const NOTE_TYPE_ID = '22222222-2222-4222-8222-222222222222';
const MEETING_TYPE_ID = '33333333-3333-4333-8333-333333333333';
const ARTIFACT_ID = '44444444-4444-4444-8444-444444444444';

const MIGRATIONS_DIR = fileURLToPath(new URL('../../../../migrations/', import.meta.url));
const MIGRATIONS_PG_DIR = fileURLToPath(new URL('../../../../migrations-pg/', import.meta.url));

function findLatestMigration(dir: string, pattern: RegExp): string {
    const match = readdirSync(dir)
        .filter((f) => pattern.test(f))
        .sort()
        .pop();
    if (!match) {
        throw new Error(`No migration matching ${pattern} in ${dir}`);
    }
    return match;
}

class InMemoryActivityStore {
    public readonly Activities = new Map<string, StoredActivityRow>();
    public readonly RequestedEntityNames: string[] = [];
    public readonly SavedEntityNames: string[] = [];

    public CreateProvider(): TestActivityProvider {
        const store = this;
        const provider: TestActivityProvider = {
            ProviderType: ProviderType.Database,
            CurrentUser: { ID: USER_ID } as UserInfo,
            Config: async () => true,
            Load: async () => ({}),
            Save: async () => ({}),
            Delete: async () => true,
            GetRecordChanges: async () => [],
            RunViews: async () => [],
            FullTextSearch: async () => ({
                Success: true,
                Results: [],
                TotalCount: 0,
                EntitiesSearched: 0,
                ElapsedMs: 0,
            }),
            SearchEntity: async () => [],
            SearchEntities: async () => [],
            GetEntityObject: async <T>(entityName: string): Promise<T> => {
                store.RequestedEntityNames.push(entityName);
                const entity = new mjBizAppsCommonActivityEntity({ Name: entityName } as EntityInfo);
                Object.assign(entity, {
                    ProviderToUse: provider,
                    RunViewProviderToUse: provider,
                });
                return entity as T;
            },
            SaveEntityRecord: async (entity): Promise<boolean> => {
                const name = entity.EntityInfo?.Name ?? '';
                store.SavedEntityNames.push(name);
                if (name === ACTIVITIES_ENTITY_NAME) {
                    const act = entity as mjBizAppsCommonActivityEntity;
                    if (!act.ID) {
                        act.ID = `90000000-0000-4000-8000-${String(hoisted.nextId++).padStart(12, '0')}`;
                    }
                    const row: StoredActivityRow = {
                        ID: act.ID,
                        ActivityTypeID: act.ActivityTypeID,
                        StartedAt: act.StartedAt,
                        EndedAt: act.EndedAt ?? null,
                        Title: act.Title,
                        Description: act.Description ?? null,
                        Direction: act.Direction,
                        Status: act.Status,
                        Outcome: act.Outcome ?? null,
                        Visibility: act.Visibility,
                        Source: act.Source,
                        LoggedByUserID: act.LoggedByUserID,
                        Details: act.Details ?? null,
                        ArtifactID: act.ArtifactID ?? null,
                    };
                    store.Activities.set(NormalizeUUID(row.ID), row);
                    return true;
                }
                return true;
            },
            DeleteEntityRecord: async (entity): Promise<boolean> => {
                if (entity.EntityInfo?.Name === ACTIVITIES_ENTITY_NAME) {
                    const act = entity as mjBizAppsCommonActivityEntity;
                    if (act.ID) {
                        store.Activities.delete(NormalizeUUID(act.ID));
                    }
                }
                return true;
            },
            RunView: async <T>(): Promise<RunViewResult<T>> => ({
                Success: true,
                Results: [],
                RowCount: 0,
                TotalRowCount: 0,
                ExecutionTime: 0,
                ErrorMessage: '',
            }),
        };
        return provider;
    }
}

describe('Common.Activity ArtifactID (Category B Hybrid Spine)', () => {
    let store: InMemoryActivityStore;
    let provider: TestActivityProvider;

    beforeEach(() => {
        hoisted.nextId = 1;
        store = new InMemoryActivityStore();
        provider = store.CreateProvider();
    });

    afterEach(() => {
        vi.restoreAllMocks();
    });

    describe('Generated entity & Zod schema contract', () => {
        it('registers mjBizAppsCommonActivityEntity in MJ ClassFactory', () => {
            LoadGeneratedEntities();
            const reg = MJGlobal.Instance.ClassFactory.GetRegistration(BaseEntity, ACTIVITIES_ENTITY_NAME);
            expect(reg).toBeDefined();
            expect(reg?.SubClass).toBe(mjBizAppsCommonActivityEntity);
        });

        it('validates Activity payloads with null ArtifactID (fast path) and linked ArtifactID while preserving Description and Details', () => {
            const now = new Date('2026-11-26T18:00:00Z');
            const basePayload: mjBizAppsCommonActivityEntityType = {
                ID: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
                ActivityTypeID: NOTE_TYPE_ID,
                StartedAt: now,
                EndedAt: null,
                Title: 'Quick discovery call notes',
                Description: 'Discussed Q1 renewal scope and key stakeholders.',
                Direction: 'Outbound',
                Status: 'Logged',
                Outcome: 'Connected',
                Visibility: 'Internal',
                Source: 'Manual',
                SourceSystem: null,
                ExternalID: null,
                ExternalThreadID: null,
                ParentActivityID: null,
                LoggedByUserID: USER_ID,
                Location: null,
                AddressID: null,
                ActivitySyncConnectionID: null,
                Details: JSON.stringify({ MeetingURL: 'https://example.test/meet/123' }),
                __mj_CreatedAt: now,
                __mj_UpdatedAt: now,
                SentimentScore: 0.75,
                ArtifactID: null,
                ActivityType: 'Call',
                ParentActivity: null,
                LoggedByUser: 'Account Executive',
                Address: null,
                ActivitySyncConnection: null,
                Artifact: null,
                RootParentActivityID: null,
                ParentActivityIDDepth: 0,
                ParentActivityIDPath: null,
                ParentActivityIDIsLeaf: true,
                ParentActivityIDChildCount: 0,
            };

            const fastPathParsed = mjBizAppsCommonActivitySchema.parse(basePayload);
            expect(fastPathParsed.ArtifactID).toBeNull();
            expect(fastPathParsed.Artifact).toBeNull();
            expect(fastPathParsed.Description).toBe('Discussed Q1 renewal scope and key stakeholders.');
            expect(fastPathParsed.Details).toContain('MeetingURL');

            const linkedPayload: mjBizAppsCommonActivityEntityType = {
                ...basePayload,
                ActivityTypeID: MEETING_TYPE_ID,
                Title: 'Executive QBR Brief',
                ArtifactID: ARTIFACT_ID,
                Artifact: 'Q4 Executive Briefing Doc',
            };
            const linkedParsed = mjBizAppsCommonActivitySchema.parse(linkedPayload);
            expect(UUIDsEqual(linkedParsed.ArtifactID, ARTIFACT_ID)).toBe(true);
            expect(linkedParsed.Artifact).toBe('Q4 Executive Briefing Doc');
        });
    });

    describe('Activity fast-path persistence (ArtifactID = null) & opt-in Artifact linking', () => {
        it('persists quick Note/Call/Meeting/Email capture with ArtifactID = null without ever creating an MJ: Artifacts record', async () => {
            const activity = await provider.GetEntityObject<mjBizAppsCommonActivityEntity>(ACTIVITIES_ENTITY_NAME);
            activity.NewRecord();
            activity.ActivityTypeID = NOTE_TYPE_ID;
            activity.StartedAt = new Date('2026-11-26T18:10:00Z');
            activity.Title = 'Quick follow-up call';
            activity.Description = 'Confirmed timeline; sending revised SOW tomorrow.';
            activity.Details = JSON.stringify({ MeetingURL: 'https://example.test/call/42' });
            activity.Direction = 'Outbound';
            activity.Status = 'Logged';
            activity.Visibility = 'Internal';
            activity.Source = 'Manual';
            activity.LoggedByUserID = USER_ID;

            expect(activity.ArtifactID).toBeNull();
            const saved = await activity.Save();
            expect(saved).toBe(true);

            const stored = store.Activities.get(NormalizeUUID(activity.ID));
            expect(stored).toBeDefined();
            expect(stored?.ArtifactID).toBeNull();
            expect(stored?.Description).toBe('Confirmed timeline; sending revised SOW tomorrow.');
            expect(stored?.Details).toBe(JSON.stringify({ MeetingURL: 'https://example.test/call/42' }));

            // Fast path must NEVER request or save an MJ: Artifacts record automatically
            expect(store.RequestedEntityNames).not.toContain(ARTIFACTS_ENTITY_NAME);
            expect(store.SavedEntityNames).toEqual([ACTIVITIES_ENTITY_NAME]);
        });

        it('persists an opt-in linked ArtifactID and supports cleanly unlinking back to null', async () => {
            const activity = await provider.GetEntityObject<mjBizAppsCommonActivityEntity>(ACTIVITIES_ENTITY_NAME);
            activity.NewRecord();
            activity.ActivityTypeID = MEETING_TYPE_ID;
            activity.StartedAt = new Date('2026-11-26T19:00:00Z');
            activity.Title = 'Architecture Steering Review';
            activity.Description = 'Summary excerpt of the architecture review.';
            activity.Direction = 'Internal';
            activity.Status = 'Completed';
            activity.Visibility = 'Internal';
            activity.Source = 'Manual';
            activity.LoggedByUserID = USER_ID;
            activity.ArtifactID = ARTIFACT_ID;

            expect(await activity.Save()).toBe(true);
            const afterLink = store.Activities.get(NormalizeUUID(activity.ID));
            expect(UUIDsEqual(afterLink?.ArtifactID, ARTIFACT_ID)).toBe(true);

            // Opt-out / unlink sets ArtifactID back to null without touching Description
            activity.ArtifactID = null;
            expect(await activity.Save()).toBe(true);
            const afterUnlink = store.Activities.get(NormalizeUUID(activity.ID));
            expect(afterUnlink?.ArtifactID).toBeNull();
            expect(afterUnlink?.Description).toBe('Summary excerpt of the architecture review.');
        });
    });

    describe('4-part T-SQL migration & deterministic PostgreSQL parity/provenance contract', () => {
        const tsFile = findLatestMigration(MIGRATIONS_DIR, /__Activity_ArtifactID\.sql$/);
        const tsRaw = readFileSync(MIGRATIONS_DIR + tsFile, 'utf8');
        const tsParts = tsRaw.split(
            /-- =============================================================================\r?\n-- GENERATED BY MemberJunction CodeGen/,
        );
        const tsHand = tsParts[0] ?? '';
        const tsCodeGen = tsParts[1] ?? '';
        const tsHandFlat = tsHand.replace(/\s+/g, ' ');

        const pgFile = findLatestMigration(MIGRATIONS_PG_DIR, /__Activity_ArtifactID\.pg\.sql$/);
        const pgRaw = readFileSync(MIGRATIONS_PG_DIR + pgFile, 'utf8');
        const pgFlat = pgRaw.replace(/\s+/g, ' ');

        it('ships paired T-SQL and PostgreSQL migrations at the exact same version stamp', () => {
            expect(pgFile.replace(/\.pg\.sql$/, '.sql')).toBe(tsFile);
        });

        it('separates hand-written DDL from CodeGen block with at least 50 blank lines and zero existence guards', () => {
            expect(tsParts.length).toBe(2);
            const trailingNewlines = tsHand.match(/\n+$/);
            const blankLines = trailingNewlines ? trailingNewlines[0].length - 1 : 0;
            expect(blankLines).toBeGreaterThanOrEqual(50);
            expect(tsHandFlat).not.toMatch(/\bIF (OBJECT_ID|COL_LENGTH)\(/i);
            expect(tsHandFlat).not.toMatch(/\bIF NOT EXISTS\b/i);
        });

        it('obeys PUBLISH_NO_BREAK_POLICY.md: strictly additive with zero drops, renames, or narrowings', () => {
            expect(tsHandFlat).toContain('ALTER TABLE [${flyway:defaultSchema}].[Activity] ADD [ArtifactID] UNIQUEIDENTIFIER NULL;');
            expect(tsHandFlat).toContain(
                'ADD CONSTRAINT [FK_Activity_Artifact] FOREIGN KEY ([ArtifactID]) REFERENCES [${mjSchema}].[Artifact]([ID]);',
            );
            expect(tsHandFlat).toContain(
                'CREATE NONCLUSTERED INDEX [IDX_AUTO_MJ_FKEY_Activity_ArtifactID] ON [${flyway:defaultSchema}].[Activity] ([ArtifactID]) WHERE [ArtifactID] IS NOT NULL;',
            );
            expect(tsHandFlat).toContain("@level1name = N'Activity'");
            expect(tsHandFlat).toContain("@level2name = N'ArtifactID'");

            expect(tsHandFlat).not.toMatch(/\bDROP\s+COLUMN\b/i);
            expect(tsHandFlat).not.toMatch(/\bsp_rename\b/i);
            expect(tsHandFlat).not.toMatch(/\bALTER\s+COLUMN\b/i);
        });

        it('includes CodeGen EntityField metadata with dynamic Sequence, vwActivities, spCreateActivity, spUpdateActivity, and zero spDeleteUnneededEntityFields', () => {
            expect(tsCodeGen).toContain("'ArtifactID'");
            expect(tsCodeGen).toContain('COALESCE(MAX([Sequence]), 0) + 1');
            expect(tsCodeGen).toContain('vwActivities');
            expect(tsCodeGen).toContain('spCreateActivity');
            expect(tsCodeGen).toContain('spUpdateActivity');
            expect(tsCodeGen).toContain('@ArtifactID');
            expect(tsCodeGen).not.toMatch(/spDeleteUnneededEntityFields/i);
        });

        it('carries a valid split-bake v1 line-1 provenance header matching the T-SQL source SHA-256', () => {
            const firstLine = pgRaw.split(/\r?\n/, 1)[0] ?? '';
            const expectedSha = createHash('sha256').update(readFileSync(MIGRATIONS_DIR + tsFile)).digest('hex');
            const match = firstLine.match(
                /^-- @mj-pg-provenance: split-bake v1 source=([^\s]+) source-sha256=([0-9a-f]{64}) mode=(baked|needs-hand-rebaked)$/,
            );
            expect(match, `Invalid line-1 provenance header: ${firstLine}`).not.toBeNull();
            expect(match?.[1]).toBe(tsFile);
            expect(match?.[2]).toBe(expectedSha);
        });

        it('applies lowercase __mj_bizappscommon schema, nullable ArtifactID FK, filtered partial index, COMMENT ON COLUMN, and baked PG CodeGen objects', () => {
            expect(pgFlat).not.toContain('"__mj_BizAppsCommon"');
            expect(pgFlat).toMatch(/ALTER TABLE __mj_bizappscommon\."Activity"\s+ADD COLUMN "ArtifactID" UUID NULL/i);
            expect(pgFlat).toMatch(
                /ADD CONSTRAINT "FK_Activity_Artifact"\s+FOREIGN KEY \("ArtifactID"\) REFERENCES (?:"?\$\{mjSchema\}"?|"?__mj"?)\."Artifact"\s*\(\s*"ID"\s*\)/i,
            );
            expect(pgFlat).toMatch(
                /CREATE INDEX(?:\s+IF NOT EXISTS)? "IDX_AUTO_MJ_FKEY_Activity_ArtifactID"\s+ON __mj_bizappscommon\."Activity"\s*\("ArtifactID"\)\s*WHERE\s*(?:\(?"ArtifactID" IS NOT NULL\)?|NOT "ArtifactID" IS NULL)/i,
            );
            expect(pgFlat).toContain('COMMENT ON COLUMN __mj_bizappscommon."Activity"."ArtifactID"');
            expect(pgFlat).toContain('spUpdateEntityFieldRelatedEntityNameFieldMap');
            expect(pgFlat).toContain('vwActivities');
            expect(pgFlat).toContain('spCreateActivity');
            expect(pgFlat).toContain('spUpdateActivity');
            expect(pgFlat).toMatch(/p_ArtifactID|p_artifactid/i);
        });
    });

    describe('Executable relational FK & filtered-index semantics (node:sqlite)', () => {
        it('supports null ArtifactID fast path, rejects dangling FK values, resolves linked Artifact view, and preserves Artifact on unlink', () => {
            const db = new DatabaseSync(':memory:');
            try {
                db.exec(`
                    PRAGMA foreign_keys = ON;
                    CREATE TABLE Artifact (
                        ID TEXT PRIMARY KEY,
                        Name TEXT NOT NULL
                    );
                    CREATE TABLE Activity (
                        ID TEXT PRIMARY KEY,
                        Title TEXT NOT NULL,
                        Description TEXT NULL,
                        Details TEXT NULL,
                        ArtifactID TEXT NULL REFERENCES Artifact(ID)
                    );
                    CREATE INDEX IDX_AUTO_MJ_FKEY_Activity_ArtifactID
                        ON Activity (ArtifactID)
                        WHERE ArtifactID IS NOT NULL;
                    CREATE VIEW vwActivities AS
                    SELECT a.*, art.Name AS Artifact
                    FROM Activity a
                    LEFT OUTER JOIN Artifact art ON art.ID = a.ArtifactID;
                `);

                // 1. Fast-path quick capture with NULL ArtifactID creates 0 Artifact rows
                db.prepare(
                    `INSERT INTO Activity (ID, Title, Description, Details, ArtifactID) VALUES (?, ?, ?, ?, NULL)`,
                ).run('act-1', 'Quick Note', 'Short note body', '{"channel":"note"}');

                const artifactCount = db.prepare(`SELECT COUNT(*) AS cnt FROM Artifact`).get() as { cnt: number };
                expect(artifactCount.cnt).toBe(0);

                const fastRow = db.prepare(`SELECT ID, Description, Details, ArtifactID, Artifact FROM vwActivities WHERE ID = ?`).get('act-1') as {
                    ID: string;
                    Description: string | null;
                    Details: string | null;
                    ArtifactID: string | null;
                    Artifact: string | null;
                };
                expect(fastRow.ArtifactID).toBeNull();
                expect(fastRow.Artifact).toBeNull();
                expect(fastRow.Description).toBe('Short note body');

                // 2. Dangling ArtifactID is rejected by FK constraint
                expect(() =>
                    db.prepare(`INSERT INTO Activity (ID, Title, ArtifactID) VALUES (?, ?, ?)`).run(
                        'act-bad',
                        'Broken link',
                        'nonexistent-artifact-id',
                    ),
                ).toThrow(/FOREIGN KEY/i);

                // 3. Opt-in link to a real Artifact succeeds and resolves via vwActivities
                db.prepare(`INSERT INTO Artifact (ID, Name) VALUES (?, ?)`).run(ARTIFACT_ID, 'Q4 Account Plan');
                db.prepare(`INSERT INTO Activity (ID, Title, Description, ArtifactID) VALUES (?, ?, ?, ?)`).run(
                    'act-2',
                    'Q4 Strategy Meeting',
                    'Executive alignment call',
                    ARTIFACT_ID,
                );

                const linkedRow = db.prepare(`SELECT ArtifactID, Artifact FROM vwActivities WHERE ID = ?`).get('act-2') as {
                    ArtifactID: string | null;
                    Artifact: string | null;
                };
                expect(UUIDsEqual(linkedRow.ArtifactID, ARTIFACT_ID)).toBe(true);
                expect(linkedRow.Artifact).toBe('Q4 Account Plan');

                // 4. Unlinking sets ArtifactID back to NULL without deleting the Artifact
                db.prepare(`UPDATE Activity SET ArtifactID = NULL WHERE ID = ?`).run('act-2');
                const unlinkedRow = db.prepare(`SELECT ArtifactID, Artifact FROM vwActivities WHERE ID = ?`).get('act-2') as {
                    ArtifactID: string | null;
                    Artifact: string | null;
                };
                expect(unlinkedRow.ArtifactID).toBeNull();
                expect(unlinkedRow.Artifact).toBeNull();
                const remainingArtifacts = db.prepare(`SELECT COUNT(*) AS cnt FROM Artifact WHERE ID = ?`).get(ARTIFACT_ID) as { cnt: number };
                expect(remainingArtifacts.cnt).toBe(1);
            } finally {
                db.close();
            }
        });
    });
});
