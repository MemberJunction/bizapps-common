#!/usr/bin/env node
/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 *
 * Real-world multi-entity domain seed fixtures for Common.Activity Category B Hybrid Spine
 * (quick capture with ArtifactID = NULL + opt-in linked MJ Docs via __mj.Artifact).
 *
 * Exports deterministic domain fixtures (>= 20 records spanning Organizations, People,
 * Roles/Permissions, Note/Call/Meeting/Email Activities, ActivityLinks, and opt-in MJ Docs)
 * and supports standalone dry-run density reporting:
 *
 *   node scripts/seed-activity-hybrid-world.mjs --dry-run --json
 */
import { realpathSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export const SEED_TAG = 'ACT-HYBRID-SEED';
export const SEED_EMAIL_DOMAIN = 'act-hybrid-world.test';

/**
 * Normalizes a UUID string to lowercase for cross-DBMS comparisons
 * (SQL Server uppercases GUIDs, PostgreSQL lowercases UUIDs).
 */
export function normalizeUuid(value) {
    return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

/**
 * Builds the deterministic multi-entity domain seed dataset used by both
 * Vitest unit/guard suites and live SQL Server + PostgreSQL cross-stack checks.
 */
export function BuildActivityHybridSeedDataset(runTag = SEED_TAG) {
    const tag = String(runTag || SEED_TAG).replace(/[^A-Za-z0-9_-]/g, '_');

    const organizations = [
        {
            Key: 'ORG_RIV',
            Code: 'RIV',
            Name: `Riverside Advisory Group (${tag})`,
            OrganizationType: 'Non-Profit',
            Email: `hello+riv.${tag}@${SEED_EMAIL_DOMAIN}`,
            Website: `https://riv.${SEED_EMAIL_DOMAIN}`,
            ParentKey: null,
        },
        {
            Key: 'ORG_BCP',
            Code: 'BCP',
            Name: `Blue Cypress Press (${tag})`,
            OrganizationType: 'Corporation',
            Email: `hello+bcp.${tag}@${SEED_EMAIL_DOMAIN}`,
            Website: `https://bcp.${SEED_EMAIL_DOMAIN}`,
            ParentKey: null,
        },
        {
            Key: 'ORG_IMP',
            Code: 'IMP',
            Name: `Blue Cypress Imprint (${tag})`,
            OrganizationType: 'Corporation',
            Email: `imprint+imp.${tag}@${SEED_EMAIL_DOMAIN}`,
            Website: `https://imp.${SEED_EMAIL_DOMAIN}`,
            ParentKey: 'ORG_BCP',
        },
        {
            Key: 'ORG_HH',
            Code: 'HH',
            Name: `Harbor House Legal (${tag})`,
            OrganizationType: 'LLC',
            Email: `counsel+hh.${tag}@${SEED_EMAIL_DOMAIN}`,
            Website: `https://hh.${SEED_EMAIL_DOMAIN}`,
            ParentKey: null,
        },
        {
            Key: 'ORG_NGS',
            Code: 'NGS',
            Name: `Northgate Health Systems (${tag})`,
            OrganizationType: 'Educational Institution',
            Email: `ops+ngs.${tag}@${SEED_EMAIL_DOMAIN}`,
            Website: `https://ngs.${SEED_EMAIL_DOMAIN}`,
            ParentKey: null,
        },
    ];

    const people = [
        {
            Key: 'PER_NORA',
            FirstName: 'Nora',
            LastName: 'Calhoun',
            Title: 'Account Executive',
            Role: 'UI',
            Email: `nora.calhoun.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_RIV',
        },
        {
            Key: 'PER_ADA',
            FirstName: 'Ada',
            LastName: 'Lovelace',
            Title: 'Managing Consultant',
            Role: 'Developer',
            Email: `ada.lovelace.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_BCP',
        },
        {
            Key: 'PER_GRACE',
            FirstName: 'Grace',
            LastName: 'Hopper',
            Title: 'General Counsel',
            Role: 'Administrator',
            Email: `grace.hopper.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_HH',
        },
        {
            Key: 'PER_PRIYA',
            FirstName: 'Priya',
            LastName: 'Shah',
            Title: 'Chief Financial Officer',
            Role: 'UI',
            Email: `priya.shah.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_BCP',
        },
        {
            Key: 'PER_ALAN',
            FirstName: 'Alan',
            LastName: 'Turing',
            Title: 'Enterprise Architect',
            Role: 'Developer',
            Email: `alan.turing.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_NGS',
        },
        {
            Key: 'PER_ELENA',
            FirstName: 'Elena',
            LastName: 'Voss',
            Title: 'Operations Director',
            Role: 'UI',
            Email: `elena.voss.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_RIV',
        },
        {
            Key: 'PER_MARCUS',
            FirstName: 'Marcus',
            LastName: 'Lee',
            Title: 'Restricted Compliance Analyst',
            Role: 'RestrictedReader',
            Email: `marcus.lee.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_HH',
        },
        {
            Key: 'PER_DANA',
            FirstName: 'Dana',
            LastName: 'Ortiz',
            Title: 'Internal Audit Lead',
            Role: 'Integration',
            Email: `dana.ortiz.${tag}@${SEED_EMAIL_DOMAIN}`,
            OrgKey: 'ORG_IMP',
        },
    ];

    const rolePermissions = [
        {
            RoleName: 'Administrator',
            Activities: { CanRead: true, CanCreate: true, CanUpdate: true, CanDelete: true },
            Artifacts: { CanRead: true, CanCreate: true, CanUpdate: true, CanDelete: true },
        },
        {
            RoleName: 'UI',
            Activities: { CanRead: true, CanCreate: true, CanUpdate: true, CanDelete: false },
            Artifacts: { CanRead: true, CanCreate: true, CanUpdate: true, CanDelete: false },
        },
        {
            RoleName: 'Developer',
            Activities: { CanRead: true, CanCreate: true, CanUpdate: true, CanDelete: true },
            Artifacts: { CanRead: true, CanCreate: true, CanUpdate: true, CanDelete: true },
        },
        {
            RoleName: 'RestrictedReader',
            Activities: { CanRead: true, CanCreate: false, CanUpdate: false, CanDelete: false },
            Artifacts: { CanRead: false, CanCreate: false, CanUpdate: false, CanDelete: false },
        },
    ];

    const artifacts = [
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

    // 12 realistic Activities across all 4 core types (Note, Call, Meeting, Email):
    // - 8 fast-path activities (ArtifactKey: null -> ArtifactID MUST remain NULL, 0 auto-created Artifacts)
    // - 4 opt-in linked MJ Doc activities (ArtifactKey != null -> FK to __mj.Artifact)
    const activities = [
        // --- Fast-path Activities (ArtifactID = NULL) ---
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

        // --- Opt-in Linked MJ Doc Activities (ArtifactID != NULL) ---
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

    const activityLinks = activities.flatMap((act) => [
        { ActivityKey: act.Key, TargetKind: 'Organization', TargetKey: act.OrgKey, Role: 'Regarding' },
        { ActivityKey: act.Key, TargetKind: 'Person', TargetKey: act.PersonKey, Role: act.ActivityTypeCode === 'Email' && act.Direction === 'Inbound' ? 'From' : 'Attendee' },
    ]);

    return {
        RunTag: tag,
        Organizations: organizations,
        People: people,
        RolePermissions: rolePermissions,
        Artifacts: artifacts,
        Activities: activities,
        ActivityLinks: activityLinks,
    };
}

/**
 * Computes deterministic seed density metrics for ART-7 (`SeedDensityReport`) and unit assertions.
 */
export function GetSeedDensitySummary(dataset = BuildActivityHybridSeedDataset()) {
    const fastPathActivities = dataset.Activities.filter((a) => a.ArtifactKey === null);
    const linkedActivities = dataset.Activities.filter((a) => a.ArtifactKey !== null);
    const activityTypesCovered = [...new Set(dataset.Activities.map((a) => a.ActivityTypeCode))].sort();

    const countsByCategory = {
        organizations: dataset.Organizations.length,
        people: dataset.People.length,
        rolePermissions: dataset.RolePermissions.length,
        artifacts: dataset.Artifacts.length,
        activitiesTotal: dataset.Activities.length,
        activitiesFastPathNullArtifact: fastPathActivities.length,
        activitiesLinkedArtifact: linkedActivities.length,
        activityLinks: dataset.ActivityLinks.length,
    };

    const totalDomainRecords =
        countsByCategory.organizations +
        countsByCategory.people +
        countsByCategory.rolePermissions +
        countsByCategory.artifacts +
        countsByCategory.activitiesTotal +
        countsByCategory.activityLinks;

    return {
        runTag: dataset.RunTag,
        totalDomainRecords,
        minimumRequiredRecords: 20,
        meetsMinimumDensity: totalDomainRecords >= 20,
        activityTypesCovered,
        countsByCategory,
    };
}

function main() {
    const args = process.argv.slice(2);
    const runTagArgIdx = args.indexOf('--tag');
    const runTag = runTagArgIdx >= 0 && args[runTagArgIdx + 1] ? args[runTagArgIdx + 1] : SEED_TAG;
    const dataset = BuildActivityHybridSeedDataset(runTag);
    const summary = GetSeedDensitySummary(dataset);

    if (args.includes('--json')) {
        console.log(JSON.stringify(summary, null, 2));
        return;
    }

    console.log(
        `Activity Hybrid Seed Dataset (${summary.runTag}): ${summary.totalDomainRecords} total domain records ` +
            `(orgs=${summary.countsByCategory.organizations}, people=${summary.countsByCategory.people}, ` +
            `roles=${summary.countsByCategory.rolePermissions}, artifacts=${summary.countsByCategory.artifacts}, ` +
            `activities=${summary.countsByCategory.activitiesTotal} [${summary.countsByCategory.activitiesFastPathNullArtifact} fast-path NULL, ` +
            `${summary.countsByCategory.activitiesLinkedArtifact} linked MJ Doc], links=${summary.countsByCategory.activityLinks}; ` +
            `types=${summary.activityTypesCovered.join(',')})`,
    );
}

if (process.argv[1] && realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url))) {
    main();
}
