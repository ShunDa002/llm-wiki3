#!/usr/bin/env bash
# Guards the CLAUDE.md -> AGENTS.md pointer, and the completeness of AGENTS.md itself.
#
# History, because it explains the shape: CLAUDE.md and AGENTS.md used to hold two full copies of
# the policy, and this script's job was to check that ~16 invariant rules appeared in both. That
# duplication existed only because CLAUDE.md could not be edited when the portability layer was
# built. Once that constraint lapsed — Phase 2 and Phase 3 both edited it — CLAUDE.md was reduced
# to an `@AGENTS.md` import and the second copy was removed instead of monitored. Drift is now
# structurally impossible rather than merely detectable, which is strictly better than a checker.
#
# What remains to guard is a different thing in the same shape as check-command-pointers.sh:
#
#   1. CLAUDE.md still imports AGENTS.md. Without that line a Claude Code session loads no policy
#      at all — a silent, total failure, and a worse one than the drift this file used to catch.
#   2. CLAUDE.md has not re-grown policy text of its own. This is the real regression to fear:
#      someone pastes the rules back in and there are two sources again.
#   3. AGENTS.md still contains every invariant rule and a parseable phase number. The old pattern
#      list moves here unchanged, so a rule silently vanishing from the canonical file is still
#      caught — that check did not stop being worth running, it just has one file to run against.
#
# Usage: bash scripts/check-policy-sync.sh
# Exit:  0 in order, 1 a problem found, 2 a policy file is missing.
set -uo pipefail
cd "$(dirname "$0")/.."

A=AGENTS.md
C=CLAUDE.md
IMPORT='@AGENTS.md'
# A pointer plus its explanation. Generous enough not to fight prose, tight enough that a pasted
# policy section cannot hide under it.
C_MAX_LINES=40

for f in "$A" "$C"; do
  [ -f "$f" ] || { printf 'MISSING: %s\n' "$f" >&2; exit 2; }
done

problems=0
report() { printf 'PROBLEM: %s\n' "$1"; problems=$((problems + 1)); }

# --- 1. the import line, on its own line so Claude Code actually resolves it ---------------
if ! grep -qxF "$IMPORT" "$C"; then
  report "$C does not contain the line '$IMPORT' — a Claude Code session would load NO policy"
fi

# --- 2. CLAUDE.md is still a pointer, not a second copy ------------------------------------
c_lines=$(grep -c '' "$C")
if [ "$c_lines" -gt "$C_MAX_LINES" ]; then
  report "$C is $c_lines lines (cap $C_MAX_LINES) — has it re-grown its own policy text?"
fi
# A phase number here could disagree with the canonical one, which is the drift in miniature.
if grep -qiE 'phase: \*\*[0-9]+' "$C"; then
  report "$C declares its own phase number — that belongs only in $A, where it cannot disagree"
fi

# --- 3. every invariant rule still present in the canonical file, and absent from the pointer -
# One pattern list, two assertions: the rule must live in AGENTS.md, and must NOT have been
# copied back into CLAUDE.md.
check() { # <description> <pattern>
  local desc="$1" pat="$2"
  grep -qiE "$pat" "$A" || report "$desc — MISSING from $A, the canonical policy"
  grep -qiE "$pat" "$C" && report "$desc — policy text has re-appeared in $C; it belongs only in $A"
  return 0
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

# --- 4. the canonical phase number must be parseable --------------------------------------
if ! grep -oiE 'phase: \*\*[0-9]+' "$A" | grep -qoE '[0-9]+'; then
  report "phase number not parseable in $A"
fi

if [ "$problems" -eq 0 ]; then
  echo "Policy is single-sourced: $C imports $A, and $A holds every invariant rule."
  exit 0
fi
cat <<EOF

$A is the only place policy text belongs. $C should contain the '$IMPORT' import and nothing
that states a rule. If a rule is missing from $A, restore it there — do not re-add it to $C, or
this vault is back to two sources that can disagree.
EOF
exit 1
