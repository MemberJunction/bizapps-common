import { describe, expect, it, vi, beforeEach } from 'vitest';

/**
 * THE BOOTSTRAP ITSELF, which nothing exercised.
 *
 * Everything in this branch rests on two registries: a host registers a transport factory, and a
 * host registers its live-mailbox attestation. Both are reachable only because
 * `LoadBizAppsCommonServer` calls their loaders, and `LoadBizAppsCommonServer` is what
 * `DynamicPackageLoader` calls at MJAPI startup.
 *
 * Measured before writing this: commenting out EITHER call left all 43 tests green. The unit tests
 * for both loaders call them directly, so they prove each loader works and say nothing about whether
 * anything invokes it — which is exactly the defect class this whole branch exists to remove, sitting
 * in the wiring that makes the removal effective.
 *
 * What each omission costs, neither of them loud:
 *
 *   * no `LoadLiveMailboxPolicyFromEnv()` — a host that set all four environment variables correctly
 *     gets live fetch REFUSED, and the refusal tells it to set the variables it already set.
 *   * no `LoadGraphTransportFactory()` — no transport is ever built for any connection, and the
 *     provider refuses with "no transport factory registered" on a host that configured everything.
 *
 * The heavy imports are stubbed rather than stood up: this asserts the CALLS happen, and each
 * loader's own behaviour is covered by its own file.
 */
const H = vi.hoisted(() => ({
    loadEngine: vi.fn(),
    loadSync: vi.fn(),
    loadLog: vi.fn(),
    loadFactory: vi.fn(),
    loadPolicy: vi.fn(() => false),
}));

vi.mock('@mj-biz-apps/common-entities', () => ({}));
vi.mock('@mj-biz-apps/common-actions', () => ({}));
vi.mock('@mj-biz-apps/common-core-entities-server', () => ({ LoadActivitySyncEngine: H.loadEngine }));
vi.mock('../custom/sync-activities.action.js', () => ({
    SyncActivitiesAction: class {},
    LoadSyncActivitiesAction: H.loadSync,
}));
vi.mock('../custom/log-activity.action.js', () => ({
    LogActivityAction: class {},
    LoadLogActivityAction: H.loadLog,
}));
vi.mock('../custom/graph-transport-factory.js', () => ({
    GraphTransportFactory: () => null,
    LoadGraphTransportFactory: H.loadFactory,
}));
vi.mock('../custom/live-mailbox-policy.js', () => ({
    LoadLiveMailboxPolicyFromEnv: H.loadPolicy,
    ENV_GROUP: 'ACTIVITY_SYNC_MAILBOX_POLICY_GROUP',
    ENV_ACCEPTED_RISK: 'ACTIVITY_SYNC_MAILBOX_POLICY_ACCEPTED_RISK',
    ENV_CONFIRMED_BY: 'ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_BY',
    ENV_CONFIRMED_AT: 'ACTIVITY_SYNC_MAILBOX_POLICY_CONFIRMED_AT',
}));
vi.mock('../generated/generated.js', () => ({}));
vi.mock('../generated/class-registrations-manifest.js', () => ({ CLASS_REGISTRATIONS: [] }));

import { LoadBizAppsCommonServer } from '../index.js';

describe('MJAPI startup wires the seams this package adds', () => {
    beforeEach(() => {
        H.loadFactory.mockClear();
        H.loadPolicy.mockClear();
        H.loadEngine.mockClear();
    });

    it('registers the Graph transport factory', () => {
        LoadBizAppsCommonServer();
        expect(H.loadFactory, 'without this no connection ever gets a transport').toHaveBeenCalled();
    });

    it('reads this host attestation from the environment', () => {
        LoadBizAppsCommonServer();
        expect(
            H.loadPolicy,
            'without this a correctly configured host is refused, and told to set what it set',
        ).toHaveBeenCalled();
    });

    it('still loads the engine and the actions it was already responsible for', () => {
        // Guards against a well-meaning reorder dropping one of the pre-existing calls while adding
        // the two new ones.
        LoadBizAppsCommonServer();
        expect(H.loadEngine).toHaveBeenCalled();
        expect(H.loadSync).toHaveBeenCalled();
        expect(H.loadLog).toHaveBeenCalled();
    });

    it('is idempotent enough to call twice', () => {
        // DynamicPackageLoader is not guaranteed to call this once, and both registries are
        // last-call-wins by design rather than by accident.
        LoadBizAppsCommonServer();
        LoadBizAppsCommonServer();
        expect(H.loadFactory).toHaveBeenCalledTimes(2);
        expect(H.loadPolicy).toHaveBeenCalledTimes(2);
    });
});
