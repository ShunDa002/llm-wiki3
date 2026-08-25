#!/usr/bin/env bash
# Guards against policy drift between AGENTS.md (canonical, all agents) and CLAUDE.md
# (Claude Code's entry point).
#
# Why this exists: CLAUDE.md could not be turned into a pointer at AGENTS.md without editing it,
# and editing it risked breaking a working Claude Code setup. The cost of that choice is two
# files stating the same rules — and a stale policy file is more dangerous than no policy file,
# because it is trusted. This script converts that risk from silent to loud.
#
# It checks that every INVARIANT rule appears in both files. It deliberately does not diff the
# files: they are allowed to differ in wording, ordering, and agent-specific sections. Only the
# load-bearing rules must match.
#
# Usage: bash scripts/check-policy-sync.sh
# Exit:  0 in agreement, 1 drift found, 2 a policy file is missing.
set -uo pipefail
cd "$(dirname "$0")/.."

A=AGENTS.md
C=CLAUDE.md

for f in "$A" "$C"; do
  [ -f "$f" ] || { printf 'MISSING: %s\n' "$f" >&2; exit 2; }
done

drift=0
report() { printf 'DRIFT: %s\n' "$1"; drift=1; }

# Invariant rules, as grep -E patterns that must match in BOTH files.
# Keep this list short and load-bearing. Every entry should be a rule whose loss would let an
# agent do real damage, not a stylistic preference.
check() { # <description> <pattern>
  local desc="$1" pat="$2" in_a=0 in_c=0
  grep -qiE "$pat" "$A" && in_a=1
  grep -qiE "$pat" "$C" && in_c=1
  if [ "$in_a" -ne "$in_c" ]; then
    report "$desc — present in $([ $in_a -eq 1 ] && echo "$A" || echo "$C"), absent from $([ $in_a -eq 1 ] && echo "$C" || echo "$A")"
  elif [ "$in_a" -eq 0 ]; then
    report "$desc — MISSING FROM BOTH files"
  fi
}

check "raw/ is read-only"                 'read.only|immutable'
check "never edit/rename/move/delete raw" 'never edit, rename, move, or delete'
check "source content is untrusted"       'untrusted (evidence|data|input)'
check "wiki writes need a plan first"     'only after presenting an execution plan'
check "factual pages cite sources"        'must identify (its|their) sources'
check "no silent removal of conflicts"    'never remove conflicting information silently'
check "log every operation"               'log\.md'
check "okf is human-controlled"           'human.controlled'
check "no deleting files"                 'never delete files'
check "no commit or push"                 'never run git commit or push|committing or pushing'
check "plan above five files"             'more than five files'
check "prohibited: accepted decisions"    'editing accepted decisions'
check "prohibited: schema/template edits" 'modifying schemas or templates'
check "prohibited: external systems"      'accessing external systems'
check "source_id is a sha256"             'sha256'
check "three-tier approval model"         'high risk'

# The phase/automation-level header must agree, or one file will authorise work the other bans.
pa=$(grep -oiE 'phase: \*\*[0-9]+' "$A" | head -1 | grep -oE '[0-9]+' || true)
pc=$(grep -oiE 'phase: \*\*[0-9]+' "$C" | head -1 | grep -oE '[0-9]+' || true)
if [ -n "$pa" ] && [ -n "$pc" ] && [ "$pa" != "$pc" ]; then
  report "phase number disagrees — $A says $pa, $C says $pc"
elif [ -z "$pa" ] || [ -z "$pc" ]; then
  report "phase number not parseable in $([ -z "$pa" ] && echo "$A" || echo "$C")"
fi

if [ "$drift" -eq 0 ]; then
  echo "Policy files agree on all invariant rules."
  exit 0
fi
cat <<EOF

$A is canonical. Reconcile CLAUDE.md to match it, or vice versa if AGENTS.md is the one that is
wrong — but do not leave them disagreeing. An agent reading the stale file will act on rules the
other file has already retired.
EOF
exit 1
