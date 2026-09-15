/**
 * Mutation driver for @mj-biz-apps/common-activity-sync.
 *
 * Sales' in-place mutate-checks.mjs dropped M-AC3–M-AC11 when ingest moved here; those
 * checks can no longer be felled from bizapps-sales. This is the explicit answer:
 * mutants for engine-owned behaviour live in this package and run this package's vitest.
 *
 * Restores from a copy, not git, so a dirty tree is safe.
 *
 *   node test-harnesses/mutate-checks.mjs
 *   node test-harnesses/mutate-checks.mjs M-AC11
 */
import { execSync } from 'node:child_process';
import { copyFileSync, readFileSync, writeFileSync, rmSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const PKG = join(dirname(fileURLToPath(import.meta.url)), '..');

const STAGES = 'src/stages.ts';
const GRAPH = 'src/providers/MSGraphActivitySyncProvider.ts';
const WRITER = 'src/writer.ts';
const WATER = 'src/watermark.ts';
const LOAD = 'src/load.ts';
const ACTION = 'src/action-result.ts';
const TRANSPORT = 'src/providers/GraphCommunicationTransport.ts';
const ENGINE = 'src/ActivitySyncEngine.ts';
// Added with the attestation and calendar work. The harness covered neither file, so every
// mutation aimed at the gate or the calendar window reported all-clear by never opening them.
const MSGTRANSPORT = 'src/providers/MessageTransport.ts';
const CALENDAR = 'src/providers/GraphCalendarTransport.ts';
const RECORDED = 'src/providers/RecordedMessageTransport.ts';
// Both of these had changesets enumerating mutations that were "all caught" and NO registered
// mutants at all. The mutations were run by hand at the time and nothing kept them, which is the
// defect this package keeps being written against, applied to its own evidence.
const PARTS = 'src/participants.ts';
const ATTACH = 'src/attachments.ts';
const CALPROVIDER = 'src/providers/MSGraphCalendarSyncProvider.ts';
const MAPPER = 'src/providers/GraphMessageMapper.ts';

const PRODUCT = [
    /**
     * THE ATTESTATION. Three mutants, because the gate guards reading an organisation's mail and its
     * description promised more than it enforced: `Confirmed` and `ConfirmedAt` were compile-time
     * shapes only, so any untyped caller opened tenant-wide Mail.Read AND Calendars.Read with neither.
     */
    {
        id: 'M-LM1',
        file: MSGTRANSPORT,
        expect: ['requires a person on either decision'],
        from: '    if (attestation.Confirmed !== true) {',
        to: '    if (false) {',
    },
    {
        id: 'M-LM2',
        file: MSGTRANSPORT,
        expect: ['requires a person on either decision'],
        from: '    if (!(confirmedAt instanceof Date) || Number.isNaN(confirmedAt.getTime())) {',
        to: '    if (false) {',
    },
    {
        id: 'M-LM3',
        file: MSGTRANSPORT,
        expect: ['rejects an attestation with nobody answerable for it'],
        from: "    if (!attestation.ConfirmedBy?.trim()) {",
        to: '    if (false) {',
    },
    /**
     * DEFECT #2, both halves. Reverting the engine to a hard-coded `[]` -- the literal original defect
     * -- passed 330 of 330 before `engine.internal-domains.test.ts` existed, because the only test
     * driving `Run` stubbed every lookup to empty.
     */
    {
        id: 'M-ID1',
        file: ENGINE,
        expect: ['passes the rule set'],
        from: '                InternalDomains: internalDomains.Rows,',
        to: '                InternalDomains: [],',
    },
    {
        id: 'M-ID2',
        file: ENGINE,
        expect: ['fails the run when the column cannot be parsed, rather than degrading to empty'],
        from: '        if (internalDomains.Failed)',
        to: '        if (false)',
    },
    /** THE REPORTING PATH. A run that succeeds still has to record what it reported. */
    {
        id: 'M-RP1',
        file: ENGINE,
        expect: ['writes its issues to the run row, not just to memory'],
        from: "            run.ErrorMessage = result.Issues.length > 0 ? result.Issues.join(' | ').slice(0, 4000) : null;",
        to: '            run.ErrorMessage = null;',
    },
    {
        id: 'M-RP2',
        file: ENGINE,
        expect: ['defaults to the registered sink when none is passed'],
        from: '        private readonly fileSink: ActivityFileSink | null = HostActivityFileSink(),',
        to: '        private readonly fileSink: ActivityFileSink | null = null,',
    },
    /**
     * THE CALENDAR WINDOW. `WatermarkBasisForKind('Calendar')` is ObservationTime -- when we last
     * LOOKED -- and StartDateTime filters on the EVENT'S own time. Using one as the other means a
     * back-dated meeting is never read, on any run, with no issue and Success = true.
     */
    /**
     * INTERNAL DOMAINS, the parsing half. An empty list is not a disabled filter, it is an INVERTED
     * one -- every participant counts as External -- so each way of quietly producing an empty or
     * wrong list is its own mutant.
     */
    /**
     * THE REFUSAL'S ACTIONABLE HALF. Every other assertion in the suite compares against the
     * `LIVE_GRAPH_REFUSAL` constant, so the message could be trimmed back to "Live Graph fetch is
     * disabled." with the suite still green -- which is how it came to name only the scoped decision,
     * and a function rather than the environment variables a deployment actually sets.
     */
    {
        id: 'M-REF1',
        file: GRAPH,
        expect: ['names the configuration a deployment actually sets'],
        from: "    'sets its ACTIVITY_SYNC_MAILBOX_POLICY_* variables (see @mj-biz-apps/common-server); anything ' +",
        to: "    'is configured by whoever deploys it; anything ' +",
    },
    {
        id: 'M-REF2',
        file: GRAPH,
        expect: ['offers BOTH decisions, not only the scoped one'],
        from: "    'not and the tenant-wide grant is accepted deliberately, in writing, by a named person on a ' +",
        to: "    'not, in which case scope it first. Also ' +",
    },
    /**
     * THE MAPPER'S READ of Graph's own flag. If it stopped reading `hasAttachments`, every rule that
     * asks for attachments would quietly find none on every real message -- the attachment feature
     * doing nothing, on a run that reports success.
     */
    {
        id: 'M-MAP1',
        file: MAPPER,
        expect: ['marks exactly the one message that carries attachments'],
        from: '        HasAttachments: message.hasAttachments === true,',
        to: '        HasAttachments: false,',
    },
    {
        id: 'M-PA1',
        file: PARTS,
        expect: ['refuses text that is not JSON'],
        from: "            Issue: `Rule set \"${ruleSetName}\" has InternalDomains that is not valid JSON. Expected an array like [\"bluecypress.io\"].`,",
        to: '            Issue: undefined,',
    },
    {
        id: 'M-PA2',
        file: PARTS,
        expect: ['refuses valid JSON that is not an array'],
        from: '    if (!Array.isArray(parsed)) {',
        to: '    if (false) {',
    },
    {
        id: 'M-PA3',
        file: PARTS,
        expect: ['normalises case and a leading @', 'de-duplicates rather than counting a domain twice'],
        from: "        const d = String(entry ?? '').trim().toLowerCase().replace(/^@/, '');",
        to: "        const d = String(entry ?? '').trim();",
    },
    {
        id: 'M-PA4',
        file: PARTS,
        expect: ['de-duplicates rather than counting a domain twice'],
        from: '        if (d && !domains.includes(d)) domains.push(d);',
        to: '        if (d) domains.push(d);',
    },
    {
        id: 'M-PA5',
        file: PARTS,
        expect: ['drops empty entries instead of matching an empty domain'],
        from: '        if (d && !domains.includes(d)) domains.push(d);',
        to: '        if (!domains.includes(d)) domains.push(d);',
    },
    /** The warning is how the ORIGINAL defect would have been visible. Silencing it is the regression. */
    {
        id: 'M-PA6',
        file: PARTS,
        expect: ['warns when a scoped rule has no domains to work with'],
        from: '    if (internalDomains.length > 0) return null;',
        to: '    if (true) return null;',
    },
    {
        id: 'M-PA7',
        file: PARTS,
        expect: ['does not treat Any as a participant test'],
        from: "    const scoped = rules.filter((r) => r.ParticipantScope && r.ParticipantScope !== 'Any');",
        to: '    const scoped = rules.filter((r) => r.ParticipantScope);',
    },
    /**
     * ATTACHMENTS. Same situation: an enumerated "all caught" list with nothing registered behind it.
     * Every one of these is a file silently not stored on a run that reports success.
     */
    {
        id: 'M-AT1',
        file: ATTACH,
        expect: ['does not look when the rule did not ask'],
        from: '    const wanted = rule?.IncludeAttachments === true;',
        to: '    const wanted = rule?.IncludeAttachments !== false;',
    },
    {
        id: 'M-AT2',
        file: ATTACH,
        expect: ['does not look when the source says there are none'],
        from: '    const fetch = wanted && item?.HasAttachments === true;',
        to: '    const fetch = wanted;',
    },
    {
        id: 'M-AT3',
        file: ATTACH,
        expect: ['treats zero and negative as no cap rather than "keep nothing"'],
        from: "        MaxBytes: typeof cap === 'number' && cap > 0 ? cap : null,",
        to: "        MaxBytes: typeof cap === 'number' ? cap : null,",
    },
    {
        id: 'M-AT4',
        file: ATTACH,
        expect: ['keeps nothing at all when the policy says not to fetch'],
        from: '    if (!policy.Fetch) return selection;',
        to: '    if (false) return selection;',
    },
    {
        id: 'M-AT5',
        file: ATTACH,
        expect: ['drops inline images but records that it did'],
        from: '        if (candidate.IsInline === true) {',
        to: '        if (false) {',
    },
    {
        id: 'M-AT6',
        file: ATTACH,
        expect: ['skips an unmeasurable file while a cap is in force'],
        from: "        if (policy.MaxBytes !== null && !(typeof candidate.Size === 'number' && candidate.Size >= 0)) {",
        to: '        if (false) {',
    },
    /** Off-by-one at the cap boundary: `>` keeps a file exactly at the cap, `>=` discards it. */
    {
        id: 'M-AT7',
        file: ATTACH,
        expect: ['keeps a file exactly at the cap'],
        from: '        if (policy.MaxBytes !== null && candidate.Size > policy.MaxBytes) {',
        to: '        if (policy.MaxBytes !== null && candidate.Size >= policy.MaxBytes) {',
    },
    {
        id: 'M-AT8',
        file: ATTACH,
        expect: ['says nothing when nothing was dropped'],
        from: '    if (selection.Skipped.length === 0) return null;',
        to: '    if (false) return null;',
    },
    /**
     * THE REPLAY CAP, on a FIRST run. `capped && !!query.Since` left the first run of a truncated
     * replay uncapped, so a newest-first recording wrote a watermark NEWER than the payloads it had
     * withheld -- the live defect, reached without a prior watermark, in durable state a later live
     * transport inherits.
     */
    {
        id: 'M-RC1',
        file: RECORDED,
        expect: ['a truncated first replay yields no watermark'],
        from: '        return { Payloads: payloads, Issues: issues, Capped: capped };',
        to: '        return { Payloads: payloads, Issues: issues, Capped: capped && !!query.Since };',
    },
    /**
     * THE REST OF THE CALENDAR READ. Its changeset enumerated these as "all caught" while the harness
     * carried exactly one mutant for the file. Each is a way for a calendar sync to report Success
     * over data it did not read, or read wrongly.
     */
    {
        id: 'M-CAL1',
        file: CALENDAR,
        expect: ['sends BOTH bounds, which is what makes Graph expand recurring series', 'reaches forward as well as back'],
        from: '                EndDateTime: end,',
        to: '                EndDateTime: undefined,',
    },
    {
        id: 'M-CAL2',
        file: CALENDAR,
        expect: ['falls back to a lookback and says so'],
        from: '        if (!query.Since) {',
        to: '        if (false) {',
    },
    {
        id: 'M-CAL3',
        file: CALENDAR,
        expect: ['asks for cancelled events, because the mapper models them'],
        from: '                IncludeCancelled: true,',
        to: '                IncludeCancelled: false,',
    },
    {
        id: 'M-CAL4',
        file: CALENDAR,
        expect: ['reads SourceData, not the normalized Events'],
        from: '        const payloads = (result.SourceData ?? []) as Record<string, unknown>[];',
        to: '        const payloads = (result.Events ?? []) as Record<string, unknown>[];',
    },
    {
        id: 'M-CAL5',
        file: CALENDAR,
        expect: ['warns when recurrence was not expanded despite a bounded window'],
        from: '        if (result.RecurrenceExpanded === false) {',
        to: '        if (false) {',
    },
    {
        id: 'M-CAL6',
        file: CALENDAR,
        expect: ['throws when Graph refuses, instead of reporting an empty calendar'],
        from: '        if (!result?.Success) {',
        to: '        if (false) {',
    },
    {
        id: 'M-CAL7',
        file: CALENDAR,
        expect: ['flags a capped read, which may have left events behind'],
        from: '        return { Payloads: payloads, Issues: issues, Capped: capped };',
        to: '        return { Payloads: payloads, Issues: issues, Capped: false };',
    },
    /** A replayed calendar run that claims to be live writes rows indistinguishable from real ones. */
    {
        id: 'M-CAL8',
        file: CALPROVIDER,
        expect: ['reports IsLive from the transport rather than claiming true'],
        from: '        return this.Transport?.IsLive ?? true;',
        to: '        return true;',
    },
    /**
     * SURFACE DISPATCH. One connection drives two surfaces from the same type row; handing the mail
     * driver to the calendar pass built a MAIL transport, fed message payloads to the event mapper,
     * and dropped every one for having no start time -- reported as a successful, empty calendar.
     */
    {
        id: 'M-SD1',
        file: ENGINE,
        expect: ['tells the calendar surface the CALENDAR driver'],
        from: "    const declared = kind === 'Calendar' ? typeRow?.CalendarDriverClass : typeRow?.DriverClass;",
        to: '    const declared = typeRow?.DriverClass;',
    },
    {
        id: 'M-SD2',
        file: ENGINE,
        expect: ['treats a blank column as absent'],
        from: '    return declared?.trim() ? declared.trim() : fallback;',
        to: '    return declared ?? fallback;',
    },
    {
        id: 'M-CW1',
        file: CALENDAR,
        expect: ['does NOT start the window at the watermark'],
        from: '        const start = new Date(now.getTime() - this.LookbackDays * 86_400_000);',
        to: '        const start = query.Since ?? new Date(now.getTime() - this.LookbackDays * 86_400_000);',
    },
    {
        id: 'M-AC6',
        file: STAGES,
        expect: ['exclusions run first and an Include rule cannot outrank them'],
        from: '    return [new ExclusionStage(), new RulesStage(), new KnownParticipantStage()];',
        to: '    return [new RulesStage(), new ExclusionStage(), new KnownParticipantStage()];',
    },
    {
        id: 'M-AC11',
        file: GRAPH,
        expect: ['Graph provider refuses live fetch until an Application Access Policy exists'],
        from: '        if ((this.Transport?.IsLive ?? true) && !this.AllowLiveFetch) {',
        to: '        if (false && (this.Transport?.IsLive ?? true) && !this.AllowLiveFetch) {',
    },
    {
        // The exemption that lets a REPLAY run without the live opt-in. Widening it to every
        // transport would re-open the tenant-wide read behind a flag that still reads as off.
        id: 'M-AC23',
        file: GRAPH,
        expect: ['refuses with the tenant-wide warning when live fetch is not opted in'],
        from: '        if ((this.Transport?.IsLive ?? true) && !this.AllowLiveFetch) {',
        to: '        if (false && !this.AllowLiveFetch) {',
    },
    {
        // An absent transport must be the STRICTER case. Defaulting it to non-live would let the
        // default construction slip past the refusal entirely.
        id: 'M-AC24',
        file: GRAPH,
        expect: ['prefers the tenant-wide warning in the DEFAULT construction'],
        from: '        if ((this.Transport?.IsLive ?? true) && !this.AllowLiveFetch) {',
        to: '        if ((this.Transport?.IsLive ?? false) && !this.AllowLiveFetch) {',
    },
    {
        // The one-message bug, restored. This shape reported a clean empty sync for a mailbox that
        // had exactly one new message.
        id: 'M-AC25',
        file: GRAPH,
        expect: ['maps exactly ONE payload rather than silently dropping it'],
        from: '        const mapped = MapGraphMessages(isEnvelope ? only : raw.Payloads, query.Mailbox);',
        to: '        const mapped = MapGraphMessages(raw.Payloads.length === 1 ? raw.Payloads[0] : raw.Payloads, query.Mailbox);',
    },
    {
        // IsLive must follow the TRANSPORT. Hard-coding it true again would make a replayed run
        // indistinguishable from a real one in the database.
        id: 'M-AC26',
        file: GRAPH,
        expect: ['reports IsLive from the transport, not from the class'],
        from: '        return this.Transport?.IsLive ?? true;',
        to: '        return true;',
    },
    {
        // The CredentialsRef read itself. Ignoring the column again puts us back where we started:
        // a connection naming its credential and being silently disregarded.
        id: 'M-AC29',
        file: GRAPH,
        expect: ['refuses with a CredentialsRef-specific message when the connection names none'],
        from: "        const ref = (context.CredentialsRef ?? '').trim();",
        to: "        const ref = 'always-set';",
    },
    {
        // A constructor-supplied transport must win. Dropping this guard lets a database row swap
        // out what a caller handed in.
        id: 'M-AC30',
        file: GRAPH,
        expect: ['NEVER replaces a transport given to the constructor'],
        // Single-line anchor ON PURPOSE. A multi-line one embedded LF and silently stopped
        // matching the moment the file was checked out with CRLF — the mutant then SKIPPED,
        // which reads as 'not proven' rather than 'broken', and is exactly the quiet failure
        // this harness exists to catch.
        from: '        if (this.Transport) {',
        to: '        if (false && this.Transport) {',
    },
    {
        // A swallowed transport failure becomes a successful empty sync, which clears LastError and
        // advances the watermark past mail nobody read.
        id: 'M-AC27',
        file: TRANSPORT,
        expect: ['THROWS when Graph reports failure, rather than returning an empty batch'],
        from: '        if (!result?.Success) {',
        to: '        if (false && !result?.Success) {',
    },
    {
        // Dropping the credential guard lets an empty secret reach MJ, which then silently falls
        // back to environment variables and reads whatever mailbox those point at.
        id: 'M-AC28',
        file: TRANSPORT,
        expect: ['refuses an incomplete credential and NAMES the missing fields'],
        from: '        if (missing.length > 0) {',
        to: '        if (false && missing.length > 0) {',
    },
    {
        id: 'M-AC18',
        file: WRITER,
        expect: ['stores a cancelled meeting as Cancelled, not Logged'],
        from: "        activity.Status = input.Item.Cancelled ? 'Cancelled' : 'Logged';",
        to: "        activity.Status = 'Logged';",
    },
    {
        id: 'M-AC19',
        file: WATER,
        expect: ['uses OBSERVATION time for a calendar surface, never the item time'],
        from: '        return items.length > 0 ? observedAt : null;',
        to: '        return newestStartedAt(items);',
    },
    {
        id: 'M-AC20',
        file: WATER,
        expect: ['withholds the advance on ANY failure — one is enough'],
        from: '    return outcome.Failed === 0;',
        to: '    return true;',
    },
    {
        id: 'M-AC21',
        file: WATER,
        expect: ['calendar Graph reports observation time, not the event start'],
        from: '        return items.length > 0 ? observedAt : null;',
        to: '        return newestStartedAt(items);',
    },
    {
        id: 'M-AC22',
        file: LOAD,
        expect: ['does not convert a failed read into an empty list'],
        from: '    if (!success) return { Failed: true, Issue: `${what} lookup failed.` };',
        to: '    if (!success) return { Failed: false, Rows: [] };',
    },
    {
        id: 'M-B2',
        file: ACTION,
        expect: ['does not report NO_CONNECTIONS when the connection load failed'],
        from: '    if (!fleet.Success && fleet.ConnectionsAttempted === 0) {',
        to: '    if (false && !fleet.Success && fleet.ConnectionsAttempted === 0) {',
    },
    // --- Exclusions: switched off, and the window of items they cover. Three columns that existed
    // --- with no reader, so every one of these mutants was the shipping behaviour until now.
    {
        id: 'M-AC31',
        file: STAGES,
        expect: ['does not apply when disabled', 'lets the item through when the exclusion is switched off'],
        from: '    if (exclusion.IsEnabled === false) return false;',
        to: '',
    },
    {
        // Absence must not read as "off": a row loaded without the column would stop excluding, which
        // is the direction that lets mail through.
        id: 'M-AC32',
        file: STAGES,
        expect: ['applies when the flag is absent, rather than assuming off'],
        from: '    if (exclusion.IsEnabled === false) return false;',
        to: '    if (!exclusion.IsEnabled) return false;',
    },
    {
        id: 'M-AC33',
        file: STAGES,
        expect: ['does not apply to an item before EffectiveFrom'],
        from: '    if (from && occurredAt.getTime() < from.getTime()) return false;',
        to: '',
    },
    {
        id: 'M-AC34',
        file: STAGES,
        expect: ['does not apply to an item after EffectiveTo'],
        from: '    if (to && occurredAt.getTime() > to.getTime()) return false;',
        to: '',
    },
    {
        // Both bounds are inclusive, matching RuleRow.DateFrom/DateTo one stage later.
        id: 'M-AC35',
        file: STAGES,
        expect: ['is inclusive at each boundary'],
        from: '    if (from && occurredAt.getTime() < from.getTime()) return false;',
        to: '    if (from && occurredAt.getTime() <= from.getTime()) return false;',
    },
    {
        id: 'M-AC36',
        file: STAGES,
        expect: ['is inclusive at each boundary'],
        from: '    if (to && occurredAt.getTime() > to.getTime()) return false;',
        to: '    if (to && occurredAt.getTime() >= to.getTime()) return false;',
    },
    {
        // One lapsed exclusion must not disarm the rest of the list.
        id: 'M-AC37',
        file: STAGES,
        expect: ['keeps evaluating later exclusions after skipping one'],
        from: '            if (!ExclusionAppliesTo(exclusion, item.StartedAt)) continue;',
        to: '            if (!ExclusionAppliesTo(exclusion, item.StartedAt)) break;',
    },
    {
        // Item time, not run time — what keeps a re-run's verdict reproducible.
        id: 'M-AC38',
        file: STAGES,
        expect: ['judges by when the item occurred, not when the sync runs'],
        from: 'if (!ExclusionAppliesTo(exclusion, item.StartedAt)) continue;',
        to: 'if (!ExclusionAppliesTo(exclusion, new Date())) continue;',
    },
    // --- ActivitySyncProviderType.IsActive: the administrator's off switch, previously unread.
    {
        id: 'M-AC39',
        file: ENGINE,
        expect: [
            'refuses the run, naming the type, when the type is switched off',
            'refuses before fetching anything and writes nothing',
        ],
        from: '        if (typeRow?.IsActive === false) {',
        to: '        if (false && typeRow?.IsActive === false) {',
    },
    {
        id: 'M-AC40',
        file: ENGINE,
        expect: ['keeps running when the row carries no IsActive at all'],
        from: '        if (typeRow?.IsActive === false) {',
        to: '        if (!typeRow?.IsActive) {',
    },
    {
        // The trap this whole fix walked into: declaring the field without requesting it leaves it
        // undefined at runtime, so the check above silently never fires.
        id: 'M-AC41',
        file: ENGINE,
        expect: ['asks for every ProviderTypeRow field by name, and no others'],
        from: "'CalendarDriverClass', 'IsActive'],",
        to: "'CalendarDriverClass'],",
    },
];

function runVitest() {
    return execSync('pnpm exec vitest run', {
        cwd: PKG,
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'pipe'],
    });
}

const wanted = process.argv.slice(2).filter((a) => a !== '--list');
if (process.argv.includes('--list')) {
    for (const m of PRODUCT) console.log(`${m.id}  ${m.file}  expect: ${m.expect.join(', ')}`);
    process.exit(0);
}

const selected = wanted.length ? PRODUCT.filter((m) => wanted.includes(m.id)) : PRODUCT;
let failed = 0;

for (const m of selected) {
    const dir = mkdtempSync(join(tmpdir(), `mut-${m.id}-`));
    const backup = join(dir, 'backup');
    const full = join(PKG, m.file);
    copyFileSync(full, backup);
    const original = readFileSync(full, 'utf8');
    const count = original.split(m.from).length - 1;
    if (count !== 1) {
        copyFileSync(backup, full);
        rmSync(dir, { recursive: true, force: true });
        console.error(`SKIP ${m.id}: anchor matched ${count} times in ${m.file}`);
        failed++;
        continue;
    }
    writeFileSync(full, original.replace(m.from, m.to));
    let output = '';
    let threw = false;
    try {
        output = runVitest();
    } catch (err) {
        threw = true;
        output = `${err.stdout ?? ''}${err.stderr ?? ''}`;
    }
    copyFileSync(backup, full);
    const restored = readFileSync(full, 'utf8');
    if (restored !== original) {
        writeFileSync(full, original);
        console.error(`FAIL ${m.id}: restore did not match the copy`);
        failed++;
        rmSync(dir, { recursive: true, force: true });
        continue;
    }
    rmSync(dir, { recursive: true, force: true });

    if (!threw) {
        console.error(`FAIL ${m.id}: suite stayed green`);
        failed++;
        continue;
    }
    const missing = m.expect.filter((name) => !output.includes(name));
    if (missing.length) {
        console.error(`FAIL ${m.id}: failed but did not name ${missing.join(', ')}`);
        failed++;
        continue;
    }
    console.log(`OK   ${m.id}: felled ${m.expect.join(', ')}`);
}

if (failed > 0) {
    console.error(`\n${failed} mutant(s) did not prove their check.`);
    process.exit(1);
}
console.log(`\n${selected.length} mutant(s) proved their checks can fail.`);
