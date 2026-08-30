#!/usr/bin/env bash
# Agent-independent vault verification. Run this under ANY agent — or none.
#
# Answers three questions no policy document can answer on its own:
#   1. Is the portable enforcement layer actually armed?
#   2. Has tracked evidence under raw/ been altered?
#   3. Does the vault pass structural lint?
#
# Usage: bash scripts/verify-vault.sh
# Exit:  0 all clear, 1 findings. Safe to run at any time; writes nothing.
set -uo pipefail
cd "$(dirname "$0")/.."

EVIDENCE_DIR="raw"
problems=0
note() { printf '  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; problems=$((problems + 1)); }
pass() { printf 'ok    %s\n' "$1"; }

echo "VAULT VERIFICATION"
echo "Vault:  $(pwd)"
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'no commit yet')"
echo "Agent:  ${VAULT_AGENT:-unset}   (set VAULT_AGENT to record which agent ran this)"
echo

# --- 1. portable enforcement armed? ----------------------------------------
echo "-- enforcement --"
hookpath=$(git config --get core.hooksPath || true)
if [ "$hookpath" = ".githooks" ]; then
  pass "core.hooksPath = .githooks"
  if [ -f .githooks/pre-commit ]; then
    if [ -x .githooks/pre-commit ]; then
      pass "pre-commit hook present and executable"
    else
      fail "pre-commit hook present but NOT executable — Git will silently skip it"
      note "fix: chmod +x .githooks/pre-commit"
      note "this environment has core.fileMode=false, so the bit may not survive a clone;"
      note "the committed index mode is what matters: git ls-files -s .githooks/pre-commit"
    fi
  else
    fail ".githooks/pre-commit is missing"
  fi
else
  fail "core.hooksPath is '${hookpath:-unset}', not '.githooks' — the portable backstop is OFF"
  note "fix: git config core.hooksPath .githooks"
  note "until then, raw/ is protected only by agent-specific hooks (Claude Code) or nothing."
fi

# --- 2. evidence integrity -------------------------------------------------
echo
echo "-- evidence integrity ($EVIDENCE_DIR/) --"
if [ ! -d "$EVIDENCE_DIR" ]; then
  note "no $EVIDENCE_DIR/ directory yet — nothing to verify"
elif ! git rev-parse --verify -q HEAD >/dev/null; then
  note "no commits yet — no committed baseline to compare against"
else
  # Mutations to tracked evidence, working tree and index alike. Added files are fine.
  mutated=$(git status --porcelain -- "$EVIDENCE_DIR" | grep -vE '^\?\?|^A ' || true)
  if [ -n "$mutated" ]; then
    fail "tracked evidence has been modified, deleted, or renamed:"
    printf '%s\n' "$mutated" | sed 's/^/      /'
    note "restore: git restore --staged --worktree -- $EVIDENCE_DIR/"
  else
    tracked=$(git ls-files -- "$EVIDENCE_DIR" | grep -c . || true)
    untracked=$(git status --porcelain -- "$EVIDENCE_DIR" | grep -c '^??' || true)
    pass "no modification to $tracked tracked file(s)"
    [ "$untracked" -gt 0 ] && note "$untracked new uncommitted file(s) present — additions are allowed"
  fi
fi

# --- 2b. content drift against recorded source_id --------------------------
# git status alone is blind to a file that was mutated *before* its first-ever commit — it
# reports that as a plain "Added" file, not a modification, so the check above lets it through.
# Compare against the source_id already recorded on the matching wiki/sources/ page instead,
# which exists independently of git history. This is what actually caught commit f38689b.
if [ -d "$EVIDENCE_DIR" ] && [ -d wiki/sources ] && [ -f scripts/lib-vault.sh ]; then
  . scripts/lib-vault.sh
  drift=0
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    recorded=$(recorded_source_id "$path")
    [ -n "$recorded" ] || continue
    actual=$(sha256sum "$path" 2>/dev/null | cut -d' ' -f1)
    if [ "$actual" != "$recorded" ]; then
      fail "content drift: $path no longer matches its recorded source_id"
      note "  recorded: $recorded"
      note "  actual:   $actual"
      drift=1
    fi
  done < <(find "$EVIDENCE_DIR" -type f -name '*.md')
  [ "$drift" -eq 0 ] && pass "no content drift against recorded source_id"
fi

# --- 3. structural lint ----------------------------------------------------
echo
echo "-- structural lint --"
if [ -f scripts/wiki-lint.sh ]; then
  if lint_out=$(bash scripts/wiki-lint.sh 2>&1); then
    pass "wiki-lint: no findings"
  else
    fail "wiki-lint reported findings:"
    printf '%s\n' "$lint_out" | grep -vE '^$|^WIKI LINT|^Vault:|^Commit:|^-- ' | sed 's/^/      /'
    note "lint recommends only; it never repairs. Review before acting."
  fi
else
  fail "scripts/wiki-lint.sh not found"
fi

# --- 4. policy files in agreement -----------------------------------------
echo
echo "-- policy consistency --"
if [ -f scripts/check-policy-sync.sh ]; then
  if sync_out=$(bash scripts/check-policy-sync.sh 2>&1); then
    pass "AGENTS.md and CLAUDE.md agree on invariant rules"
  else
    fail "policy files disagree:"
    printf '%s\n' "$sync_out" | sed 's/^/      /'
  fi
else
  note "scripts/check-policy-sync.sh not found — skipping"
fi

# --- 5. workflow command pointers still thin and permitted -----------------
echo
echo "-- command pointer integrity --"
if [ -f scripts/check-command-pointers.sh ]; then
  if ptr_out=$(bash scripts/check-command-pointers.sh 2>&1); then
    pass "command files are thin pointers with adequate tool permissions"
  else
    fail "command/prompt pointer problem:"
    printf '%s\n' "$ptr_out" | sed 's/^/      /'
  fi
else
  note "scripts/check-command-pointers.sh not found — skipping"
fi

# --- 6. schema conformance (Phase 2) --------------------------------------
echo
echo "-- schema conformance --"
if [ -f scripts/check-schema.sh ]; then
  if schema_out=$(bash scripts/check-schema.sh 2>&1); then
    pass "every page matches the approved metadata schema"
  else
    fail "schema findings:"
    printf '%s\n' "$schema_out" | grep -vE '^$|^SCHEMA|^Vault:' | sed 's/^/      /'
  fi
else
  note "scripts/check-schema.sh not found — skipping"
fi

# --- 7. duplicate candidates (Phase 2, advisory) --------------------------
# Advisory on purpose: a title collision is a question for a human, not a broken vault. Failing
# the run on it would mean every legitimate concept/counterclaim pair blocks write work.
echo
echo "-- duplicate candidates (advisory) --"
if [ -f scripts/find-duplicates.sh ]; then
  if dup_out=$(bash scripts/find-duplicates.sh 2>&1); then
    pass "no duplicate candidates"
  else
    printf 'note  %s\n' "possible duplicates — review, never auto-merge:"
    printf '%s\n' "$dup_out" | grep -E '^(key-collision|similar-title)' | sed 's/^/      /'
  fi
else
  note "scripts/find-duplicates.sh not found — skipping"
fi

echo
if [ "$problems" -eq 0 ]; then
  echo "All clear."
  exit 0
fi
echo "$problems problem(s). Resolve before write work."
exit 1
