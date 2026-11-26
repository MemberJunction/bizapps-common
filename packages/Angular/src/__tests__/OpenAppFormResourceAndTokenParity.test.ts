import '@angular/compiler';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { MJGlobal } from '@memberjunction/global';
import { BaseFormComponent, BaseFormPanel } from '@memberjunction/ng-base-forms';
import { BaseResourceComponent } from '@memberjunction/ng-shared';
import {
    ActivityContentPanel,
    ActivityFilesPanel,
    ActivityHeaderPanel,
    ActivityHierarchyPanel,
    ActivityLinksPanel,
    LoadBizAppsCommonClient,
} from '../public-api';

const HERE = dirname(fileURLToPath(import.meta.url));
const ANGULAR_ROOT = resolve(HERE, '..', '..');
const REPO_ROOT = resolve(ANGULAR_ROOT, '..', '..');

interface MjAppManifest {
    name: string;
    packages?: {
        client?: Array<{ name: string; role?: string; startupExport?: string }>;
    };
}

interface ApplicationMetadataRecord {
    fields?: {
        Name?: string;
        DefaultNavItems?: Array<{
            Label?: string;
            Icon?: string;
            ResourceType?: string;
            DriverClass?: string;
        }>;
    };
}

interface EntityMetadataRecord {
    primaryKey?: { ID?: string };
}

function stripComments(source: string): string {
    return source
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/<!--[\s\S]*?-->/g, '')
        .replace(/\/\/.*$/gm, '');
}

function collectFiles(dir: string, predicate: (filePath: string) => boolean): string[] {
    const out: string[] = [];
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const full = join(dir, entry.name);
        if (entry.isDirectory()) {
            if (entry.name === 'generated' || entry.name === '__tests__' || entry.name === 'node_modules') {
                continue;
            }
            out.push(...collectFiles(full, predicate));
        } else if (predicate(full)) {
            out.push(full);
        }
    }
    return out;
}

describe('OpenApp v3 Readiness: Dual Form, Resource, Design Token & Hygiene Parity', () => {
    it('exports and retains mj-app.json startupExport LoadBizAppsCommonClient with live BaseFormComponent registrations for every Common entity', () => {
        const manifestPath = resolve(REPO_ROOT, 'mj-app.json');
        expect(existsSync(manifestPath)).toBe(true);

        const manifest = JSON.parse(readFileSync(manifestPath, 'utf8')) as MjAppManifest;
        const clientPkg = manifest.packages?.client?.find((p) => p.name === '@mj-biz-apps/common-ng');
        expect(clientPkg?.startupExport).toBe('LoadBizAppsCommonClient');

        // Invoke startupExport exactly as MJExplorer does
        LoadBizAppsCommonClient();

        // Extract every generated BaseEntity registration in @mj-biz-apps/common-entities
        const entitiesSource = readFileSync(
            resolve(REPO_ROOT, 'packages/Entities/src/generated/entities/__mj_BizAppsCommon.ts'),
            'utf8',
        );
        const entityNames = [
            ...entitiesSource.matchAll(/@RegisterClass\(BaseEntity,\s*'([^']+)'\)/g),
        ].map((m) => m[1]);
        expect(entityNames.length).toBeGreaterThanOrEqual(25);

        for (const entityName of entityNames) {
            const registration = MJGlobal.Instance.ClassFactory.GetRegistration(BaseFormComponent, entityName);
            expect(
                registration,
                `Expected active live @RegisterClass(BaseFormComponent, '${entityName}') registration`,
            ).toBeDefined();
        }

        // Also verify every entity referenced in metadata/entities/.entities.json has a live BaseFormComponent
        const metadataEntities = JSON.parse(
            readFileSync(resolve(REPO_ROOT, 'metadata/entities/.entities.json'), 'utf8'),
        ) as EntityMetadataRecord[];
        for (const rec of metadataEntities) {
            const lookup = rec.primaryKey?.ID ?? '';
            const match = lookup.match(/Name=(.+)$/);
            if (match) {
                const name = match[1];
                expect(
                    MJGlobal.Instance.ClassFactory.GetRegistration(BaseFormComponent, name),
                    `Metadata entity '${name}' must retain BaseFormComponent registration`,
                ).toBeDefined();
            }
        }

        // Verify Activity BaseFormPanel slot contributions coexist alongside BaseFormComponent
        const panelRegs = MJGlobal.Instance.ClassFactory.GetAllRegistrations(BaseFormPanel);
        for (const panelClass of [
            ActivityHeaderPanel,
            ActivityContentPanel,
            ActivityLinksPanel,
            ActivityFilesPanel,
            ActivityHierarchyPanel,
        ]) {
            expect(panelRegs.some((r) => r.SubClass === panelClass)).toBe(true);
        }
    });

    it('maintains Navigation & Resource Parity between metadata/applications DefaultNavItems and live BaseResourceComponent registrations', () => {
        LoadBizAppsCommonClient();

        const appMetadataPath = resolve(REPO_ROOT, 'metadata/applications/.common-application.json');
        const appMetadata = JSON.parse(readFileSync(appMetadataPath, 'utf8')) as ApplicationMetadataRecord[];
        const navItems = appMetadata[0]?.fields?.DefaultNavItems ?? [];
        expect(navItems.length).toBeGreaterThanOrEqual(5);

        const sectionsSource = readFileSync(
            resolve(ANGULAR_ROOT, 'src/lib/sections/common-sections.component.ts'),
            'utf8',
        );

        for (const item of navItems) {
            const driver = item.DriverClass;
            expect(driver).toBeTruthy();
            if (!driver) continue;

            const reg = MJGlobal.Instance.ClassFactory.GetRegistration(BaseResourceComponent, driver);
            expect(
                reg,
                `DefaultNavItems DriverClass '${driver}' must be registered as BaseResourceComponent`,
            ).toBeDefined();
            expect(sectionsSource).toContain(`@RegisterClass(BaseResourceComponent, '${driver}')`);
        }

        // Every top-level resource uses <mj-page-layout>, NotifyLoadComplete(), queueMicrotask deferral, NavigationService, and OnPush
        const pageLayoutCount = (sectionsSource.match(/<mj-page-layout>/g) ?? []).length;
        expect(pageLayoutCount).toBe(navItems.length);
        expect(sectionsSource).toContain('NotifyLoadComplete()');
        expect(sectionsSource).toContain('queueMicrotask(');
        expect(sectionsSource).toContain('NavigationService');
        const onPushCount = (sectionsSource.match(/ChangeDetectionStrategy\.OnPush/g) ?? []).length;
        expect(onPushCount).toBe(navItems.length);
    });

    it('enforces semantic --mj-* CSS tokens (zero raw #hex, rgb, rgba, hsl) across Activity UI, pages, sections, and identity header', () => {
        const filesToCheck = [
            resolve(ANGULAR_ROOT, 'src/lib/components/activity-artifact-badge/activity-artifact-badge.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/activity-artifact-section/activity-artifact-section.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/activity-composer/activity-composer.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/identity-header/activity-identity.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/identity-header/activity-identity.component.html'),
            resolve(ANGULAR_ROOT, 'src/lib/components/identity-header/identity-header.css'),
            resolve(ANGULAR_ROOT, 'src/lib/custom/panels/activity-content.panel.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/custom/panels/activity-links.panel.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/custom/panels/activity-files.panel.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/custom/panels/activity-hierarchy.panel.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/custom/panels/activity-type-hierarchy.panel.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/activities-dashboard.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/common-dashboard.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/people-list.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/organizations-list.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/sections/common-sections.component.ts'),
        ];

        const rawColorPattern = /#[0-9a-fA-F]{3,8}\b|\brgba?\s*\(|\bhsla?\s*\(/;

        for (const filePath of filesToCheck) {
            const stripped = stripComments(readFileSync(filePath, 'utf8'));
            expect(stripped, `Raw color literal found in ${filePath}`).not.toMatch(rawColorPattern);
        }
    });

    it('enforces zero window.print(), zero localStorage/sessionStorage, OnPush hygiene, and zero any/unknown/.Get/.Set', () => {
        const allSourceFiles = collectFiles(
            resolve(ANGULAR_ROOT, 'src/lib'),
            (p) => p.endsWith('.ts') || p.endsWith('.html') || p.endsWith('.css'),
        );
        expect(allSourceFiles.length).toBeGreaterThan(20);

        for (const filePath of allSourceFiles) {
            const stripped = stripComments(readFileSync(filePath, 'utf8'));
            expect(stripped, `window.print() forbidden in ${filePath}`).not.toMatch(/window\.print\s*\(/);
            expect(stripped, `localStorage/sessionStorage forbidden in ${filePath}`).not.toMatch(
                /\b(localStorage|sessionStorage)\b/,
            );
        }

        // Strict type-safety & OnPush check on all Activity + page + section TypeScript files
        const activityAndPageFiles = [
            resolve(ANGULAR_ROOT, 'src/lib/data/activity-artifact.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/activity-artifact-badge/activity-artifact-badge.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/activity-artifact-section/activity-artifact-section.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/activity-composer/activity-composer.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/components/identity-header/activity-identity.component.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/custom/panels/activity-content.panel.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/activities-dashboard.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/common-dashboard.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/people-list.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/pages/organizations-list.page.ts'),
            resolve(ANGULAR_ROOT, 'src/lib/sections/common-sections.component.ts'),
        ];

        for (const filePath of activityAndPageFiles) {
            const stripped = stripComments(readFileSync(filePath, 'utf8'));
            expect(stripped, `Explicit any forbidden in ${filePath}`).not.toMatch(/:\s*any\b|\bas\s+any\b|<any>/);
            expect(stripped, `Lazy unknown forbidden in ${filePath}`).not.toMatch(/:\s*unknown\b|\bas\s+unknown\b|<unknown>/);
            expect(stripped, `BaseEntity .Get()/.Set() forbidden in ${filePath}`).not.toMatch(/\.(Get|Set)\s*\(/);
            if (!filePath.endsWith('activity-artifact.ts')) {
                expect(stripped, `ChangeDetectionStrategy.OnPush required in ${filePath}`).toContain(
                    'ChangeDetectionStrategy.OnPush',
                );
            }
        }
    });
});
