import { ActionParam, ActionResultSimple, RunActionParams } from '@memberjunction/actions-base';
import { BaseAction } from '@memberjunction/actions';
import {
    DatabaseProviderBase,
    IMetadataProvider,
    LogError,
    Metadata,
    RunView,
    UserInfo,
} from '@memberjunction/core';
import { EncryptionEngine } from '@memberjunction/encryption';
import { RegisterClass, UUIDsEqual } from '@memberjunction/global';
import type { mjBizAppsCommonActivitySyncRunDetailEntity } from '@mj-biz-apps/common-entities';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ROLE_DEVELOPER_ID = 'DEAFCCEC-6A37-EF11-86D4-000D3A4E707E';
const RUN_DETAILS_ENTITY = 'MJ_BizApps_Common: Activity Sync Run Details';

type RunDetailWithPreview = mjBizAppsCommonActivitySyncRunDetailEntity & {
    SubjectPreview?: string | null;
};

function isIndependentDatabaseProvider(
    provider: IMetadataProvider | null | undefined,
): provider is DatabaseProviderBase {
    return (
        Boolean(provider) &&
        'CreateIndependentInstance' in (provider as DatabaseProviderBase) &&
        typeof (provider as DatabaseProviderBase).CreateIndependentInstance === 'function'
    );
}

function isAuthorizedSkippedContentReader(user: UserInfo): boolean {
    if (user.Type?.trim() === 'Owner') {
        return true;
    }
    return (
        user.UserRoles?.some(
            (r) => UUIDsEqual(r.RoleID, ROLE_DEVELOPER_ID) || r.Role?.trim() === 'Developer',
        ) ?? false
    );
}

/**
 * Audited break-glass action (`Common.ReadSkippedContent`) for reading and decrypting
 * `ActivitySyncRunDetail.CapturedContent`.
 *
 * `CapturedContent` and `EncryptionKeyID` on `MJ_BizApps_Common: Activity Sync Run Details`
 * are denied to the `UI` role via Field-Level Security so routine grid reads cannot pull
 * skipped-message ciphertext. When an administrator (`Type = 'Owner'` or `Developer` role)
 * diagnoses a qualification rule, they invoke this action:
 * - Action execution is logged in `ActionExecutionLog`.
 * - Input `Reason` has `LogValue = true` so the justification is recorded in the audit log.
 * - Output `Plaintext` has `LogValue = false` so decrypted content is never persisted in logs.
 */
@RegisterClass(BaseAction, 'Common.ReadSkippedContent')
export class ReadSkippedContentAction extends BaseAction {
    public static readonly AuthorizesCaller = true;

    protected override async InternalRunAction(params: RunActionParams): Promise<ActionResultSimple> {
        const contextUser = params.ContextUser;
        if (!contextUser) {
            return {
                Success: false,
                ResultCode: 'VALIDATION_ERROR',
                Message: 'Common.ReadSkippedContent requires a ContextUser.',
            };
        }

        if (!isAuthorizedSkippedContentReader(contextUser)) {
            return {
                Success: false,
                ResultCode: 'PERMISSION_DENIED',
                Message:
                    'Common.ReadSkippedContent requires an Owner user or a member of the Developer role.',
            };
        }

        const runDetailID = this.readStringParam(params, 'RunDetailID');
        if (!runDetailID || !UUID_PATTERN.test(runDetailID)) {
            return {
                Success: false,
                ResultCode: 'VALIDATION_ERROR',
                Message: 'RunDetailID is required and must be a valid UUID.',
            };
        }

        const shared = Metadata.Provider;
        if (!isIndependentDatabaseProvider(shared)) {
            const message =
                'Common.ReadSkippedContent requires a database provider that supports independent instances.';
            LogError(`[Common.ReadSkippedContent] ${message}`);
            return { Success: false, ResultCode: 'ERROR', Message: message };
        }

        const own = await shared.CreateIndependentInstance();
        try {
            const res = await new RunView(own).RunView<RunDetailWithPreview>(
                {
                    EntityName: RUN_DETAILS_ENTITY,
                    ExtraFilter: `ID = '${runDetailID}'`,
                    MaxRows: 1,
                    ResultType: 'entity_object',
                },
                contextUser,
            );

            if (!res.Success) {
                const message = res.ErrorMessage || 'Failed to load Activity Sync Run Detail.';
                LogError(`[Common.ReadSkippedContent] ${message}`);
                return { Success: false, ResultCode: 'ERROR', Message: message };
            }

            const detail = res.Results?.[0];
            if (!detail) {
                return {
                    Success: false,
                    ResultCode: 'NOT_FOUND',
                    Message: `Activity Sync Run Detail '${runDetailID}' was not found.`,
                };
            }

            let plaintext: string | null = null;
            if (detail.CapturedContent) {
                await EncryptionEngine.Instance.Config(false, contextUser);
                plaintext = await EncryptionEngine.Instance.Decrypt(detail.CapturedContent, contextUser);
            }

            this.setOutputParam(params, 'Plaintext', plaintext);
            this.setOutputParam(params, 'RunDetailID', detail.ID);
            this.setOutputParam(params, 'SubjectPreview', detail.SubjectPreview ?? null);

            return {
                Success: true,
                ResultCode: 'SUCCESS',
                Message: plaintext !== null ? 'Decrypted skipped content.' : 'No captured content present on row.',
                Params: params.Params,
            };
        } catch (err) {
            const detail = err instanceof Error ? err.message : String(err);
            LogError(`[Common.ReadSkippedContent] Failed for RunDetailID=${runDetailID}: ${detail}`);
            return {
                Success: false,
                ResultCode: 'ERROR',
                Message: `Common.ReadSkippedContent failed: ${detail}`,
            };
        } finally {
            await own.ReleaseIndependentInstance();
        }
    }

    private readStringParam(params: RunActionParams, name: string): string | null {
        const lower = name.toLowerCase();
        const found = params.Params?.find((p) => p.Name.trim().toLowerCase() === lower);
        if (found?.Value === undefined || found.Value === null) return null;
        const trimmed = String(found.Value).trim();
        return trimmed.length > 0 ? trimmed : null;
    }

    private setOutputParam(params: RunActionParams, name: string, value: string | null): void {
        if (!params.Params) {
            params.Params = [];
        }
        const lower = name.toLowerCase();
        const existing = params.Params.find((p) => p.Name.trim().toLowerCase() === lower);
        if (existing) {
            existing.Value = value;
            existing.Type = 'Output';
        } else {
            params.Params.push({ Name: name, Value: value, Type: 'Output' });
        }
    }
}

export function LoadReadSkippedContentAction(): void {
    // Prevents tree-shaking of @RegisterClass decorator
}
