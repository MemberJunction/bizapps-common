#!/usr/bin/env bash
#
# The installer runs migrations. It never reads metadata/. So a metadata change reaches a
# customer ONLY through a hand-written `*__Metadata_Sync.sql` migration — the convention this
# repo already follows. Nothing verified that one was written, so metadata could change, pass
# every check, bump the version, publish, and reach nobody.
#
# This is a GATE check, not a door one, deliberately: a feature PR may legitimately land
# metadata before its sync migration is written. What must be true is that by release time,
# every substantive metadata change since the last release has one, or is listed in
# ci/metadata-shipped-by.txt against a migration added since then that already writes it.
set -euo pipefail

. "$(dirname "$0")/lib/release-surface.sh"

. "$(dirname "$0")/lib/last-release.sh"
LAST_TAG=$(last_release_tag)
if [ -z "$LAST_TAG" ]; then
  echo "No v* tag yet — nothing to compare against"
  exit 0
fi

METADATA=$(substantive_metadata_changes "$LAST_TAG" HEAD || true)
if [ -z "$METADATA" ]; then
  echo "No substantive metadata change since $LAST_TAG — nothing to ship"
  exit 0
fi

# --no-renames: a renamed migration is a new version to Skyway, so it counts as added.
ADDED_MIGRATIONS=$(git --no-pager diff --no-renames --name-only --diff-filter=A "$LAST_TAG" HEAD -- migrations/ || true)

# A metadata change counts as shipped when ci/metadata-shipped-by.txt names a migration for it
# and that migration was added since the last tag.
DECLARED="$(dirname "$0")/metadata-shipped-by.txt"
UNSHIPPED=""
while IFS= read -r file; do
  [ -n "$file" ] || continue
  migration=""
  if [ -f "$DECLARED" ]; then
    migration=$(awk -v f="$file" '$1 !~ /^#/ && $1 == f { print $2; exit }' "$DECLARED")
  fi
  if [ -n "$migration" ] && printf '%s\n' "$ADDED_MIGRATIONS" | grep -qxF "migrations/$migration"; then
    echo "  $file ships in $migration"
    continue
  fi
  if [ -n "$migration" ]; then
    echo "  $file: declared in $migration, but that migration was not added since $LAST_TAG; not counted"
  fi
  UNSHIPPED="${UNSHIPPED}${file}"$'\n'
done <<EOF
$METADATA
EOF

if [ -z "$UNSHIPPED" ]; then
  echo "Every metadata change since $LAST_TAG ships in a migration named in ci/metadata-shipped-by.txt"
  exit 0
fi

SYNC=$(printf '%s\n' "$ADDED_MIGRATIONS" | grep -iE 'metadata_sync.*\.sql$' || true)
if [ -n "$SYNC" ]; then
  echo "Metadata changed since $LAST_TAG and a sync migration ships it:"
  printf '%s\n' "$SYNC" | sed 's/^/  /'
  exit 0
fi

echo "::error::metadata/ changed since $LAST_TAG but no Metadata_Sync migration was added. The installer runs migrations and never reads metadata/, so these changes would publish and reach nobody. Add a '*__Metadata_Sync.sql' migration (and its .pg.sql counterpart), or, if a migration added since $LAST_TAG already writes these rows, list it in ci/metadata-shipped-by.txt. Metadata not shipped:"
printf '%s' "$UNSHIPPED" | sed 's/^/  /'
exit 1
