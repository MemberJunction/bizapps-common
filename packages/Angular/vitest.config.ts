import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Plugin } from 'vite';
import { defineConfig } from 'vitest/config';

const rootDir = dirname(fileURLToPath(import.meta.url));
const entitiesSrc = resolve(rootDir, '../Entities/src/index.ts');

/**
 * Inlines external Angular `templateUrl`, `styleUrls`, and `styleUrl` declarations
 * so standalone components can compile with JIT inside Vitest without Angular CLI's
 * full build pipeline.
 */
function inlineAngularComponentResources(): Plugin {
    return {
        name: 'bizapps-inline-angular-resources',
        enforce: 'pre',
        transform(code: string, id: string) {
            const cleanId = id.split('?')[0];
            if (!cleanId.endsWith('.ts') || cleanId.endsWith('.d.ts')) {
                return null;
            }
            if (!code.includes('templateUrl') && !code.includes('styleUrl')) {
                return null;
            }

            const dir = dirname(cleanId);
            let transformed = code.replace(
                /templateUrl\s*:\s*['"]([^'"]+)['"]/g,
                (_match, relPath: string) => {
                    const fullPath = resolve(dir, relPath);
                    const html = readFileSync(fullPath, 'utf-8');
                    return `template: ${JSON.stringify(html)}`;
                }
            );

            transformed = transformed.replace(
                /styleUrls\s*:\s*\[([^\]]*)\]/g,
                (_match, rawList: string) => {
                    const urls = Array.from(rawList.matchAll(/['"]([^'"]+)['"]/g), m => m[1]);
                    const styles = urls.map(relPath => {
                        const fullPath = resolve(dir, relPath);
                        return JSON.stringify(readFileSync(fullPath, 'utf-8'));
                    });
                    return `styles: [${styles.join(', ')}]`;
                }
            );

            transformed = transformed.replace(
                /styleUrl\s*:\s*['"]([^'"]+)['"]/g,
                (_match, relPath: string) => {
                    const fullPath = resolve(dir, relPath);
                    const css = readFileSync(fullPath, 'utf-8');
                    return `styles: [${JSON.stringify(css)}]`;
                }
            );

            return {
                code: transformed,
                map: null,
            };
        },
    };
}

export default defineConfig({
    plugins: [inlineAngularComponentResources()],
    resolve: {
        alias: {
            '@mj-biz-apps/common-entities': entitiesSrc,
        },
    },
    test: {
        projects: [
            {
                extends: true,
                test: {
                    name: 'node',
                    environment: 'node',
                    include: ['src/**/*.test.ts'],
                    exclude: ['src/**/*.dom.test.ts'],
                },
            },
            {
                extends: true,
                test: {
                    name: 'dom',
                    environment: 'jsdom',
                    setupFiles: ['./vitest.dom.setup.ts'],
                    include: ['src/**/*.dom.test.ts'],
                },
            },
        ],
    },
});
