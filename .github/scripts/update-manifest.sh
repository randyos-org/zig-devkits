#!/usr/bin/env bash
# Merge entries into devkits.json on main, commit, and push, retrying when the
# other workflow pushed first.
# usage: update-manifest.sh <message> < entries.json
#   entries.json: {"<host triple>": {version, source, release, asset, url, sha256, ...}, ...}
# Needs a checkout of main with push access (GITHUB_TOKEN with contents: write).
set -euo pipefail
MSG=${1:?usage: update-manifest.sh <message> < entries.json}
ENTRIES=$(cat)

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
for attempt in 1 2 3 4 5; do
  git fetch -q origin main
  git reset -q --hard origin/main
  jq --argjson new "$ENTRIES" '.devkits = ((.devkits // {}) + $new) | .devkits |= (to_entries | sort_by(.key) | from_entries)' \
    devkits.json > devkits.json.tmp
  mv devkits.json.tmp devkits.json
  if git diff --quiet devkits.json; then
    echo "devkits.json already up to date"
    exit 0
  fi
  git commit -qam "$MSG"
  if git push -q origin HEAD:main; then
    echo "devkits.json updated"
    exit 0
  fi
  echo "main moved; retrying ($attempt)"
  sleep $((attempt * 5))
done
echo "::error::could not push devkits.json"
exit 1
