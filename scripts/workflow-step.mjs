/**
 * Reads one step out of a GitHub Actions workflow, for specs that RUN a step rather than read it.
 *
 * A workflow step is a decision that only executes inside Actions, so its spec extracts the step's
 * `run: |` body verbatim and executes it under `bash -e`, as Actions does. Text, not a YAML parser:
 * these specs are stdlib-only, like the gates they pin, and a step's name, `if:` and body are all
 * the specs need.
 */
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/** The text of `.github/workflows/<file>`. */
export function readWorkflow(file) {
    return readFileSync(join(REPO_ROOT, '.github', 'workflows', file), 'utf8');
}

/** The lines of the step named `name`, from its `- name:` line to the next step or job. */
function stepLines(workflow, name) {
    const lines = workflow.split('\n');
    const start = lines.findIndex((line) => line.trim() === `- name: ${name}`);
    if (start < 0) throw new Error(`no step named "${name}"`);
    const stepIndent = lines[start].indexOf('-');
    const end = lines.findIndex((line, i) => i > start && line.trim() !== '' && !line.trim().startsWith('#') && line.search(/\S/) <= stepIndent);
    return { lines: lines.slice(start, end === -1 ? undefined : end), stepIndent };
}

/** The step's `if:` expression, or `null` when it has none. */
export function stepCondition(workflow, name) {
    const { lines, stepIndent } = stepLines(workflow, name);
    const found = lines.find((line) => line.search(/\S/) === stepIndent + 2 && line.trim().startsWith('if:'));
    return found ? found.trim().slice(3).trim() : null;
}

/** The step's `run: |` body, dedented. Throws if the step has none. */
export function stepBody(workflow, name) {
    const { lines, stepIndent } = stepLines(workflow, name);
    const runAt = lines.findIndex((line) => /^\s+run: \|\s*$/.test(line));
    if (runAt < 0) throw new Error(`step "${name}" has no run: | block`);
    const body = [];
    for (const line of lines.slice(runAt + 1)) {
        if (line.trim() !== '' && line.search(/\S/) <= stepIndent + 2) break;
        body.push(line);
    }
    const indent = Math.min(...body.filter((l) => l.trim()).map((l) => l.search(/\S/)));
    return body.map((l) => l.slice(indent)).join('\n');
}
