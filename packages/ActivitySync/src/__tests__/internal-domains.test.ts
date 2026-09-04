/**
 * `InternalDomains` — the column that decides what "internal" means, and had no reader.
 *
 * THE DEFECT. `ActivitySyncRuleSet.InternalDomains` describes itself as "Required for any rule using
 * ParticipantScope", `participants.ts` names it as where the list lives, and
 * `ActivitySyncEngine` passed a hard-coded `[]` into every qualification context. So the column was
 * written, documented, migrated, and never read — the same shape as the `CredentialsRef` gap.
 *
 * WHY AN EMPTY LIST IS WORSE THAN NO FEATURE. `ClassifyParticipants` counts an address as Internal
 * only when its domain appears in the list. With an empty list every participant is External, so:
 *
 *   HasExternal / AllExternal  match EVERYTHING, including the purely internal chatter they exist
 *                              to keep out — a filter that reads as working and filters nothing
 *   AllInternal / HasInternal  match NOTHING
 *   Mixed                      can never match
 *
 * A rule set that means to exclude internal mail therefore includes all of it. That is why a
 * malformed list fails the run instead of degrading to empty, and why an absent one is called out.
 */
import { describe, expect, it } from 'vitest';

import {
    ClassifyParticipants,
    MatchesParticipantScope,
    ParseInternalDomains,
    ParticipantScopeWarning,
} from '../participants.js';
import type { ItemParticipant } from '../types.js';

const p = (address: string): ItemParticipant => ({
    Address: address,
    Name: null,
    Role: 'To',
    IdentityKind: 'Email',
});

describe('parsing what the rule set declares', () => {
    it('reads a JSON array, the documented format', () => {
        const r = ParseInternalDomains('["bluecypress.io"]', 'Default');
        expect(r).toEqual({ Ok: true, Domains: ['bluecypress.io'] });
    });

    it('accepts several domains', () => {
        const r = ParseInternalDomains('["bluecypress.io", "memberjunction.com"]', 'Default');
        expect(r.Ok && r.Domains).toEqual(['bluecypress.io', 'memberjunction.com']);
    });

    /**
     * Normalised exactly as `ClassifyParticipants` normalises the domain it extracts from an
     * address. If these two disagreed, a correctly-written list would silently match nothing —
     * which is the empty-list failure wearing a different hat.
     */
    it('normalises case and a leading @, matching how addresses are classified', () => {
        const r = ParseInternalDomains('["@BlueCypress.IO", "  MemberJunction.com  "]', 'Default');
        expect(r.Ok && r.Domains).toEqual(['bluecypress.io', 'memberjunction.com']);
    });

    it('de-duplicates rather than counting a domain twice', () => {
        const r = ParseInternalDomains('["bluecypress.io", "@bluecypress.io", "BLUECYPRESS.IO"]', 'Default');
        expect(r.Ok && r.Domains).toEqual(['bluecypress.io']);
    });

    it('treats null and blank as "none declared", not as an error', () => {
        expect(ParseInternalDomains(null, 'Default')).toEqual({ Ok: true, Domains: [] });
        expect(ParseInternalDomains('   ', 'Default')).toEqual({ Ok: true, Domains: [] });
        expect(ParseInternalDomains('[]', 'Default')).toEqual({ Ok: true, Domains: [] });
    });

    it('drops empty entries instead of matching an empty domain', () => {
        const r = ParseInternalDomains('["bluecypress.io", "", "   ", null]', 'Default');
        expect(r.Ok && r.Domains).toEqual(['bluecypress.io']);
    });
});

describe('malformed fails the run rather than degrading to empty', () => {
    /**
     * The load-bearing pair. Returning `{Ok:true, Domains:[]}` here would turn a typo in a config
     * column into "sync everything", silently.
     */
    it('refuses text that is not JSON', () => {
        const r = ParseInternalDomains('bluecypress.io', 'Sales mailboxes');
        expect(r.Ok).toBe(false);
        expect(!r.Ok && r.Issue).toMatch(/Sales mailboxes/);
        expect(!r.Ok && r.Issue).toMatch(/not valid JSON/);
    });

    it('refuses valid JSON that is not an array', () => {
        const r = ParseInternalDomains('{"domain":"bluecypress.io"}', 'Sales mailboxes');
        expect(r.Ok).toBe(false);
        expect(!r.Ok && r.Issue).toMatch(/not a JSON array/);
    });

    it('names the rule set, because a deployment has more than one', () => {
        const r = ParseInternalDomains('nope', 'Renewals');
        expect(!r.Ok && r.Issue).toContain('"Renewals"');
    });
});

describe('the warning when rules test participants and nothing defines internal', () => {
    const scoped = (s: string | null) => ({ ParticipantScope: s });

    it('warns when a scoped rule has no domains to work with', () => {
        const w = ParticipantScopeWarning([scoped('HasExternal')], []);
        expect(w).toMatch(/no bound rule set defines InternalDomains/);
        expect(w).toMatch(/do not filter what they appear/);
    });

    it('counts how many rules are affected', () => {
        const w = ParticipantScopeWarning([scoped('HasExternal'), scoped('AllInternal'), scoped(null)], []);
        expect(w).toMatch(/^2 rule\(s\)/);
    });

    it('says nothing once domains are defined', () => {
        expect(ParticipantScopeWarning([scoped('HasExternal')], ['bluecypress.io'])).toBeNull();
    });

    it('says nothing when no rule tests participants', () => {
        expect(ParticipantScopeWarning([scoped(null), scoped('Any')], [])).toBeNull();
    });

    /** `Any` is not a participant test — warning on it would cry wolf on every ordinary rule set. */
    it('does not treat Any as a participant test', () => {
        expect(ParticipantScopeWarning([scoped('Any')], [])).toBeNull();
    });

    it('says nothing when there are no rules at all', () => {
        expect(ParticipantScopeWarning([], [])).toBeNull();
    });
});

describe('what the empty list actually did, end to end', () => {
    const internal = p('rep@bluecypress.io');
    const external = p('buyer@customer.com');

    /**
     * The bug, demonstrated rather than described: purely internal mail, a rule that says
     * "only threads with an outside party", and the empty list lets it straight through.
     */
    it('HasExternal matched purely internal mail when the list was empty', () => {
        const composition = ClassifyParticipants([internal, p('boss@bluecypress.io')], []);
        expect(MatchesParticipantScope('HasExternal', composition)).toBe(true);
    });

    it('and correctly excludes it once the domain is declared', () => {
        const composition = ClassifyParticipants([internal, p('boss@bluecypress.io')], ['bluecypress.io']);
        expect(MatchesParticipantScope('HasExternal', composition)).toBe(false);
    });

    it('still catches a genuinely external thread', () => {
        const composition = ClassifyParticipants([internal, external], ['bluecypress.io']);
        expect(MatchesParticipantScope('HasExternal', composition)).toBe(true);
    });

    /** The mirror image: the scope meant to capture internal-only traffic matched nothing. */
    it('AllInternal matched nothing when the list was empty', () => {
        const composition = ClassifyParticipants([internal, p('boss@bluecypress.io')], []);
        expect(MatchesParticipantScope('AllInternal', composition)).toBe(false);
    });

    it('and matches once the domain is declared', () => {
        const composition = ClassifyParticipants([internal, p('boss@bluecypress.io')], ['bluecypress.io']);
        expect(MatchesParticipantScope('AllInternal', composition)).toBe(true);
    });

    /** A parsed list must be usable directly by the classifier — no second normalisation step. */
    it('feeds ParseInternalDomains straight into ClassifyParticipants', () => {
        const parsed = ParseInternalDomains('["@BlueCypress.IO"]', 'Default');
        const composition = ClassifyParticipants([internal, external], parsed.Ok ? parsed.Domains : []);
        expect(composition).toEqual({ Internal: 1, External: 1, Unknown: 0 });
        expect(MatchesParticipantScope('Mixed', composition)).toBe(true);
    });
});
