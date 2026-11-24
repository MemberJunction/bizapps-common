/**
 * Copyright (c) MemberJunction.com
 * SPDX-License-Identifier: BUSL-1.1
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(HERE, '..', '..', '..', '..');

const MIRROR_SOURCE_FILES = [
    'packages/Entities/src/company-organization-mirror.ts',
    'packages/Entities/src/company-organization-sync.operation.ts',
    'packages/Entities/src/index.ts',
    'packages/CoreEntitiesServer/src/CompanyOrganizationMirrorServer.ts',
    'packages/CoreEntitiesServer/src/PersonEntityServer.ts',
    'packages/CoreEntitiesServer/src/index.ts',
];

const MIRROR_TEST_FILES = [
    'packages/Entities/src/__tests__/organization-mirror-dedup.test.ts',
    'packages/Entities/src/__tests__/mirror-error-contract.test.ts',
    'packages/Entities/src/__tests__/company-delete-unlink.test.ts',
    'packages/Entities/src/__tests__/mirror-hygiene.test.ts',
    'packages/Server/src/__tests__/company-mirror-sync.test.ts',
    'packages/Server/src/__tests__/company-organization-mirror.test.ts',
    'packages/Server/src/__tests__/company-delete-unlink.test.ts',
];

const TRADEMARK_COPY_TARGETS = [
    ...MIRROR_SOURCE_FILES,
    ...MIRROR_TEST_FILES.filter((file) => !file.endsWith('mirror-hygiene.test.ts')),
    'docs/company-organization-mirroring.md',
    'packages/Angular/prototypes/person-widget-mockups.html',
    'packages/Angular/prototypes/organization-widget-mockups.html',
    'packages/IntegrationTests/README.md',
];

const DISALLOWED_TRADEMARK_PATTERN =
    /\b(Salesforce|HubSpot|Dynamics 365|NetSuite|Workday|Blue Cypress|bluecypress|BCSaaS|QuickBooks|Xero|Stripe|Notion|Linear(?!-gradient))\b/i;

function stripComments(source: string): string {
    return source
        .replace(/\/\*[\s\S]*?\*\//g, (match) => match.replace(/[^\n]/g, ' '))
        .replace(/\/\/.*$/gm, '');
}

describe('Company <-> Organization mirror static hygiene & release-line alignment', () => {
    it('enforces BUSL-1.1 license headers on all mirror source and test files', () => {
        for (const relPath of [...MIRROR_SOURCE_FILES, ...MIRROR_TEST_FILES]) {
            const content = readFileSync(join(REPO_ROOT, relPath), 'utf8');
            const header = content.slice(0, 200);
            expect(header, `${relPath} missing MemberJunction copyright header`).toContain('Copyright (c) MemberJunction.com');
            expect(header, `${relPath} missing SPDX BUSL-1.1 identifier`).toContain('SPDX-License-Identifier: BUSL-1.1');
        }
    });

    it('enforces zero explicit any, zero as unknown casts, and zero BaseEntity.Get()/Set() in mirror sources and tests', () => {
        const explicitAnyPattern = /:\s*any\b|\bas\s+any\b|<any\b/;
        const unknownCastPattern = /\bas\s+unknown\b/;
        const entityGetSetPattern = /\.\s*(?:Get|Set)\s*\(/;

        for (const relPath of [...MIRROR_SOURCE_FILES, ...MIRROR_TEST_FILES]) {
            if (relPath.endsWith('mirror-hygiene.test.ts')) {
                continue;
            }
            const stripped = stripComments(readFileSync(join(REPO_ROOT, relPath), 'utf8'));
            expect(explicitAnyPattern.test(stripped), `${relPath} must not contain explicit any`).toBe(false);
            expect(unknownCastPattern.test(stripped), `${relPath} must not contain as unknown casts`).toBe(false);
            if (MIRROR_SOURCE_FILES.includes(relPath)) {
                expect(entityGetSetPattern.test(stripped), `${relPath} must not call BaseEntity.Get()/Set()`).toBe(false);
            }
        }
    });

    it('enforces domain-neutral copy free of third-party trademark references across mirror files, docs, and prototypes', () => {
        for (const relPath of TRADEMARK_COPY_TARGETS) {
            const content = readFileSync(join(REPO_ROOT, relPath), 'utf8');
            const match = DISALLOWED_TRADEMARK_PATTERN.exec(content);
            expect(match, `${relPath} contains disallowed third-party trademark reference: ${match?.[0] ?? ''}`).toBeNull();
        }
    });

    it('aligns release-lines.json and mj-app.json for MJ 6.3 edge targeting next', () => {
        const releaseLines = JSON.parse(readFileSync(join(REPO_ROOT, 'release-lines.json'), 'utf8')) as {
            next?: { edgeOnlyMigrations?: string[] };
            lines?: Record<string, { branch: string; status: string; mjVersion: string; appMajor: number; releasesThrough: string }>;
        };
        expect(Array.isArray(releaseLines.next?.edgeOnlyMigrations)).toBe(true);
        expect(releaseLines.lines?.['6.2']?.status).toBe('open');
        expect(releaseLines.lines?.['6.2']?.releasesThrough).toBe('main');

        const mjApp = JSON.parse(readFileSync(join(REPO_ROOT, 'mj-app.json'), 'utf8')) as {
            mjVersionRange?: string;
            license?: string;
        };
        expect(mjApp.license).toBe('BUSL-1.1');
        expect(mjApp.mjVersionRange).toContain('6.3.0-edge');
    });
});
