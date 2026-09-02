import { describe, expect, it } from 'vitest';
import type { UserInfo } from '@memberjunction/core';

import { BaseActivitySyncExtension, type ActivityWriteContext } from '../BaseActivitySyncExtension.js';
import {
    ExtensionsExtraFilter,
    RunRegisteredExtensions,
    WithTimeout,
    type ExtensionRegistration,
} from '../extensions.js';

const CONN = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
const TYPE = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

function ctx(): ActivityWriteContext {
    return {
        Activity: { ID: 'act-1' } as ActivityWriteContext['Activity'],
        Links: [],
        Item: {} as ActivityWriteContext['Item'],
        ResolvedParties: [],
        UnresolvedParties: [],
        ConnectionID: CONN,
        ProviderTypeCode: 'Microsoft365',
        ContextUser: { ID: 'user' } as UserInfo,
        Provider: {} as ActivityWriteContext['Provider'],
    };
}

function row(overrides: Partial<ExtensionRegistration> = {}): ExtensionRegistration {
    return {
        ID: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        DriverClass: 'Sales.DealLinker',
        Sequence: 10,
        FailurePolicy: 'Skip',
        TimeoutMS: 5000,
        ActivitySyncConnectionID: null,
        ActivitySyncProviderTypeID: null,
        ...overrides,
    };
}

class RecordingExtension extends BaseActivitySyncExtension {
    public calls = 0;
    public async Enrich(): Promise<void> {
        this.calls++;
    }
}

class ThrowingExtension extends BaseActivitySyncExtension {
    public constructor(private readonly message: string) {
        super();
    }
    public async Enrich(): Promise<void> {
        throw new Error(this.message);
    }
}

class SlowExtension extends BaseActivitySyncExtension {
    public async Enrich(): Promise<void> {
        await new Promise((resolve) => setTimeout(resolve, 50));
    }
}

describe('ExtensionsExtraFilter', () => {
    it('includes globals and the named connection / type', () => {
        const filter = ExtensionsExtraFilter(CONN, TYPE);
        expect(filter).toContain('IsEnabled = 1');
        expect(filter).toContain(CONN);
        expect(filter).toContain(TYPE);
        expect(filter).toContain('ActivitySyncConnectionID IS NULL');
        expect(filter).toContain('ActivitySyncProviderTypeID IS NULL');
    });

    it('when the connection has no provider type, only unscoped-to-type rows apply', () => {
        const filter = ExtensionsExtraFilter(CONN, null);
        expect(filter).toContain('ActivitySyncProviderTypeID IS NULL');
        expect(filter).not.toMatch(/ActivitySyncProviderTypeID = /);
    });
});

describe('RunRegisteredExtensions', () => {
    it('runs in Sequence order, not registration order', async () => {
        const order: string[] = [];
        class A extends BaseActivitySyncExtension {
            public async Enrich(): Promise<void> {
                order.push('A');
            }
        }
        class B extends BaseActivitySyncExtension {
            public async Enrich(): Promise<void> {
                order.push('B');
            }
        }
        const create = (driver: string) => (driver === 'A' ? new A() : new B());
        await RunRegisteredExtensions(ctx(), [
            row({ ID: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', DriverClass: 'B', Sequence: 20 }),
            row({ ID: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', DriverClass: 'A', Sequence: 10 }),
        ], create);
        expect(order).toEqual(['A', 'B']);
    });

    it('Skip records the error and continues — the activity is still committed by the caller', async () => {
        const result = await RunRegisteredExtensions(
            ctx(),
            [row({ FailurePolicy: 'Skip' })],
            () => new ThrowingExtension('matcher failed'),
        );
        expect(result.Aborted).toBe(false);
        expect(result.Errors).toBe(1);
        expect(result.Stamps[0].LastError).toMatch(/matcher failed/);
    });

    it('Abort returns Aborted so the writer can roll the activity back and still stamp LastError', async () => {
        const result = await RunRegisteredExtensions(
            ctx(),
            [row({ FailurePolicy: 'Abort' })],
            () => new ThrowingExtension('cannot link'),
        );
        expect(result.Aborted).toBe(true);
        expect(result.Errors).toBe(1);
        expect(result.Stamps[0].LastError).toMatch(/cannot link/);
    });

    it('a missing DriverClass is a failure of that row, not a silent skip', async () => {
        const result = await RunRegisteredExtensions(ctx(), [row({ FailurePolicy: 'Skip' })], () => null);
        expect(result.Errors).toBe(1);
        expect(result.Stamps[0].LastError).toMatch(/No BaseActivitySyncExtension/);
    });

    it('TimeoutMS is enforced', async () => {
        const result = await RunRegisteredExtensions(
            ctx(),
            [row({ FailurePolicy: 'Abort', TimeoutMS: 5 })],
            () => new SlowExtension(),
        );
        expect(result.Aborted).toBe(true);
        expect(result.Stamps[0].LastError).toMatch(/timed out after 5ms/);
    });

    it('success stamps LastError null so a previous error is cleared', async () => {
        const result = await RunRegisteredExtensions(ctx(), [row()], () => new RecordingExtension());
        expect(result.Errors).toBe(0);
        expect(result.Stamps[0].LastError).toBeNull();
    });
});

describe('WithTimeout', () => {
    it('resolves when the work finishes in time', async () => {
        await expect(WithTimeout(Promise.resolve(1), 100, 'x')).resolves.toBe(1);
    });

    it('aborts the controller so Enrich can stop cooperatively', async () => {
        const controller = new AbortController();
        await expect(WithTimeout(new Promise(() => undefined), 5, 'Slow', controller)).rejects.toThrow(
            /timed out after 5ms/,
        );
        expect(controller.signal.aborted).toBe(true);
    });
});
