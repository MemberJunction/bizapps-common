import { test } from 'node:test';
import assert from 'node:assert/strict';
import { SQLCMD_CANDIDATES } from '../parse-migrations.mjs';
import { SQLCMD_CANDIDATES as DRIFT_SQLCMD_CANDIDATES } from '../check-entityfield-drift.mjs';

// bizapps-common only: check-entityfield-drift.mjs exists in this repo alone. The shared
// parse-migrations.spec.mjs (copied byte-for-byte from bizapps-issues) therefore cannot carry this
// test, so it lives here. Both scripts have the identical stated purpose (locate sqlcmd) and must
// agree on every candidate location, not just share one entry.
test("the sqlcmd candidate list is identical to check-entityfield-drift.mjs's -- not just a superset check", () => {
    assert.deepEqual(SQLCMD_CANDIDATES, DRIFT_SQLCMD_CANDIDATES);
});
