import { CompositeKey } from '@memberjunction/core';
import { SharedService } from '@memberjunction/ng-shared';

/** Explorer path sentinel for a blank new record (`/record/:entity/new`). */
const NEW_RECORD_URL_ID = 'new';

/** Open a Common entity record in the host (Explorer tab). */
export function OpenCommonRecord(entityName: string, recordID: string | null | undefined): void {
    if (!recordID) return;
    SharedService.Instance.OpenEntityRecord(entityName, CompositeKey.FromID(recordID));
}

/** Open a blank new record for the entity. */
export function OpenNewCommonRecord(entityName: string): void {
    SharedService.Instance.OpenEntityRecord(entityName, CompositeKey.FromID(NEW_RECORD_URL_ID));
}
