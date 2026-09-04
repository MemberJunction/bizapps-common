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

const PRODUCT = [
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
