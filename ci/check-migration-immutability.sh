#!/usr/bin/env bash
# A migration that has shipped is frozen.
#
# Flyway records a checksum for every migration it applies. Edit an applied file and every
# database that already ran it fails validation on the next migrate — while a database built
# from scratch happily applies the new text. The two diverge silently, and the fix is manual
# repair on each existing installation. So: once a migration is on `main`, it is published,
# and the only legal change to `migrations/` is a NEW file.
#
# Compares against the MERGE BASE (three-dot), not the tip of main. A migration added on
# `next` and then corrected on `next` before it ever released is fine — it was never in main,
# so nobody has applied it. That is the case this check must NOT flag, and two-dot would.
#
# MIGRATION_IMMUTABILITY_EXEMPT=true skips it, for the rare deliberate case (a coordinated
# Flyway repair). Expect to explain it in the PR.
set -euo pipefail

BASE="${1:-origin/main}"

if [ "${MIGRATION_IMMUTABILITY_EXEMPT:-false}" = "true" ]; then
  echo "Exempt via label — skipping the migration immutability check"
  exit 0
fi

if ! git rev-parse --verify --quiet "$BASE" >/dev/null; then
  echo "::error::Cannot resolve '$BASE'. This check needs the base branch fetched (fetch-depth: 0)."
  exit 1
fi

# M=modified, D=deleted, R=renamed. Additions (A) are the whole point and are never flagged.
TOUCHED=$(git diff --name-only --diff-filter=MDR "$BASE"...HEAD -- migrations/ migrations-pg/ || true)

if [ -z "$TOUCHED" ]; then
  echo "No already-released migration was modified, deleted or renamed — ok"
  exit 0
fi

echo "::error::A migration already on $BASE was modified, deleted or renamed. Flyway checksums the file at apply time, so editing it breaks validation on every database that already ran it, while a fresh database silently gets the new text. Add a NEW migration that makes the correction instead. Offending files:"
echo "$TOUCHED" | sed 's/^/  /'
exit 1
