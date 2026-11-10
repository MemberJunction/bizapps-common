import { describe, expect, it, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { StatTileComponent } from '../stat-tile.component';

describe('StatTileComponent DOM rendering (#309)', () => {
    it('renders a static <div> without a <button> when not clickable', () => {
        const fixture = TestBed.createComponent(StatTileComponent);
        const component = fixture.componentInstance;
        component.Label = 'Relationships';
        component.Value = 42;
        component.Clickable = false;
        fixture.detectChanges();

        const host: HTMLElement = fixture.nativeElement;
        expect(host.querySelector('button.bizapps-stat')).toBeNull();
        const div = host.querySelector('div.bizapps-stat');
        expect(div).not.toBeNull();
        expect(div?.classList.contains('bizapps-stat--clickable')).toBe(false);
        expect(div?.querySelector('.bizapps-stat__value')?.textContent).toBe('42');
    });

    it('renders a real <button type="button"> when Clickable is true or Clicked is observed and emits Clicked on click', () => {
        const fixture = TestBed.createComponent(StatTileComponent);
        const component = fixture.componentInstance;
        component.Label = 'People';
        component.Value = 18;
        const clickSpy = vi.fn();
        component.Clicked.subscribe(clickSpy);
        fixture.detectChanges();

        const host: HTMLElement = fixture.nativeElement;
        expect(host.querySelector('div.bizapps-stat')).toBeNull();
        const button = host.querySelector<HTMLButtonElement>('button.bizapps-stat');
        expect(button).not.toBeNull();
        expect(button?.type).toBe('button');
        expect(button?.classList.contains('bizapps-stat--clickable')).toBe(true);

        button?.click();
        expect(clickSpy).toHaveBeenCalledOnce();
    });
});
