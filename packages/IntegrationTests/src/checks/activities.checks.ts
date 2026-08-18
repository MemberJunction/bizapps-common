import {
    Assert,
    AssertEqual,
    IntegrationCheckRegistry,
    type NamedCheck,
} from '@memberjunction/testing-integration/registry';
import {
    mjBizAppsCommonActivityEntity,
    mjBizAppsCommonActivityLinkEntity,
    mjBizAppsCommonActivitySyncConnectionEntity,
    mjBizAppsCommonActivitySyncRuleEntity,
    mjBizAppsCommonActivityTypeEntity,
} from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES, WORLD_EMAIL_DOMAIN } from '../entity-names.js';
import { FindRows, Quote, RequireSave } from '../wire.js';
import { GetOrLoadWorld } from '../world/load-world.js';

const SYSTEM_CODES = ['Email', 'Call', 'Meeting', 'Note', 'SMS', 'Chat'] as const;

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
        Name: 'A1 — six system Activity Types are seeded and unique by Code',
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
];

for (const check of checks) {
    IntegrationCheckRegistry.Instance.Register(check);
}

IntegrationCheckRegistry.Instance.RegisterLifecycle('activities', {
    Setup: async () => {},
    Teardown: async () => {},
});
