#!/bin/bash
# Detects case-sensitivity mismatches between package-lock.json and git

echo "Validating package-lock.json for case-sensitivity issues..."

MISMATCHES=()

PATHS=$(jq -r '.packages | keys[]' package-lock.json | grep -E '^packages/' | sed 's|/$||')

for path in $PATHS; do
  if ! git ls-files --error-unmatch "$path/package.json" > /dev/null 2>&1; then
    actual=$(git ls-files "$path*/package.json" 2>/dev/null | grep -i "^$path/package.json$" | head -1)
    if [ -n "$actual" ]; then
      actual_dir=$(dirname "$actual")
      MISMATCHES+=("lockfile: $path -> git: $actual_dir")
    fi
  fi
done

if [ ${#MISMATCHES[@]} -gt 0 ]; then
  echo ""
  echo "::error::Found ${#MISMATCHES[@]} case mismatch(es) in package-lock.json"
  echo ""
  for m in "${MISMATCHES[@]}"; do echo "  $m"; done
  echo ""
  echo "To fix:"
  echo "  1. Check actual casing: git ls-files packages/ | grep -i <package>"
  echo "  2. Rename via temp: mv packages/Path packages/temp && mv packages/temp packages/path"
  echo "  3. Regenerate lockfile: rm package-lock.json && npm install"
  exit 1
fi

echo "No case-sensitivity issues found in package-lock.json"
