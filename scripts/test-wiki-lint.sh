#!/usr/bin/env bash
# Self-check for wiki-lint.sh: plants one defect per check and asserts lint finds it.
# This is also the Phase 1 exit evidence for "lint identifies at least the known test defects".
# Run: scripts/test-wiki-lint.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)

fx=$(mktemp -d)
trap 'rm -r -- "$fx"' EXIT
mkdir -p "$fx/scripts" "$fx/wiki/concepts" "$fx/wiki/sources" "$fx/wiki/syntheses" \
         "$fx/okf/decisions" "$fx/okf/experiments" "$fx/raw"
cp "$here/wiki-lint.sh" "$here/lib-vault.sh" "$fx/scripts/"

# --- planted defects, one per lint check ---

# broken-link + no-sources on the same page, and an inbound link so it is not also an orphan.
printf -- '---\ntitle: Concept A\n---\nSee [[Nonexistent Page]].\n' \
  > "$fx/wiki/concepts/Concept A.md"

# orphan: nothing links to it. Has sources, so it trips only the orphan check.
printf -- '---\ntitle: Lonely\nsources:\n  - "[[Source - X]]"\n---\nText.\n' \
  > "$fx/wiki/concepts/Lonely.md"

# near-duplicate: "Concept As" normalises onto "concept a".
printf -- '---\ntitle: Concept As\nsources:\n  - "[[Source - X]]"\n---\n[[Concept A]]\n' \
  > "$fx/wiki/concepts/Concept As.md"

# single-source-synthesis + index-omission (empty index below).
printf -- '---\ntitle: Thin Synthesis\nsources:\n  - "[[Source - X]]"\n---\nOne source only.\n' \
  > "$fx/wiki/syntheses/Thin Synthesis.md"

# no-log-entry: a source page the log never mentions.
printf -- '---\ntitle: Source - X\ntype: source\n---\nEvidence.\n' \
  > "$fx/wiki/sources/Source - X.md"

# no-knowledge-basis
printf -- '---\ntitle: DEC-0001\nstatus: accepted\n---\nChose a thing.\n' \
  > "$fx/okf/decisions/DEC-0001.md"

# no-conclusion, and an empty-conclusion case
printf -- '---\ntitle: EXP-0001\nstatus: running\nsources: []\n---\nNo conclusion heading.\n' \
  > "$fx/okf/experiments/EXP-0001.md"
printf -- '---\ntitle: EXP-0002\nstatus: complete\nsources: []\n---\n## Conclusion\n\n' \
  > "$fx/okf/experiments/EXP-0002.md"

printf -- '---\ntitle: Wiki Index\n---\n# Index\n\nNothing listed.\n' > "$fx/wiki/index.md"
printf -- '---\ntitle: Operation Log\n---\n# Log\n' > "$fx/wiki/log.md"

out=$(cd "$fx" && bash scripts/wiki-lint.sh)
rc=$?

fail=0
expect() { # label pattern
  if grep -qF "$2" <<< "$out"; then
    echo "ok   $1"
  else
    echo "FAIL $1 -- no line matching: $2"
    fail=1
  fi
}

expect "broken link"              "broken-link                  wiki/concepts/Concept A.md -> [[Nonexistent Page]]"
expect "missing sources"          "no-sources                   wiki/concepts/Concept A.md"
expect "orphan page"              "orphan                       wiki/concepts/Lonely.md"
expect "near-duplicate title"     "near-duplicate"
expect "single-source synthesis"  "single-source-synthesis"
expect "index omission"           "index-omission               Thin Synthesis not in wiki/index.md"
expect "missing log entry"        "no-log-entry                 Source - X never appears"
expect "no knowledge basis"       "no-knowledge-basis           okf/decisions/DEC-0001.md"
expect "experiment no conclusion" "no-conclusion                okf/experiments/EXP-0001.md"
expect "empty conclusion"         "empty-conclusion             okf/experiments/EXP-0002.md"

# A clean vault must exit 0; a dirty one must exit 1, or CI can never gate on it.
[ "$rc" -eq 1 ] && echo "ok   exit code 1 on findings" || { echo "FAIL exit code was $rc, want 1"; fail=1; }

if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; echo "--- lint output ---"; echo "$out"; fi
exit "$fail"
