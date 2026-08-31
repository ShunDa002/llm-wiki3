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

# --- 2c. OS-level lock still applied? --------------------------------------
# lock-raw.sh's chmod 444 is not Git-tracked, so it silently does not survive a clone, and a file
# added after the last run stays writable. Before this section a skipped lock-raw.sh was invisible
# until a write actually succeeded — a control that has quietly stopped applying is worse than one
# known to be absent, because it is still trusted.
#
# Report, never chmod: this script is a read-only verifier, and a verifier that repairs its own
# findings can no longer be trusted to report them.
#
# Tracked vs untracked is split deliberately. Committed evidence is supposed to be frozen, so a
# writable tracked file is a regression and fails. A newly added file is legitimately pending —
# the owner adds, then locks — so it is only noted. Failing on the normal case is how a check
# teaches its operator to switch it off, the same reasoning that keeps §7 advisory.
if [ -d "$EVIDENCE_DIR" ]; then
  echo
  echo "-- OS-level lock ($EVIDENCE_DIR/) --"
  unlocked_tracked=""; unlocked_new=0
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
      unlocked_tracked="$unlocked_tracked$path"$'\n'
    else
      unlocked_new=$((unlocked_new + 1))
    fi
  done < <(find "$EVIDENCE_DIR" -type f -perm -u+w 2>/dev/null)

  if [ -n "$unlocked_tracked" ]; then
    fail "committed evidence is writable — the OS-level lock is not applied:"
    printf '%s' "$unlocked_tracked" | sed 's/^/      /'
    note "fix: bash scripts/lock-raw.sh"
  else
    pass "all committed evidence is read-only"
  fi
  [ "$unlocked_new" -gt 0 ] && note "$unlocked_new new uncommitted file(s) still writable — lock after review: bash scripts/lock-raw.sh"
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
echo "-- policy single-sourcing --"
if [ -f scripts/check-policy-sync.sh ]; then
  if sync_out=$(bash scripts/check-policy-sync.sh 2>&1); then
    pass "CLAUDE.md imports AGENTS.md, which holds every invariant rule"
  else
    fail "policy pointer or canonical file problem:"
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

# --- 8. OKF semantic protection (Phase 3) ---------------------------------
echo
echo "-- OKF semantic protection --"
if [ -f scripts/check-okf-guard.sh ]; then
  if okf_out=$(bash scripts/check-okf-guard.sh --worktree 2>&1); then
    pass "no unauthorized change to an accepted decision, a completed experiment, or a project's protected fields"
  else
    fail "OKF semantic-immutability findings:"
    printf '%s\n' "$okf_out" | grep -vE '^$' | sed 's/^/      /'
  fi
else
  note "scripts/check-okf-guard.sh not found — skipping"
fi

echo
if [ "$problems" -eq 0 ]; then
  echo "All clear."
  exit 0
fi
echo "$problems problem(s). Resolve before write work."
exit 1
