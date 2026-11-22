import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, describe, expect, it } from 'vitest';
import {
    COMMON_ENTITIES_LIMITS_BOUNDS,
    DEFAULT_COMMON_ENTITIES_LIMITS,
    GetRegisteredCommonEntitiesLimits,
    RegisterCommonEntitiesLimits,
    ResetCommonEntitiesLimits,
    ResolveCommonEntitiesLimits,
} from '../index.js';

const HERE = dirname(fileURLToPath(import.meta.url));

describe('Common Entities Limits Configuration Resolver', () => {
    afterEach(() => {
        ResetCommonEntitiesLimits();
    });

    it('resolves canonical defaults with zero RunawayGuard hits', () => {
        const resolved = ResolveCommonEntitiesLimits();
        expect(resolved).toEqual(DEFAULT_COMMON_ENTITIES_LIMITS);
        expect(resolved.RunawayGuards.ZeroHitsConfirmed).toBe(true);
        expect(resolved.ResourceGuards.MaxReportingChainDepth).toBe(100);
    });

    it('supports runtime overrides, ceiling clamping, and invalid-value fallback', () => {
        RegisterCommonEntitiesLimits({ ResourceGuards: { MaxReportingChainDepth: 250 } });
        expect(GetRegisteredCommonEntitiesLimits()?.ResourceGuards?.MaxReportingChainDepth).toBe(250);
        expect(ResolveCommonEntitiesLimits().ResourceGuards.MaxReportingChainDepth).toBe(250);

        expect(
            ResolveCommonEntitiesLimits({ ResourceGuards: { MaxReportingChainDepth: 50_000 } }).ResourceGuards
                .MaxReportingChainDepth,
        ).toBe(COMMON_ENTITIES_LIMITS_BOUNDS.ResourceGuards.MaxReportingChainDepth.Max);

        expect(
            ResolveCommonEntitiesLimits({ ResourceGuards: { MaxReportingChainDepth: Number.NaN } }).ResourceGuards
                .MaxReportingChainDepth,
        ).toBe(100);

        const resolverSrc = readFileSync(resolve(HERE, '../limits.config.ts'), 'utf8')
            .replace(/\/\*[\s\S]*?\*\//g, '')
            .replace(/\/\/.*$/gm, '');
        expect(resolverSrc).not.toMatch(/:\s*any\b|\bas\s+any\b|<any>|\bunknown\b/);
    });
});
