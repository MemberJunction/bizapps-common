/**
 * GraphQL-wire helpers. Every lookup and write goes through ctx.Provider so
 * MJAPI / GraphQL is on the path — never a raw SQL pool.
 */
import { CompositeKey, RunView, type IMetadataProvider } from '@memberjunction/core';
import type { IntegrationCheckContext } from '@memberjunction/testing-integration/registry';
import { Assert } from '@memberjunction/testing-integration/registry';

export function Quote(value: string): string {
    return value.replace(/'/g, "''");
}

export function SameID(left: string | null | undefined, right: string | null | undefined): boolean {
    return (left ?? '').toLowerCase() === (right ?? '').toLowerCase();
}

export function View(ctx: IntegrationCheckContext): RunView {
    return RunView.FromMetadataProvider(ctx.Provider as IMetadataProvider);
}

export async function FindRows<T extends object>(
    ctx: IntegrationCheckContext,
    entityName: string,
    extraFilter: string,
    fields: string[],
): Promise<T[]> {
    const res = await View(ctx).RunView<T>(
        {
            EntityName: entityName,
            ExtraFilter: extraFilter,
            Fields: fields,
            ResultType: 'simple',
        },
        ctx.User,
    );
    Assert(res.Success, `RunView ${entityName} failed: ${res.ErrorMessage ?? 'unknown'}`);
    return res.Results ?? [];
}

export async function FindId(
    ctx: IntegrationCheckContext,
    entityName: string,
    extraFilter: string,
): Promise<string | null> {
    const rows = await FindRows<{ ID: string }>(ctx, entityName, extraFilter, ['ID']);
    return rows[0]?.ID ?? null;
}

export async function RequireSave(entity: { Save: () => Promise<boolean>; LatestResult?: { CompleteMessage?: string } }, what: string): Promise<void> {
    const saved = await entity.Save();
    Assert(saved, `${what} save failed: ${entity.LatestResult?.CompleteMessage ?? 'unknown'}`);
}

export async function LoadById<T extends { InnerLoad: (key: CompositeKey) => Promise<boolean> }>(
    entity: T,
    id: string,
): Promise<T> {
    const key = new CompositeKey();
    key.KeyValuePairs.push({ FieldName: 'ID', Value: id });
    const loaded = await entity.InnerLoad(key);
    Assert(loaded, `failed to load ${id}`);
    return entity;
}
