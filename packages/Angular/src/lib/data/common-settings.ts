import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import { ApplicationSettingEngine } from '@memberjunction/core-entities';

/**
 * The Common application's own settings, read by name.
 *
 * These are per-instance values that the shared library cannot know: Common ships each row with a
 * documented name and an empty value, and the host that installs it fills the value in. Reading
 * them through a named accessor rather than a bare string at each call site keeps a typo from
 * silently reading as "not configured".
 */
const COMMON_APPLICATION_NAME = 'Common';

export const COMMON_SETTING = {
    /** The `MJ: Companies` row that new orders and contracts default their selling company to. */
    DefaultSellingCompanyID: 'DefaultSellingCompanyID',
} as const;

export class CommonSettings {
    /** Idempotent; the engine caches, so callers may call this on every component init. */
    public static async Load(provider?: IMetadataProvider, user?: UserInfo): Promise<void> {
        const metadata = new Metadata();
        await ApplicationSettingEngine.Instance.Config(false, user ?? metadata.CurrentUser, provider ?? Metadata.Provider);
    }

    /**
     * The configured default selling company, or null when this instance has not set one — in
     * which case the field stays blank and nothing is confirmed, which is the pre-existing
     * behaviour rather than a guess.
     */
    public static get DefaultSellingCompanyID(): string | null {
        return this.read(COMMON_SETTING.DefaultSellingCompanyID);
    }

    private static read(name: string): string | null {
        const raw = ApplicationSettingEngine.Instance.GetSetting(name, this.applicationID());
        const value = (raw ?? '').trim();
        return value.length > 0 ? value : null;
    }

    private static applicationID(): string | undefined {
        return new Metadata().Applications?.find((application) => application.Name === COMMON_APPLICATION_NAME)?.ID;
    }
}
