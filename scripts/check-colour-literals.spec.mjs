/**
 * Unit tests for scripts/check-colour-literals.mjs (#306).
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { scanText, scanRepo } from './check-colour-literals.mjs';

describe('check-colour-literals (#306)', () => {
    it('flags raw hex, rgb(), rgba(), hsl(), and hsla() literals', () => {
        const hits = scanText([
            '.a { color: #0284c7; }',
            '.b { background: rgba(0, 0, 0, 0.4); }',
            '.c { border-color: hsl(210, 50%, 40%); }',
        ].join('\n'));
        assert.equal(hits.length, 3);
        assert.deepEqual(
            hits.map((h) => ({ line: h.line, kind: h.kind, literal: h.literal })),
            [
                { line: 1, kind: 'hex', literal: '#0284c7' },
                { line: 2, kind: 'rgb', literal: 'rgba(0, 0, 0, 0.4)' },
                { line: 3, kind: 'hsl', literal: 'hsl(210, 50%, 40%)' },
            ],
        );
    });

    it('allows var(--token, <fallback>) including nested rgba() fallbacks', () => {
        const hits = scanText([
            '.a { color: var(--mj-text-primary, #0f172a); }',
            '.b { background: var(--mj-bg-overlay, rgba(15, 23, 42, 0.45)); }',
        ].join('\n'));
        assert.deepEqual(hits, []);
    });

    it('allows custom property definitions (--mj-*: #...)', () => {
        const hits = scanText('  --mj-brand-primary: #0284c7;');
        assert.deepEqual(hits, []);
    });

    it('ignores hex-shaped strings inside JS, CSS, and HTML comments', () => {
        const hits = scanText([
            '// Fixed in issue #311 and #deadbeef',
            '/* Multi-line comment',
            '   referencing #0284c7 and #343 */',
            '<!-- HTML comment (#343) -->',
        ].join('\n'));
        assert.deepEqual(hits, []);
    });

    it('respects colour-literal-ok annotation with a reason on the same or preceding line', () => {
        const allowed = scanText([
            '/* colour-literal-ok: canvas axis requires literal white */',
            '.axis { color: #ffffff; }',
            '.ring { border-color: #000000; } // colour-literal-ok: high-contrast reticle',
        ].join('\n'));
        assert.deepEqual(allowed, []);

        const missingReason = scanText([
            '/* colour-literal-ok: */',
            '.axis { color: #ffffff; }',
        ].join('\n'));
        assert.equal(missingReason.length, 1);
    });

    it('passes across packages/Angular/src in the repository', () => {
        const { violations, emptyRoots } = scanRepo();
        assert.deepEqual(emptyRoots, []);
        assert.deepEqual(violations, []);
    });
});
