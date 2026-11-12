import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';

describe('Angular public-api exports', () => {
    it('exports mjBizAppsCommonAddressLinkFormComponent from generated entities', () => {
        const publicApiPath = path.resolve(__dirname, '../../../Angular/src/public-api.ts');
        const content = fs.readFileSync(publicApiPath, 'utf-8');
        expect(content).toMatch(
            /export\s*\{\s*mjBizAppsCommonAddressLinkFormComponent\s*\}\s*from\s*['"]\.\/lib\/generated\/Entities\/mjBizAppsCommonAddressLink\/mjbizappscommonaddresslink\.form\.component['"];/
        );
    });
});
