import '@angular/compiler';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, describe, expect, it } from 'vitest';
import {
    COMMON_ANGULAR_LIMITS_BOUNDS,
    COMMON_ANGULAR_LIMITS_CONFIG,
    DEFAULT_COMMON_ANGULAR_LIMITS,
    GetRegisteredCommonAngularLimits,
    PartyLookupParamsFor,
    RegisterCommonAngularLimits,
    ResetCommonAngularLimits,
    ResolveCommonAngularLimits,
    ResolveCommonAngularLimitsWithProvenance,
} from '../public-api';
import { LatestByCreated } from '../lib/data/directory-stats';

const HERE = dirname(fileURLToPath(import.meta.url));
const ANGULAR_ROOT = resolve(HERE, '..', '..');
const REPO_ROOT = resolve(ANGULAR_ROOT, '..', '..');

describe('Common Angular Limits Configuration Resolver', () => {
    afterEach(() => {
        ResetCommonAngularLimits();
    });

    it('resolves canonical default limits and documents zero RunawayGuard hits', () => {
        const resolved = ResolveCommonAngularLimits();
        expect(resolved).toEqual(DEFAULT_COMMON_ANGULAR_LIMITS);
        expect(resolved.RunawayGuards.ZeroHitsConfirmed).toBe(true);
        expect(resolved.RunawayGuards.ActiveGuardCount).toBe(0);
        expect(resolved.ResourceGuards.PartySearchTimeoutMs).toBe(20_000);
        expect(resolved.ResourceGuards.SellingCompanyListLimit).toBe(1000);
        expect(resolved.ResourceGuards.DirectorySnapshotPeopleMaxRows).toBe(1000);
        expect(resolved.ResourceGuards.DirectorySnapshotOrganizationsMaxRows).toBe(1000);
        expect(resolved.ResourceGuards.DirectorySnapshotRelationshipsMaxRows).toBe(1000);
        expect(resolved.Tuning.RelationshipGraphInitialMaxRows).toBe(60);
        expect(resolved.Tuning.RelationshipGraphHopMaxRows).toBe(30);
        expect(resolved.Tuning.DirectorySearchPeopleMaxRows).toBe(200);
        expect(resolved.Tuning.DirectorySearchOrganizationsMaxRows).toBe(200);
        expect(resolved.Tuning.ActivitiesDashboardMaxRows).toBe(250);
        expect(resolved.Ux.PartySearchDebounceMs).toBe(250);
        expect(resolved.Ux.PartyLookupMinTermLength).toBe(2);
        expect(resolved.Ux.DirectoryLatestTakeCount).toBe(7);
        expect(COMMON_ANGULAR_LIMITS_CONFIG.toString()).toContain('COMMON_ANGULAR_LIMITS_CONFIG');
    });

    it('supports runtime registry overrides and higher-priority call/DI overrides', () => {
        RegisterCommonAngularLimits({
            ResourceGuards: { SellingCompanyListLimit: 500 },
            Tuning: { ActivitiesDashboardMaxRows: 120 },
            Ux: { PartySearchDebounceMs: 150 },
        });
        expect(GetRegisteredCommonAngularLimits()?.ResourceGuards?.SellingCompanyListLimit).toBe(500);

        const fromRegistry = ResolveCommonAngularLimits();
        expect(fromRegistry.ResourceGuards.SellingCompanyListLimit).toBe(500);
        expect(fromRegistry.Tuning.ActivitiesDashboardMaxRows).toBe(120);
        expect(fromRegistry.Ux.PartySearchDebounceMs).toBe(150);

        const withCallOverride = ResolveCommonAngularLimitsWithProvenance({
            ResourceGuards: { SellingCompanyListLimit: 250 },
        });
        expect(withCallOverride.Limits.ResourceGuards.SellingCompanyListLimit).toBe(250);
        expect(withCallOverride.Provenance['ResourceGuards.SellingCompanyListLimit'].SourceTier).toBe('CallOverride');
        expect(withCallOverride.Provenance['Tuning.ActivitiesDashboardMaxRows'].SourceTier).toBe('RuntimeRegistry');
        expect(withCallOverride.Provenance['Tuning.DirectorySearchPeopleMaxRows'].SourceTier).toBe('CodeFallback');
    });

    it('clamps out-of-range finite values to policy bounds and falls back on invalid overrides', () => {
        const result = ResolveCommonAngularLimitsWithProvenance({
            ResourceGuards: {
                PartySearchTimeoutMs: Number.NaN,
                SellingCompanyListLimit: 999_999,
                DirectorySnapshotPeopleMaxRows: 2,
                DirectorySnapshotOrganizationsMaxRows: -50,
                DirectorySnapshotRelationshipsMaxRows: Number.POSITIVE_INFINITY,
            },
            Tuning: {
                RelationshipGraphInitialMaxRows: 0,
                RelationshipGraphHopMaxRows: 12.9,
            },
            Ux: {
                PartySearchDebounceMs: 0,
                PartyLookupMinTermLength: 50,
                DirectoryLatestTakeCount: Number.NEGATIVE_INFINITY,
            },
        });

        // Invalid values fall back to safe code defaults
        expect(result.Limits.ResourceGuards.PartySearchTimeoutMs).toBe(20_000);
        expect(result.Provenance['ResourceGuards.PartySearchTimeoutMs'].UsedFallbackDueToInvalidOverride).toBe(true);
        expect(result.Limits.ResourceGuards.DirectorySnapshotOrganizationsMaxRows).toBe(1000);
        expect(result.Limits.ResourceGuards.DirectorySnapshotRelationshipsMaxRows).toBe(1000);
        expect(result.Limits.Tuning.RelationshipGraphInitialMaxRows).toBe(60);
        expect(result.Limits.Ux.DirectoryLatestTakeCount).toBe(7);

        // Above-ceiling or below-floor finite values clamp cleanly to policy bounds
        expect(result.Limits.ResourceGuards.SellingCompanyListLimit).toBe(
            COMMON_ANGULAR_LIMITS_BOUNDS.ResourceGuards.SellingCompanyListLimit.Max,
        );
        expect(result.Provenance['ResourceGuards.SellingCompanyListLimit'].WasClamped).toBe(true);
        expect(result.Limits.ResourceGuards.DirectorySnapshotPeopleMaxRows).toBe(
            COMMON_ANGULAR_LIMITS_BOUNDS.ResourceGuards.DirectorySnapshotPeopleMaxRows.Min,
        );
        expect(result.Provenance['ResourceGuards.DirectorySnapshotPeopleMaxRows'].WasClamped).toBe(true);
        expect(result.Limits.Ux.PartyLookupMinTermLength).toBe(
            COMMON_ANGULAR_LIMITS_BOUNDS.Ux.PartyLookupMinTermLength.Max,
        );

        // Integer normalization and explicit Min=0 support for debounce
        expect(result.Limits.Tuning.RelationshipGraphHopMaxRows).toBe(12);
        expect(result.Limits.Ux.PartySearchDebounceMs).toBe(0);
    });

    it('integrates runtime limit overrides with PartyLookupParamsFor and LatestByCreated', () => {
        expect(PartyLookupParamsFor('Person', 'abc')).not.toBeNull();
        RegisterCommonAngularLimits({ Ux: { PartyLookupMinTermLength: 4, DirectoryLatestTakeCount: 2 } });

        expect(PartyLookupParamsFor('Person', 'abc')).toBeNull();
        expect(PartyLookupParamsFor('Person', 'abcd')).toEqual({ Term: 'abcd', Domain: null });

        const rows = [
            { id: '1', __mj_CreatedAt: '2026-01-01T00:00:00Z' },
            { id: '2', __mj_CreatedAt: '2026-01-03T00:00:00Z' },
            { id: '3', __mj_CreatedAt: '2026-01-02T00:00:00Z' },
        ];
        expect(LatestByCreated(rows).map((r) => r.id)).toEqual(['2', '3']);
    });

    it('enforces zero any, zero unknown, zero BaseEntity.Get/Set, zero process.env, and OpenApp nav parity', () => {
        const resolverSource = readFileSync(resolve(ANGULAR_ROOT, 'src/lib/config/limits.config.ts'), 'utf8');
        const strippedResolver = resolverSource.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '');
        expect(strippedResolver).not.toMatch(/:\s*any\b|\bas\s+any\b|<any>/);
        expect(strippedResolver).not.toMatch(/\bunknown\b/);
        expect(strippedResolver).not.toMatch(/\.Get\s*\(|\.Set\s*\(/);
        expect(strippedResolver).not.toMatch(/\bprocess\.env\b/);
        expect(strippedResolver).not.toMatch(/window\.print\s*\(/);
        expect(strippedResolver).not.toMatch(/#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\(/);

        const appManifestPath = resolve(REPO_ROOT, 'mj-app.json');
        const appMetadataPath = resolve(REPO_ROOT, 'metadata/applications/.common-application.json');
        const sectionsSource = readFileSync(
            resolve(ANGULAR_ROOT, 'src/lib/sections/common-sections.component.ts'),
            'utf8',
        );
        expect(existsSync(appManifestPath)).toBe(true);
        expect(existsSync(appMetadataPath)).toBe(true);

        const appMeta = JSON.parse(readFileSync(appMetadataPath, 'utf8')) as Array<{
            fields?: { DefaultNavItems?: Array<{ DriverClass?: string }> };
        }>;
        const driverClasses = (appMeta[0]?.fields?.DefaultNavItems ?? [])
            .map((item) => item.DriverClass)
            .filter((name): name is string => typeof name === 'string' && name.length > 0);
        expect(driverClasses.length).toBeGreaterThan(0);
        for (const driver of driverClasses) {
            expect(sectionsSource).toContain(`@RegisterClass(BaseResourceComponent, '${driver}')`);
        }
    });
});
