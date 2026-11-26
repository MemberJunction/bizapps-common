import * as fs from 'node:fs';
import * as path from 'node:path';
import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import type { MJArtifactEntity } from '@memberjunction/core-entities';
import { UUIDsEqual } from '@memberjunction/global';
import {
    mjBizAppsCommonActivityEntity,
    mjBizAppsCommonActivityLinkEntity,
    mjBizAppsCommonActivitySyncConnectionEntity,
    mjBizAppsCommonActivitySyncRuleEntity,
    mjBizAppsCommonActivitySyncRunEntity,
    mjBizAppsCommonActivityTypeEntity,
} from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { FindRows, Quote, RequireSave } from '../wire.js';
import { GetOrLoadWorld } from '../world/load-world.js';
import { ResolveActivityTypeIdMap } from '../world/activity-hybrid-world.js';

/**
 * The system Activity Types this app seeds, in the order `metadata/activity-types/.activity-types.json`
 * declares them. That file is the source of truth; this list is a SECOND OPINION on it, so a type that
 * appears in the database without going through metadata is caught rather than accepted.
 *
 * KEEP IT IN STEP WITH THAT FILE. `SystemEvent` was seeded by the 5.37.0 Activity Sync Engine release
 * and this list was not updated, so A1 asserted six against a database holding seven from 2026-09-01
 * until it was noticed. The check did its job — it failed loudly and named the difference — but nothing
 * connected that failure back to the release that caused it.
 */
const SYSTEM_CODES = ['Email', 'Call', 'Meeting', 'Note', 'SMS', 'Chat', 'SystemEvent'] as const;

async function RequireTypeId(ctx: Parameters<NamedCheck['Fn']>[0], code: string): Promise<string> {
    const rows = await FindRows<{ ID: string }>(
        ctx,
        COMMON_ENTITIES.ActivityType,
        `Code = '${Quote(code)}'`,
        ['ID'],
    );
    Assert(rows.length === 1, `system Activity Type ${code} must exist (seed via metadata/activity-types)`);
    return rows[0].ID;
}

const checks: NamedCheck[] = [
    {
        Id: 'activities.A1',
        Name: 'A1 — every system Activity Type is seeded and unique by Code',
        RequiresMutation: false,
        Fn: async (ctx) => {
            const rows = await FindRows<Pick<mjBizAppsCommonActivityTypeEntity, 'ID' | 'Code' | 'IsSystem'>>(
                ctx,
                COMMON_ENTITIES.ActivityType,
                `IsSystem = 1`,
                ['ID', 'Code', 'IsSystem'],
            );
            const codes = rows.map((r) => r.Code).sort();
            AssertEqual(codes.join(','), [...SYSTEM_CODES].sort().join(','), 'system type codes');
        },
    },
    {
        Id: 'activities.A2',
        Name: 'A2 — manual Activity + Regarding link to a Person over GraphQL',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const nora = world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`];
            const personEntity = ctx.Provider.EntityByName(COMMON_ENTITIES.Person);
            Assert(!!personEntity, 'People entity');
            const typeId = await RequireTypeId(ctx, 'Call');

            const activity = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                COMMON_ENTITIES.Activity,
                ctx.User,
            );
            activity.NewRecord();
            activity.ActivityTypeID = typeId;
            activity.StartedAt = new Date();
            activity.Title = `COM-TEST called Nora ${Date.now()}`;
            activity.Direction = 'Outbound';
            activity.Status = 'Logged';
            activity.Visibility = 'Internal';
            activity.Source = 'Manual';
            activity.LoggedByUserID = ctx.User.ID;
            await RequireSave(activity, 'A2 activity');

            const link = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityLinkEntity>(
                COMMON_ENTITIES.ActivityLink,
                ctx.User,
            );
            link.NewRecord();
            link.ActivityID = activity.ID;
            link.Role = 'Regarding';
            link.EntityID = personEntity!.ID;
            link.RecordID = nora.ID;
            await RequireSave(link, 'A2 regarding link');

            const found = await FindRows<{ ID: string }>(
                ctx,
                COMMON_ENTITIES.ActivityLink,
                `ActivityID = '${activity.ID}' AND Role = 'Regarding'`,
                ['ID'],
            );
            AssertEqual(found.length, 1, 'regarding link visible via RunView');
            Assert(await link.Delete(), 'cleanup link');
            Assert(await activity.Delete(), 'cleanup activity');
        },
    },
    {
        Id: 'activities.A3',
        Name: 'A3 — ActivityLink refuses resolved + unresolved identity together',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const world = await GetOrLoadWorld(ctx);
            const nora = world.People[`nora.calhoun@${WORLD_EMAIL_DOMAIN}`];
            const personEntity = ctx.Provider.EntityByName(COMMON_ENTITIES.Person);
            const typeId = await RequireTypeId(ctx, 'Email');

            const activity = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                COMMON_ENTITIES.Activity,
                ctx.User,
            );
            activity.NewRecord();
            activity.ActivityTypeID = typeId;
            activity.StartedAt = new Date();
            activity.Title = `COM-TEST xor both ${Date.now()}`;
            activity.Direction = 'Inbound';
            activity.LoggedByUserID = ctx.User.ID;
            await RequireSave(activity, 'A3 activity');

            const link = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityLinkEntity>(
                COMMON_ENTITIES.ActivityLink,
                ctx.User,
            );
            link.NewRecord();
            link.ActivityID = activity.ID;
            link.Role = 'From';
            link.EntityID = personEntity!.ID;
            link.RecordID = nora.ID;
            link.IdentityKind = 'Email';
            link.IdentityValue = `ghost.${Date.now()}@${WORLD_EMAIL_DOMAIN}`;
            const saved = await link.Save();
            Assert(!saved, 'link with both resolved record and identity must refuse');
            Assert(await activity.Delete(), 'cleanup activity');
        },
    },
    {
        Id: 'activities.A4',
        Name: 'A4 — unresolved identity link saves; ExternalID is unique per SourceSystem',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const typeId = await RequireTypeId(ctx, 'Email');
            const externalId = `com-test-${Date.now()}@example.invalid`;

            const first = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                COMMON_ENTITIES.Activity,
                ctx.User,
            );
            first.NewRecord();
            first.ActivityTypeID = typeId;
            first.StartedAt = new Date();
            first.Title = `COM-TEST inbound ${externalId}`;
            first.Direction = 'Inbound';
            first.Source = 'Integration';
            first.SourceSystem = 'Gmail';
            first.ExternalID = externalId;
            first.LoggedByUserID = ctx.User.ID;
            await RequireSave(first, 'A4 first activity');

            const link = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityLinkEntity>(
                COMMON_ENTITIES.ActivityLink,
                ctx.User,
            );
            link.NewRecord();
            link.ActivityID = first.ID;
            link.Role = 'From';
            link.IdentityKind = 'Email';
            link.IdentityValue = `unmatched.${Date.now()}@${WORLD_EMAIL_DOMAIN}`;
            await RequireSave(link, 'A4 unresolved from');

            const dup = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                COMMON_ENTITIES.Activity,
                ctx.User,
            );
            dup.NewRecord();
            dup.ActivityTypeID = typeId;
            dup.StartedAt = new Date();
            dup.Title = `COM-TEST dup ${externalId}`;
            dup.Direction = 'Inbound';
            dup.Source = 'Integration';
            dup.SourceSystem = 'Gmail';
            dup.ExternalID = externalId;
            dup.LoggedByUserID = ctx.User.ID;
            const saved = await dup.Save();
            Assert(!saved, 'duplicate SourceSystem+ExternalID must refuse');

            Assert(await link.Delete(), 'cleanup link');
            Assert(await first.Delete(), 'cleanup first');
        },
    },
    {
        Id: 'activities.A5',
        Name: 'A5 — EndedAt before StartedAt refuses; sync connection + rule persist',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const typeId = await RequireTypeId(ctx, 'Meeting');
            const started = new Date();
            const ended = new Date(started.getTime() - 60_000);

            const bad = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                COMMON_ENTITIES.Activity,
                ctx.User,
            );
            bad.NewRecord();
            bad.ActivityTypeID = typeId;
            bad.StartedAt = started;
            bad.EndedAt = ended;
            bad.Title = `COM-TEST inverted window ${Date.now()}`;
            bad.Direction = 'Internal';
            bad.LoggedByUserID = ctx.User.ID;
            const saved = await bad.Save();
            Assert(!saved, 'EndedAt < StartedAt must refuse');

            const connection = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionEntity>(
                COMMON_ENTITIES.ActivitySyncConnection,
                ctx.User,
            );
            connection.NewRecord();
            connection.Name = `COM-TEST Gmail ${Date.now()}`;
            connection.Provider = 'Gmail';
            connection.Status = 'Paused';
            connection.Direction = 'Inbound';
            connection.OwnerUserID = ctx.User.ID;
            connection.Mailbox = `sync.${Date.now()}@${WORLD_EMAIL_DOMAIN}`;
            await RequireSave(connection, 'A5 connection');

            const rule = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncRuleEntity>(
                COMMON_ENTITIES.ActivitySyncRule,
                ctx.User,
            );
            rule.NewRecord();
            rule.ActivitySyncConnectionID = connection.ID;
            rule.Name = 'Exclude noreply';
            rule.IsEnabled = true;
            rule.Sequence = 10;
            rule.Action = 'Exclude';
            rule.ActivityTypeID = typeId;
            rule.Filter = JSON.stringify({ ExcludeDomains: ['noreply.invalid'] });
            await RequireSave(rule, 'A5 rule');

            const rules = await FindRows<{ ID: string }>(
                ctx,
                COMMON_ENTITIES.ActivitySyncRule,
                `ActivitySyncConnectionID = '${connection.ID}'`,
                ['ID'],
            );
            AssertEqual(rules.length, 1, 'rule visible via RunView');
            Assert(await rule.Delete(), 'cleanup rule');
            Assert(await connection.Delete(), 'cleanup connection');
        },
    },
    {
        Id: 'activities.A6',
        Name: 'A6 — ActivitySyncRuns and ActivitySyncRunDetails SaveReturnMode datestamps_only verification and benchmark log',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const syncRunInfo = ctx.Provider.EntityByName(COMMON_ENTITIES.ActivitySyncRun);
            const syncRunDetailInfo = ctx.Provider.EntityByName(COMMON_ENTITIES.ActivitySyncRunDetail);
            Assert(!!syncRunInfo, 'Activity Sync Runs entity metadata');
            Assert(!!syncRunDetailInfo, 'Activity Sync Run Details entity metadata');
            AssertEqual(syncRunInfo!.SaveReturnMode, 'datestamps_only', 'Activity Sync Runs SaveReturnMode');
            AssertEqual(syncRunDetailInfo!.SaveReturnMode, 'datestamps_only', 'Activity Sync Run Details SaveReturnMode');

            const connection = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncConnectionEntity>(
                COMMON_ENTITIES.ActivitySyncConnection,
                ctx.User,
            );
            connection.NewRecord();
            connection.Name = `COM-TEST SyncPerf ${Date.now()}`;
            connection.Provider = 'Gmail';
            connection.Status = 'Paused';
            connection.Direction = 'Inbound';
            connection.OwnerUserID = ctx.User.ID;
            connection.Mailbox = `syncperf.${Date.now()}@${WORLD_EMAIL_DOMAIN}`;
            await RequireSave(connection, 'A6 connection');

            const createdRuns: mjBizAppsCommonActivitySyncRunEntity[] = [];
            try {
                const t0 = performance.now();
                for (let i = 0; i < 5; i++) {
                    const syncRun = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivitySyncRunEntity>(
                        COMMON_ENTITIES.ActivitySyncRun,
                        ctx.User,
                    );
                    syncRun.NewRecord();
                    syncRun.ActivitySyncConnectionID = connection.ID;
                    syncRun.StartedAt = new Date();
                    syncRun.EndedAt = new Date();
                    syncRun.Status = 'Completed';
                    syncRun.Fetched = 25;
                    syncRun.Included = 10;
                    syncRun.Excluded = 15;
                    syncRun.Duplicates = 0;
                    syncRun.Failed = 0;
                    await RequireSave(syncRun, `A6 syncRun #${i}`);
                    Assert(!!syncRun.ID, 'syncRun ID populated');
                    Assert(!!syncRun.__mj_CreatedAt, 'syncRun __mj_CreatedAt populated');
                    createdRuns.push(syncRun);
                }
                const elapsedMs = Number((performance.now() - t0).toFixed(2));
                const logDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../benchmark-logs');
                fs.mkdirSync(logDir, { recursive: true });
                const entry = {
                    Timestamp: new Date().toISOString(),
                    Package: '@mj-biz-apps/common-integration-tests',
                    Check: 'activities.A6',
                    DatestampsOnlyEntities: [COMMON_ENTITIES.ActivitySyncRun, COMMON_ENTITIES.ActivitySyncRunDetail],
                    FiveActivitySyncRunSavesMs: elapsedMs,
                };
                fs.writeFileSync(path.join(logDir, 'latest.json'), JSON.stringify(entry, null, 2) + '\n', 'utf8');
                fs.appendFileSync(path.join(logDir, 'history.jsonl'), JSON.stringify(entry) + '\n', 'utf8');
            } finally {
                for (const sr of createdRuns) {
                    await sr.Delete();
                }
                await connection.Delete();
            }
        },
    },
    {
        Id: 'activities.A7',
        Name: 'A7 — Category B Hybrid Activity: fast-path ArtifactID=NULL (0 Artifacts), opt-in MJ Doc link/unlink, vwActivities.Artifact, and dangling FK refusal',
        RequiresMutation: true,
        Fn: async (ctx) => {
            const typeIds = await ResolveActivityTypeIdMap(ctx);
            const runStamp = `COM-HYBRID-${Date.now()}`;
            const createdActivities: mjBizAppsCommonActivityEntity[] = [];
            let createdArtifact: MJArtifactEntity | null = null;

            try {
                // 1. Snapshot MJ: Artifacts count before fast-path quick capture
                const artifactsBefore = await FindRows<{ ID: string }>(
                    ctx,
                    COMMON_ENTITIES.Artifact,
                    `Name LIKE '${Quote(runStamp)}%'`,
                    ['ID'],
                );
                AssertEqual(artifactsBefore.length, 0, 'no pre-existing artifacts for run stamp');

                // 2. Fast-path quick capture across Note/Call/Meeting/Email with ArtifactID = null
                const quickNote = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                    COMMON_ENTITIES.Activity,
                    ctx.User,
                );
                quickNote.NewRecord();
                quickNote.ActivityTypeID = typeIds.Note;
                quickNote.StartedAt = new Date();
                quickNote.Title = `${runStamp} Quick Note`;
                quickNote.Description = 'Captured in under 2 seconds without creating an MJ Doc.';
                quickNote.Details = JSON.stringify({ Channel: 'QuickNote', FastPath: true });
                quickNote.Direction = 'Internal';
                quickNote.Status = 'Logged';
                quickNote.Visibility = 'Internal';
                quickNote.Source = 'Manual';
                quickNote.LoggedByUserID = ctx.User.ID;
                Assert(quickNote.ArtifactID === null, 'default ArtifactID must be null');
                await RequireSave(quickNote, 'A7 fast-path quick note');
                createdActivities.push(quickNote);

                const fastRows = await FindRows<{
                    ID: string;
                    Description: string | null;
                    Details: string | null;
                    ArtifactID: string | null;
                    Artifact: string | null;
                }>(
                    ctx,
                    COMMON_ENTITIES.Activity,
                    `ID = '${Quote(quickNote.ID)}'`,
                    ['ID', 'Description', 'Details', 'ArtifactID', 'Artifact'],
                );
                AssertEqual(fastRows.length, 1, 'fast-path activity visible via vwActivities');
                Assert(fastRows[0].ArtifactID === null, 'fast-path ArtifactID remains null');
                Assert(fastRows[0].Artifact === null, 'fast-path vwActivities.Artifact remains null');
                AssertEqual(
                    fastRows[0].Description ?? '',
                    'Captured in under 2 seconds without creating an MJ Doc.',
                    'fast-path Description preserved',
                );

                // Verify zero MJ: Artifacts were auto-created by quick capture
                const artifactsAfterFast = await FindRows<{ ID: string }>(
                    ctx,
                    COMMON_ENTITIES.Artifact,
                    `Name LIKE '${Quote(runStamp)}%'`,
                    ['ID'],
                );
                AssertEqual(artifactsAfterFast.length, 0, 'fast-path capture must create zero MJ: Artifacts');

                // 3. Opt-in linked MJ Doc (ArtifactID FK -> __mj.Artifact)
                const artifactTypes = await FindRows<{ ID: string; Name: string }>(
                    ctx,
                    COMMON_ENTITIES.ArtifactType,
                    '',
                    ['ID', 'Name'],
                );
                Assert(artifactTypes.length > 0, 'at least one MJ: Artifact Type must exist');
                const environments = await FindRows<{ ID: string }>(
                    ctx,
                    COMMON_ENTITIES.Environment,
                    '',
                    ['ID'],
                );
                Assert(environments.length > 0, 'at least one MJ: Environment must exist');

                const artifact = await ctx.Provider.GetEntityObject<MJArtifactEntity>(
                    COMMON_ENTITIES.Artifact,
                    ctx.User,
                );
                artifact.NewRecord();
                artifact.EnvironmentID = environments[0].ID;
                artifact.TypeID = artifactTypes[0].ID;
                artifact.UserID = ctx.User.ID;
                artifact.Name = `${runStamp} Executive QBR Brief`;
                artifact.Description = 'Opt-in long-form collaborative MJ Doc linked to Meeting Activity.';
                artifact.Visibility = 'Always';
                await RequireSave(artifact, 'A7 opt-in artifact');
                createdArtifact = artifact;

                const linkedMeeting = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                    COMMON_ENTITIES.Activity,
                    ctx.User,
                );
                linkedMeeting.NewRecord();
                linkedMeeting.ActivityTypeID = typeIds.Meeting;
                linkedMeeting.StartedAt = new Date();
                linkedMeeting.Title = `${runStamp} Executive QBR Meeting`;
                linkedMeeting.Description = 'Concise summary preserved alongside linked MJ Doc.';
                linkedMeeting.Details = JSON.stringify({ Location: 'Boardroom', LinkedDocMode: 'OptIn' });
                linkedMeeting.Direction = 'Outbound';
                linkedMeeting.Status = 'Completed';
                linkedMeeting.Visibility = 'Internal';
                linkedMeeting.Source = 'Manual';
                linkedMeeting.LoggedByUserID = ctx.User.ID;
                linkedMeeting.ArtifactID = artifact.ID;
                await RequireSave(linkedMeeting, 'A7 linked meeting activity');
                createdActivities.push(linkedMeeting);

                const linkedRows = await FindRows<{
                    ID: string;
                    ArtifactID: string | null;
                    Artifact: string | null;
                    Description: string | null;
                }>(
                    ctx,
                    COMMON_ENTITIES.Activity,
                    `ID = '${Quote(linkedMeeting.ID)}'`,
                    ['ID', 'ArtifactID', 'Artifact', 'Description'],
                );
                AssertEqual(linkedRows.length, 1, 'linked activity visible via vwActivities');
                Assert(UUIDsEqual(linkedRows[0].ArtifactID, artifact.ID), 'linked ArtifactID matches');
                AssertEqual(linkedRows[0].Artifact ?? '', artifact.Name, 'vwActivities.Artifact projects Artifact.Name');

                // 4. Unlink ArtifactID back to null preserving Description & Details and leaving Artifact intact
                linkedMeeting.ArtifactID = null;
                await RequireSave(linkedMeeting, 'A7 unlink artifact from activity');

                const unlinkedRows = await FindRows<{
                    ID: string;
                    ArtifactID: string | null;
                    Artifact: string | null;
                    Description: string | null;
                    Details: string | null;
                }>(
                    ctx,
                    COMMON_ENTITIES.Activity,
                    `ID = '${Quote(linkedMeeting.ID)}'`,
                    ['ID', 'ArtifactID', 'Artifact', 'Description', 'Details'],
                );
                Assert(unlinkedRows[0].ArtifactID === null, 'unlinked ArtifactID is null');
                Assert(unlinkedRows[0].Artifact === null, 'unlinked vwActivities.Artifact is null');
                AssertEqual(
                    unlinkedRows[0].Description ?? '',
                    'Concise summary preserved alongside linked MJ Doc.',
                    'Description preserved on unlink',
                );
                Assert(
                    (unlinkedRows[0].Details ?? '').includes('Boardroom'),
                    'Details preserved on unlink',
                );

                const stillThere = await FindRows<{ ID: string }>(
                    ctx,
                    COMMON_ENTITIES.Artifact,
                    `ID = '${Quote(artifact.ID)}'`,
                    ['ID'],
                );
                AssertEqual(stillThere.length, 1, 'unlinking must preserve underlying MJ: Artifact record');

                // 5. Adversarial FK boundary check: dangling non-existent ArtifactID must be refused
                const dangling = await ctx.Provider.GetEntityObject<mjBizAppsCommonActivityEntity>(
                    COMMON_ENTITIES.Activity,
                    ctx.User,
                );
                dangling.NewRecord();
                dangling.ActivityTypeID = typeIds.Call;
                dangling.StartedAt = new Date();
                dangling.Title = `${runStamp} Dangling Artifact FK`;
                dangling.Direction = 'Outbound';
                dangling.Status = 'Logged';
                dangling.Visibility = 'Internal';
                dangling.Source = 'Manual';
                dangling.LoggedByUserID = ctx.User.ID;
                dangling.ArtifactID = 'deadbeef-dead-4eef-8eef-deadbeef0001';
                const danglingSaved = await dangling.Save();
                Assert(!danglingSaved, 'dangling non-existent ArtifactID must be refused by FK_Activity_Artifact');
            } finally {
                for (const act of createdActivities.reverse()) {
                    await act.Delete();
                }
                if (createdArtifact) {
                    await createdArtifact.Delete();
                }
            }
        },
    },
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('activities', {
    Setup: async () => {},
    Teardown: async () => {},
});
