import '@angular/compiler';
import { describe, it, expect } from 'vitest';
import { StatTileComponent } from '../stat-tile.component';
import { StatRowComponent } from '../stat-row.component';

/**
 * These pin BEHAVIOUR, not markup: the em-dash rule and the "interactive only when observed" rule
 * are the two things every consuming dashboard depends on, and both are silent when they regress —
 * a zero looks like good news, and a dead tile looks like a tile.
 */
describe('StatTileComponent', () => {
    describe('the em-dash rule', () => {
        it('renders an em dash for null — an unreadable count is NOT zero', () => {
            const tile = new StatTileComponent();
            tile.Value = null;
            expect(tile.DisplayValue).toBe('—');
        });

        it('renders an em dash for undefined, the shape a missing property arrives as', () => {
            const tile = new StatTileComponent();
            tile.Value = undefined as unknown as null;
            expect(tile.DisplayValue).toBe('—');
        });

        it('renders a real zero as "0" — nothing to do is a legitimate answer', () => {
            const tile = new StatTileComponent();
            tile.Value = 0;
            expect(tile.DisplayValue).toBe('0');
        });

        it('passes a pre-formatted string through untouched', () => {
            const tile = new StatTileComponent();
            tile.Value = '1,204';
            expect(tile.DisplayValue).toBe('1,204');
        });
    });

    describe('interactivity follows the subscription', () => {
        it('is not clickable with no subscriber', () => {
            const tile = new StatTileComponent();
            expect(tile.IsClickable).toBe(false);
        });

        it('becomes clickable once something subscribes', () => {
            const tile = new StatTileComponent();
            tile.Clicked.subscribe(() => undefined);
            expect(tile.IsClickable).toBe(true);
        });

        it('emits on activation when clickable', () => {
            const tile = new StatTileComponent();
            let fired = 0;
            tile.Clicked.subscribe(() => (fired += 1));
            tile.OnActivate();
            expect(fired).toBe(1);
        });

        it('swallows activation when nothing is listening, rather than emitting into the void', () => {
            const tile = new StatTileComponent();
            expect(() => tile.OnActivate()).not.toThrow();
            expect(tile.IsClickable).toBe(false);
        });

        it('prevents the default on Space so the tile does not scroll the dashboard', () => {
            const tile = new StatTileComponent();
            tile.Clicked.subscribe(() => undefined);
            let prevented = false;
            tile.OnActivate({ preventDefault: () => (prevented = true) } as unknown as Event);
            expect(prevented).toBe(true);
        });

        it('does not prevent the default when it is not going to act', () => {
            const tile = new StatTileComponent();
            let prevented = false;
            tile.OnActivate({ preventDefault: () => (prevented = true) } as unknown as Event);
            expect(prevented).toBe(false);
        });
    });

    it('defaults to the neutral tone', () => {
        expect(new StatTileComponent().Tone).toBe('none');
    });
});

describe('StatRowComponent', () => {
    it('carries no error by default', () => {
        expect(new StatRowComponent().Error).toBeNull();
    });
});
