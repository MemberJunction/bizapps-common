#!/usr/bin/env bash
# Copies MemberJunction's Claude guidance into this repo so it is available here on demand:
#
#   .claude/mj/<path>/CLAUDE.md   every CLAUDE.md in the MJ checkout, at MJ's own relative path
#   .claude/skills/<name>/        every MJ skill (repo-owned skills such as report-issue are untouched)
#   .claude/rules/<name>.md       MJ's path-scoped rules, except changesets.md (this repo has its own model)
#   .claude/commands/<name>.md    the MJ commands this repo adopts (listed below)
#   .claude/mj/SOURCE.json        which MJ branch and commit the copy came from
#
# Copies are verbatim. Relative links inside them (`../../guides/...`) resolve in the MJ checkout,
# not here. Re-run after pulling MJ: scripts/sync-mj-claude-docs.sh [path-to-MJ-checkout]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MJ="${1:-${MJ_CHECKOUT:-$ROOT/../MJ}}"
MJ="$(cd "$MJ" && pwd)"
[ -f "$MJ/CLAUDE.md" ] || { echo "No MJ checkout at $MJ (pass the path or set MJ_CHECKOUT)" >&2; exit 1; }

DEST="$ROOT/.claude/mj"
rm -rf "$DEST"
mkdir -p "$DEST" "$ROOT/.claude/skills" "$ROOT/.claude/rules" "$ROOT/.claude/commands"

# 1. Every CLAUDE.md, keeping MJ's relative layout. templates/ holds a packaged copy, not guidance.
(cd "$MJ" && find . -name CLAUDE.md -not -path '*/node_modules/*' -not -path './templates/*' | sort) |
while read -r f; do
    mkdir -p "$DEST/$(dirname "$f")"
    cp "$MJ/$f" "$DEST/$f"
done

# 2. Skills: replace each MJ skill wholesale so removed files do not linger.
for s in "$MJ"/.claude/skills/*/; do
    name="$(basename "$s")"
    rm -rf "$ROOT/.claude/skills/$name"
    cp -R "$s" "$ROOT/.claude/skills/$name"
done

# 3. Rules. changesets.md is skipped: it describes MJ's fixed-group Edge tuple, and here
#    changesets are user-authored and `minor` is enforced by changes.yml.
for r in data-access typescript-style design-tokens testing; do
    cp "$MJ/.claude/rules/$r.md" "$ROOT/.claude/rules/$r.md"
done

# 4. Commands adopted from MJ. commit/update-pr are already identical; notes stays repo-specific.
for c in create-pr new-branch; do
    cp "$MJ/.claude/commands/$c.md" "$ROOT/.claude/commands/$c.md"
done

# 5. Provenance.
rev="$(git -C "$MJ" rev-parse --short HEAD)"
branch="$(git -C "$MJ" branch --show-current)"
printf '{\n  "source": "MemberJunction/MJ",\n  "branch": "%s",\n  "rev": "%s",\n  "copiedAt": "%s",\n  "script": "scripts/sync-mj-claude-docs.sh"\n}\n' \
    "$branch" "$rev" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$DEST/SOURCE.json"

echo "Synced MJ guidance from $MJ ($branch @ $rev)"
find "$DEST" -type f | sed "s|$ROOT/||" | sort
