import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, describe, expect, it } from 'vitest';
import {
    DEFAULT_SERVER_LIMITS,
    GetRegisteredServerLimits,
    RegisterServerLimits,
    ResetServerLimits,
    ResolveServerLimits,
    SERVER_LIMITS_BOUNDS,
} from '../custom/limits.config.js';

const HERE = dirname(fileURLToPath(import.meta.url));

describe('Common Server Limits Configuration Resolver', () => {
    afterEach(() => {
        ResetServerLimits();
    });

    it('resolves canonical defaults and documents zero RunawayGuard hits', () => {
        const resolved = ResolveServerLimits();
        expect(resolved).toEqual(DEFAULT_SERVER_LIMITS);
        expect(resolved.RunawayGuards.ZeroHitsConfirmed).toBe(true);
        expect(resolved.Tuning.SyncActivitiesDefaultLimit).toBe(100);
    });

    it('applies runtime overrides, ceiling clamping, and invalid-value fallbacks', () => {
        RegisterServerLimits({ Tuning: { SyncActivitiesDefaultLimit: 250 } });
        expect(GetRegisteredServerLimits()?.Tuning?.SyncActivitiesDefaultLimit).toBe(250);
        expect(ResolveServerLimits().Tuning.SyncActivitiesDefaultLimit).toBe(250);

        expect(
            ResolveServerLimits({ Tuning: { SyncActivitiesDefaultLimit: 99_999 } }).Tuning.SyncActivitiesDefaultLimit,
        ).toBe(SERVER_LIMITS_BOUNDS.Tuning.SyncActivitiesDefaultLimit.Max);

        expect(
            ResolveServerLimits({ Tuning: { SyncActivitiesDefaultLimit: -10 } }).Tuning.SyncActivitiesDefaultLimit,
        ).toBe(100);

        const resolverSrc = readFileSync(resolve(HERE, '../custom/limits.config.ts'), 'utf8')
            .replace(/\/\*[\s\S]*?\*\//g, '')
            .replace(/\/\/.*$/gm, '');
        expect(resolverSrc).not.toMatch(/:\s*any\b|\bas\s+any\b|<any>|\bunknown\b/);
    });
});
