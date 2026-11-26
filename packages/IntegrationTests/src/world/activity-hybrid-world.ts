/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 *
 * Typed multi-entity Activity Hybrid World dataset & GraphQL-wire helper for
 * @mj-biz-apps/common-integration-tests.
 *
 * Provides >= 20 realistic domain records across Organizations, People, Role/Permission
 * matrices, Activity Types (Note, Call, Meeting, Email), fast-path Activities
 * (ArtifactID = null, zero auto-created Artifacts), opt-in linked MJ Docs, and ActivityLinks.
 */
import type { IntegrationCheckContext } from '@memberjunction/testing-integration/registry';
import { Assert } from '@memberjunction/testing-integration/registry';
import type { mjBizAppsCommonActivityEntity } from '@mj-biz-apps/common-entities';
import { COMMON_ENTITIES } from '../entity-names.js';
import { FindRows, Quote } from '../wire.js';

export type HybridActivityTypeCode = 'Note' | 'Call' | 'Meeting' | 'Email';

export interface HybridWorldOrganizationFixture {
    Key: string;
    Code: string;
    Name: string;
    OrganizationType: string;
    ParentKey: string | null;
}

export interface HybridWorldPersonFixture {
    Key: string;
    FirstName: string;
    LastName: string;
    Title: string;
    RoleName: 'Administrator' | 'UI' | 'Developer' | 'Integration' | 'RestrictedReader';
    OrgKey: string;
}

export interface HybridWorldRolePermissionFixture {
    RoleName: 'Administrator' | 'UI' | 'Developer' | 'RestrictedReader';
    CanReadActivities: boolean;
    CanWriteActivities: boolean;
    CanReadArtifacts: boolean;
    CanWriteArtifacts: boolean;
}

export interface HybridWorldArtifactFixture {
    Key: string;
    Name: string;
    Description: string;
    Visibility: 'Always' | 'System Only';
    RestrictedToAuthorOnly: boolean;
}

export interface HybridWorldActivityFixture {
    Key: string;
    ActivityTypeCode: HybridActivityTypeCode;
    Title: string;
    Description: string;
    Details: string;
    Direction: mjBizAppsCommonActivityEntity['Direction'];
    Status: mjBizAppsCommonActivityEntity['Status'];
    Visibility: mjBizAppsCommonActivityEntity['Visibility'];
    Source: mjBizAppsCommonActivityEntity['Source'];
    ArtifactKey: string | null;
    OrgKey: string;
    PersonKey: string;
}

export interface HybridWorldActivityLinkFixture {
    ActivityKey: string;
    TargetKind: 'Organization' | 'Person';
    TargetKey: string;
    Role: 'Regarding' | 'From' | 'Attendee';
}

export interface ActivityHybridWorldFixtures {
    Organizations: ReadonlyArray<HybridWorldOrganizationFixture>;
    People: ReadonlyArray<HybridWorldPersonFixture>;
    RolePermissions: ReadonlyArray<HybridWorldRolePermissionFixture>;
    Artifacts: ReadonlyArray<HybridWorldArtifactFixture>;
    Activities: ReadonlyArray<HybridWorldActivityFixture>;
    ActivityLinks: ReadonlyArray<HybridWorldActivityLinkFixture>;
}

export interface ActivityHybridSeedSummary {
    TotalDomainRecords: number;
    OrganizationsCount: number;
    PeopleCount: number;
    RolePermissionsCount: number;
    ArtifactsCount: number;
    ActivitiesCount: number;
    FastPathActivitiesCount: number;
    LinkedActivitiesCount: number;
    ActivityLinksCount: number;
    ActivityTypesCovered: ReadonlyArray<HybridActivityTypeCode>;
}

export function GetActivityHybridWorldFixtures(tag = 'COM-HYBRID'): ActivityHybridWorldFixtures {
    const organizations: HybridWorldOrganizationFixture[] = [
        { Key: 'ORG_RIV', Code: 'RIV', Name: `Riverside Advisory Group (${tag})`, OrganizationType: 'Non-Profit', ParentKey: null },
        { Key: 'ORG_BCP', Code: 'BCP', Name: `Blue Cypress Press (${tag})`, OrganizationType: 'Corporation', ParentKey: null },
        { Key: 'ORG_IMP', Code: 'IMP', Name: `Blue Cypress Imprint (${tag})`, OrganizationType: 'Corporation', ParentKey: 'ORG_BCP' },
        { Key: 'ORG_HH', Code: 'HH', Name: `Harbor House Legal (${tag})`, OrganizationType: 'LLC', ParentKey: null },
        { Key: 'ORG_NGS', Code: 'NGS', Name: `Northgate Health Systems (${tag})`, OrganizationType: 'Educational Institution', ParentKey: null },
    ];

    const people: HybridWorldPersonFixture[] = [
        { Key: 'PER_NORA', FirstName: 'Nora', LastName: 'Calhoun', Title: 'Account Executive', RoleName: 'UI', OrgKey: 'ORG_RIV' },
        { Key: 'PER_ADA', FirstName: 'Ada', LastName: 'Lovelace', Title: 'Managing Consultant', RoleName: 'Developer', OrgKey: 'ORG_BCP' },
        { Key: 'PER_GRACE', FirstName: 'Grace', LastName: 'Hopper', Title: 'General Counsel', RoleName: 'Administrator', OrgKey: 'ORG_HH' },
        { Key: 'PER_PRIYA', FirstName: 'Priya', LastName: 'Shah', Title: 'Chief Financial Officer', RoleName: 'UI', OrgKey: 'ORG_BCP' },
        { Key: 'PER_ALAN', FirstName: 'Alan', LastName: 'Turing', Title: 'Enterprise Architect', RoleName: 'Developer', OrgKey: 'ORG_NGS' },
        { Key: 'PER_ELENA', FirstName: 'Elena', LastName: 'Voss', Title: 'Operations Director', RoleName: 'UI', OrgKey: 'ORG_RIV' },
        { Key: 'PER_MARCUS', FirstName: 'Marcus', LastName: 'Lee', Title: 'Restricted Compliance Analyst', RoleName: 'RestrictedReader', OrgKey: 'ORG_HH' },
        { Key: 'PER_DANA', FirstName: 'Dana', LastName: 'Ortiz', Title: 'Internal Audit Lead', RoleName: 'Integration', OrgKey: 'ORG_IMP' },
    ];

    const rolePermissions: HybridWorldRolePermissionFixture[] = [
        { RoleName: 'Administrator', CanReadActivities: true, CanWriteActivities: true, CanReadArtifacts: true, CanWriteArtifacts: true },
        { RoleName: 'UI', CanReadActivities: true, CanWriteActivities: true, CanReadArtifacts: true, CanWriteArtifacts: true },
        { RoleName: 'Developer', CanReadActivities: true, CanWriteActivities: true, CanReadArtifacts: true, CanWriteArtifacts: true },
        { RoleName: 'RestrictedReader', CanReadActivities: true, CanWriteActivities: false, CanReadArtifacts: false, CanWriteArtifacts: false },
    ];

    const artifacts: HybridWorldArtifactFixture[] = [
        {
            Key: 'ART_Q4_PLAN',
            Name: `Q4 Executive Account Plan (${tag})`,
            Description: 'Long-form collaborative executive account strategy brief for Riverside Advisory Group.',
            Visibility: 'Always',
            RestrictedToAuthorOnly: false,
        },
        {
            Key: 'ART_MSA_REDLINE',
            Name: `Harbor House MSA Redline Brief (${tag})`,
            Description: 'Structured clause-by-clause legal redline review for Harbor House Legal.',
            Visibility: 'Always',
            RestrictedToAuthorOnly: false,
        },
        {
            Key: 'ART_ARCH_MEMO',
            Name: `Northgate EHR Architecture Steering Memo (${tag})`,
            Description: 'Multi-section platform architecture decision record and integration blueprint.',
            Visibility: 'Always',
            RestrictedToAuthorOnly: false,
        },
        {
            Key: 'ART_RENEWAL_PROP',
            Name: `Blue Cypress Annual Renewal Proposal (${tag})`,
            Description: 'Confidential pricing, expansion tiers, and renewal schedule for Blue Cypress Press.',
            Visibility: 'System Only',
            RestrictedToAuthorOnly: true,
        },
    ];

    const activities: HybridWorldActivityFixture[] = [
        {
            Key: 'ACT_FAST_NOTE_1',
            ActivityTypeCode: 'Note',
            Title: `[${tag}] Quick stakeholder note after library walk-through`,
            Description: 'Nora confirmed FY27 budget review starts first week of December; no formal brief needed yet.',
            Details: JSON.stringify({ Channel: 'QuickNote', CaptureTargetMs: 1200, FastPath: true }),
            Direction: 'Internal',
            Status: 'Logged',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_RIV',
            PersonKey: 'PER_NORA',
        },
        {
            Key: 'ACT_FAST_NOTE_2',
            ActivityTypeCode: 'Note',
            Title: `[${tag}] Quick note on Blue Cypress Imprint print schedule`,
            Description: 'Imprint spring catalog deadline moved to Jan 15. Keep follow-up lightweight.',
            Details: JSON.stringify({ Channel: 'QuickNote', Priority: 'Normal', FastPath: true }),
            Direction: 'Internal',
            Status: 'Logged',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_IMP',
            PersonKey: 'PER_DANA',
        },
        {
            Key: 'ACT_FAST_CALL_1',
            ActivityTypeCode: 'Call',
            Title: `[${tag}] Outbound discovery call with Priya Shah`,
            Description: '15-minute check-in on invoice consolidation. Priya asked for a summary email tomorrow.',
            Details: JSON.stringify({ DurationMinutes: 15, PhoneOutcome: 'Connected', FastPath: true }),
            Direction: 'Outbound',
            Status: 'Completed',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_BCP',
            PersonKey: 'PER_PRIYA',
        },
        {
            Key: 'ACT_FAST_CALL_2',
            ActivityTypeCode: 'Call',
            Title: `[${tag}] Inbound support call from Elena Voss`,
            Description: 'Confirmed read-only access for seasonal volunteers; resolved on call.',
            Details: JSON.stringify({ DurationMinutes: 8, PhoneOutcome: 'Connected', FastPath: true }),
            Direction: 'Inbound',
            Status: 'Completed',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_RIV',
            PersonKey: 'PER_ELENA',
        },
        {
            Key: 'ACT_FAST_MEETING_1',
            ActivityTypeCode: 'Meeting',
            Title: `[${tag}] Weekly 15-min standup with Alan Turing`,
            Description: 'Reviewed sprint blockers and test data refresh schedule; no standalone doc required.',
            Details: JSON.stringify({ Location: 'Zoom', DurationMinutes: 15, FastPath: true }),
            Direction: 'Internal',
            Status: 'Completed',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_NGS',
            PersonKey: 'PER_ALAN',
        },
        {
            Key: 'ACT_FAST_MEETING_2',
            ActivityTypeCode: 'Meeting',
            Title: `[${tag}] Ad-hoc hallway sync with Grace Hopper`,
            Description: 'Aligned on NDA turnaround SLA (48 hours).',
            Details: JSON.stringify({ Location: 'HQ Floor 3', DurationMinutes: 10, FastPath: true }),
            Direction: 'Internal',
            Status: 'Logged',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_HH',
            PersonKey: 'PER_GRACE',
        },
        {
            Key: 'ACT_FAST_EMAIL_1',
            ActivityTypeCode: 'Email',
            Title: `[${tag}] Follow-up email confirming workshop dates`,
            Description: 'Sent confirmed Tuesday/Wednesday workshop slots to Nora and Elena.',
            Details: JSON.stringify({ MessageCount: 1, ThreadHint: 'workshop-dates', FastPath: true }),
            Direction: 'Outbound',
            Status: 'Logged',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_RIV',
            PersonKey: 'PER_NORA',
        },
        {
            Key: 'ACT_FAST_EMAIL_2',
            ActivityTypeCode: 'Email',
            Title: `[${tag}] Inbound billing question from Blue Cypress Press`,
            Description: 'Received PO number #BCP-4419 for Q4 renewal billing.',
            Details: JSON.stringify({ MessageCount: 1, PONumber: 'BCP-4419', FastPath: true }),
            Direction: 'Inbound',
            Status: 'Logged',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: null,
            OrgKey: 'ORG_BCP',
            PersonKey: 'PER_PRIYA',
        },
        {
            Key: 'ACT_LINKED_MEETING_1',
            ActivityTypeCode: 'Meeting',
            Title: `[${tag}] Q4 Executive QBR with Riverside Advisory Group`,
            Description: 'Executive QBR summary excerpt; full collaborative account plan linked as MJ Doc.',
            Details: JSON.stringify({ Location: 'Boardroom A', DurationMinutes: 60, LinkedDocMode: 'OptIn' }),
            Direction: 'Outbound',
            Status: 'Completed',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: 'ART_Q4_PLAN',
            OrgKey: 'ORG_RIV',
            PersonKey: 'PER_NORA',
        },
        {
            Key: 'ACT_LINKED_NOTE_1',
            ActivityTypeCode: 'Note',
            Title: `[${tag}] Legal clause redline summary for Harbor House MSA`,
            Description: 'Captures indemnity and liability cap decisions; full redline brief attached via ArtifactID.',
            Details: JSON.stringify({ ReviewRound: 2, LinkedDocMode: 'OptIn' }),
            Direction: 'Internal',
            Status: 'Logged',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: 'ART_MSA_REDLINE',
            OrgKey: 'ORG_HH',
            PersonKey: 'PER_GRACE',
        },
        {
            Key: 'ACT_LINKED_CALL_1',
            ActivityTypeCode: 'Call',
            Title: `[${tag}] Architecture steering call with Northgate Health`,
            Description: 'Reviewed dual-DBMS migration strategy; linked full Architecture Steering Memo.',
            Details: JSON.stringify({ DurationMinutes: 45, PhoneOutcome: 'Connected', LinkedDocMode: 'OptIn' }),
            Direction: 'Outbound',
            Status: 'Completed',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: 'ART_ARCH_MEMO',
            OrgKey: 'ORG_NGS',
            PersonKey: 'PER_ALAN',
        },
        {
            Key: 'ACT_LINKED_EMAIL_1',
            ActivityTypeCode: 'Email',
            Title: `[${tag}] Annual renewal package sent to Blue Cypress Press`,
            Description: 'Dispatched multi-year renewal summary; restricted pricing doc linked via ArtifactID.',
            Details: JSON.stringify({ RenewalYear: 2027, RestrictedDoc: true, LinkedDocMode: 'OptIn' }),
            Direction: 'Outbound',
            Status: 'Completed',
            Visibility: 'Internal',
            Source: 'Manual',
            ArtifactKey: 'ART_RENEWAL_PROP',
            OrgKey: 'ORG_BCP',
            PersonKey: 'PER_ADA',
        },
    ];

    const activityLinks: HybridWorldActivityLinkFixture[] = activities.flatMap((act) => [
        { ActivityKey: act.Key, TargetKind: 'Organization' as const, TargetKey: act.OrgKey, Role: 'Regarding' as const },
        {
            ActivityKey: act.Key,
            TargetKind: 'Person' as const,
            TargetKey: act.PersonKey,
            Role: act.ActivityTypeCode === 'Email' && act.Direction === 'Inbound' ? ('From' as const) : ('Attendee' as const),
        },
    ]);

    return {
        Organizations: organizations,
        People: people,
        RolePermissions: rolePermissions,
        Artifacts: artifacts,
        Activities: activities,
        ActivityLinks: activityLinks,
    };
}

export function SummarizeActivityHybridWorld(fixtures: ActivityHybridWorldFixtures): ActivityHybridSeedSummary {
    const fastPathCount = fixtures.Activities.filter((a) => a.ArtifactKey === null).length;
    const linkedCount = fixtures.Activities.filter((a) => a.ArtifactKey !== null).length;
    const types = Array.from(new Set(fixtures.Activities.map((a) => a.ActivityTypeCode)));

    const total =
        fixtures.Organizations.length +
        fixtures.People.length +
        fixtures.RolePermissions.length +
        fixtures.Artifacts.length +
        fixtures.Activities.length +
        fixtures.ActivityLinks.length;

    return {
        TotalDomainRecords: total,
        OrganizationsCount: fixtures.Organizations.length,
        PeopleCount: fixtures.People.length,
        RolePermissionsCount: fixtures.RolePermissions.length,
        ArtifactsCount: fixtures.Artifacts.length,
        ActivitiesCount: fixtures.Activities.length,
        FastPathActivitiesCount: fastPathCount,
        LinkedActivitiesCount: linkedCount,
        ActivityLinksCount: fixtures.ActivityLinks.length,
        ActivityTypesCovered: types,
    };
}

export async function ResolveActivityTypeIdMap(
    ctx: IntegrationCheckContext,
): Promise<Record<HybridActivityTypeCode, string>> {
    const codes: ReadonlyArray<HybridActivityTypeCode> = ['Note', 'Call', 'Meeting', 'Email'];
    const filter = `Code IN (${codes.map((c) => `'${Quote(c)}'`).join(', ')})`;
    const rows = await FindRows<{ ID: string; Code: string }>(
        ctx,
        COMMON_ENTITIES.ActivityType,
        filter,
        ['ID', 'Code'],
    );
    const map = {} as Record<HybridActivityTypeCode, string>;
    for (const row of rows) {
        if (row.Code === 'Note' || row.Code === 'Call' || row.Code === 'Meeting' || row.Code === 'Email') {
            map[row.Code] = row.ID;
        }
    }
    for (const code of codes) {
        Assert(!!map[code], `Required system Activity Type '${code}' missing`);
    }
    return map;
}
