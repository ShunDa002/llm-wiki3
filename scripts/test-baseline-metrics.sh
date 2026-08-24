#!/usr/bin/env bash
# Self-check for baseline-metrics.sh. Builds a fixture vault with known defects in a temp
# directory and asserts the counts. Run: scripts/test-baseline-metrics.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)

fx=$(mktemp -d)
trap 'rm -r -- "$fx"' EXIT
mkdir -p "$fx/scripts" "$fx/wiki/concepts" "$fx/okf/decisions" "$fx/okf/experiments" "$fx/raw"
cp "$here/baseline-metrics.sh" "$fx/scripts/"

# Spaces in filenames are deliberate: they broke the link graph once already.
printf -- '---\nsources:\n  - "[[Source - A]]"\n---\nLinks [[Concept B]] and [[Missing Page]].\n' \
  > "$fx/wiki/concepts/Concept A.md"
printf -- '---\ntitle: B\n---\nNo sources field.\n'          > "$fx/wiki/concepts/Concept B.md"
printf -- '---\ntitle: dup\n---\n'                            > "$fx/okf/decisions/Concept A.md"
printf -- '---\ntitle: D1\n---\nNo basis.\n'                  > "$fx/okf/decisions/DEC-0001.md"
printf -- '---\ntitle: E1\n---\n## Conclusion\nDone.\n'       > "$fx/okf/experiments/EXP-0001.md"
printf -- '---\ntitle: E2\n---\nStill running.\n'             > "$fx/okf/experiments/EXP-0002.md"

out=$("$fx/scripts/baseline-metrics.sh")
fail=0
check() { # label expected regex
  if grep -qE "$2" <<< "$out"; then
    echo "ok   $1"
  else
    echo "FAIL $1 -- got: $(grep -E "${2%%:*}" <<< "$out")"
    fail=1
  fi
}

check "6 notes"                  '^Notes \(wiki/ \+ okf/ \+ raw/\) +: 6$'
check "5 notes without sources"  '^Notes without a sources: field +: 5$'
check "1 duplicate filename"     '^Duplicate note filenames +: 1$'
check "2 broken wikilinks"       '^Broken internal wikilinks +: 2$'
check "5 orphans"                '^Orphan notes \(no inbound link\) +: 5$'
check "2 decisions"              '^OKF decisions +: 2$'
check "2 without knowledge_basis" '^ +without knowledge_basis +: 2$'
check "1 of 2 experiments concluded" '^ +with a documented conclusion +: 1 \(50%\)$'

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAILED"
exit "$fail"
