/**
 * The business time zone: one instance-wide setting, cached, read on client and server.
 *
 * Stored as one `MJ: Instance Configurations` row whose JSON value carries the IANA name code uses
 * (`Intl` knows only those) and the Windows name SQL Server's `AT TIME ZONE` accepts (it knows only
 * those). bizapps-common defines the row; the host sets its value. MJ 6.2 is asked to define its
 * own key, `Business.TimeZone`, with the same two-name shape (MemberJunction/MJ#4541); when that
 * row exists it wins, so nothing here changes when the framework catches up — provided the shape
 * matches, which is why that issue pins it.
 *
 * Fail open to UTC. A missing row, a blank value, unreadable JSON, an unknown zone, or a user
 * without read permission on the configuration entity all resolve to UTC, with one warning per
 * process, because a date default that throws is worse than a date default in the wrong zone.
 */
import {
    BaseEngine,
    BaseEnginePropertyConfig,
    IMetadataProvider,
    LogStatus,
    RegisterForStartup,
    UserInfo,
} from '@memberjunction/core';
import { CalendarDay, FromCalendarDay, IsKnownTimeZone, TodayIn, UTC_ZONE } from './business-day.js';

export const BUSINESS_TIME_ZONE_KEYS = ['Business.TimeZone', 'BizApps.BusinessTimeZone'] as const;

export type BusinessTimeZoneKey = (typeof BUSINESS_TIME_ZONE_KEYS)[number];

export const BUSINESS_TIME_ZONE_ENTITY = 'MJ: Instance Configurations';

export interface InstanceConfigurationRow {
    FeatureKey: string;
    Value: string | null;
    DefaultValue: string | null;
}

export interface BusinessTimeZoneSetting {
    Iana: string;
    Sql: string;
    Source: BusinessTimeZoneKey | 'fallback';
    Warning?: string;
}

export interface BusinessTimeZoneTestInput {
    iana: string;
    sql: string;
}

const IANA_TO_WINDOWS: Readonly<Record<string, string>> = {
    UTC: 'UTC',
    'Etc/UTC': 'UTC',
    'America/Chicago': 'Central Standard Time',
    'America/New_York': 'Eastern Standard Time',
    'America/Denver': 'Mountain Standard Time',
    'America/Phoenix': 'US Mountain Standard Time',
    'America/Los_Angeles': 'Pacific Standard Time',
    'America/Anchorage': 'Alaskan Standard Time',
    'Pacific/Honolulu': 'Hawaiian Standard Time',
    'America/Toronto': 'Eastern Standard Time',
    'America/Vancouver': 'Pacific Standard Time',
    'Europe/London': 'GMT Standard Time',
    'Europe/Paris': 'Romance Standard Time',
    'Europe/Berlin': 'W. Europe Standard Time',
    'Asia/Tokyo': 'Tokyo Standard Time',
    'Asia/Kolkata': 'India Standard Time',
    'Australia/Sydney': 'AUS Eastern Standard Time',
};

const FALLBACK: BusinessTimeZoneSetting = { Iana: UTC_ZONE, Sql: UTC_ZONE, Source: 'fallback' };

/** The UTC fallback, carrying why resolution landed there. */
function fallback(reason: string): BusinessTimeZoneSetting {
    return { Iana: UTC_ZONE, Sql: UTC_ZONE, Source: 'fallback', Warning: reason };
}

interface ParsedZone {
    iana?: unknown;
    sql?: unknown;
}

function parseZone(text: string | null | undefined): ParsedZone | null {
    const trimmed = (text ?? '').trim();
    if (trimmed.length === 0) return null;
    try {
        const parsed: unknown = JSON.parse(trimmed);
        return typeof parsed === 'object' && parsed !== null ? (parsed as ParsedZone) : null;
    } catch {
        return null;
    }
}

function settingFrom(row: InstanceConfigurationRow, key: BusinessTimeZoneKey): BusinessTimeZoneSetting | null {
    const raw = (row.Value ?? '').trim();
    const parsed = raw.length === 0 ? parseZone(row.DefaultValue) : parseZone(raw);
    if (!parsed || typeof parsed.iana !== 'string' || !IsKnownTimeZone(parsed.iana)) return null;
    // BOTH names or neither. `iana` is what code reads and `sql` is what SQL Server's AT TIME ZONE
    // takes, so a row carrying one of them would have code and views answering different days —
    // and substituting the IANA name for the missing `sql` makes AT TIME ZONE throw, not fall back.
    const sql = typeof parsed.sql === 'string' ? parsed.sql.trim() : '';
    if (sql.length === 0) return null;
    return { Iana: parsed.iana, Sql: sql, Source: key };
}

/** The setting the rows describe, in key precedence order, or the UTC fallback. Pure, for tests. */
export function ResolveBusinessTimeZoneSetting(rows: ReadonlyArray<InstanceConfigurationRow>): BusinessTimeZoneSetting {
    for (const key of BUSINESS_TIME_ZONE_KEYS) {
        const row = rows.find((r) => r.FeatureKey === key);
        if (!row) continue;
        // The first key present wins, readable or not; an unreadable preferred row means UTC on
        // every tier rather than a code/view split.
        return settingFrom(row, key) ?? fallback(`row ${key} is unreadable, names an unknown zone, or sets only one of iana/sql; dates fall back to UTC`);
    }
    return fallback('no BizApps.BusinessTimeZone or Business.TimeZone row');
}

@RegisterForStartup()
export class BusinessTimeZoneEngine extends BaseEngine<BusinessTimeZoneEngine> {
    private _configurations: InstanceConfigurationRow[] = [];
    private _ianaZone: string = UTC_ZONE;
    private _sqlZoneName: string = UTC_ZONE;
    private warned = new Set<string>();

    public static get Instance(): BusinessTimeZoneEngine {
        return super.getInstance<BusinessTimeZoneEngine>();
    }

    /**
     * Test-only helper that pins the business time zone without loading configuration from a database.
     * Sets `_ianaZone`, `_sqlZoneName`, `_configurations`, and `_loaded = true`, and returns a restore
     * callback that reverts the engine to its previous state.
     */
    public static SetZoneForTesting(zone: BusinessTimeZoneTestInput | string): () => void {
        const instance = BusinessTimeZoneEngine.Instance;
        const loadedTarget = instance as unknown as { _loaded: boolean };
        const previousRows = instance._configurations.slice();
        const previousLoaded = loadedTarget._loaded;
        const previousIana = instance._ianaZone;
        const previousSql = instance._sqlZoneName;
        const previousWarned = new Set(instance.warned);

        const resolved: BusinessTimeZoneTestInput =
            typeof zone === 'string'
                ? { iana: zone, sql: IANA_TO_WINDOWS[zone] ?? zone }
                : { iana: zone.iana, sql: zone.sql };

        instance._ianaZone = resolved.iana;
        instance._sqlZoneName = resolved.sql;
        instance._configurations = [
            {
                FeatureKey: 'BizApps.BusinessTimeZone',
                Value: JSON.stringify({ iana: resolved.iana, sql: resolved.sql }),
                DefaultValue: '{"iana":"UTC","sql":"UTC"}',
            },
        ];
        loadedTarget._loaded = true;
        instance.warned.clear();

        return () => {
            instance._configurations = previousRows;
            loadedTarget._loaded = previousLoaded;
            instance._ianaZone = previousIana;
            instance._sqlZoneName = previousSql;
            instance.warned = new Set(previousWarned);
        };
    }

    /**
     * Test-only helper that resets the engine to its unloaded initial state.
     */
    public static ResetForTesting(): void {
        const instance = BusinessTimeZoneEngine.Instance;
        const loadedTarget = instance as unknown as { _loaded: boolean };
        instance._configurations = [];
        instance._ianaZone = UTC_ZONE;
        instance._sqlZoneName = UTC_ZONE;
        loadedTarget._loaded = false;
        instance.warned.clear();
    }

    /** Instance alias for {@link BusinessTimeZoneEngine.SetZoneForTesting}. */
    public SetZoneForTesting(zone: BusinessTimeZoneTestInput | string): () => void {
        return BusinessTimeZoneEngine.SetZoneForTesting(zone);
    }

    /** Instance alias for {@link BusinessTimeZoneEngine.ResetForTesting}. */
    public ResetForTesting(): void {
        BusinessTimeZoneEngine.ResetForTesting();
    }

    public async Config(forceRefresh?: boolean, contextUser?: UserInfo, provider?: IMetadataProvider): Promise<unknown> {
        const keys = BUSINESS_TIME_ZONE_KEYS.map((k) => `'${k}'`).join(',');
        const params: Array<Partial<BaseEnginePropertyConfig>> = [
            {
                PropertyName: '_configurations',
                EntityName: BUSINESS_TIME_ZONE_ENTITY,
                Filter: `FeatureKey IN (${keys})`,
                ResultType: 'simple',
            },
        ];
        return await this.Load(params, provider as IMetadataProvider, forceRefresh ?? false, contextUser);
    }

    /** The resolved setting; UTC before load, on any unreadable row, or without read permission. */
    public get Setting(): BusinessTimeZoneSetting {
        if (!this.Loaded) {
            return this.warnOnce('engine not configured — call BusinessTimeZoneEngine.Instance.Config() where you configure your other engines');
        }
        let rows: InstanceConfigurationRow[];
        try {
            rows = this.GetConfigData<InstanceConfigurationRow>('_configurations');
        } catch {
            return this.warnOnce('the current user cannot read MJ: Instance Configurations');
        }
        const setting = ResolveBusinessTimeZoneSetting(rows);
        if (setting.Warning) this.warnOnce(setting.Warning);
        return setting;
    }

    /** IANA zone name for code. */
    public get Zone(): string {
        return this.Setting.Iana;
    }

    /** Windows zone name for SQL Server's AT TIME ZONE. */
    public get SqlZone(): string {
        return this.Setting.Sql;
    }

    /**
     * The zone for a record. `companyID` is accepted from day one and ignored until MJ carries a
     * TimeZone column on Companies (MemberJunction/MJ#4541); call sites do not change when it
     * arrives.
     */
    public Resolve(companyID?: string): string {
        void companyID;
        return this.Zone;
    }

    public Today(companyID?: string): CalendarDay {
        return TodayIn(this.Resolve(companyID));
    }

    public TodayAsDate(companyID?: string): Date {
        return FromCalendarDay(this.Today(companyID));
    }

    private warnOnce(reason: string): BusinessTimeZoneSetting {
        if (!this.warned.has(reason)) {
            this.warned.add(reason);
            LogStatus(`BusinessTimeZoneEngine: ${reason}; dates default to UTC until it is set.`);
        }
        return FALLBACK;
    }
}
