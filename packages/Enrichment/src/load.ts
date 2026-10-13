import { FixtureEnrichmentProvider } from './providers/FixtureEnrichmentProvider.js';
import { PersonEnrichmentEngine } from './PersonEnrichmentEngine.js';

/** Tree-shaking anchor: referencing the classes keeps their @RegisterClass registrations in the bundle. */
export function LoadCommonEnrichment(): void {
    void PersonEnrichmentEngine;
    void FixtureEnrichmentProvider;
}
