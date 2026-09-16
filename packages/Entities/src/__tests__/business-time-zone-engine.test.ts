/**
 * Which zone the business books in, resolved from the instance configuration.
 *
 * The engine is a thin BaseEngine over one or two rows of `MJ: Instance Configurations`; the logic
 * worth testing is the resolution, so it is a pure function over rows and the engine calls it.
 * Everything that can go wrong on a real instance is a row shape: missing, blank, malformed JSON, a
 * zone name the runtime does not know, or MJ's own key arriving later and taking precedence.
 */
import { describe, expect, it } from 'vitest';
import { ResolveBusinessTimeZoneSetting, type InstanceConfigurationRow } from '../business-time-zone-engine.js';

const row = (FeatureKey: string, Value: string | null, DefaultValue: string | null = '{"iana":"UTC","sql":"UTC"}'): InstanceConfigurationRow =>
    ({ FeatureKey, Value, DefaultValue });

describe('ResolveBusinessTimeZoneSetting', () => {
    it('reads the BizApps row', () => {
        const setting = ResolveBusinessTimeZoneSetting([row('BizApps.BusinessTimeZone', '{"iana":"America/Chicago","sql":"Central Standard Time"}')]);
        expect(setting).toEqual({ Iana: 'America/Chicago', Sql: 'Central Standard Time', Source: 'BizApps.BusinessTimeZone' });
    });

    it("prefers MJ's Business.TimeZone when both rows exist", () => {
        const setting = ResolveBusinessTimeZoneSetting([
            row('BizApps.BusinessTimeZone', '{"iana":"America/Chicago","sql":"Central Standard Time"}'),
            row('Business.TimeZone', '{"iana":"America/New_York","sql":"Eastern Standard Time"}'),
        ]);
        expect(setting.Iana).toBe('America/New_York');
        expect(setting.Source).toBe('Business.TimeZone');
    });

    it('falls back to the row DefaultValue when Value is blank', () => {
        const setting = ResolveBusinessTimeZoneSetting([row('BizApps.BusinessTimeZone', '   ')]);
        expect(setting).toEqual({ Iana: 'UTC', Sql: 'UTC', Source: 'BizApps.BusinessTimeZone' });
    });

    it('falls back to UTC when there is no row at all', () => {
        const setting = ResolveBusinessTimeZoneSetting([]);
        expect(setting).toMatchObject({ Iana: 'UTC', Sql: 'UTC', Source: 'fallback' });
        expect(setting.Warning).toMatch(/no BizApps\.BusinessTimeZone or Business\.TimeZone row/);
    });

    it('falls back to UTC when the JSON is unreadable or the zone is unknown', () => {
        expect(ResolveBusinessTimeZoneSetting([row('BizApps.BusinessTimeZone', 'America/Chicago')]).Source).toBe('fallback');
        expect(ResolveBusinessTimeZoneSetting([row('BizApps.BusinessTimeZone', '{"iana":"America/Chicagoo","sql":"Central Standard Time"}')]).Source).toBe('fallback');
    });

    it('refuses a row that sets only one of the two names — both tiers would answer differently', () => {
        expect(ResolveBusinessTimeZoneSetting([row('BizApps.BusinessTimeZone', '{"iana":"America/Chicago"}')]).Source).toBe('fallback');
        expect(ResolveBusinessTimeZoneSetting([row('BizApps.BusinessTimeZone', '{"sql":"Central Standard Time"}')]).Source).toBe('fallback');
    });

    it('never reports an IANA name as the SQL zone', () => {
        const setting = ResolveBusinessTimeZoneSetting([row('BizApps.BusinessTimeZone', '{"iana":"America/Chicago"}')]);
        expect(setting.Sql).toBe('UTC');
    });

    it('does not fall through to the BizApps row when an unreadable Business.TimeZone row exists — the views would not either', () => {
        const setting = ResolveBusinessTimeZoneSetting([
            row('Business.TimeZone', 'not json'),
            row('BizApps.BusinessTimeZone', '{"iana":"America/Chicago","sql":"Central Standard Time"}'),
        ]);
        expect(setting.Source).toBe('fallback');
    });
});
