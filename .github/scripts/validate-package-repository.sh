#!/bin/bash
# Validates repository.url in all @memberjunction/bizapps-common-* packages

EXPECTED_URL="https://github.com/MemberJunction/bizapps-common"
ERRORS=0

echo "Checking repository.url in all publishable packages..."

for pkg_json in $(find packages -name "package.json" -maxdepth 2 -not -path "*/node_modules/*" -not -path "*/dist/*"); do
  name=$(jq -r '.name // ""' "$pkg_json")

  if [[ "$name" != @memberjunction/bizapps-common-* ]]; then
    continue
  fi

  repo_url=$(jq -r '.repository.url // ""' "$pkg_json")

  if [ -z "$repo_url" ]; then
    echo "::error file=$pkg_json::Missing repository.url in $pkg_json"
    ERRORS=$((ERRORS + 1))
  elif [ "$repo_url" != "$EXPECTED_URL" ]; then
    echo "::error file=$pkg_json::Invalid repository.url in $pkg_json: expected '$EXPECTED_URL', got '$repo_url'"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "::error::Found $ERRORS package(s) with missing or invalid repository.url"
  exit 1
fi

echo "All publishable packages have valid repository.url"
