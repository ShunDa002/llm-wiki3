#!/usr/bin/env bash
# Self-check for the agent-portability layer: the universal guard, the Git pre-commit backstop,
# and the policy-drift detector. Run: bash scripts/test-portability.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)

fail=0
ok()   { printf 'ok   %s\n' "$1"; }
bad()  { printf 'FAIL %s\n' "$1"; fail=1; }
G="$here/guard-raw-universal.sh"

# ---------------------------------------------------------------- guard: paths
expect_deny_path() {
  if bash "$G" --path "$1" >/dev/null 2>&1; then bad "path should DENY: $1"; else ok "deny path: $1"; fi
}
expect_allow_path() {
  if bash "$G" --path "$1" >/dev/null 2>&1; then ok "allow path: $1"; else bad "path should ALLOW: $1"; fi
}
expect_deny_path "raw/articles/x.md"
expect_deny_path "/abs/vault/raw/notes/y.md"
expect_allow_path "wiki/concepts/x.md"
expect_allow_path "okf/decisions/d.md"
expect_allow_path "rawdata/x.md"          # substring must not false-positive

# ------------------------------------------------------------- guard: commands
expect_deny_cmd() {
  if bash "$G" --command "$1" >/dev/null 2>&1; then bad "cmd should DENY: $1"; else ok "deny cmd: $1"; fi
}
expect_allow_cmd() {
  if bash "$G" --command "$1" >/dev/null 2>&1; then ok "allow cmd: $1"; else bad "cmd should ALLOW: $1"; fi
}
expect_deny_cmd 'echo hi > raw/articles/x.md'
expect_deny_cmd 'rm -rf raw/notes'
expect_deny_cmd 'sed -i s/a/b/ raw/x.md'
expect_deny_cmd 'mv raw/a.md raw/b.md'
expect_allow_cmd 'grep -r foo raw/ | head -5'
expect_allow_cmd 'cat raw/articles/x.md'
expect_allow_cmd 'rm /tmp/junk'

# Regression: the whole-command matcher used to deny these. A mutator in one segment plus an
# unrelated mention of the evidence dir in another segment is NOT a violation, and blocking it
# trained the operator to work around the guard — the worst possible outcome for a safety control.
expect_allow_cmd 'rm -rf /tmp/clone && grep -c . raw/articles/x.md'
expect_allow_cmd 'mkdir -p /tmp/out; wc -l raw/notes/a.md'

# Regression: an absolute or variable-interpolated path must not walk through the guard. The
# original boundary treated `/` as a word character, so "$VAULT/raw/x" evaded detection
# entirely — found by an actual tamper attempt, not by reading the regex.
expect_deny_cmd 'printf x > /c/Data/llm-wiki3/raw/.gitkeep'
expect_deny_cmd 'printf x > "$VAULT/raw/a.md"'
expect_deny_cmd 'rm ./raw/articles/x.md'
expect_deny_cmd 'sed -i s/a/b/ /abs/vault/raw/x.md'
expect_allow_cmd 'cat /c/Data/llm-wiki3/raw/articles/x.md'
expect_allow_cmd 'rm /tmp/scratch/rawdata.md'   # 'raw' as a name fragment, not the dir

# ------------------------------------------------------------ guard: JSON mode
json_deny() { # <payload> <label>
  out=$(printf '%s' "$1" | bash "$G" --stdin-json --format json 2>/dev/null)
  case "$out" in
    *'"permissionDecision":"deny"'*) ok "json deny: $2" ;;
    *) bad "json should DENY: $2 (got: ${out:-<empty>})" ;;
  esac
}
json_allow() { # <payload> <label>
  out=$(printf '%s' "$1" | bash "$G" --stdin-json --format json 2>/dev/null)
  if [ -z "$out" ]; then ok "json allow: $2"; else bad "json should ALLOW: $2 (got: $out)"; fi
}
json_deny  '{"tool_name":"Write","tool_input":{"file_path":"raw/a.md"}}'            'Claude Write'
json_deny  '{"tool_name":"write_file","tool_input":{"file_path":"raw/a.md"}}'       'Gemini write_file'
json_deny  '{"tool_name":"apply_patch","tool_input":{"file_path":"raw/a.md"}}'      'Codex apply_patch'
json_deny  '{"tool_name":"run_shell_command","tool_input":{"command":"rm raw/a.md"}}' 'Gemini shell'
json_allow '{"tool_name":"Write","tool_input":{"file_path":"wiki/c.md"}}'           'Claude Write to wiki'
json_allow '{"tool_name":"Bash","tool_input":{"command":"grep x raw/a.md"}}'        'read-only shell'

# ------------------------------------------------- pre-commit hook, real git repo
tmp=$(mktemp -d)
trap 'rm -r -- "$tmp"' EXIT
(
  cd "$tmp" || exit 1
  git init -q .
  git config user.email t@t.t; git config user.name t
  mkdir -p .githooks "raw/articles" wiki
  cp "$root/.githooks/pre-commit" .githooks/pre-commit
  chmod +x .githooks/pre-commit
  git config core.hooksPath .githooks

  printf 'original evidence\n' > "raw/articles/a.md"
  printf 'page\n' > wiki/p.md
  git add -A && git commit -q -m init

  # Adding new evidence must be allowed.
  printf 'new evidence\n' > "raw/articles/b.md"
  git add -A
  if git commit -q -m "add evidence" 2>/dev/null; then
    echo "ok   pre-commit: allows ADDING evidence"
  else
    echo "FAIL pre-commit: blocked a legitimate evidence addition"; exit 3
  fi

  # Modifying tracked evidence must be blocked.
  printf 'tampered\n' >> "raw/articles/a.md"
  git add -A
  if git commit -q -m "tamper" 2>/dev/null; then
    echo "FAIL pre-commit: allowed MODIFICATION of tracked evidence"; exit 3
  else
    echo "ok   pre-commit: blocks modification of tracked evidence"
  fi
  git restore --staged --worktree -- raw/ 2>/dev/null || true

  # Deleting tracked evidence must be blocked.
  git rm -q "raw/articles/a.md"
  if git commit -q -m "delete" 2>/dev/null; then
    echo "FAIL pre-commit: allowed DELETION of tracked evidence"; exit 3
  else
    echo "ok   pre-commit: blocks deletion of tracked evidence"
  fi
  git reset -q --hard HEAD

  # Changes outside the evidence dir must pass.
  printf 'edit\n' >> wiki/p.md
  git add -A
  if git commit -q -m "wiki edit" 2>/dev/null; then
    echo "ok   pre-commit: allows normal wiki changes"
  else
    echo "FAIL pre-commit: blocked a normal wiki change"; exit 3
  fi

  # Content-drift regression: a raw/ file mutated BEFORE its first-ever commit reports as
  # "Added", not "Modified" — the MDRCT check above cannot see it. This is exactly what let
  # commit f38689b through against the real vault. Cover both directions: tampered content
  # must be blocked even though git calls it an add; already-correct content must still be
  # allowed to be committed late (the normal case — the pilot owner catching up on real evidence).
  mkdir -p scripts wiki/sources
  cp "$root/scripts/lib-vault.sh" scripts/lib-vault.sh
  good_hash=$(printf 'legitimate evidence\n' | sha256sum | cut -d' ' -f1)
  cat > wiki/sources/c.md <<SRC
---
title: Source - C
type: source
raw_file: "[[raw/articles/c]]"
source_id: $good_hash
---
SRC
  git add -A && git commit -q -m "ingest source c (page only — raw/articles/c.md not committed yet)"

  # raw/articles/c.md has never been committed, so this first commit reports as "Added", not
  # "Modified" — exactly the shape that let commit f38689b through against the real vault.
  printf 'TAMPERED before first commit\n' > raw/articles/c.md
  git add -A
  if git commit -q -m "first commit of tampered c" 2>/dev/null; then
    echo "FAIL pre-commit: allowed a drifted file through as a plain 'Added' file"; exit 3
  else
    echo "ok   pre-commit: blocks content drift even when git reports it as 'Added'"
  fi
  git restore --staged -- raw/ 2>/dev/null || true
  rm -f raw/articles/c.md

  printf 'legitimate evidence\n' > raw/articles/c.md
  git add -A
  if git commit -q -m "first commit of untouched c" 2>/dev/null; then
    echo "ok   pre-commit: allows the first commit of content that matches its recorded hash"
  else
    echo "FAIL pre-commit: blocked a late-but-correct first commit"; exit 3
  fi
) || fail=1

# ------------------------------------------------- OKF semantic guard, real git repo (Phase 3)
tmp2=$(mktemp -d)
trap 'rm -rf -- "$tmp" "$tmp2"' EXIT
(
  cd "$tmp2" || exit 1
  git init -q .
  git config user.email t@t.t; git config user.name t
  mkdir -p .githooks okf/decisions okf/experiments okf/projects scripts
  cp "$root/.githooks/pre-commit" .githooks/pre-commit
  chmod +x .githooks/pre-commit
  cp "$root/scripts/check-okf-guard.sh" scripts/check-okf-guard.sh
  cp "$root/scripts/lib-vault.sh" scripts/lib-vault.sh
  git config core.hooksPath .githooks

  cat > okf/decisions/d.md <<'EOF'
---
title: D
type: decision
status: accepted
---
# D
EOF
  cat > okf/experiments/e.md <<'EOF'
---
title: E
type: experiment
status: complete
---
## Conclusion
Final.
EOF
  cat > okf/projects/p.md <<'EOF'
---
title: P
type: project
status: active
owner: alice
started: 2026-01-01
review_date: 2026-06-01
---
## Status notes
EOF
  git add -A && git commit -q -m init

  # Editing an accepted decision must be blocked.
  printf '\nMore.\n' >> okf/decisions/d.md
  git add -A
  if git commit -q -m "edit accepted decision" 2>/dev/null; then
    echo "FAIL okf-guard: allowed editing an accepted decision"; exit 3
  else
    echo "ok   okf-guard: blocks editing an accepted decision"
  fi
  git reset -q --hard HEAD

  # Editing a completed experiment's conclusion must be blocked.
  # Portable in-place edit: BSD/macOS sed requires an argument to -i, GNU sed forbids one.
  # A portability suite that is not itself portable is the joke that writes itself.
  sed 's/Final\./Changed./' okf/experiments/e.md > e.tmp && mv e.tmp okf/experiments/e.md
  git add -A
  if git commit -q -m "edit completed experiment" 2>/dev/null; then
    echo "FAIL okf-guard: allowed editing a completed experiment"; exit 3
  else
    echo "ok   okf-guard: blocks editing a completed experiment"
  fi
  git reset -q --hard HEAD

  # Changing a project's protected field (status) must be blocked.
  sed 's/status: active/status: paused/' okf/projects/p.md > p.tmp && mv p.tmp okf/projects/p.md
  git add -A
  if git commit -q -m "change project status" 2>/dev/null; then
    echo "FAIL okf-guard: allowed changing a project's status field"; exit 3
  else
    echo "ok   okf-guard: blocks changing a project's protected field"
  fi
  git reset -q --hard HEAD

  # Appending a status note (no protected field touched) must be allowed — the negative case,
  # so this check can't quietly start blocking legitimate work.
  printf '\n- 2026-08-30 — noted.\n' >> okf/projects/p.md
  git add -A
  if git commit -q -m "append status note" 2>/dev/null; then
    echo "ok   okf-guard: allows appending a status note"
  else
    echo "FAIL okf-guard: blocked a legitimate status-note append"; exit 3
  fi
) || fail=1

# --------------------------- verify-vault 2c: OS-level lock check, real git repo
tmp3=$(mktemp -d)
trap 'rm -rf -- "$tmp" "$tmp2" "$tmp3"' EXIT
(
  cd "$tmp3" || exit 1
  git init -q .
  git config user.email t@t.t; git config user.name t
  mkdir -p scripts raw/articles
  cp "$root/scripts/verify-vault.sh" scripts/verify-vault.sh
  cp "$root/scripts/lib-vault.sh" scripts/lib-vault.sh
  printf 'evidence\n' > raw/articles/a.md
  git add -A && git commit -q -m init

  # Capability probe first. On a filesystem that cannot represent a cleared write bit, every file
  # reads as writable and the check under test has nothing to detect — a "pass" there would be a
  # lie. A test that cannot represent its own precondition must say so, not pass quietly.
  chmod 444 raw/articles/a.md
  if [ -w raw/articles/a.md ]; then
    echo "skip verify-vault 2c: filesystem cannot clear the write bit — check not exercised"
    exit 0
  fi

  # Committed evidence left writable must be reported. Only this section's line is asserted on:
  # the throwaway repo has no wiki-lint or policy files, so other sections legitimately fail.
  chmod u+w raw/articles/a.md
  out=$(bash scripts/verify-vault.sh 2>&1)
  case "$out" in
    *"committed evidence is writable"*) : ;;
    *) echo "FAIL verify-vault 2c: a writable committed evidence file was not reported"; exit 3 ;;
  esac

  # And it must clear once locked, or the finding is noise the operator learns to ignore.
  chmod 444 raw/articles/a.md
  out=$(bash scripts/verify-vault.sh 2>&1)
  case "$out" in
    *"all committed evidence is read-only"*)
      echo "ok   verify-vault 2c: reports writable committed evidence, clears once locked" ;;
    *) echo "FAIL verify-vault 2c: still reporting a finding after the lock was applied"; exit 3 ;;
  esac
) || fail=1

# --------------------------------------------------- policy pointer integrity
# The two old cases here planted drift between two policy copies. There is one copy now, so that
# plant plants nothing. These are the two failures that replaced it, and both are silent in a way
# the old drift was not: a missing import means a Claude Code session loads NO policy, and a
# re-grown CLAUDE.md means the vault is quietly back to two sources that can disagree.
# The live-files assertion moved to verify-vault.sh, which runs this checker on every invocation.

# 1. The @AGENTS.md import line removed from CLAUDE.md must be detected.
d=$(mktemp -d)
mkdir -p "$d/scripts"
cp "$here/check-policy-sync.sh" "$d/scripts/"
cp "$root/AGENTS.md" "$d/AGENTS.md"
grep -vxF '@AGENTS.md' "$root/CLAUDE.md" > "$d/CLAUDE.md"
if (cd "$d" && bash scripts/check-policy-sync.sh >/dev/null 2>&1); then
  bad "policy pointer: did NOT detect a missing @AGENTS.md import"
else
  ok "policy pointer: detects a missing @AGENTS.md import"
fi

# 2. CLAUDE.md re-grown into a full policy copy must be detected, import line or not.
{ cat "$root/AGENTS.md"; printf '%s\n' '@AGENTS.md'; } > "$d/CLAUDE.md"
if (cd "$d" && bash scripts/check-policy-sync.sh >/dev/null 2>&1); then
  bad "policy pointer: did NOT detect CLAUDE.md re-grown into a second policy copy"
else
  ok "policy pointer: detects CLAUDE.md re-grown into a second policy copy"
fi
rm -r -- "$d"

# --------------------------------------------------- command-pointer drift detection
# Real command files must currently be thin pointers with adequate tool permissions.
if bash "$here/check-command-pointers.sh" >/dev/null 2>&1; then
  ok "command pointers: live files are thin and permitted correctly"
else
  bad "command pointers: live .claude/commands/*.md have drifted from prompts/*.md"
fi

# Detector must fire when a command file is re-forked into a full copy.
d=$(mktemp -d)
mkdir -p "$d/scripts" "$d/prompts" "$d/.claude/commands"
cp "$here/check-command-pointers.sh" "$d/scripts/"
cp "$root/prompts/wiki-lint.md" "$d/prompts/"
cp "$root/prompts/wiki-ingest.md" "$d/prompts/"
cp "$root/prompts/wiki-query.md" "$d/prompts/"
cp "$root/.claude/commands/wiki-ingest.md" "$d/.claude/commands/"
cp "$root/.claude/commands/wiki-query.md" "$d/.claude/commands/"
# Simulate exactly what happened before this refactor: the command file re-grows its own
# "## Step" content instead of pointing at the prompt.
{ echo "---"; echo "allowed-tools: Read"; echo "---"; echo; cat "$root/prompts/wiki-lint.md"; } \
  > "$d/.claude/commands/wiki-lint.md"
if (cd "$d" && bash scripts/check-command-pointers.sh >/dev/null 2>&1); then
  bad "command pointers: did NOT detect a re-forked command file"
else
  ok "command pointers: detects a re-forked command file"
fi
rm -r -- "$d"

# Detector must fire when allowed-tools no longer covers what the prompt invokes.
d=$(mktemp -d)
mkdir -p "$d/scripts" "$d/prompts" "$d/.claude/commands"
cp "$here/check-command-pointers.sh" "$d/scripts/"
cp "$root/prompts/"*.md "$d/prompts/"
cp "$root/.claude/commands/"*.md "$d/.claude/commands/"
sed '/allowed-tools:/s/, Bash(bash scripts\/verify-vault\.sh)//' \
  "$root/.claude/commands/wiki-lint.md" > "$d/.claude/commands/wiki-lint.md"
if (cd "$d" && bash scripts/check-command-pointers.sh >/dev/null 2>&1); then
  bad "command pointers: did NOT detect a missing tool permission"
else
  ok "command pointers: detects a missing tool permission"
fi
rm -r -- "$d"

echo
[ "$fail" -eq 0 ] && { echo PASS; exit 0; } || { echo FAILED; exit 1; }
