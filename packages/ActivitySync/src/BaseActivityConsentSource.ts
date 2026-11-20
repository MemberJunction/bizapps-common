/**
 * @fileoverview Standing consent from a named source: how an app tells Common which domains a mailbox
 * owner has already agreed to have logged, without Common knowing the app exists.
 *
 * ── A SOURCE RETURNS DATA AND NEVER SEES A MAIL ITEM ──────────────────────────────────────────
 *
 * A source answers one question, once per run: "for this connection's owner, which domains?" (for
 * example, the website domains of the accounts that person owns). Every rule about what that list may
 * capture stays in Common (`consent.ts`, `consent-stages.ts`): which participants count, what a Private
 * mark does, what an exclusion does. A source that could look at an item would make capture depend on
 * which apps a host installed, which is the coupling `BaseActivitySyncExtension` also refuses.
 *
 * Registered by key and named per connection in `Settings.Consent.Sources`:
 *
 * ```ts
 * @RegisterClass(BaseActivityConsentSource, 'Sales.OwnedAccounts')
 * export class OwnedAccountsConsentSource extends BaseActivityConsentSource { ... }
 * ```
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import type { IMetadataProvider, UserInfo } from '@memberjunction/core';

import { DomainOf } from './participants.js';

export interface StandingConsentRequest {
    ConnectionID: string;
    /** `ActivitySyncConnection.OwnerUserID`: whose consent is being asked about. */
    OwnerUserID: string;
    Mailbox: string;
    ContextUser: UserInfo;
    /** The provider the run reads through. A source reads through the same one. */
    Provider: IMetadataProvider;
}

export interface StandingConsentDomain {
    /** A bare domain, e.g. `acme.com`. */
    Domain: string;
    /** Why this domain grants, in words for the audit trail, e.g. the account's name. */
    Label: string;
}

export interface StandingConsent {
    Domains: StandingConsentDomain[];
    /** Things the run should report but that do not stop it, e.g. "user is not linked to an employee". */
    Issues: string[];
}

export abstract class BaseActivityConsentSource {
    /**
     * The domains this connection's owner has standing consent for.
     *
     * "Nothing to grant" is an empty list, with an issue when the reason is worth an operator's time.
     * A read that FAILED must throw: an empty list would make a broken source look like an owner with
     * no accounts, and the run would quietly capture nothing. A throw fails the run for this connection.
     */
    public abstract StandingConsent(request: StandingConsentRequest): Promise<StandingConsent>;
}

/**
 * Consumer mailbox domains. One of these on an account record (a sole trader's Gmail as the "website")
 * would otherwise grant standing consent for every personal email the owner exchanges with anyone there.
 */
export const FREE_MAIL_DOMAINS: ReadonlySet<string> = new Set([
    'gmail.com', 'googlemail.com', 'outlook.com', 'hotmail.com', 'live.com', 'msn.com', 'yahoo.com', 'ymail.com',
    'rocketmail.com', 'icloud.com', 'me.com', 'mac.com', 'aol.com', 'proton.me', 'protonmail.com', 'pm.me',
    'gmx.com', 'gmx.net', 'mail.com', 'zoho.com', 'yandex.com', 'fastmail.com', 'hey.com', 'comcast.net',
    'verizon.net', 'att.net', 'sbcglobal.net', 'qq.com', '163.com',
]);

/** A source by its `Settings.Consent.Sources` key. */
export interface KeyedConsentSource {
    Key: string;
    Source: BaseActivityConsentSource;
}

/**
 * Ask every source, in the order the connection names them, and merge the answers.
 *
 * Throws on the first source that throws, naming the source and the connection: one source failing
 * means the list is incomplete, and the caller must fail the run rather than decide on part of it.
 */
export async function AskConsentSources(sources: readonly KeyedConsentSource[], request: StandingConsentRequest): Promise<StandingConsent> {
    const merged: StandingConsent = { Domains: [], Issues: [] };
    for (const { Key, Source } of sources) {
        let answer: StandingConsent;
        try {
            answer = await Source.StandingConsent(request);
        } catch (e) {
            throw new Error(
                `Consent source "${Key}" failed for connection ${request.ConnectionID} (owner user ${request.OwnerUserID}): ` +
                    (e instanceof Error ? e.message : String(e)),
                { cause: e },
            );
        }
        if (!answer || !Array.isArray(answer.Domains) || !Array.isArray(answer.Issues)) {
            throw new Error(`Consent source "${Key}" returned no Domains/Issues lists for connection ${request.ConnectionID}.`);
        }
        merged.Domains.push(...answer.Domains);
        merged.Issues.push(...answer.Issues.map((issue) => `Consent source "${Key}": ${issue}`));
    }
    return merged;
}

/**
 * What a source's list may actually grant: domain → label, with everything else dropped and reported.
 *
 * Dropped: free-mail domains, the deployment's own domains (our own company kept as an account must not
 * capture internal mail), and anything that is not a bare domain. Matching is exact, so `mail.acme.com`
 * is not `acme.com`; a wider match would grant on a guess.
 */
export function StandingGrantDomains(
    domains: readonly StandingConsentDomain[],
    internalDomains: readonly string[],
): { Granting: Map<string, string>; Issues: string[] } {
    const internal = new Set(internalDomains.map(normalizeDomain));
    const labels = new Map<string, string[]>();
    const issues: string[] = [];
    for (const entry of domains) {
        const domain = normalizeDomain(String(entry?.Domain ?? ''));
        const label = String(entry?.Label ?? '').trim() || domain;
        const refusal = !isBareDomain(domain)
            ? 'is not a domain'
            : FREE_MAIL_DOMAINS.has(domain)
              ? 'is a free-mail domain'
              : internal.has(domain)
                ? 'is one of this deployment\'s own domains'
                : null;
        if (refusal) {
            issues.push(`Standing consent ignored "${domain}" (${label}): it ${refusal}, so it can never grant capture.`);
            continue;
        }
        const known = labels.get(domain) ?? [];
        if (!known.includes(label)) known.push(label);
        labels.set(domain, known);
    }
    return { Granting: new Map([...labels].map(([domain, names]) => [domain, names.join('; ')] as const)), Issues: issues };
}

function normalizeDomain(value: string): string {
    return value.trim().toLowerCase().replace(/^@/, '');
}

function isBareDomain(domain: string): boolean {
    return /^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(domain) && DomainOf(`x@${domain}`) === domain;
}
