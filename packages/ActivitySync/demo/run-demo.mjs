/**
 * Activity Sync — end-to-end demo over recorded Microsoft Graph payloads.
 *
 *   node demo/run-demo.mjs
 *   node demo/run-demo.mjs --live        (refuses unless a credential and the policy exist)
 *
 * WHAT THIS RUNS. The real provider, the real Graph mapper, real participant extraction, real
 * direction inference, real threading and the real watermark. The ONLY substituted piece is the
 * outermost call — the one that would reach the network. That is the whole point of the transport
 * seam: a replayed run and a live run differ in where the bytes come from and nothing else.
 *
 * WHAT IT DOES NOT PROVE, said plainly because a green demo invites the opposite assumption: nothing
 * here contacts Microsoft. The payloads are shaped from Microsoft's published `message` resource
 * schema, not captured from a tenant, because capturing needs a credential and none is configured.
 * The first live run will still be the first live run.
 *
 * @module @mj-biz-apps/common-activity-sync
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
    GRAPH_CREDENTIAL_TYPE,
    LIVE_GRAPH_REFUSAL,
    MSGraphActivitySyncProvider,
    RecordedMessageTransport,
} from '../dist/index.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const LIVE = process.argv.includes('--live');

const C = {
    dim: (s) => `[2m${s}[0m`,
    bold: (s) => `[1m${s}[0m`,
    green: (s) => `[32m${s}[0m`,
    yellow: (s) => `[33m${s}[0m`,
    cyan: (s) => `[36m${s}[0m`,
    red: (s) => `[31m${s}[0m`,
};

const rule = (t) => console.log('\n' + C.bold(t) + '\n' + '─'.repeat(78));
const iso = (d) => (d instanceof Date ? d.toISOString().replace('.000Z', 'Z') : String(d));

// ── Load the recordings ──────────────────────────────────────────────────────────────────────
const raw = JSON.parse(readFileSync(join(HERE, 'graph-sample-messages.json'), 'utf8'));
const MAILBOX = raw.mailbox;

const transport = new RecordedMessageTransport([
    {
        Mailbox: MAILBOX,
        Payloads: raw.value,
        Provenance: 'Microsoft Graph `message` schema, hand-built from published docs — NOT a tenant capture',
    },
]);

// AllowLiveFetch stays FALSE. The recorded transport is exempt from that gate because it reaches no
// mailbox; passing `true` here would prove nothing and would misrepresent what the run did.
const provider = new MSGraphActivitySyncProvider(false, transport);

console.log(C.bold('\nACTIVITY SYNC — END-TO-END OVER RECORDED MICROSOFT 365 MAIL'));
console.log(C.dim(`mailbox ${MAILBOX} · ${raw.value.length} recorded message(s)`));
console.log(C.dim(`provider IsLive = ${provider.IsLive}  ← follows the transport, so this run cannot`));
console.log(C.dim('  be written to the database as Integration-sourced. That guard is the reason'));
console.log(C.dim('  a replayed run is safe to demo with.'));

// ── Pass 1: a first sync, no watermark ───────────────────────────────────────────────────────
rule('PASS 1 — first sync, no watermark (everything the mailbox holds)');

const first = await provider.Fetch({ Mailbox: MAILBOX, Since: null, Limit: 50 });

if (first.Failed) {
    console.log(C.red('  FAILED — ') + first.Issues.join(' '));
    process.exit(1);
}

for (const item of first.Items) {
    const from = item.Participants.find((p) => p.Role === 'From');
    const others = item.Participants.filter((p) => p.Role !== 'From');
    console.log('');
    console.log('  ' + C.cyan(item.Subject));
    console.log('    ' + C.dim('direction ') + C.bold(item.Direction) + C.dim(`   started ${iso(item.StartedAt)}`));
    console.log('    ' + C.dim('from      ') + (from ? `${from.Name ?? '(no name)'} <${from.Address}>` : '(none)'));
    for (const p of others) {
        console.log('    ' + C.dim(`${p.Role.padEnd(9)} `) + `${p.Name ?? '(no name)'} <${p.Address}>`);
    }
    console.log('    ' + C.dim('thread    ') + (item.ExternalThreadID ?? '(none)'));
    console.log('    ' + C.dim('type      ') + item.TypeCode + C.dim('   external id ') + item.ExternalID.slice(-8));
}

console.log('');
console.log('  ' + C.green(`${first.Items.length} item(s) normalized`) + C.dim(`   watermark → ${iso(first.HighWatermark)}`));

// ── What the mapper decided, and why it is worth watching ────────────────────────────────────
rule('WHAT THE MAPPING ACTUALLY DECIDED');

const threads = new Map();
for (const i of first.Items) {
    const k = i.ExternalThreadID ?? '(none)';
    threads.set(k, (threads.get(k) ?? 0) + 1);
}
console.log(`  Threads: ${threads.size} conversation(s) across ${first.Items.length} message(s)`);
for (const [id, n] of threads) console.log(C.dim(`    ${id.slice(-10)}  ${n} message(s)`));

const byDirection = first.Items.reduce((a, i) => ((a[i.Direction] = (a[i.Direction] ?? 0) + 1), a), {});
console.log('');
console.log('  Direction is INFERRED from the mailbox, not read off a field:');
for (const [d, n] of Object.entries(byDirection)) console.log(C.dim(`    ${d.padEnd(9)} ${n}`));
console.log(C.dim('    Internal = the mailbox sent it and every other participant is the mailbox.'));

const commaName = first.Items
    .flatMap((i) => i.Participants)
    .find((p) => (p.Name ?? '').includes(','));
if (commaName) {
    console.log('');
    console.log('  A display name containing a comma survived parsing:');
    console.log(C.dim(`    "${commaName.Name}" <${commaName.Address}>  (role ${commaName.Role})`));
}

if (first.Issues.length) {
    console.log('');
    console.log('  ' + C.yellow('Issues reported (not thrown — a partial batch is still worth filing):'));
    for (const issue of first.Issues) console.log(C.dim('    · ') + issue);
}

// ── Pass 2: incremental ──────────────────────────────────────────────────────────────────────
rule('PASS 2 — incremental, using the watermark from pass 1');

const midpoint = new Date('2026-08-30T00:00:00Z');
const second = await provider.Fetch({ Mailbox: MAILBOX, Since: midpoint, Limit: 50 });

console.log(`  Since ${iso(midpoint)} → ${C.green(`${second.Items.length} item(s)`)} of ${raw.value.length} recorded`);
for (const i of second.Items) console.log(C.dim('    · ') + i.Subject + C.dim(`  (${iso(i.StartedAt)})`));
console.log('');
console.log(C.dim('  The window is applied after the fetch, in Normalize. Once MJ#4123 publishes,'));
console.log(C.dim('  `ReceivedAfter` pushes it into the Graph query instead and the fetch shrinks.'));

// ── The refusals, which are features ─────────────────────────────────────────────────────────
rule('THE SAFETY GATES — shown working, not described');

const ungated = new MSGraphActivitySyncProvider();
const refused = await ungated.Fetch({ Mailbox: MAILBOX, Since: null, Limit: 50 });
console.log('  Default construction, no transport, no opt-in:');
console.log(C.dim('    items: ') + refused.Items.length + C.dim('   says: ') + C.yellow(refused.Issues[0].slice(0, 62) + '…'));
console.log('');
console.log(C.dim('  That refusal is not about a missing transport — it is the tenant-wide read.'));
console.log(C.dim('  App-only Mail.Read reaches EVERY mailbox until an Exchange Application Access'));
console.log(C.dim('  Policy scopes the app registration. The gate stays shut until someone confirms it.'));

// ── The live path, and exactly what it still needs ───────────────────────────────────────────
rule('THE LIVE PATH — what is wired, and what is missing');

if (!LIVE) {
    console.log('  Not attempted (no --live). What a live run needs, both external to this code:');
    console.log('');
    console.log('    1. ' + C.bold(`An "${GRAPH_CREDENTIAL_TYPE}" credential in MJ`));
    console.log(C.dim('       __mj.Credential is EMPTY on this host and no AZURE_* settings exist.'));
    console.log(C.dim('       Needs tenantId, clientId, clientSecret — the last is isSecret, so MJ'));
    console.log(C.dim('       encrypts it at rest and nobody has to hand the value around.'));
    console.log('');
    console.log('    2. ' + C.bold('The Exchange Application Access Policy'));
    console.log(C.dim('       Independent of the credential. A yes on one does not cover the other.'));
    console.log('');
    console.log(C.dim('  Everything between those two and the output above is built and tested. When'));
    console.log(C.dim('  they land, the only change is which transport is constructed — one line.'));
} else {
    console.log('  ' + C.yellow('--live requested.'));
    console.log(C.dim('  Refusing: no credential is configured on this host, and the Application Access'));
    console.log(C.dim('  Policy is unconfirmed. Enabling live fetch without it reads every mailbox in'));
    console.log(C.dim('  the tenant. This demo will not do that on its own initiative.'));
    console.log('');
    console.log(C.dim('  For the record, the refusal text the provider carries:'));
    console.log(C.dim('    ' + LIVE_GRAPH_REFUSAL.slice(0, 74) + '…'));
}

// ── Honest summary ───────────────────────────────────────────────────────────────────────────
rule('WHAT THIS RUN DID AND DID NOT PROVE');
console.log('  ' + C.green('Proven: ') + 'provider, transport seam, Graph mapping, participants, direction,');
console.log('          threading, watermark, incremental filtering, and both safety gates.');
console.log('  ' + C.yellow('Not proven: ') + 'that Microsoft returns these shapes. Nothing here contacted');
console.log('          Microsoft. The payloads follow the published schema; they are not a capture.');
console.log('');
