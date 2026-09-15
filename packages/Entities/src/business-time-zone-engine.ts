/**
 * The business time zone: one instance-wide setting, cached, read on client and server.
 *
 * Stored as one `MJ: Instance Configurations` row whose JSON value carries the IANA name code uses
 * (`Intl` knows only those) and the Windows name SQL Server's `AT TIME ZONE` accepts (it knows only
 * those). bizapps-common defines the row; the host sets its value. MJ 6.2 defines its own key,
 * `Business.TimeZone`; when that row exists it wins, so nothing here changes when the framework
 * catches up.
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

export const BUSINESS_TIME_ZONE_ENTITY = 'MJ: Instance Configurations';

export interface InstanceConfigurationRow {
    FeatureKey: string;
    Value: string | null;
    DefaultValue: string | null;
}

export interface BusinessTimeZoneSetting {
    Iana: string;
    Sql: string;
    Source: (typeof BUSINESS_TIME_ZONE_KEYS)[number] | 'fallback';
    Warning?: string;
}

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

function settingFrom(row: InstanceConfigurationRow, key: (typeof BUSINESS_TIME_ZONE_KEYS)[number]): BusinessTimeZoneSetting | null {
    const raw = (row.Value ?? '').trim();
    const parsed = raw.length === 0 ? parseZone(row.DefaultValue) : parseZone(raw);
    if (!parsed || typeof parsed.iana !== 'string' || !IsKnownTimeZone(parsed.iana)) return null;
    const sqlRaw = typeof parsed.sql === 'string' ? parsed.sql.trim() : '';
    if (sqlRaw.length === 0) {
        return {
            Iana: parsed.iana,
            Sql: parsed.iana,
            Source: key,
            Warning: `row ${row.FeatureKey} sets iana but not sql; SQL Server views will fall back to UTC until sql is set`,
        };
    }
    return { Iana: parsed.iana, Sql: sqlRaw, Source: key };
}

/** The setting the rows describe, in key precedence order, or the UTC fallback. Pure, for tests. */
export function ResolveBusinessTimeZoneSetting(rows: ReadonlyArray<InstanceConfigurationRow>): BusinessTimeZoneSetting {
    for (const key of BUSINESS_TIME_ZONE_KEYS) {
        const row = rows.find((r) => r.FeatureKey === key);
        if (!row) continue;
        // The first key present wins, readable or not; an unreadable preferred row means UTC on
        // every tier rather than a code/view split.
        return settingFrom(row, key) ?? fallback(`row ${key} is unreadable or names an unknown zone`);
    }
    return fallback('no BizApps.BusinessTimeZone or Business.TimeZone row');
}

@RegisterForStartup()
export class BusinessTimeZoneEngine extends BaseEngine<BusinessTimeZoneEngine> {
    private _configurations: InstanceConfigurationRow[] = [];
    private warned = new Set<string>();

    public static get Instance(): BusinessTimeZoneEngine {
        return super.getInstance<BusinessTimeZoneEngine>();
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
     * The zone for a record. `companyID` is accepted from day one and ignored until MJ 6.2 carries a
     * TimeZone column on Companies; call sites do not change when it arrives.
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
