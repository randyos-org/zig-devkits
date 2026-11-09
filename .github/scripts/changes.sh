#!/usr/bin/env bash
# Whether a workflow's work should run: false only for a push whose every
# changed file matches a pattern in no-ci.txt. Prints ci=true or ci=false, for
# $GITHUB_OUTPUT. Needs history back to <before> (checkout's fetch-depth: 0).
# usage: changes.sh <event name> <before sha> <after sha>
set -euo pipefail
EVENT=$1
BEFORE=${2:-}
AFTER=$3

# runs by hand or on a schedule, a new branch, or a force push past history
if [ "$EVENT" != push ] || [ -z "$BEFORE" ] || [ "$BEFORE" = 0000000000000000000000000000000000000000 ] \
    || ! git cat-file -e "$BEFORE^{commit}"; then
  echo ci=true
  exit 0
fi

mapfile -t patterns < <(sed -e 's/#.*//' -e 's/[[:space:]]*$//' no-ci.txt | grep -v '^$')
while IFS= read -r f; do
  [ -z "$f" ] && continue
  skip=false
  for p in "${patterns[@]}"; do
    # shellcheck disable=SC2053 # a glob on purpose
    if [[ $f == $p ]]; then skip=true; break; fi
  done
  if [ "$skip" = false ]; then
    echo "changed: $f" >&2
    echo ci=true
    exit 0
  fi
done < <(git diff --name-only "$BEFORE" "$AFTER")
echo "only files of no-ci.txt changed; skipping" >&2
echo ci=false
