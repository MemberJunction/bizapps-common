#!/bin/bash
# Validates that all @memberjunction-bizapps/common-* packages exist on npm

echo "Checking for new packages that need npm placeholders..."

MISSING=()
CHECKED=0
MAX_RETRIES=3
RETRY_DELAY=2

for pkg_json in $(find packages -name "package.json" -maxdepth 2 -not -path "*/node_modules/*"); do
  name=$(jq -r '.name // ""' "$pkg_json")

  if [[ "$name" != @memberjunction-bizapps/common-* ]]; then
    continue
  fi

  CHECKED=$((CHECKED + 1))

  EXISTS=false
  for attempt in $(seq 1 $MAX_RETRIES); do
    if timeout 10 npm view "$name" version > /dev/null 2>&1; then
      EXISTS=true
      break
    fi
    exit_code=$?
    if [ $exit_code -eq 1 ]; then
      break
    fi
    sleep $RETRY_DELAY
  done

  if [ "$EXISTS" = false ]; then
    MISSING+=("$name")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "::error::Found ${#MISSING[@]} package(s) without npm placeholders:"
  for pkg in "${MISSING[@]}"; do
    echo "  - $pkg"
  done
  echo ""
  echo "Required actions:"
  echo "For each missing package, publish a placeholder first:"
  echo "  cd packages/<dir> && npm publish --access public"
  exit 1
fi

echo "All $CHECKED @memberjunction-bizapps/common-* packages exist on npm"
